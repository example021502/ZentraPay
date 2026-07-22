package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.accountsAuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.newFiatWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.newFiatAccountRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.fiatWalletBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.fiatBalancesRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {
    private final fiatBalancesRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService; // Inject the JwtService

    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;

//REGISTER
    public accountsAuthResponse register(@Valid newFiatAccountRequestDTO req) {
        if (userRepository.existsByEmail(req.email())) throw new RuntimeException("Email taken");

        String hashedPassword = passwordEncoder.encode(req.password() + passwordPepper);
        String hashedPin = passwordEncoder.encode(req.pin() + pinPepper);

        fiatWalletBalancesModel user = new fiatWalletBalancesModel();
        user.setFullName(req.fullName());
        user.setEmail(req.email());
        user.setPassword(hashedPassword);
        // Assuming you have a way to generate a zentag
        user.setZentag(req.zentag());
        user.setZentag(req.email());
        user.setZentag(hashedPin);
        user.setZentag(req.country());
        user.setZentag(req.phoneNumber());
        userRepository.save(user);

        // Generate token upon registration
        String token = jwtService.generateToken(user.getEmail());

        return new accountsAuthResponse(token, user.getUserId(), user.getFullName(), user.getEmail(), user.getZentag());
    }

    // LOGIN
    public accountsAuthResponse login(@Valid newFiatWalletRequestDTO req) {
        // 1. Find user by email or phone
        fiatWalletBalancesModel user = userRepository.findByEmailOrPhoneNumber(req.email(), req.phoneNumber())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 2. Verify password (incorporating your pepper)
        if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }

        // 3. Generate JWT
        String token = jwtService.generateToken(user.getEmail());

        // 4. Return the DTO with the token and user details
        return new accountsAuthResponse(
                token,
                user.getUserId(),
                user.getFullName(),
                user.getEmail(),
                user.getZentag()
        );
    }
}