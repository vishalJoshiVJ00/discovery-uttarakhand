-- ==============================================================================
-- Temporal Range Integrity Hardening (CHECK Constraints)
-- ==============================================================================

-- 1. Ensure booking start time strictly precedes end time (prevents empty and inverted ranges)
ALTER TABLE "Booking" ADD CONSTRAINT "chk_booking_temporal_order"
CHECK ("startTime" < "endTime");

-- 2. Ensure booking end time does not exceed the buffered reservation boundary
ALTER TABLE "Booking" ADD CONSTRAINT "chk_booking_buffer_order"
CHECK ("endTime" <= "endTimeWithBuffer");

-- 3. Ensure calendar block start date strictly precedes end date (prevents empty and inverted ranges)
ALTER TABLE "CalendarBlock" ADD CONSTRAINT "chk_calendar_block_temporal_order"
CHECK ("startDate" < "endDate");

