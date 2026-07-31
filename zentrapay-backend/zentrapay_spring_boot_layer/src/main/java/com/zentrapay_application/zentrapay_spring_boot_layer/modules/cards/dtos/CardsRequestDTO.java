package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.dtos;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CardsRequestDTO(
        @NotNull(message = "User id missing")
        UUID userId
) {
}