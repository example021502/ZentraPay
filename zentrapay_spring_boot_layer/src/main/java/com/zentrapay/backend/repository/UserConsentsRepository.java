package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserConsentsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface UserConsentsRepository extends JpaRepository<UserConsentsModel, UUID> {
}
