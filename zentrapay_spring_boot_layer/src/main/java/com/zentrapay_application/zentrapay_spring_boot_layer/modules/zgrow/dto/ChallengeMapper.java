package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collections;
import java.util.List;

public class ChallengeMapper {

    // Map ChallengesModel -> ChallengesResponseDTO
    public static ChallengesResponseDTO toChallengeResponseDTO(ChallengesModel model) {
        if (model == null) return null;

        List<ChallengesTargetResponseDTO> targets = model.getTargets() == null ? Collections.emptyList() :
                model.getTargets().stream()
                        .map(ChallengeMapper::toTargetResponseDTO)
                        .toList();

        return new ChallengesResponseDTO(
                model.getId(),
                model.getTitle(),
                model.getDescription(),
                model.getCategory(),
                model.getChallengeType(),
                model.getDurationDays(),
                model.getIsActive(),
                model.getStartDate(),
                model.getEndDate(),
                targets
        );
    }

    /**
     * Overload used by the service layer, which loads the tiers up-front because
     * {@code ChallengesModel.targets} is LAZY and cannot be touched safely once
     * the transaction/EntityManager has closed.
     */
    public static ChallengesResponseDTO toChallengeResponseDTO(ChallengesModel model,
                                                              List<ChallengesTargetResponseDTO> targets) {
        if (model == null) return null;

        return new ChallengesResponseDTO(
                model.getId(),
                model.getTitle(),
                model.getDescription(),
                model.getCategory(),
                model.getChallengeType(),
                model.getDurationDays(),
                model.getIsActive(),
                model.getStartDate(),
                model.getEndDate(),
                targets == null ? Collections.emptyList() : targets
        );
    }

    // Map ChallengesTargetModel -> ChallengesTargetResponseDTO
    public static ChallengesTargetResponseDTO toTargetResponseDTO(ChallengesTargetModel model) {
        if (model == null) return null;

        return new ChallengesTargetResponseDTO(
                model.getId(),
                model.getTargetAmount(),
                model.getRewardType(),
                model.getRewardValue(),
                model.getTierLevel()
        );
    }

    // Map UserChallengesModel -> UserChallengesResponseDTO
    public static UserChallengesResponseDTO toUserChallengeResponseDTO(UserChallengesModel model) {
        if (model == null) return null;

        List<ChallengesProgressResponseDTO> progressLogs = model.getProgressLogs() == null ? Collections.emptyList() :
                model.getProgressLogs().stream()
                        .map(ChallengeMapper::toProgressResponseDTO)
                        .toList();

        return toUserChallengeResponseDTO(model, progressLogs);
    }

    /**
     * Overload used by the service layer, which loads the ledger up-front because
     * {@code UserChallengesModel.progressLogs} is LAZY and cannot be touched
     * safely once the transaction/EntityManager has closed.
     */
    public static UserChallengesResponseDTO toUserChallengeResponseDTO(UserChallengesModel model,
                                                                       List<ChallengesProgressResponseDTO> progressLogs) {
        if (model == null) return null;

        // Calculate progress percentage for Flutter progress bar (0.0 to 100.0)
        double progressPercentage = 0.0;
        BigDecimal currentAmount = model.getCurrentAmount() == null ? BigDecimal.ZERO : model.getCurrentAmount();
        if (model.getTargetAmount() != null && model.getTargetAmount().compareTo(BigDecimal.ZERO) > 0) {
            progressPercentage = currentAmount
                    .multiply(BigDecimal.valueOf(100))
                    .divide(model.getTargetAmount(), 2, RoundingMode.HALF_UP)
                    .doubleValue();
            progressPercentage = Math.max(0.0, Math.min(100.0, progressPercentage));
        }

        return new UserChallengesResponseDTO(
                model.getId(),
                model.getUserId(),
                toChallengeResponseDTO(model.getChallenge()),
                model.getStatus(),
                currentAmount,
                model.getTargetAmount(),
                progressPercentage,
                model.getStartedAt(),
                model.getEndsAt(),
                model.getCompletedAt(),
                progressLogs == null ? Collections.emptyList() : progressLogs
        );
    }

    // Map ChallengesProgressModel -> ChallengesProgressResponseDTO
    public static ChallengesProgressResponseDTO toProgressResponseDTO(ChallengesProgressModel model) {
        if (model == null) return null;

        return new ChallengesProgressResponseDTO(
                model.getId(),
                model.getAmountContributed(),
                model.getNewTotalAmount(),
                model.getTransactionReference(),
                model.getNotes(),
                model.getCreatedAt()
        );
    }
}