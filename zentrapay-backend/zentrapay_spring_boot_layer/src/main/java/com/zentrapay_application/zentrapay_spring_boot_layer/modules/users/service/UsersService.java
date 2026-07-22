package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UsersRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UsersService {
    private final UsersRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService; // Inject the JwtService
    private final com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.service.CurrencyAccountsService currencyAccountsService;

    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;
    // REGISTER logic
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
        user.setFullName(req.fullName());
        user.setEmail(req.email());
        user.setPassword(hashedPassword);
        user.setZentag(req.zentag());
        user.setPin(hashedPin);
        user.setCountry(req.country());
        user.setPhoneNumber(req.phoneNumber());

        userRepository.save(user);

        // Create default wallets for the new user
        currencyAccountsService.createDefaultWallets(user.getUserId(), req.country());

        String token = jwtService.generateToken(user.getEmail(), user.getUserId());
        return new usersAuthResponse(token, user.getFullName(), user.getEmail(), user.getZentag());
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
        String token = jwtService.generateToken(user.getEmail(), user.getUserId());

        return new usersAuthResponse(
                token,
                user.getFullName(),
                user.getEmail(),
                user.getZentag()
        );
    }
}