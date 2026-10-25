package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ProviderCategory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProviderCategoryRepository extends JpaRepository<ProviderCategory, String> {
}
