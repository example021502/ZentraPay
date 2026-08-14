package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    @Value("${app.jwt.secret}")
    private String secret;

    @Value("${app.jwt.expiration-ms}")
    private long expirationMs;

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(UUID userId, String email, String fullName, String zentag) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);

        return Jwts.builder()
                .subject(userId.toString())
                .claim("email", email)
                .claim("fullName", fullName)
                .claim("zentag", zentag)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(signingKey())
                .compact();
    }

    public Claims parseAndValidate(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Same signature validation as {@link #parseAndValidate(String)} but tolerates an
     * expired token — used only by {@code POST /api/users/refresh}, which the API
     * contract requires to work on "an expired-but-validly-signed token". Any other
     * validation failure (bad signature, malformed token, ...) still throws.
     */
    public Claims parseAllowExpired(String token) {
        try {
            return parseAndValidate(token);
        } catch (ExpiredJwtException e) {
            return e.getClaims();
        }
    }
}
