package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;

import java.time.LocalDateTime;
import java.util.UUID;

public record VoiceFraudAlertDTO(
        UUID commandId,
        String transcript,
        String fraudReason,
        LocalDateTime createdAt
) {
    public static VoiceFraudAlertDTO from(VoiceCommandModel command) {
        return new VoiceFraudAlertDTO(
                command.getCommandId(),
                command.getTranscript(),
                command.getFraudReason(),
                command.getCreatedAt()
        );
    }
}
