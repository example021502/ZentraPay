package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.TutorialsModel;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TutorialsRepository extends JpaRepository<TutorialsModel, Integer> {
}
