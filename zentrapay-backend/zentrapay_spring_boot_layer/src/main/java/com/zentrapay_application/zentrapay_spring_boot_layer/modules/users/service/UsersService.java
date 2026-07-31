package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.LoginRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.PinVerifyResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.RegisterRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.UserProfileDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.usersAuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.UserWalletsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UserWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UsersRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.JwtService;
import io.jsonwebtoken.Claims;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UsersService {
    private final UsersRepository userRepository;
    private final UserWalletRepository userWalletRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

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
        String[] nameParts = req.fullName().trim().split("\\s+", 2);
        user.setFirstName(nameParts[0]);
        user.setLastName(nameParts.length > 1 ? nameParts[1] : "");
        user.setPassword(hashedPassword);
        user.setPin(hashedPin);
        user.setPhoneNumber(req.phoneNumber());
        user.setZentag(req.zentag());
        user.setCountry(req.country());

        userRepository.save(user);

        // Create default wallet for the new user
        if (!userWalletRepository.existsByUserId(user.getUserId())) {
            UserWalletsModel fiatWallet = new UserWalletsModel();
            fiatWallet.setUserId(user.getUserId());
            fiatWallet.setWalletName("Default Wallet");
            fiatWallet.setCurrencyCode("GHS");
            fiatWallet.setBalance(0.0);
            fiatWallet.setIsDefault(true);
            fiatWallet.setStatus("active");
            LocalDateTime now = LocalDateTime.now();
            fiatWallet.setCreatedAt(now);
            fiatWallet.setUpdatedAt(now);
            userWalletRepository.save(fiatWallet);
        }

        String fullName = fullName(user);
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), fullName, user.getZentag());

        return new usersAuthResponse(user.getUserId(), user.getEmail(), fullName, user.getZentag(), token);
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
        String fullName = fullName(user);
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), fullName, user.getZentag());

        return new usersAuthResponse(user.getUserId(), user.getEmail(), fullName, user.getZentag(), token);
    }

    // REFRESH logic — exchanges a still-valid JWT for a new one, no credentials involved.
    public usersAuthResponse refresh(String bearerToken) {
        Claims claims = jwtService.parseAndValidate(bearerToken);
        UUID userId = UUID.fromString(claims.getSubject());

        usersModel user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String fullName = fullName(user);
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), fullName, user.getZentag());

        return new usersAuthResponse(user.getUserId(), user.getEmail(), fullName, user.getZentag(), token);
    }

    private String fullName(usersModel user) {
        String first = user.getFirstName() != null ? user.getFirstName() : "";
        String last = user.getLastName() != null ? user.getLastName() : "";
        return (first + " " + last).trim();
    }

    // PROFILE logic
    public UserProfileDTO getProfile(UUID userId) {
        usersModel user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return new UserProfileDTO(
                user.getUserId(),
                user.getEmail(),
                fullName(user),
                user.getZentag(),
                user.getPhoneNumber(),
                user.getCountry(),
                user.getStatus()
        );
    }

    // PIN VERIFICATION logic
    public PinVerifyResponseDTO verifyPin(UUID userId, String pin) {
        usersModel user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        boolean verified = passwordEncoder.matches(pin + pinPepper, user.getPin());
        return new PinVerifyResponseDTO(verified);
    }
}