package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.time.LocalDateTime;

public record PointsLedgerEntryDTO(
        int points,
        String reason,
        LocalDateTime createdAt
) {
}
