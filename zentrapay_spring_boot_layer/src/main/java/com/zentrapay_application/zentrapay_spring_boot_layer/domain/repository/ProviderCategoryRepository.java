package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ProviderCategory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProviderCategoryRepository extends JpaRepository<ProviderCategory, String> {
}
