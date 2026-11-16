package com.zentrapay.backend.security;

import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.service.user.PinService;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class AttemptLimiterTest {

    private final AttemptLimiter limiter = new AttemptLimiter();

    @Test
    void locksAfterTheMaximumNumberOfFailures() {
        for (int i = 0; i < AttemptLimiter.MAX_FAILURES - 1; i++) {
            limiter.requireNotLocked("k");
            limiter.recordFailure("k");
        }
        limiter.requireNotLocked("k"); // one try left: still open
        limiter.recordFailure("k");

        IllegalArgumentException locked = assertThrows(IllegalArgumentException.class, () -> limiter.requireNotLocked("k"));
        assertTrue(locked.getMessage().startsWith("Too many incorrect attempts"));
    }

    @Test
    void successClearsTheCounter() {
        for (int i = 0; i < AttemptLimiter.MAX_FAILURES - 1; i++) {
            limiter.recordFailure("k");
        }
        limiter.recordSuccess("k");
        limiter.recordFailure("k");
        assertDoesNotThrow(() -> limiter.requireNotLocked("k"));
    }

    @Test
    void keysAreIndependent() {
        for (int i = 0; i < AttemptLimiter.MAX_FAILURES; i++) {
            limiter.recordFailure("a");
        }
        assertThrows(IllegalArgumentException.class, () -> limiter.requireNotLocked("a"));
        assertDoesNotThrow(() -> limiter.requireNotLocked("b"));
    }

    @Test
    void pinServiceLocksAfterWrongGuessesEvenForTheRightPin() {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(4);
        PinService pins = new PinService(encoder, limiter);
        ReflectionTestUtils.setField(pins, "pinPepper", "pepper");
        UserModel user = new UserModel();
        user.setUserId(UUID.randomUUID());
        user.setTransactionPinHash(encoder.encode("1234" + "pepper"));

        assertTrue(pins.matches(user, "1234"));
        for (int i = 0; i < AttemptLimiter.MAX_FAILURES; i++) {
            assertFalse(pins.matches(user, "0000"));
        }
        assertThrows(IllegalArgumentException.class, () -> pins.matches(user, "1234"));
        assertThrows(IllegalArgumentException.class, () -> pins.requireValid(user, "1234"));
    }
}
