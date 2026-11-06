-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('USER', 'ADMIN');

-- CreateEnum
CREATE TYPE "ProviderKycStatus" AS ENUM ('KYC_PENDING', 'KYC_SUBMITTED', 'KYC_APPROVED', 'KYC_REJECTED');

-- CreateEnum
CREATE TYPE "LegalEligibilityStatus" AS ENUM ('LEGAL_GATE_PENDING', 'LEGAL_GATE_APPROVED');

-- CreateEnum
CREATE TYPE "VehicleListingStatus" AS ENUM ('DRAFT', 'UNDER_REVIEW', 'APPROVED_PENDING_LEGAL_GATE', 'ACTIVE_PUBLISHED', 'UNDER_MAINTENANCE_HOLD', 'SUSPENDED', 'INACTIVE');

-- CreateEnum
CREATE TYPE "RentalMode" AS ENUM ('SELF_DRIVE', 'WITH_DRIVER');

-- CreateEnum
CREATE TYPE "VehicleCategory" AS ENUM ('SCOOTER', 'MOTORCYCLE', 'HATCHBACK', 'SEDAN', 'SUV');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('DRAFT', 'PENDING_CONFIRMATION', 'CONFIRMED', 'REJECTED', 'CANCELLED_BY_TOURIST', 'CANCELLED_BY_PROVIDER', 'CANCELLED_NO_SHOW', 'EXPIRED_SLA', 'EXPIRED_HOLD', 'OVERBOOKING_PREVENTED', 'CLOSED');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING_CHECKOUT', 'PAYMENT_FAILED', 'CAPTURED', 'REFUND_PENDING', 'REFUNDED', 'FORFEITED');

-- CreateEnum
CREATE TYPE "PaymentOrderStatus" AS ENUM ('PENDING', 'CAPTURED', 'FAILED');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'TRIP_COMPLETED');

-- CreateEnum
CREATE TYPE "OnSiteSettlementStatus" AS ENUM ('NONE', 'PENDING_COLLECTION', 'COLLECTION_LOGGED', 'SETTLED', 'DISPUTED');

-- CreateEnum
CREATE TYPE "RefundStatus" AS ENUM ('NONE', 'REFUND_INITIATED', 'REFUND_PENDING_GATEWAY', 'REFUNDED', 'REFUND_FAILED', 'MANUAL_ESCALATION');

-- CreateEnum
CREATE TYPE "DisputeStatus" AS ENUM ('NONE', 'OPEN_INVESTIGATION', 'RESOLVED_SETTLED', 'RESOLVED_REFUNDED', 'RESOLVED_DISMISSED');

-- CreateEnum
CREATE TYPE "LedgerAccountType" AS ENUM ('ASSET_GATEWAY_CLEARING', 'ASSET_PLATFORM_BANK', 'LIABILITY_PROVIDER_PAYABLE_PENDING', 'LIABILITY_PROVIDER_PAYABLE_CLEARED', 'LIABILITY_CUSTOMER_REFUND_PAYABLE', 'REVENUE_PLATFORM_COMMISSION', 'REVENUE_PLATFORM_CANCELLATION_FEE', 'EXPENSE_GATEWAY_MDR');

