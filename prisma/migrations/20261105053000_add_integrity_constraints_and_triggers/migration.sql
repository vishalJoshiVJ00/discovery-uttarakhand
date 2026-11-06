-- ==============================================================================
-- 1. PostgreSQL GiST Temporal Exclusion Constraints (Architecture v1.0.3 Section 8.2)
-- ==============================================================================

-- Exclusion constraint preventing overlapping vehicle reservations
ALTER TABLE "Booking" ADD CONSTRAINT "no_overlapping_vehicle_reservations"
EXCLUDE USING GIST (
  "vehicleId" WITH =,
  tstzrange("startTime", "endTimeWithBuffer", '[)') WITH &&
)
WHERE ("bookingStatus" IN ('CONFIRMED', 'PENDING_CONFIRMATION'));

-- Exclusion constraint preventing overlapping driver assignments (With-Driver)
ALTER TABLE "Booking" ADD CONSTRAINT "no_overlapping_driver_assignments"
EXCLUDE USING GIST (
  "driverId" WITH =,
  tstzrange("startTime", "endTimeWithBuffer", '[)') WITH &&
)
WHERE (
  "driverId" IS NOT NULL 
  AND "bookingStatus" IN ('CONFIRMED', 'PENDING_CONFIRMATION')
);

-- Exclusion constraint preventing overlapping provider calendar blocks
ALTER TABLE "CalendarBlock" ADD CONSTRAINT "no_overlapping_calendar_blocks"
EXCLUDE USING GIST (
  "vehicleId" WITH =,
  tstzrange("startDate", "endDate", '[)') WITH &&
);

-- ==============================================================================
-- 2. Immutable Double-Entry Ledger Architecture Enforcement (Architecture v1.0.3 Section 9.2.1)
-- ==============================================================================

CREATE OR REPLACE FUNCTION prevent_ledger_mutation() RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Ledger records are strictly immutable. UPDATE and DELETE operations are prohibited on %. (Entity ID: %)', TG_TABLE_NAME, OLD.id;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_immutable_ledger_journal ON "LedgerJournalEntry";
CREATE TRIGGER trg_immutable_ledger_journal
BEFORE UPDATE OR DELETE ON "LedgerJournalEntry"
FOR EACH ROW EXECUTE FUNCTION prevent_ledger_mutation();

DROP TRIGGER IF EXISTS trg_immutable_ledger_posting ON "LedgerPosting";
CREATE TRIGGER trg_immutable_ledger_posting
BEFORE UPDATE OR DELETE ON "LedgerPosting"
FOR EACH ROW EXECUTE FUNCTION prevent_ledger_mutation();

-- ==============================================================================
-- 3. Dual Deferred Balance & Postings Constraint Triggers (Architecture v1.0.3 Section 9.2.2)
-- ==============================================================================

-- Trigger Function A: Evaluated on LedgerPosting insertions
CREATE OR REPLACE FUNCTION verify_journal_entry_balance() RETURNS TRIGGER AS $$
DECLARE
  posting_count INT;
  debit_sum NUMERIC(10, 2);
  credit_sum NUMERIC(10, 2);
  invalid_amount_count INT;
  invalid_direction_count INT;
BEGIN
  SELECT 
    COUNT(*),
    COALESCE(SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE 0 END), 0),
    COUNT(CASE WHEN amount <= 0 THEN 1 END),
    COUNT(CASE WHEN direction NOT IN ('DEBIT', 'CREDIT') THEN 1 END)
  INTO 
    posting_count, 
    debit_sum, 
    credit_sum, 
    invalid_amount_count, 
    invalid_direction_count
  FROM "LedgerPosting"
  WHERE "journalEntryId" = NEW."journalEntryId";

  IF posting_count < 2 THEN
    RAISE EXCEPTION 'Ledger journal entry % must have at least 2 postings, found %', NEW."journalEntryId", posting_count;
  END IF;

  IF invalid_amount_count > 0 THEN
    RAISE EXCEPTION 'Ledger postings must have strictly positive amounts (> 0) in entry %', NEW."journalEntryId";
  END IF;

  IF invalid_direction_count > 0 THEN
    RAISE EXCEPTION 'Ledger posting directions must be strictly DEBIT or CREDIT in entry %', NEW."journalEntryId";
  END IF;

  IF debit_sum <> credit_sum THEN
    RAISE EXCEPTION 'Ledger transaction unbalanced for entry %: Total Debits (%) != Total Credits (%)', NEW."journalEntryId", debit_sum, credit_sum;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger Function B: Evaluated on LedgerJournalEntry creation to prevent zero-posting journals
CREATE OR REPLACE FUNCTION verify_journal_entry_has_postings() RETURNS TRIGGER AS $$
DECLARE
  posting_count INT;
BEGIN
  SELECT COUNT(*) INTO posting_count
  FROM "LedgerPosting"
  WHERE "journalEntryId" = NEW.id;

  IF posting_count < 2 THEN
    RAISE EXCEPTION 'Ledger journal entry % has % postings. Every journal entry must have at least 2 postings at commit.', NEW.id, posting_count;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Constraint Trigger 1: Evaluated on LedgerPosting at transaction commit
DROP TRIGGER IF EXISTS trg_verify_journal_balance ON "LedgerPosting";
CREATE CONSTRAINT TRIGGER trg_verify_journal_balance
AFTER INSERT ON "LedgerPosting"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_journal_entry_balance();

-- Constraint Trigger 2: Evaluated on LedgerJournalEntry at transaction commit
DROP TRIGGER IF EXISTS trg_verify_journal_entry_has_postings ON "LedgerJournalEntry";
CREATE CONSTRAINT TRIGGER trg_verify_journal_entry_has_postings
AFTER INSERT ON "LedgerJournalEntry"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION verify_journal_entry_has_postings();

-- ==============================================================================
-- 4. Platform vs. Provider Ledger Accounts Uniqueness (Architecture v1.0.3 Section 9.2.3)
-- ==============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS "uq_platform_ledger_account" 
ON "LedgerAccount" ("accountType") 
WHERE "providerId" IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "uq_provider_ledger_account" 
ON "LedgerAccount" ("accountType", "providerId") 
WHERE "providerId" IS NOT NULL;

