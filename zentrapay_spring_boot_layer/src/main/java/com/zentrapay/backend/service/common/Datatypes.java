package com.zentrapay.backend.service.common;


import lombok.Getter;

public class Datatypes {

    //    CHALLENGES REWARDS TYPES
    public enum RewardType {
        POINTS,
        GIFT_BOX,
        CASHBACK,
        BADGE
    }

    //    TUTORIALS TYPES
    public enum TutorialType {
        BUDGETING,
        SAVING,
        INVESTING,
        DEBT_MANAGEMENT,
        FINANCIAL_PLANNING,
        GENERAL
    }

    //    CATEGORIES OF THE CHALLENGES
    public enum ChallengeCategory {
        SAVINGS,
        STREAK,
        INVESTMENT,
        SPENDING_LIMIT
    }

    // Mechanical structure of the challenge
    public enum ChallengeType {
        FIXED_AMOUNT,
        RECURRING_DAILY,
        SAVINGS_GOAL
    }

    //CHALLENGES STATUS TYPES
    public enum ChallengeStatus {
        IN_PROGRESS,
        COMPLETED,
        FAILED,
        ABANDONED
    }

    public enum CardForm {
        VIRTUAL_CARD("virtual_card"),
        PHYSICAL_CARD("physical_card");

        private final String form;

        CardForm(String form) {
            this.form = form;
        }

        public String getCardForm() {
            return form;
        }
    }

    //TRANSACTIONS STATUS
    // INITIATED = money debited, gateway not called yet
    // PENDING   = gateway accepted it, waiting for the webhook
    // SUCCESS / FAILED / EXPIRED are final; REVERSED = a settled payout the gateway later took back (refunded)
    public enum TransactionStatus {
        INITIATED,
        PENDING,
        SUCCESS,
        FAILED,
        REVERSED,
        EXPIRED
    }

    //    RECIPIENT TYPES
    public enum AccountStatus {
        ACTIVE("active"),
        FROZEN("frozen"),
        SUSPENDED("suspended");

        private final String status;

        AccountStatus(String status) {
            this.status = status;
        }

        public String getAccountStatus() {
            return status;
        }
    }

    //USER TYPE
    public enum UserType {
        APP_USER,
        MERCHANT,
        KYC_OFFICER,
        ADMIN,
        SUPPORT_AGENT,
        OTHERS,
    }

    //USER STATUS
    public enum UserStatus {
        ACTIVE,
        INACTIVE,
        FROZEN,
    }

    //WALLET TYPES
    public enum AlertLevel {
        LOW("low"),
        MEDIUM("medium"),
        HIGH("high");

        private final String level;

        AlertLevel(String level) {
            this.level = level;
        }

        public String getAlertType() {
            return level;
        }

    }

    //PAYMENT GATEWAYS
    public enum PaymentGateway {
        PAYSTACK,
        FLUTTERWAVE,
        ONAFRIQ
    }

    public enum TransactionType {
        // Comment: Funding the system (User depositing money via external payment gateways)
        CASH_IN_MOMO,
        CASH_IN_BANK,
        CASH_IN_CARD,

        // Comment: Disbursing money out of the system to external rails
        CASH_OUT_MOMO,
        CASH_OUT_BANK,

        // Comment: Paying a bill (electricity, TV, airtime ...) through a gateway
        BILL_PAYMENT,
        // Comment: Internal ledger movements between user wallets
        P2P_TRANSFER,

        // funding user wallet account
        WALLET_FUNDING,

        // Comment: Money moved between a wallet account and one of the user's savings goals
        SAVINGS_DEPOSIT,
        SAVINGS_WITHDRAWAL,

        // Comment: Money moved between a wallet account and a ZInvest position (buy / sell)
        INVESTMENT_BUY,
        INVESTMENT_SELL,

        // Comment: Micro-loans - the loan paid into the wallet, and the user paying it back
        LOAN_DISBURSEMENT,
        LOAN_REPAYMENT,

        // Comment: Platform operational adjustments, fees, and refunds
        PLATFORM_FEE,
        REFUND
    }

    // LEDGER ENTRY TYPES
    public enum LedgerEntryType {
        DEBIT("debit"),
        CREDIT("credit");

        private final String type;

        LedgerEntryType(String type) {
            this.type = type;
        }

