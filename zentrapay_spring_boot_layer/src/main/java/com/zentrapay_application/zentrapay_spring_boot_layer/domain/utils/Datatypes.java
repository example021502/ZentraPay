package com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils;


public class Datatypes {

//    CHALLENGES REWARDS TYPES
    public enum RewardType {
        POINTS,
        GIFT_BOX,
        CASHBACK,
        BADGE
    }

//    TUTORIALS TYPES
    public enum TutorialTypeEnum {
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
    public enum TransactionStatus {
      INITIATED,
      STK_PUSH_TRIGGERED,
      PENDING_USER_PIN,
      SUCCESS,
      FAILED,
      EXPIRED
    }

    //USER TYPE
    public enum UserType {
      APP_USER,
      MERCHANT,
      AGENT,
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
        FLUTTERWAV,
        ONAFRI
    }

    //PAYMENT GATEWAYS
    public enum TransactionType {
        MOMO_TRANSFER,
        BANK_TRANSFER,
        CARD_PAYMENT,
        WALLET_TOPUP,
        INTERNAL
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

        /** Null-safe parse of a DB/DTO category code; unknown codes map to OTHERS. */
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
