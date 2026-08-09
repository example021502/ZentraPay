package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * {@code POST /api/zvoice/command} request body (API contract §17). Previously
 * the endpoint bound {@code @RequestParam}s against what the Flutter client
 * actually posted as a JSON body — a real bug this DTO fixes.
 */
public record CommandRequestDTO(
        @NotBlank(message = "Command type is required") String commandType, // VOICE, CHAT
        String language,
        @NotBlank(message = "Transcript is required") String transcript,
        Boolean fraudAlert,
        String fraudReason
) {
}
