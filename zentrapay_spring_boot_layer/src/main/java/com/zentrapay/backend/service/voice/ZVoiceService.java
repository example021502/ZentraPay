package com.zentrapay.backend.service.voice;

import com.zentrapay.backend.dto.voice.VoiceDTOs.VoiceCommandRequestDTO;
import com.zentrapay.backend.dto.voice.VoiceDTOs.VoiceCommandResponseDTO;
import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.FraudAlert;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.VoiceCommandModel;
import com.zentrapay.backend.repository.FiatAccountRepository;
import com.zentrapay.backend.repository.FiatWalletRepository;
import com.zentrapay.backend.repository.FraudAlertRepository;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.VoiceCommandRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * ZVoice AI. Every instruction the user speaks (VOICE) or types (CHAT) is saved to
 * {@code voice_commands} together with the reply and what it was about, so the user can look back on
 * everything they asked in the History tab.
 *
 * <p>The phone turns speech into text; this class works out what the instruction is about, answers
 * what can be answered safely (balance, latest activity, how things work) and flags instructions
 * that look like someone trying to get a PIN / password / code out of the app.
 *
 * <p>Money is never moved by voice alone: a send or bill instruction is recorded and the user is
 * pointed to the normal flow, which asks for the PIN.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ZVoiceService {

    private static final Set<String> COMMAND_TYPES = Set.of("VOICE", "CHAT");

    // Asking the app to reveal or read out a secret is a classic social-engineering move
    private static final Pattern SECRET_REQUEST = Pattern.compile(
            "(tell|read|say|show|give|what'?s|what is|repeat|reveal|share|send)\\b.{0,30}\\b(pin|password|passcode|otp|cvv|one[- ]time|secret)");

    private final VoiceCommandRepository voiceCommandRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final TransactionRepository transactionRepository;
    private final FraudAlertRepository fraudAlertRepository;

    // ------------------------------------------------------------------
    // Record an instruction
    // ------------------------------------------------------------------

    @Transactional
    public VoiceCommandResponseDTO record(UUID userId, VoiceCommandRequestDTO req) {
        String type = req.commandType().trim().toUpperCase(Locale.ROOT);
        if (!COMMAND_TYPES.contains(type)) {
            throw new IllegalArgumentException("Command type must be VOICE or CHAT");
        }
        String transcript = req.transcript().trim();
        String lower = transcript.toLowerCase(Locale.ROOT);
        String intent = intentOf(lower);

        // Fraud: what the phone reported, or what the server itself can see in the wording
        boolean fraud = Boolean.TRUE.equals(req.fraudAlert());
        String fraudReason = fraud ? req.fraudReason() : null;
        if (SECRET_REQUEST.matcher(lower).find()) {
            fraud = true;
            fraudReason = "The instruction asked the assistant to reveal a PIN, password or code.";
            intent = "SECURITY";
        }

        VoiceCommandModel command = new VoiceCommandModel();
        command.setUserId(userId);
        command.setCommandType(type);
        command.setLanguage(languageOf(req.language()));
        command.setTranscript(transcript);
        command.setIntent(intent);
        command.setDurationMs(req.durationMs());
        command.setConfidence(req.confidence());
        command.setFraudAlert(fraud);
        command.setFraudReason(fraudReason);
        command.setStatus(fraud ? "FLAGGED" : "PROCESSED");
        command.setResponseText(fraud
                ? "For your safety I will never read out or ask for your PIN, password or codes, and nobody from ZentraPay will either. "
                + "If someone asked you to say them, please stop and contact support."
                : answerFor(userId, intent));
        command = voiceCommandRepository.save(command);

        if (fraud) {
            FraudAlert alert = new FraudAlert();
            alert.setUserId(userId);
            alert.setAlertType("VOICE_SENSITIVE_REQUEST");
            alert.setMessage(fraudReason == null || fraudReason.isBlank() ? "A suspicious voice instruction was flagged." : fraudReason);
            alert.setSeverity("HIGH");
            fraudAlertRepository.save(alert);
            log.warn("ZVoice: flagged instruction {} for user {}", command.getCommandId(), userId);
        }
        return toDTO(command);
    }

    // ------------------------------------------------------------------
    // History
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<VoiceCommandResponseDTO> history(UUID userId, int limit) {
        int size = Math.min(Math.max(limit, 1), 200);
        return voiceCommandRepository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, size)).stream()
                .map(ZVoiceService::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<VoiceCommandResponseDTO> fraudAlerts(UUID userId) {
        return voiceCommandRepository.findByUserIdAndFraudAlertTrueOrderByCreatedAtDesc(userId).stream()
                .map(ZVoiceService::toDTO)
                .toList();
    }

    // ------------------------------------------------------------------
    // Understanding and answering
    // ------------------------------------------------------------------

    private static String intentOf(String text) {
        if (containsAny(text, "balance", "how much do i have", "how much money", "what do i have")) {
            return "BALANCE";
        }
        if (containsAny(text, "last transaction", "recent", "history", "latest transaction", "what did i spend", "my transactions")) {
            return "HISTORY";
        }
        if (containsAny(text, "send", "transfer", "remit", "give money")) {
            return "SEND_MONEY";
        }
        if (containsAny(text, "bill", "airtime", "electricity", "water", "data bundle", "tv subscription", "pay for")) {
            return "PAY_BILL";
        }
        if (containsAny(text, "fraud", "scam", "secure", "security", "hacked", "stolen", "suspicious")) {
            return "SECURITY";
        }
        if (containsAny(text, "help", "how do i", "how can i", "what can you do", "support")) {
            return "HELP";
        }
        if (containsAny(text, "hello", "hi ", "hey", "good morning", "good afternoon", "good evening")
                || text.equals("hi")) {
            return "GREETING";
        }
        return "UNKNOWN";
    }

    private String answerFor(UUID userId, String intent) {
        return switch (intent) {
            case "BALANCE" -> balanceReply(userId);
            case "HISTORY" -> historyReply(userId);
            case "SEND_MONEY" -> "I have noted that you want to send money. For your security I cannot move money by voice: "
                    + "open Send Money, pick who to pay and confirm with your PIN. Use ZRemit for people in another country.";
            case "PAY_BILL" -> "I have noted that you want to pay a bill. Open Pay, search the provider and confirm with your PIN.";
            case "SECURITY" -> "Your account is protected by your PIN and fraud monitoring. Never share your PIN, password or codes with anyone. "
                    + "Open Settings, then Security, to review recent activity and alerts.";
            case "HELP" -> "I can tell you your balance and latest activity, and guide you to send money, pay bills or check security. "
                    + "Just ask, for example: What is my balance?";
            case "GREETING" -> "Hello! How can I help you today? You can ask about your balance or recent activity.";
            default -> "I have saved that. I can help with your balance, recent activity, sending money, bills and security. "
                    + "Try asking: What is my balance?";
        };
    }

    private String balanceReply(UUID userId) {
        return fiatWalletRepository.getWalletByUserId(userId)
                .map(wallet -> {
                    List<FiatAccountModel> accounts = fiatAccountRepository.findByWalletId(wallet.getWalletId());
                    if (accounts.isEmpty()) {
                        return "You do not have any account yet.";
                    }
                    StringBuilder reply = new StringBuilder("Your balance is ");
                    for (int i = 0; i < accounts.size(); i++) {
                        FiatAccountModel a = accounts.get(i);
                        if (i > 0) {
                            reply.append(i == accounts.size() - 1 ? " and " : ", ");
                        }
                        reply.append(a.getCurrencyCode()).append(' ').append(a.getBalance().setScale(2, java.math.RoundingMode.HALF_UP).toPlainString());
                    }
                    return reply.append('.').toString();
                })
                .orElse("I could not find your wallet.");
    }

    private String historyReply(UUID userId) {
        List<TransactionModel> latest = transactionRepository.findUserHistory(userId, PageRequest.of(0, 1)).getContent();
        if (latest.isEmpty()) {
            return "You have no transactions yet.";
        }
        TransactionModel t = latest.get(0);
        boolean sent = userId.equals(t.getSenderId());
        String other = sent ? t.getReceiverName() : t.getSenderName();
        return "Your latest transaction: you " + (sent ? "sent " : "received ") + t.getSourceCurrencyCode() + " "
                + t.getAmount().setScale(2, java.math.RoundingMode.HALF_UP).toPlainString()
                + (other == null || other.isBlank() ? "" : (sent ? " to " : " from ") + other)
                + ", status " + String.valueOf(t.getStatus()).toLowerCase(Locale.ROOT) + ".";
    }

    private static boolean containsAny(String text, String... needles) {
        for (String needle : needles) {
            if (text.contains(needle)) {
                return true;
            }
        }
        return false;
    }

    private static String languageOf(String language) {
        if (language == null || language.isBlank()) {
            return "en";
        }
        String code = language.trim();
        return code.length() > 10 ? code.substring(0, 10) : code;
    }

    private static VoiceCommandResponseDTO toDTO(VoiceCommandModel c) {
        return new VoiceCommandResponseDTO(c.getCommandId(), c.getCommandType(), c.getLanguage(), c.getTranscript(),
                c.getResponseText(), c.getIntent(), c.getStatus(), c.isFraudAlert(), c.getFraudReason(),
                c.getDurationMs(), c.getConfidence(), c.getCreatedAt());
    }
}
