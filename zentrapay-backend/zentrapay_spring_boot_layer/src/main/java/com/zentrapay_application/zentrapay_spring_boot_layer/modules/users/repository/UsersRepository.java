package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository;

<<<<<<< HEAD
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.core.annotation.MergedAnnotation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.lang.annotation.Annotation;
import java.util.Optional;

@Repository
    public interface UsersRepository extends JpaRepository<usersModel, Long> {
        Optional<usersModel> findByEmailOrPhoneNumber(String email, String phone_number);
        Boolean existsByEmail(@Email(message = "Invalid email format") String email);
        Boolean existsByPhoneNumber(String phoneNumber);
=======
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.fiatWalletBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
    public interface UserRepository extends JpaRepository<fiatWalletBalancesModel, Long> {
        Optional<fiatWalletBalancesModel> findByEmailOrPhoneNumber(String email, String phone_number);
        boolean existsByEmail(String email);
>>>>>>> update
    }
