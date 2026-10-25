package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ConversionModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ConversionRepository extends JpaRepository<ConversionModel, UUID> {

    // The 50 most recent conversions of a user, newest first
    List<ConversionModel> findTop50ByUserIdOrderByCreatedAtDesc(UUID userId);
}
