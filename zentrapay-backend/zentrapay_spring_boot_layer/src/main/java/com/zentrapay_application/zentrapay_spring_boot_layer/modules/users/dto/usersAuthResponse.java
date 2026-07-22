package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

/**
 * DTO representing the data returned upon successful authentication.
 * We use a Java record here for immutability and conciseness.
 */
public record AuthResponse(
        String token,
        Long userId,
        String fullName,
        String email,
        String zentag // Added as it was present in your original requirements
) {}