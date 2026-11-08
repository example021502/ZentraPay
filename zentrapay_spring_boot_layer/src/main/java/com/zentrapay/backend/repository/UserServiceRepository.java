package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserServiceModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserServiceRepository extends JpaRepository<UserServiceModel, UUID> {

    List<UserServiceModel> findByUserIdOrderByCreatedAtAsc(UUID userId);

    Optional<UserServiceModel> findByUserIdAndServiceKindAndProviderId(UUID userId, String serviceKind, UUID providerId);
}