        public String getLedgerEntryType() {
            return type;
        }
    }

    // BILL / SERVICE PROVIDER CATEGORIES
    // Mirrors the provider_categories lookup table (V2 seed + V23 'OTHERS').
    // `iconKey` is the icon the client renders for the category — the Flutter
    // side keeps a matching map in provider_display.dart, so adding a
    // category here means adding it there too (unknown codes fall back to
    // the receipt icon on the client and 'others' here).
    public enum ProviderCategory {
        UTILITY("Electricity & Water", "utility"),
        AIRTIME("Airtime & Mobile Data", "airtime"),
        TV_SUBSCRIPTION("TV Subscription", "tv"),
        INTERNET("Internet & Broadband", "internet"),
        INSURANCE("Insurance", "insurance"),
        GOVERNMENT("Government Services", "government"),
        TRANSPORT("Transport & Toll", "transport"),
        EDUCATION("Education & School Fees", "education"),
        HEALTH("Health & Medical", "health"),
        ENTERTAINMENT("Entertainment & Ticketing", "entertainment"),
        OTHERS("Other Services", "others");

        private final String displayName;
        private final String iconKey;

        ProviderCategory(String displayName, String iconKey) {
            this.displayName = displayName;
            this.iconKey = iconKey;
        }

        public String getDisplayName() {
            return displayName;
        }

        public String getIconKey() {
            return iconKey;
        }

        /**
         * Null-safe parse of a DB/DTO category code; unknown codes map to OTHERS.
         */
        public static ProviderCategory fromCode(String code) {
            if (code == null) return OTHERS;
            try {
                return valueOf(code.trim().toUpperCase());
            } catch (IllegalArgumentException e) {
                return OTHERS;
            }
        }
    }

    // SAVINGS LEDGER SOURCES — shared vocabulary for the user_savings ledger
    // (V24).
    public enum SavingsSource {
        MILESTONE("milestone"),
        CHALLENGE("challenge"),
        MANUAL("manual"),
        DEPOSIT("deposit");

        private final String source;

        SavingsSource(String source) {
            this.source = source;
        }

        public String getSavingsSource() {
            return source;
        }
    }

    public enum PaymentMethod {
        BANK_TRANSFER("bank_transfer"),
        MOBILE_MONEY_TRANSFER("mobile_money_transfer"),
        CARD_TRANSFER("card_transfer");

        private final String method;

        PaymentMethod(String method) {
            this.method = method;
        }

        public final String getMethod() {
            return method;
        }
    }

    public enum AntiMoneyStatuses {
        CLEAR("clear"),
        IN_REVIEW("in_review"),
        FLAGGED("flagged");


        private final String method;

        AntiMoneyStatuses(String method) {
            this.method = method;
        }

        public final String getMethod() {
            return method;
        }
    }

    public enum PayoutType {
        BANK("bank"),
        MOBILE_MONEY("mobile_money");

        private final String type;

        PayoutType(String type) {
            this.type = type;
        }

        public String getPayoutType() {
            return type;
        }
    }

    public enum FundingType {
        BANK_TRANSFER("bank_transfer"),
        MOBILE_MONEY("mobile_money"),
        CARD("card"),
        USSD("ussd");

        private final String type;

        FundingType(String type) {
            this.type = type;
        }

        public String getFundingType() {
            return type;
        }
    }

    public enum InvestmentType {
        STOCK("STOCK"),
        ETF("etf"),
        COMMODITY("commodity"),
        CRYPTO("crypto"),
        OTHERS("others");

        private final String type;

        InvestmentType(String type) {
            this.type = type;
        }

        public String getInvestmentType() {
            return type;
        }
    }

    public enum InvestmentStatus {
        ACTIVE("active"),
        CLOSED("closed");

        private final String type;

        InvestmentStatus(String type) {
            this.type = type;
        }

        public String getInvestmentStatus() {
            return type;
        }
    }

    public enum LoanStatus {
        PENDING("pending"),
        APPROVED("approved"),
        REJECTED("rejected"),
        ACTIVE("active"),
        CLOSED("closed"),
        DEFAULT("default");

        private final String status;

        LoanStatus(String status) {
            this.status = status;
        }

        public String getLoanStatus() {
            return status;
        }
    }

    public enum CardStatus {
        ACTIVE("active"),
        FROZEN("frozen"),
        REMOVED("removed");

