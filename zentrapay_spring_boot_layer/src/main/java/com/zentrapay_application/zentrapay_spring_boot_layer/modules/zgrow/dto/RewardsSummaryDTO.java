package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.util.List;

public record RewardsSummaryDTO(
        int totalPoints,
        String tier,
        List<PointsLedgerEntryDTO> recentLedger
) {
}
