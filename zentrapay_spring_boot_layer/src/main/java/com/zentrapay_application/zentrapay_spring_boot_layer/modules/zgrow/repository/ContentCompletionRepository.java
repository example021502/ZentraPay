package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.ContentCompletion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContentCompletionRepository extends JpaRepository<ContentCompletion, UUID> {
    boolean existsByContentIdAndUserId(UUID contentId, UUID userId);
    Optional<ContentCompletion> findByContentIdAndUserId(UUID contentId, UUID userId);
    List<ContentCompletion> findByUserId(UUID userId);
}