        private final String status;

        CardStatus(String status) {
            this.status = status;
        }

        public String getCardStatus() {
            return status;
        }

    }

    public enum NotificationTypes {
        CREDIT("credit"),
        DEBIT("debit");

        private final String type;

        NotificationTypes(String type) {
            this.type = type;
        }

        public String getNotificationTypes() {
            return type;
        }

    }

    public enum CardType {
        CREDIT("credit"),
        DEBIT("debit"),
        PREPAID("prepaid");

        private final String type;

        CardType(String type) {
            this.type = type;
        }

        public String getCardType() {
            return type;
        }

    }

    public enum AutoSaveFrequency {
        DAILY("daily"),
        WEEKLY("weekly"),
        MONTHLY("monthly");

        private final String f;

        AutoSaveFrequency(String f) {
            this.f = f;
        }

        public String getAutoSaveFrequency() {
            return f;
        }

    }

    public enum BiometricType {
        FINGERPRINT("fingerprint"),
        FACE("face"),
        IRIS("iris"),
        VOICE("voice"),
        PASSKEY("passkey"),
        DEVICE_BIOMETRIC("device_biometric");

        private final String type;

        BiometricType(String type) {
            this.type = type;
        }

        public String getBiometricType() {
            return type;
        }

    }

    public enum ServiceCategory {
        AIRTIME("airtime"),
        DATA_BUNDLE("data_bundle"),
        ELECTRICITY("electricity"),
        CABLE_TV("cable_tv"),
        INTERNET("internet"),
        WATER("water"),
        BETTING("betting");

        private final String category;

        ServiceCategory(String category) {
            this.category = category;
        }

        public String getServiceCategory() {
            return category;
        }
    }

    public enum UserBankConnectionStatus {
        ACTIVE("active"),
        INACTIVE("inactive"),
        RE_AUTH_REQUIRED("re_auth_required");

        private final String status;

        UserBankConnectionStatus(String status) {
            this.status = status;
        }

        public String getUserBankConnectionStatus() {
            return status;
        }
    }

    // Supported spending limit reset/evaluation periods.
    public enum BudgetPeriod {
        DAILY("daily"),
        WEEKLY("weekly"),
        MONTHLY("monthly"),
        YEARLY("yearly");

        private final String period;

        BudgetPeriod(String period) {
            this.period = period;
        }

        public String getBudgetPeriod() {
            return period;
        }
    }

    public enum CommandType {
        VOICE("voice"),
        TEXT("text");

        private final String type;

        CommandType(String type) {
            this.type = type;
        }

        public String getCommandType() {
            return type;
        }
    }

    public enum CommandStatus {
        PROCESSED("processed"),
        FLAGGED("flagged");

        private final String status;

        CommandStatus(String status) {
            this.status = status;
        }

        public String getCommandStatus() {
            return status;
        }
    }

    public enum KYCDocumentVerificationStatus {
        SUBMITTED("submitted"),
        PENDING("pending"),
        VERIFIED("verified"),
        REJECTED("rejected");

        private final String status;

        KYCDocumentVerificationStatus(String status) {
            this.status = status;
        }

        public String getKYCDocumentVerificationStatus() {
            return status;
        }
    }

    public enum KYCDocumentType {
        PASSPORT("passport"),
        NATIONAL_ID("national_id"),
        DRIVER_LICENCE("driver_licence");

        private final String type;

        KYCDocumentType(String type) {
            this.type = type;
        }

        public String getKYCDocumentType() {
            return type;
        }
    }

    public enum UserRiskScoreLevel {
        LOW("low"),
        MEDIUM("medium"),
        HIGH("high");

        private final String level;

        UserRiskScoreLevel(String level) {
            this.level = level;
        }

        public String getUserRiskScoreLevel() {
            return level;
        }
    }

    public enum AccountTypes {
        USER("user"),
        FLOAT("float"),
        CLEARING("clearing");

        private final String type;

        AccountTypes(String type) {
            this.type = type;
        }

        public String getAccountTypes() {
            return type;
        }
    }

    @Getter
    public enum Gateway {
        FLUTTERWAVE("flutterwave"),
        PAYSTACK("paystack"),
        ONAFRIQ("onafriq");

        private final String gateway;

        Gateway(String gateway) {
            this.gateway = gateway;
        }

    }

}
