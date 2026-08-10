package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

import java.util.List;

/**
 * Everything the Home "Receive" sheet needs in one call: the user's zentag, a QR
 * payload the client renders locally (a {@code zentrapay://receive} deep link — no
 * server-side image generation), and their linked funding sources (bank accounts)
 * so a sender paying by bank transfer can see where it lands.
 */
public record ReceiveInfoDTO(
        String userId,
        String fullName,
        String zentag,
        String qrPayload,
        List<LinkedAccountDTO> linkedAccounts
) {
    public record LinkedAccountDTO(
            String sourceId,
            String sourceName,
            String accountIdentifier,
            String sourceType,
            boolean verified
    ) {
    }
}
