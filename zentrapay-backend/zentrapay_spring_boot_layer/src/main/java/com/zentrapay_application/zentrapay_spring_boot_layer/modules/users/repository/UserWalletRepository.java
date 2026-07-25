package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.UserWalletsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserWalletRepository extends JpaRepository<UserWalletsModel, Long> {
    List<UserWalletsModel> findByUserId(UUID user_id);

    boolean existsByUserId(UUID userId);
}
