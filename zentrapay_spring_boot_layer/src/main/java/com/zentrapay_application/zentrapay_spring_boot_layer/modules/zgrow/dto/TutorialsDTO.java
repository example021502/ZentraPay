package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import java.time.LocalDateTime;

/** GET /api/notifications item shape. */
public record TutorialsDTO(
    int id,
    String title,
    Datatypes.TutorialTypeEnum type,
    String description,
    String videoUrl,
    String thumbnailUrl,
    int durationSeconds,
    Boolean isActive,
    LocalDateTime createdAt,
    LocalDateTime updatedAt
) {
}
