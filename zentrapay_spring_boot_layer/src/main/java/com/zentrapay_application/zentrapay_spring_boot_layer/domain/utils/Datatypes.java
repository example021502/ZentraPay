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

}
