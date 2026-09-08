package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TutorialsModel;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TutorialsRepository extends JpaRepository<TutorialsModel, Integer> {
}
