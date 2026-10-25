package com.zentrapay.backend.dto.voice;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** Request / response shapes of the ZVoice endpoints. */
public final class VoiceDTOs {

    private VoiceDTOs() {
    }

    /**
     * POST /api/zvoice/command. {@code commandType} is VOICE (spoken, already turned into text on the
     * phone) or CHAT (typed). {@code durationMs} / {@code confidence} describe a spoken instruction.
     */
    public record VoiceCommandRequestDTO(
            @NotBlank(message = "Command type is required")
            String commandType,
            String language,
            @NotBlank(message = "Nothing was said")
            @Size(max = 2000, message = "That instruction is too long")
            String transcript,
            Boolean fraudAlert,
            String fraudReason,
            Integer durationMs,
            @DecimalMin(value = "0.0", message = "Confidence must be between 0 and 1")
            @DecimalMax(value = "1.0", message = "Confidence must be between 0 and 1")
            BigDecimal confidence
    ) {
    }

    public record VoiceCommandResponseDTO(
            UUID commandId,
            String commandType,
            String language,
            String transcript,
            String responseText,
            String intent,
            String status,
            boolean fraudAlert,
            String fraudReason,
            Integer durationMs,
            BigDecimal confidence,
            LocalDateTime createdAt
    ) {
    }
}
