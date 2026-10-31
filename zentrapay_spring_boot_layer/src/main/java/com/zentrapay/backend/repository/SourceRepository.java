package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SourceModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface SourceRepository extends JpaRepository<SourceModel, UUID> {

    @Query("SELECT * FROM SourceModel s WHERE s.isActive = :active")
    List<SourceModel> findAllActive(boolean active);
}
