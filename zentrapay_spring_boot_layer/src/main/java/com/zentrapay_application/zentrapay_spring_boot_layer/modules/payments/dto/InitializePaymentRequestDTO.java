package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;


/**
 * POST /api/payments/initialize — customer checkout (inbound wallet funding).
 * The authenticated caller is the payer; {@code email} is optional and
 * defaults to the JWT user's email. {@code currencyCode} selects the
 * corridor: the gateway is resolved from it (national -> PAYSTACK,
 * international -> ONAFRIQ, failover -> FLUTTERWAVE).
 */
public record InitializePaymentRequestDTO(
        @NotNull(message = "PIN missing!")
        String pin,
        @NotNull(message = "Transaction reference missing!")
        String TXN_Ref,
        TransferDetails transfer,
        AppUserDetails appUser,
        BankDetails bank,
//        MobileMoneyDetails mobileMoney,
        @NotNull(message = "Channel type missing")
        Datatypes.TransactionType channelType
) {
//        FOR SENDING TO AN APP USER
        public record AppUserDetails(
                String userId,
                @NotNull(message = "Recipient name missing")
                String name,
                @NotNull(message="Account identifier missing!")
                String zentag,
                @NotNull(message="Recipient country code is required!")
                String countryCode,
                @NotNull(message="Recipient contact number is required!")
                String phoneNumber,
                @NotNull(message = "Recipient type is required")
                Datatypes.UserType type

        ){}
//        FOR SENDING TO A BANK ACCOUNT
        public record BankDetails(
                @NotNull(message="Bank name missing!")
                String bankName,
                @NotNull(message="Bank identifier missing!")
                String bankCode,
                @NotNull(message="Account number missing!")
                String accountNumber,
                @NotNull(message = "Bank system type missing!")
                String type
        ){}
//        FOR THE AMOUNT DETAILS
         public record TransferDetails(
                 @NotNull(message = "Amount is required")
                 @DecimalMin(value = "0.50", message = "Amount must be at least 0.50")
                 BigDecimal amount,
                 @NotBlank(message = "Currency code is required")
                 String currencyCode,
                 @NotBlank(message = "The wallet type is required")
                 String purpose
){}

//        FOR SENDING TO A MOBILE MONEY ACCOUNT USER
//        public record MobileMoneyDetails(){}

}