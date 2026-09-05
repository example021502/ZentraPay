package com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.NotificationModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.RewardsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.NotificationRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.RewardsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.dto.ChallengesResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.challenges.dto.RewardsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * In-app notifications — GET/PATCH {@code /api/notifications}. Backed by
 * the {@code notifications} table ({@link NotificationModel}) that
 * payment/webhook flows already write to.
 */
@Service
@RequiredArgsConstructor
public class ChallengesServices {

    private final RewardsRepository rewardsRepository;

    @Transactional(readOnly = true)
    public List<RewardsDTO> list() {
        return rewardsRepository.findAll().stream().map(
                r-> new RewardsDTO(
                        r.getRewardId(),
                        r.getRewardType(),
                        r.getTitle(),
                        r.getDescription(),
                        r.getWorth(),
                        r.getCurrencyCode(),
                        r.getIsActive(),
                        r.getCreatedOn(),
                        r.getUpdatedOn()
                                )
        ).toList();
    }


}
