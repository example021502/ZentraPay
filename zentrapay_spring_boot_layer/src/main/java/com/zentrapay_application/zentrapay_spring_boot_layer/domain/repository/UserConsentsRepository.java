package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserConsentsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface UserConsentsRepository extends JpaRepository<UserConsentsModel, UUID> {
}
