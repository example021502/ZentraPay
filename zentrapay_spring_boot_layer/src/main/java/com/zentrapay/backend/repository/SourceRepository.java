package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SourceModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface SourceRepository extends JpaRepository<SourceModel, UUID> {

    // JPQL, not SQL: "SELECT *" is not valid JPQL and fails application startup.
    @Query("SELECT s FROM SourceModel s WHERE s.active = :active ORDER BY s.name")
    List<SourceModel> findAllActive(@Param("active") boolean active);
}
