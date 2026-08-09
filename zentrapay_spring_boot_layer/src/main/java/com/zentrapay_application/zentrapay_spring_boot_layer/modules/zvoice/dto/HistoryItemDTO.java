package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;

import java.time.LocalDateTime;
import java.util.UUID;

public record HistoryItemDTO(
        UUID commandId,
        String commandType,
        String transcript,
        String responseText,
        LocalDateTime createdAt
) {
    public static HistoryItemDTO from(VoiceCommandModel command) {
        return new HistoryItemDTO(
                command.getCommandId(),
                command.getCommandType(),
                command.getTranscript(),
                command.getResponseText(),
                command.getCreatedAt()
        );
    }
}
