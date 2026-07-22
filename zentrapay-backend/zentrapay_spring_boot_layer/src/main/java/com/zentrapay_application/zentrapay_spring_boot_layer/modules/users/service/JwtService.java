package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys; // Important import
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    @Value("${app.jwt.jwt_secret_key}")
    private String jwtSecret;

    // This method handles the conversion from String to Key
    private SecretKey getSigningKey() {
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

<<<<<<< HEAD
    public String generateToken(String email, String userId) {
        return Jwts.builder()
                .subject(userId)
                .claim("email", email)
=======
    public String generateToken(String email) {
        return Jwts.builder()
                .subject(email)
>>>>>>> update
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 86400000))
                // Now you pass the SecretKey object, which matches the required signature
                .signWith(getSigningKey())
                .compact();
    }
}