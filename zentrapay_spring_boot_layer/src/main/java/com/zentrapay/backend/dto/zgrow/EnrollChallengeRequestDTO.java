package com.zentrapay.backend.dto.zgrow;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

// Payload sent by frontend when accepting a challenge
public record EnrollChallengeRequestDTO(
        @NotNull(message = "Challenge ID is required")
        UUID challengeId
) {}