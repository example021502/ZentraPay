package com.zentrapay.backend.service.user;

import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.security.AttemptLimiter;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * The one place that checks a transaction PIN, so payments, remittances, bill payments and
 * the PIN-verify endpoint can never drift apart. The PIN is stored hashed with a secret
 * "pepper" added (see app.pin.pepper).
 *
 * <p>A 4-digit PIN has only 10,000 combinations, so wrong guesses are counted per user:
 * after a few in a row the PIN is locked for a while ({@link AttemptLimiter}).
 */
@Service
@RequiredArgsConstructor
public class PinService {

    private final PasswordEncoder passwordEncoder;
    private final AttemptLimiter attemptLimiter;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    /**
     * True when the PIN is the user's transaction PIN. Throws while the PIN is locked after too many wrong guesses.
     */
    public boolean matches(UserModel user, String pin) {
        String key = "pin:" + user.getId();
        attemptLimiter.requireNotLocked(key);
        boolean ok = pin != null && passwordEncoder.matches(pin + pinPepper, user.getTransactionPinHash());
        if (ok) {
            attemptLimiter.recordSuccess(key);
        } else {
            attemptLimiter.recordFailure(key);
        }
        return ok;
    }

    /**
     * Throws "Invalid PIN" (HTTP 400) when the PIN is wrong.
     */
    public void requireValid(UserModel user, String pin) {
        if (!matches(user, pin)) {
            throw new IllegalArgumentException("Invalid PIN");
        }
    }
}
