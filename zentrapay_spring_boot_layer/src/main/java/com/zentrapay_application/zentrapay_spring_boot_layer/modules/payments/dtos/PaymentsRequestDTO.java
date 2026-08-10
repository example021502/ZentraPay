package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;

// Ensure these are imported if they exist in a separate package,
// or ensure the class files are created in this exact same package directory.
// import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.RecipientDetailsDTO;
// import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.AmountDetailsDTO;
// import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DestinationDetailsDTO;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.AmountDetailsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DestinationDetailsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.RecipientDetailsDTO;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Payment request payload record containing authorization pin and nested transaction details.
 */
public record PaymentsRequestDTO(
        // User authorization PIN required for the transfer
        @NotBlank(message = "PIN is required for authorization")
        String pin,

        // Information about the receiver
        @Valid
        @NotNull(message = "Recipient details are required")
        RecipientDetailsDTO recipientDetails,

        // Transaction amount and currency data
        @Valid
        @NotNull(message = "Amount details are required")
        AmountDetailsDTO amountDetails,

        // Routing and channel details (bank, momo, or wallet)
        @Valid
        @NotNull(message = "Destination details are required")
        DestinationDetailsDTO destinationDetails
) {
}