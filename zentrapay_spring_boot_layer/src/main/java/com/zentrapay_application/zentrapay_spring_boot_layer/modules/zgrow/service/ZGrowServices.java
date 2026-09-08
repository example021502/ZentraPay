package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.NotificationModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.RewardsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TutorialsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.RewardsDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.dto.TutorialsDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * In-app notifications — GET/PATCH {@code /api/notifications}. Backed by
 * the {@code notifications} table ({@link NotificationModel}) that
 * payment/webhook flows already write to.
 */
@Service
@RequiredArgsConstructor
public class ZGrowServices {

    private final RewardsRepository rewardsRepository;
    private final TutorialsRepository tutorialsRepository;

    @Transactional(readOnly = true)
    public List<RewardsDTO> listRewards() {
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
    @Transactional(readOnly = true)
    public List<TutorialsDTO> listTutorials() {
        return tutorialsRepository.findAll().stream().map(
                r-> new TutorialsDTO(
                        r.getId(),
                        r.getTitle(),
                        r.getType(),
                        r.getDescription(),
                        r.getVideoUrl(),
                        r.getThumbnailUrl(),
                        r.getDurationSeconds(),
                        r.getIsActive(),
                        r.getCreatedAt(),
                        r.getUpdatedAt()
                )
                        ).toList();
    }


}
