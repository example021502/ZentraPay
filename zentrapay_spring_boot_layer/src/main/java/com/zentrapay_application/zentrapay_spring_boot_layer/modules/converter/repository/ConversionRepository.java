package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.model.Conversion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ConversionRepository extends JpaRepository<Conversion, UUID> {
    List<Conversion> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
