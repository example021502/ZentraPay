package com.zentrapay.backend.security;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Brute-force guard for secrets with a tiny search space (the 4-digit transaction PIN) and for logins.
 *
 * <p>After {@value #MAX_FAILURES} wrong guesses for the same key the key is locked for
 * {@value #LOCK_MINUTES} minutes; a correct guess clears the counter. Failures older than the
 * lock window are forgotten, so a user who mistypes now and then is never locked.
 *
 * <p>State is in memory: it is per server instance and resets on restart. That is enough to stop
 * online guessing against one instance; run it behind a shared store before scaling out.
 */
@Component
public class AttemptLimiter {

    static final int MAX_FAILURES = 5;
    static final long LOCK_MINUTES = 15;
    private static final int SWEEP_ABOVE = 10_000;

    private record State(int failures, Instant windowStart, Instant lockedUntil) {
    }

    private final ConcurrentHashMap<String, State> states = new ConcurrentHashMap<>();

    /** Throws (HTTP 400 through the global handler) while the key is locked. */
    public void requireNotLocked(String key) {
        State state = states.get(key);
        if (state == null || state.lockedUntil() == null) {
            return;
        }
        Instant now = Instant.now();
        if (state.lockedUntil().isAfter(now)) {
            long minutes = Math.max(1, Duration.between(now, state.lockedUntil()).toMinutes() + 1);
            throw new IllegalArgumentException(
                    "Too many incorrect attempts. Please try again in " + minutes + " minute" + (minutes == 1 ? "" : "s") + ".");
        }
        states.remove(key, state);
    }

    /** Records one wrong guess; locks the key when the limit is reached. */
    public void recordFailure(String key) {
        Instant now = Instant.now();
        states.compute(key, (k, old) -> {
            boolean fresh = old == null || old.windowStart().plus(Duration.ofMinutes(LOCK_MINUTES)).isBefore(now);
            int failures = fresh ? 1 : old.failures() + 1;
            Instant start = fresh ? now : old.windowStart();
            Instant lockedUntil = failures >= MAX_FAILURES ? now.plus(Duration.ofMinutes(LOCK_MINUTES)) : null;
            return new State(failures, start, lockedUntil);
        });
        if (states.size() > SWEEP_ABOVE) {
            sweep(now);
        }
    }

    /** A correct guess: forget the failures. */
    public void recordSuccess(String key) {
        states.remove(key);
    }

    // Keeps memory bounded: drops every entry whose window has fully passed
    private void sweep(Instant now) {
        Duration window = Duration.ofMinutes(LOCK_MINUTES);
        states.entrySet().removeIf(e -> e.getValue().windowStart().plus(window).isBefore(now)
                && (e.getValue().lockedUntil() == null || e.getValue().lockedUntil().isBefore(now)));
    }
}
