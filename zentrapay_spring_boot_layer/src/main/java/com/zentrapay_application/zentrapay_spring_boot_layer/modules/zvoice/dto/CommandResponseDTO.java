package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;

import java.time.LocalDateTime;
import java.util.UUID;

public record CommandResponseDTO(
        UUID commandId,
        String transcript,
        String responseText,
        LocalDateTime createdAt
) {
    public static CommandResponseDTO from(VoiceCommandModel command) {
        return new CommandResponseDTO(
                command.getCommandId(),
                command.getTranscript(),
                command.getResponseText(),
                command.getCreatedAt()
        );
    }
}
