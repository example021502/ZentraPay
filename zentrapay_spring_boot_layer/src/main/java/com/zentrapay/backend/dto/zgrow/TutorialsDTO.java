package com.zentrapay.backend.dto.zgrow;

import com.zentrapay.backend.service.common.Datatypes;

import java.time.LocalDateTime;

/**
 * GET /api/zgrow/tutorials item shape.
 */
public record TutorialsDTO(
        int id,
        String title,
        Datatypes.TutorialType type,
        String description,
        String videoUrl,
        String thumbnailUrl,
        int durationSeconds,
        Boolean isActive,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
