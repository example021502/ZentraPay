package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

// Payload sent by frontend when accepting a challenge
public record EnrollChallengeRequestDTO(
        @NotNull(message = "Challenge ID is required")
        UUID challengeId
) {}