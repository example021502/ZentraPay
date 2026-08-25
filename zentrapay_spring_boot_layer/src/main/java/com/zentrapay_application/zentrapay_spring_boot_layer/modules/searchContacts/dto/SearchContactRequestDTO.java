package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public record SearchContactRequestDTO(
        @NotBlank(message = "Identifier missing")
        UUID query
) {
}