package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.AuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.LoginRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.RegisterRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.User;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService; // Inject the JwtService

    @Value("${app.password.pepper}")
    private String passwordPepper;
//REGISTER
    public AuthResponse register(@Valid RegisterRequestDTO req) {
        if (userRepository.existsByEmail(req.email())) throw new RuntimeException("Email taken");

        String hashedPassword = passwordEncoder.encode(req.password() + passwordPepper);

        User user = new User();
        user.setFullName(req.fullName());
        user.setEmail(req.email());
        user.setPassword(hashedPassword);
        // Assuming you have a way to generate a zentag
        user.setZentag(req.email());
        userRepository.save(user);

        // Generate token upon registration
        String token = jwtService.generateToken(user.getEmail());

        return new AuthResponse(token, user.getUserId(), user.getFullName(), user.getEmail(), user.getZentag());
    }

    // LOGIN
    public AuthResponse login(@Valid LoginRequestDTO req) {
        // 1. Find user by email or phone
        User user = userRepository.findByEmailOrPhoneNumber(req.email(), req.phoneNumber())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 2. Verify password (incorporating your pepper)
        if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }

        // 3. Generate JWT
        String token = jwtService.generateToken(user.getEmail());

        // 4. Return the DTO with the token and user details
        return new AuthResponse(
                token,
                user.getUserId(),
                user.getFullName(),
                user.getEmail(),
                user.getZentag()
        );
    }
}