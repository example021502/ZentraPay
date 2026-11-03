package com.zentrapay.backend.service.payment;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

/**
 * Turns an account the user just VERIFIED (bank account / mobile-money wallet that is not a
 * ZentraPay account) into an opaque, encrypted, short-lived token, and back.
 *
 * <p>Why: before this, the app typed the account number + holder name in, verified them, and then
 * sent them AGAIN, in clear and fully client-controlled, with the payment. Now the send call only
 * carries this token. The server decides what the destination is from what the provider confirmed,
 * so a tampered app can neither pay an unverified account nor change the name that was shown, and
 * the number is not re-posted, re-logged or kept in app state after verification.
 *
 * <p>Token = AES-256-GCM (random IV) over the destination, bound to the user id and an expiry, then
 * Base64URL. Anything altered fails authentication; a token for user A is useless for user B.
 */
@Service
public class DestinationTokenService {

    /** How long a verified destination may be paid after it was verified. */
    public static final long TTL_SECONDS = 15 * 60;

    private static final String SEP = "\u001f";
    private static final SecureRandom RANDOM = new SecureRandom();

    /** What the provider confirmed about the destination. */
    public record Destination(String type, UUID destinationId, String destinationCode, String countryCode,
                              String accountNumber, String accountName, String destinationName,
                              boolean nameConfirmed, UUID gatewayId) {
    }

    private final SecretKeySpec key;

    public DestinationTokenService(@Value("${app.jwt.secret}") String secret) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(("zentrapay-destination-token|" + secret).getBytes(StandardCharsets.UTF_8));
            this.key = new SecretKeySpec(digest, "AES");
        } catch (Exception e) {
            throw new IllegalStateException("Could not initialise destination tokens", e);
        }
    }

    /** Encrypts a verified destination for this user. */
    public String issue(UUID userId, Destination d) {
        String plain = String.join(SEP,
                userId.toString(),
                String.valueOf(Instant.now().getEpochSecond() + TTL_SECONDS),
                nz(d.type()),
                d.destinationId() == null ? "" : d.destinationId().toString(),
                nz(d.destinationCode()),
                nz(d.countryCode()),
                nz(d.accountNumber()),
                nz(d.accountName()),
                nz(d.destinationName()),
                d.nameConfirmed() ? "1" : "0",
                // The gateway that verified the account: the payout is made through this one
                d.gatewayId() == null ? "" : d.gatewayId().toString());
        try {
            byte[] iv = new byte[12];
            RANDOM.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, iv));
            byte[] encrypted = cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8));
            byte[] out = new byte[iv.length + encrypted.length];
            System.arraycopy(iv, 0, out, 0, iv.length);
            System.arraycopy(encrypted, 0, out, iv.length, encrypted.length);
            return Base64.getUrlEncoder().withoutPadding().encodeToString(out);
        } catch (Exception e) {
            throw new IllegalStateException("Could not create the verification token", e);
        }
    }

    /**
     * Opens a token. Every failure (tampered, expired, someone else's) gives the same message, so a
     * caller learns nothing about why.
     */
    public Destination open(UUID userId, String token) {
        final String problem = "Please verify the account again before sending";
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Please verify the account before sending");
        }
        try {
            byte[] in = Base64.getUrlDecoder().decode(token.trim());
            if (in.length < 13) {
                throw new IllegalArgumentException(problem);
            }
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, in, 0, 12));
            String plain = new String(cipher.doFinal(in, 12, in.length - 12), StandardCharsets.UTF_8);
            String[] f = plain.split(SEP, -1);
            if (f.length != 11 ||!userId.toString().equals(f[0]) || Instant.now().getEpochSecond() > Long.parseLong(f[1])) {
                throw new IllegalArgumentException(problem);
            }
            return new Destination(f[2], f[3].isEmpty() ? null : UUID.fromString(f[3]), f[4], f[5], f[6], f[7], f[8], "1".equals(f[9]),
                    f[10].isEmpty() ? null : UUID.fromString(f[10]));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(problem);
        } catch (Exception e) {
            throw new IllegalArgumentException(problem);
        }
    }

    /** "0123456789" -> "******6789": for logs, receipts and the transactions table. */
    public static String mask(String accountNumber) {
        if (accountNumber == null || accountNumber.isBlank()) {
            return "";
        }
        String n = accountNumber.trim();
        if (n.length() <= 4) {
            return "****";
        }
        return "*".repeat(n.length() - 4) + n.substring(n.length() - 4);
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }
}
