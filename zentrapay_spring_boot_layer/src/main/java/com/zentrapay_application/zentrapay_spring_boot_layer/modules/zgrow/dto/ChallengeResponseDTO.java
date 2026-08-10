package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import java.util.List;
import java.util.Map;

public record ChallengeResponseDTO(
     List<?> joinedChallenges,
     List<?> otherChallenges
) {
}
