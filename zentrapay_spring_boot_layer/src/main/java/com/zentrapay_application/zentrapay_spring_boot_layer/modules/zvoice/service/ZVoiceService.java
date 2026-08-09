package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.dto.CommandRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model.VoiceCommandModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.repository.VoiceCommandRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * ZVoice AI (API contract §17): voice/chat command capture, plus a simple
 * rule-based assistant reply for {@code commandType:"CHAT"} — no external LLM
 * call in this pass, just templated replies keyed on transcript keywords, good
 * enough to make the AI Assistance screen feel conversational.
 */
@Service
@Transactional
public class ZVoiceService {

    private static final Logger log = LoggerFactory.getLogger(ZVoiceService.class);

    private final VoiceCommandRepository voiceCommandRepository;

    public ZVoiceService(VoiceCommandRepository voiceCommandRepository) {
        this.voiceCommandRepository = voiceCommandRepository;
    }

    public VoiceCommandModel recordCommand(UUID userId, CommandRequestDTO request) {
        log.info("[ZVOICE] Recording command: userId={}, type={}, language={}", userId, request.commandType(), request.language());

        VoiceCommandModel command = new VoiceCommandModel();
        command.setUserId(userId);
        command.setCommandType(request.commandType());
        command.setLanguage(request.language() != null && !request.language().isBlank() ? request.language() : "en");
        command.setTranscript(request.transcript());
        command.setStatus("PROCESSED");
        command.setFraudAlert(Boolean.TRUE.equals(request.fraudAlert()));
        command.setFraudReason(request.fraudReason());

        if ("CHAT".equalsIgnoreCase(request.commandType())) {
            command.setResponseText(generateChatReply(request.transcript()));
        }

        return voiceCommandRepository.save(command);
    }

    /**
     * Templated, keyword-driven assistant reply. Deliberately simple: no external
     * LLM call in this pass (per API contract §17) — just enough to make the AI
     * Assistance screen read as a real conversation rather than a static stub.
     */
    private String generateChatReply(String transcript) {
        String t = transcript == null ? "" : transcript.toLowerCase(Locale.ROOT);

        if (t.isBlank()) {
            return "I didn't catch that — could you say it again?";
        }
        if (containsAny(t, "hello", "hi ", "hey", "good morning", "good afternoon", "good evening") || t.equals("hi")) {
            return "Hello! I'm your ZentraPay assistant. I can help you check balances, send money, or answer questions about your account.";
        }
        if (containsAny(t, "balance", "how much")) {
            return "You can check your balance anytime from the Wallets tab — I can also pull it up for you if you ask me to \"show my balance\".";
        }
        if (containsAny(t, "send money", "transfer", "pay ")) {
            return "To send money, tell me the recipient and amount, e.g. \"send 50 GHS to John\", and I'll help set that up.";
        }
        if (containsAny(t, "card")) {
            return "You can create a virtual card and toggle NFC/QR payments from the Cards tab. Want me to walk you through it?";
        }
        if (containsAny(t, "fraud", "suspicious", "scam", "hacked")) {
            return "If you've spotted something suspicious, I've flagged it for review — you can also check Secure > Fraud Alerts for the latest status.";
        }
        if (containsAny(t, "thank")) {
            return "You're welcome! Let me know if there's anything else I can help with.";
        }
        if (containsAny(t, "help", "what can you do")) {
            return "I can help with balance checks, transfers, card management, and security questions. What would you like to do?";
        }
        return "Got it — I've logged that. For account-specific actions like payments or transfers, please confirm the details and I'll guide you through it.";
    }

    private boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    @Transactional(readOnly = true)
    public List<VoiceCommandModel> getUserVoiceCommands(UUID userId, String language) {
        if (language != null && !language.isBlank()) {
            return voiceCommandRepository.findByUserIdAndLanguageOrderByCreatedAtDesc(userId, language);
        }
        return voiceCommandRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<VoiceCommandModel> getFraudAlerts(UUID userId) {
        return voiceCommandRepository.findByUserIdAndFraudAlertOrderByCreatedAtDesc(userId, true);
    }
}
