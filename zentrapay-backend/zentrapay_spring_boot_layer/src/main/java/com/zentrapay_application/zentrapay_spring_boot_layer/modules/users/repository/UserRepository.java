package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
    public interface UserRepository extends JpaRepository<User, Long> {
        Optional<User> findByEmailOrPhoneNumber(String email, String phone_number);
        boolean existsByEmail(String email);
    }
