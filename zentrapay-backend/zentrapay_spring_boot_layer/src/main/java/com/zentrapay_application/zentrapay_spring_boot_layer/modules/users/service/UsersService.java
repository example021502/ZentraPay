package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.LoginRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.RegisterRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.usersAuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.UserWalletsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UserWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UsersRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UsersService {
    private final UsersRepository userRepository;
    private final UserWalletRepository userWalletRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    // REGISTER logic
    @Transactional
    public usersAuthResponse register(@Valid RegisterRequestDTO req) {
        // Correctly check if user exists using Boolean.TRUE.equals() to handle null
        if (Boolean.TRUE.equals(userRepository.existsByEmail(req.email()))) {
            throw new RuntimeException("Email already taken");
        }
        if (Boolean.TRUE.equals(userRepository.existsByPhoneNumber(req.phoneNumber()))) {
            throw new RuntimeException("Phone number already taken");
        }

        String hashedPassword = passwordEncoder.encode(req.password() + passwordPepper);
        String hashedPin = passwordEncoder.encode(req.pin() + pinPepper);

        usersModel user = new usersModel();
        user.setEmail(req.email());
        user.setPassword(hashedPassword);
        user.setPin(hashedPin);
        user.setPhoneNumber(req.phoneNumber());
        user.setZentag(req.zentag());
        user.setCountry(req.country());

        userRepository.save(user);

        // Create default wallets for the new user
        if (!userWalletRepository.existsByUserId(user.getUserId())) {
            UserWalletsModel fiatWallet = new UserWalletsModel();
            fiatWallet.setUserId(user.getUserId());
            fiatWallet.setStatus("active");
            fiatWallet.setStatus("Default Wallet");
            userWalletRepository.save(fiatWallet);
        }


        return new usersAuthResponse(user.getUserId(), user.getEmail());
    }

    // LOGIN logic
    public usersAuthResponse login(@Valid LoginRequestDTO req) {
        // 1. Fetch the user object instead of a boolean
        usersModel user = userRepository.findByEmailOrPhoneNumber(req.email(), req.phoneNumber())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 2. Verify password (incorporating your pepper)
        if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }

        // 3. Generate JWT

        return new usersAuthResponse(
                user.getUserId(),
                user.getEmail()
        );
    }
}