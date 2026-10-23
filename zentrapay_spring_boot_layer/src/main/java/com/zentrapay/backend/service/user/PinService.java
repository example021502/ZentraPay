package com.zentrapay.backend.service.user;

import com.zentrapay.backend.entity.UserModel;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * The one place that checks a transaction PIN, so payments, remittances, bill payments and
 * the PIN-verify endpoint can never drift apart. The PIN is stored hashed with a secret
 * "pepper" added (see app.pin.pepper).
 */
@Service
@RequiredArgsConstructor
public class PinService {

    private final PasswordEncoder passwordEncoder;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    /** True when the PIN is the user's transaction PIN. */
    public boolean matches(UserModel user, String pin) {
        return pin != null && passwordEncoder.matches(pin + pinPepper, user.getTransactionPinHash());
    }

    /** Throws "Invalid PIN" (HTTP 400) when the PIN is wrong. */
    public void requireValid(UserModel user, String pin) {
        if (!matches(user, pin)) {
            throw new IllegalArgumentException("Invalid PIN");
        }
    }
}
