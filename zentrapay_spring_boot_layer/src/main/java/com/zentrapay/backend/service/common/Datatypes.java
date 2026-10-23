package com.zentrapay.backend.service.common;


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

    //CHALLENGES DIFFICULTY LEVELS
    public enum ChallengeDifficulty {
        EASY,
        MEDIUM,
        HARD,
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
    public enum RecipientType {
        INTERNAL_WALLET,
        BANK_ACCOUNT,
        MOBILE_MONEY,
        MERCHANT_ACCOUNT,
        BILL_SERVICE_PROVIDER,
        SELF_OWNED_WALLET
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
    public enum WalletTypes {
        FIAT_DIGITAL_CURRENCY,
        CRYPTO_CURRENCY,
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

        // Comment: Platform operational adjustments, fees, and refunds
        PLATFORM_FEE,
        REFUND
    }

    // LEDGER ENTRY TYPES
    public enum LedgerEntryType {
        DEBIT,
        CREDIT
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
        MILESTONE,
        CHALLENGE,
        MANUAL,
        DEPOSIT
    }

}
