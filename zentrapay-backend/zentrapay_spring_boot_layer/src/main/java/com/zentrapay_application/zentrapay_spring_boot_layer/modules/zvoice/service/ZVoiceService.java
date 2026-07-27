package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.repository.VoiceCommandRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Service for ZVoice AI: full voice control, hands-free balance checks, voice fraud alerts.
 */
@Service
@Transactional
public class ZVoiceService {

    private static final Logger log = LoggerFactory.getLogger(ZVoiceService.class);

    private final VoiceCommandRepository voiceCommandRepository;

    public ZVoiceService(VoiceCommandRepository voiceCommandRepository) {
        this.voiceCommandRepository = voiceCommandRepository;
    }

    /**
     * Records a voice command.
     */
    public VoiceCommandModel recordVoiceCommand(UUID userId, String commandType, String language,
                                               String transcript, boolean fraudAlert, String fraudReason) {
        log.info("[ZVOICE] Recording voice command: userId={}, type={}, language={}", userId, commandType, language);

        VoiceCommandModel command = new VoiceCommandModel();
        command.setUserId(userId);
        command.setCommandType(commandType);
        command.setLanguage(language);
        command.setTranscript(transcript);
        command.setStatus("PROCESSED");
        command.setFraudAlert(fraudAlert);
        command.setFraudReason(fraudReason);

        return voiceCommandRepository.save(command);
    }

    /**
     * Retrieves voice command history for a user.
     */
    @Transactional(readOnly = true)
    public List<VoiceCommandModel> getUserVoiceCommands(UUID userId) {
        log.info("[ZVOICE] Fetching voice commands for userId={}", userId);
        return voiceCommandRepository.findByUserId(userId);
    }

    /**
     * Retrieves voice commands with fraud alerts.
     */
    @Transactional(readOnly = true)
    public List<VoiceCommandModel> getFraudAlerts(UUID userId) {
        log.info("[ZVOICE] Fetching fraud alerts for userId={}", userId);
        return voiceCommandRepository.findByUserIdAndFraudAlert(userId, true);
    }

    /**
     * Retrieves voice commands by language.
     */
    @Transactional(readOnly = true)
    public List<VoiceCommandModel> getCommandsByLanguage(UUID userId, String language) {
        log.info("[ZVOICE] Fetching {} commands for userId={}", language, userId);
        return voiceCommandRepository.findByUserIdAndLanguage(userId, language);
    }
}