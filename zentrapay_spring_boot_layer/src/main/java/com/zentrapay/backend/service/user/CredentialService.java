package com.zentrapay.backend.service.user;

import com.zentrapay.backend.dto.user.CredentialDTOs.ResetRequestedDTO;
import com.zentrapay.backend.dto.user.CredentialDTOs.ResetTokenDTO;
import com.zentrapay.backend.entity.CredentialResetModel;
import com.zentrapay.backend.entity.NotificationModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.CredentialResetRepository;
import com.zentrapay.backend.repository.NotificationRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.mail.MailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Changing and recovering the password and the transaction PIN.
 *
 * <p><b>Change</b> - the user must give the CURRENT password / PIN first.
 * <p><b>Forgot</b> - three steps, each usable once:
 * <ol>
 *   <li>{@link #requestReset}: a one-time code is emailed to the registered address.</li>
 *   <li>{@link #verifyCode}: the user pastes the code; if it is right (and not expired / over-tried)
 *       a short-lived reset token comes back.</li>
 *   <li>{@link #resetPassword} / {@link #resetPin}: the token is exchanged for the new password / PIN.</li>
 * </ol>
 * Only hashes of the code and the token are stored.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CredentialService {

    public static final String PASSWORD = "PASSWORD";
    public static final String PIN = "PIN";

    private static final int CODE_MINUTES = 15;
    private static final int TOKEN_MINUTES = 10;
    private static final int MAX_WRONG_CODES = 5;
    private static final int MAX_REQUESTS_PER_HOUR = 3;
    private static final Pattern PIN_FORMAT = Pattern.compile("\\d{4}");
    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final CredentialResetRepository resetRepository;
    private final NotificationRepository notificationRepository;
    private final PasswordEncoder passwordEncoder;
    private final MailService mailService;

    @Value("${app.password.pepper}")
    private String passwordPepper;
    @Value("${app.pin.pepper}")
    private String pinPepper;
    // Secret mixed into the stored hashes of codes / tokens
    @Value("${app.reset.secret:${app.jwt.secret}}")
    private String resetSecret;

    // ==================================================================
    // Change (current value required)
    // ==================================================================

    @Transactional
    public void changePassword(UUID userId, String currentPassword, String newPassword) {
        UserModel user = requireUser(userId);
        if (!passwordEncoder.matches(currentPassword + passwordPepper, user.getPasswordHash())) {
            throw new IllegalArgumentException("Your current password is not correct");
        }
        requireValidPassword(newPassword);
        if (newPassword.equals(currentPassword)) {
            throw new IllegalArgumentException("Your new password must be different from the current one");
        }
        savePassword(user, newPassword);
    }

    @Transactional
    public void changePin(UUID userId, String currentPin, String newPin) {
        UserModel user = requireUser(userId);
        if (!passwordEncoder.matches(currentPin + pinPepper, user.getTransactionPinHash())) {
            throw new IllegalArgumentException("Your current PIN is not correct");
        }
        requireValidPin(newPin);
        if (newPin.equals(currentPin)) {
            throw new IllegalArgumentException("Your new PIN must be different from the current one");
        }
        savePin(user, newPin);
    }

    // ==================================================================
    // Forgot - step 1: email the code
    // ==================================================================

    @Transactional
    public ResetRequestedDTO requestReset(UUID userId, String purpose) {
        UserModel user = requireUser(userId);
        LocalDateTime now = LocalDateTime.now();
        if (resetRepository.countByUserIdAndPurposeAndCreatedAtAfter(userId, purpose, now.minusHours(1)) >= MAX_REQUESTS_PER_HOUR) {
            throw new IllegalArgumentException("Too many reset requests. Please wait a while before trying again.");
        }

        // A newer request replaces the older ones
        for (CredentialResetModel open : resetRepository.findByUserIdAndPurposeAndUsedAtIsNull(userId, purpose)) {
            open.setUsedAt(now);
            resetRepository.save(open);
        }

        String code = randomToken(24);
        CredentialResetModel request = new CredentialResetModel();
        request.setUserId(userId);
        request.setPurpose(purpose);
        request.setCodeHash(hash(code));
        request.setExpiresAt(now.plusMinutes(CODE_MINUTES));
        resetRepository.save(request);

        String what = PIN.equals(purpose) ? "transaction PIN" : "password";
        boolean sent = mailService.send(user.getEmail(), "Confirm your ZentraPay " + what + " reset",
                "Hello " + user.getFirstName() + ",\n\n"
                        + "We received a request to reset your ZentraPay " + what + ". "
                        + "If this was you, copy the code below and paste it into the open ZentraPay app to confirm:\n\n"
                        + code + "\n\n"
                        + "The code works once and expires in " + CODE_MINUTES + " minutes.\n\n"
                        + "If you did not ask for this, do not share the code with anyone and ignore this email - "
                        + "your " + what + " has not been changed. You may want to change your password.\n\n"
                        + "ZentraPay Security");
        if (!sent) {
            // Nothing reached the user, so do not leave a code behind that nobody can read
            request.setUsedAt(now);
            resetRepository.save(request);
            throw new IllegalArgumentException("We could not send the email right now. Please try again in a moment.");
        }
        return new ResetRequestedDTO(maskEmail(user.getEmail()), CODE_MINUTES);
    }

    // ==================================================================
    // Forgot - step 2: check the pasted code
    // ==================================================================

    // noRollbackFor: a wrong guess must still be counted, or the attempt limit would never trip
    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public ResetTokenDTO verifyCode(UUID userId, String purpose, String code) {
        LocalDateTime now = LocalDateTime.now();
        CredentialResetModel request = resetRepository
                .findFirstByUserIdAndPurposeAndUsedAtIsNullOrderByCreatedAtDesc(userId, purpose)
                .orElseThrow(() -> new IllegalArgumentException("There is no open reset request. Choose Forgot again to get a new code."));

        if (request.getExpiresAt().isBefore(now)) {
            request.setUsedAt(now);
            resetRepository.save(request);
            throw new IllegalArgumentException("That code has expired. Choose Forgot again to get a new one.");
        }
        if (request.getAttempts() >= MAX_WRONG_CODES) {
            request.setUsedAt(now);
            resetRepository.save(request);
            throw new IllegalArgumentException("Too many wrong codes. Choose Forgot again to get a new one.");
        }

        String entered = code == null ? "" : code.trim();
        if (!constantTimeEquals(hash(entered), request.getCodeHash())) {
            request.setAttempts(request.getAttempts() + 1);
            resetRepository.save(request);
            int left = MAX_WRONG_CODES - request.getAttempts();
            throw new IllegalArgumentException(left > 0
                    ? "That code is not correct. You have " + left + (left == 1 ? " try left." : " tries left.")
                    : "Too many wrong codes. Choose Forgot again to get a new one.");
        }

        String token = randomToken(32);
        request.setVerifiedAt(now);
        request.setResetTokenHash(hash(token));
        request.setResetTokenExpiresAt(now.plusMinutes(TOKEN_MINUTES));
        resetRepository.save(request);
        return new ResetTokenDTO(token, TOKEN_MINUTES);
    }

    // ==================================================================
    // Forgot - step 3: set the new value
    // ==================================================================

    @Transactional
    public void resetPassword(UUID userId, String resetToken, String newPassword) {
        requireValidPassword(newPassword);
        UserModel user = requireUser(userId);
        consumeToken(userId, PASSWORD, resetToken);
        savePassword(user, newPassword);
    }

    @Transactional
    public void resetPin(UUID userId, String resetToken, String newPin) {
        requireValidPin(newPin);
        UserModel user = requireUser(userId);
        consumeToken(userId, PIN, resetToken);
        savePin(user, newPin);
    }

    // The token must belong to a verified, unused, unexpired request of this user; it works once
    private void consumeToken(UUID userId, String purpose, String resetToken) {
        LocalDateTime now = LocalDateTime.now();
        CredentialResetModel request = resetRepository
                .findFirstByUserIdAndPurposeAndUsedAtIsNullOrderByCreatedAtDesc(userId, purpose)
                .filter(r -> r.getVerifiedAt() != null && r.getResetTokenHash() != null)
                .orElseThrow(() -> new IllegalArgumentException("Please confirm the code from your email first."));
        if (request.getResetTokenExpiresAt() == null || request.getResetTokenExpiresAt().isBefore(now)) {
            request.setUsedAt(now);
            resetRepository.save(request);
            throw new IllegalArgumentException("This reset has expired. Choose Forgot again to start over.");
        }
        if (resetToken == null || !constantTimeEquals(hash(resetToken.trim()), request.getResetTokenHash())) {
            throw new IllegalArgumentException("This reset is not valid. Choose Forgot again to start over.");
        }
        request.setUsedAt(now);
        resetRepository.save(request);
    }

    // ==================================================================
    // Helpers
    // ==================================================================

    private void savePassword(UserModel user, String newPassword) {
        user.setPasswordHash(passwordEncoder.encode(newPassword + passwordPepper));
        userRepository.save(user);
        announce(user, "Password changed", "Your ZentraPay password was changed.");
    }

    private void savePin(UserModel user, String newPin) {
        user.setTransactionPinHash(passwordEncoder.encode(newPin + pinPepper));
        userRepository.save(user);
        announce(user, "PIN changed", "Your ZentraPay transaction PIN was changed.");
    }

    // An in-app notice and an email, so a change the user did not make does not go unnoticed
    private void announce(UserModel user, String title, String message) {
        NotificationModel notification = new NotificationModel();
        notification.setUserId(user.getUserId());
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType("SECURITY");
        notificationRepository.save(notification);
        mailService.send(user.getEmail(), "ZentraPay: " + title.toLowerCase(),
                "Hello " + user.getFirstName() + ",\n\n" + message
                        + " If this was not you, contact ZentraPay support immediately.\n\nZentraPay Security");
    }

    private UserModel requireUser(UUID userId) {
        return userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private static void requireValidPassword(String password) {
        if (password == null || password.length() < 8 || password.length() > 32) {
            throw new IllegalArgumentException("Your password must be 8 to 32 characters long");
        }
    }

    private static void requireValidPin(String pin) {
        if (pin == null || !PIN_FORMAT.matcher(pin).matches()) {
            throw new IllegalArgumentException("Your PIN must be exactly 4 digits");
        }
    }

    // URL-safe random text, bytes of randomness long
    private static String randomToken(int bytes) {
        byte[] data = new byte[bytes];
        RANDOM.nextBytes(data);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(data);
    }

    private String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest((resetSecret + ":" + value).getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private static boolean constantTimeEquals(String a, String b) {
        return MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
    }

    // m****@gmail.com
    static String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return email;
        }
        return email.charAt(0) + "*".repeat(Math.min(at - 1, 6)) + email.substring(at);
    }
}
