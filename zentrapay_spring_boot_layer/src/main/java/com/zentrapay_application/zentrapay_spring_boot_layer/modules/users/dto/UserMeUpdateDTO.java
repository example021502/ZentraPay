package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto;

/**
 * {@code PATCH /api/users/me} request body — only self-service editable fields.
 * Both fields optional; null means "leave unchanged".
 */
public record UserMeUpdateDTO(
        String firstName,
        String lastName
) {
}
