package com.zentrapay.backend.service.common;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Small helpers for checking that a webhook really came from the gateway.
 * Comparisons are constant-time so a signature cannot be guessed byte by byte.
 */
public final class WebhookSignature {

    private WebhookSignature() {
    }

    /** True when {@code received} equals the hex HMAC of {@code body} (algorithm e.g. HmacSHA512). */
    public static boolean hmacMatches(String algorithm, String secret, String body, String received) {
        if (secret == null || secret.isBlank() || received == null) {
            return false;
        }
        try {
            Mac mac = Mac.getInstance(algorithm);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), algorithm));
            byte[] digest = mac.doFinal(body.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            return sameText(hex.toString(), received.trim().toLowerCase());
        } catch (Exception e) {
            return false;
        }
    }

    /** True when the two texts are equal (constant time). A blank expected value never matches. */
    public static boolean sameText(String expected, String received) {
        if (expected == null || expected.isBlank() || received == null) {
            return false;
        }
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), received.getBytes(StandardCharsets.UTF_8));
    }
}
