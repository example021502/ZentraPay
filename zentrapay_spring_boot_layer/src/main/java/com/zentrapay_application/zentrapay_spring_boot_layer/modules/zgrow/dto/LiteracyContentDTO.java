package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.util.UUID;

public record LiteracyContentDTO(
        UUID contentId,
        String title,
        String category,
        String contentUrl,
        Integer durationMinutes,
        Integer pointsReward,
        boolean completed
) {
}
