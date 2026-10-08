package com.zentrapay_application.zentrapay_spring_boot_layer.modules.qrCodes.dto;

import java.util.UUID;

public record qrCodeInformationResponseDTO(
        String phoneNumber,
        String email,
        String zentag,
        String currencyCode,
        String accountName,
        String userName
) {
}
