package com.zentrapay.backend.dto.qr;

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