-- CreateEnum
CREATE TYPE "OutboxEventStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "fullName" TEXT,
    "email" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "familyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "isRevoked" BOOLEAN NOT NULL DEFAULT false,
    "expiresAt" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProviderProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "businessName" TEXT NOT NULL,
    "operatorType" TEXT NOT NULL,
    "kycStatus" "ProviderKycStatus" NOT NULL DEFAULT 'KYC_PENDING',
    "legalStatus" "LegalEligibilityStatus" NOT NULL DEFAULT 'LEGAL_GATE_PENDING',
    "rejectionReason" TEXT,
    "bankAccountEncrypted" TEXT,
    "bankAccountLast4" TEXT,
    "bankIfscEncrypted" TEXT,
    "bankIfscMasked" TEXT,
    "bankAccountHolderName" TEXT,
    "bankVerificationStatus" TEXT NOT NULL DEFAULT 'UNVERIFIED',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "ProviderProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Driver" (
    "id" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "commercialLicenceNo" TEXT NOT NULL,
    "licenceExpiryDate" TIMESTAMPTZ NOT NULL,
    "hillEndorsementVerified" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Driver_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vehicle" (
    "id" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "modelName" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "yearOfManufacture" INTEGER NOT NULL,
    "category" "VehicleCategory" NOT NULL,
    "rentalMode" "RentalMode" NOT NULL,
    "transmission" TEXT NOT NULL,
    "fuelType" TEXT NOT NULL,
    "seatingCapacity" INTEGER NOT NULL,
    "registrationNumber" TEXT NOT NULL,
    "status" "VehicleListingStatus" NOT NULL DEFAULT 'DRAFT',
    "dailyBasePrice" DECIMAL(10,2) NOT NULL,
    "securityDeposit" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    "kmAllowancePerDay" INTEGER NOT NULL DEFAULT 150,
    "extraKmRate" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    "locationCluster" TEXT NOT NULL,
    "pickupAddress" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VehiclePhoto" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "storageProvider" TEXT NOT NULL DEFAULT 'CLOUDINARY',
    "publicUrl" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "fileSize" INTEGER NOT NULL,
    "isCover" BOOLEAN NOT NULL DEFAULT false,
    "orderIndex" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VehiclePhoto_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ComplianceDocument" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "documentType" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "storageProvider" TEXT NOT NULL DEFAULT 'CLOUDINARY',
    "mimeType" TEXT NOT NULL,
    "fileSize" INTEGER NOT NULL,
    "checksumSha256" TEXT NOT NULL,
    "expiryDate" TIMESTAMPTZ,
    "isVerified" BOOLEAN NOT NULL DEFAULT false,
    "verifiedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ComplianceDocument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CalendarBlock" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "startDate" TIMESTAMPTZ NOT NULL,
    "endDate" TIMESTAMPTZ NOT NULL,
    "reason" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CalendarBlock_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Booking" (
    "id" TEXT NOT NULL,
    "bookingReferenceNumber" TEXT NOT NULL,
    "touristId" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "driverId" TEXT,
    "bookingStatus" "BookingStatus" NOT NULL DEFAULT 'DRAFT',
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING_CHECKOUT',
    "tripStatus" "TripStatus" NOT NULL DEFAULT 'NOT_STARTED',
    "settlementStatus" "OnSiteSettlementStatus" NOT NULL DEFAULT 'NONE',
    "refundStatus" "RefundStatus" NOT NULL DEFAULT 'NONE',
    "disputeStatus" "DisputeStatus" NOT NULL DEFAULT 'NONE',
    "startTime" TIMESTAMPTZ NOT NULL,
    "endTime" TIMESTAMPTZ NOT NULL,
    "endTimeWithBuffer" TIMESTAMPTZ NOT NULL,
    "holdExpiresAt" TIMESTAMPTZ,
    "slaExpiresAt" TIMESTAMPTZ,
    "grossRentalFare" DECIMAL(10,2) NOT NULL,
    "onlineAdvanceAmount" DECIMAL(10,2) NOT NULL,
    "platformCommission" DECIMAL(10,2) NOT NULL,
    "providerAdvanceCredit" DECIMAL(10,2) NOT NULL,
    "onSiteBalanceAmount" DECIMAL(10,2) NOT NULL,
    "securityDepositAmount" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    "pickupOtpHash" TEXT,
    "pickupOtpExpiresAt" TIMESTAMPTZ,
    "pickupOtpAttempts" INTEGER NOT NULL DEFAULT 0,
    "pickupOtpVerifiedAt" TIMESTAMPTZ,
    "dropOtpHash" TEXT,
    "dropOtpExpiresAt" TIMESTAMPTZ,
    "dropOtpAttempts" INTEGER NOT NULL DEFAULT 0,
    "dropOtpVerifiedAt" TIMESTAMPTZ,
    "handoverOtpHash" TEXT,
    "handoverOtpExpiresAt" TIMESTAMPTZ,
    "handoverOtpAttempts" INTEGER NOT NULL DEFAULT 0,
    "handoverOtpVerifiedAt" TIMESTAMPTZ,
    "returnOtpHash" TEXT,
    "returnOtpExpiresAt" TIMESTAMPTZ,
    "returnOtpAttempts" INTEGER NOT NULL DEFAULT 0,
    "returnOtpVerifiedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SelfDriveChecklist" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "handoverOdometer" INTEGER NOT NULL,
    "handoverFuelFraction" TEXT NOT NULL,
    "handoverPhotoStorageKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "physicalDlInspected" BOOLEAN NOT NULL DEFAULT false,
    "handoverCompletedAt" TIMESTAMPTZ,
    "returnOdometer" INTEGER,
    "returnFuelFraction" TEXT,
    "returnPhotoStorageKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "netDepositReturned" DECIMAL(10,2),
    "depositSettlementStorageKey" TEXT,
    "returnCompletedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "SelfDriveChecklist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Dispute" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "raisedById" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "evidenceStorageKeys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "adminNotes" TEXT,
    "resolutionType" TEXT,
    "status" "DisputeStatus" NOT NULL DEFAULT 'OPEN_INVESTIGATION',
    "resolvedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Dispute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentOrder" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "gatewayProvider" TEXT NOT NULL,
    "gatewayOrderId" TEXT NOT NULL,
    "gatewayPaymentId" TEXT,
    "amount" DECIMAL(10,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "status" "PaymentOrderStatus" NOT NULL DEFAULT 'PENDING',
    "idempotencyKey" TEXT NOT NULL,
    "webhookPayloadRaw" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "PaymentOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefundRecord" (
    "id" TEXT NOT NULL,
    "paymentOrderId" TEXT NOT NULL,
    "gatewayRefundId" TEXT,
    "amount" DECIMAL(10,2) NOT NULL,
    "status" "RefundStatus" NOT NULL DEFAULT 'REFUND_INITIATED',
    "idempotencyKey" TEXT NOT NULL,
    "retryCount" INTEGER NOT NULL DEFAULT 0,
    "failureReason" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "RefundRecord_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OutboxEvent" (
    "id" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" "OutboxEventStatus" NOT NULL DEFAULT 'PENDING',
    "retryCount" INTEGER NOT NULL DEFAULT 0,
    "maxRetries" INTEGER NOT NULL DEFAULT 5,
    "lastError" TEXT,
    "processedAt" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "OutboxEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProcessedWebhookEvent" (
    "id" TEXT NOT NULL,
    "gatewayProvider" TEXT NOT NULL,
    "gatewayEventId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "idempotencyKey" TEXT,
    "processedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProcessedWebhookEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LedgerAccount" (
    "id" TEXT NOT NULL,
    "accountType" "LedgerAccountType" NOT NULL,
    "providerId" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LedgerAccount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LedgerJournalEntry" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT,
    "entryType" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "idempotencyKey" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LedgerJournalEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LedgerPosting" (
    "id" TEXT NOT NULL,
    "journalEntryId" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "direction" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LedgerPosting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PayoutBatch" (
    "id" TEXT NOT NULL,
    "batchReference" TEXT NOT NULL,
    "totalAmount" DECIMAL(12,2) NOT NULL,
    "status" TEXT NOT NULL,
    "generatedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "remittedAt" TIMESTAMPTZ,

    CONSTRAINT "PayoutBatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PayoutItem" (
    "id" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "bankAccountLast4" TEXT NOT NULL,
    "bankAccountEncrypted" TEXT NOT NULL,
    "bankIfscMasked" TEXT NOT NULL,
    "bankIfscEncrypted" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "utrNumber" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PayoutItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "touristId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT NOT NULL,
    "reply" TEXT,
    "repliedAt" TIMESTAMPTZ,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "beforeState" JSONB,
    "afterState" JSONB,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_phoneNumber_key" ON "User"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_tokenHash_key" ON "RefreshToken"("tokenHash");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- CreateIndex
CREATE INDEX "RefreshToken_familyId_idx" ON "RefreshToken"("familyId");

-- CreateIndex
CREATE UNIQUE INDEX "ProviderProfile_userId_key" ON "ProviderProfile"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_registrationNumber_key" ON "Vehicle"("registrationNumber");

-- CreateIndex
CREATE INDEX "Vehicle_locationCluster_category_status_idx" ON "Vehicle"("locationCluster", "category", "status");

-- CreateIndex
CREATE INDEX "CalendarBlock_vehicleId_startDate_endDate_idx" ON "CalendarBlock"("vehicleId", "startDate", "endDate");

-- CreateIndex
CREATE UNIQUE INDEX "Booking_bookingReferenceNumber_key" ON "Booking"("bookingReferenceNumber");

-- CreateIndex
CREATE INDEX "Booking_vehicleId_startTime_endTimeWithBuffer_idx" ON "Booking"("vehicleId", "startTime", "endTimeWithBuffer");

-- CreateIndex
CREATE INDEX "Booking_touristId_idx" ON "Booking"("touristId");

-- CreateIndex
CREATE INDEX "Booking_bookingStatus_idx" ON "Booking"("bookingStatus");

-- CreateIndex
CREATE UNIQUE INDEX "SelfDriveChecklist_bookingId_key" ON "SelfDriveChecklist"("bookingId");

-- CreateIndex
CREATE INDEX "Dispute_bookingId_idx" ON "Dispute"("bookingId");

-- CreateIndex
CREATE INDEX "Dispute_status_idx" ON "Dispute"("status");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentOrder_gatewayOrderId_key" ON "PaymentOrder"("gatewayOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentOrder_gatewayPaymentId_key" ON "PaymentOrder"("gatewayPaymentId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentOrder_idempotencyKey_key" ON "PaymentOrder"("idempotencyKey");

-- CreateIndex
CREATE INDEX "PaymentOrder_bookingId_idx" ON "PaymentOrder"("bookingId");

-- CreateIndex
CREATE UNIQUE INDEX "RefundRecord_gatewayRefundId_key" ON "RefundRecord"("gatewayRefundId");

-- CreateIndex
CREATE UNIQUE INDEX "RefundRecord_idempotencyKey_key" ON "RefundRecord"("idempotencyKey");

-- CreateIndex
CREATE INDEX "RefundRecord_paymentOrderId_idx" ON "RefundRecord"("paymentOrderId");

-- CreateIndex
CREATE INDEX "OutboxEvent_status_createdAt_idx" ON "OutboxEvent"("status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "ProcessedWebhookEvent_gatewayEventId_key" ON "ProcessedWebhookEvent"("gatewayEventId");

-- CreateIndex
CREATE INDEX "ProcessedWebhookEvent_gatewayProvider_gatewayEventId_idx" ON "ProcessedWebhookEvent"("gatewayProvider", "gatewayEventId");

-- CreateIndex
CREATE INDEX "LedgerAccount_accountType_providerId_idx" ON "LedgerAccount"("accountType", "providerId");

-- CreateIndex
CREATE UNIQUE INDEX "LedgerJournalEntry_idempotencyKey_key" ON "LedgerJournalEntry"("idempotencyKey");

-- CreateIndex
CREATE INDEX "LedgerJournalEntry_bookingId_idx" ON "LedgerJournalEntry"("bookingId");

-- CreateIndex
CREATE INDEX "LedgerPosting_accountId_idx" ON "LedgerPosting"("accountId");

-- CreateIndex
CREATE INDEX "LedgerPosting_journalEntryId_idx" ON "LedgerPosting"("journalEntryId");

-- CreateIndex
CREATE UNIQUE INDEX "PayoutBatch_batchReference_key" ON "PayoutBatch"("batchReference");

-- CreateIndex
CREATE UNIQUE INDEX "Review_bookingId_key" ON "Review"("bookingId");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_idx" ON "AuditLog"("entityType", "entityId");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProviderProfile" ADD CONSTRAINT "ProviderProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Driver" ADD CONSTRAINT "Driver_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VehiclePhoto" ADD CONSTRAINT "VehiclePhoto_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ComplianceDocument" ADD CONSTRAINT "ComplianceDocument_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CalendarBlock" ADD CONSTRAINT "CalendarBlock_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_touristId_fkey" FOREIGN KEY ("touristId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "Driver"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SelfDriveChecklist" ADD CONSTRAINT "SelfDriveChecklist_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dispute" ADD CONSTRAINT "Dispute_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Dispute" ADD CONSTRAINT "Dispute_raisedById_fkey" FOREIGN KEY ("raisedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentOrder" ADD CONSTRAINT "PaymentOrder_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefundRecord" ADD CONSTRAINT "RefundRecord_paymentOrderId_fkey" FOREIGN KEY ("paymentOrderId") REFERENCES "PaymentOrder"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerAccount" ADD CONSTRAINT "LedgerAccount_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerJournalEntry" ADD CONSTRAINT "LedgerJournalEntry_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerPosting" ADD CONSTRAINT "LedgerPosting_journalEntryId_fkey" FOREIGN KEY ("journalEntryId") REFERENCES "LedgerJournalEntry"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LedgerPosting" ADD CONSTRAINT "LedgerPosting_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "LedgerAccount"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PayoutItem" ADD CONSTRAINT "PayoutItem_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "PayoutBatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PayoutItem" ADD CONSTRAINT "PayoutItem_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "ProviderProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Review" ADD CONSTRAINT "Review_touristId_fkey" FOREIGN KEY ("touristId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
