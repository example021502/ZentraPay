package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

<<<<<<< HEAD
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UsersRepository;
=======
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.accountsAuthResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.newFiatWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.newFiatAccountRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.fiatWalletBalancesModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.fiatBalancesRepository;
>>>>>>> update
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

<<<<<<< HEAD
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UsersService {
    private final UsersRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService; // Inject the JwtService
    private final com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.service.CurrencyAccountsService currencyAccountsService;
=======
@Service
@RequiredArgsConstructor
public class UserService {
    private final fiatBalancesRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService; // Inject the JwtService
>>>>>>> update

    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;
<<<<<<< HEAD
    // REGISTER logic
    public usersAuthResponse register(@Valid RegisterRequestDTO req) {
        // Correctly check if user exists using Boolean.TRUE.equals() to handle null
        if (Boolean.TRUE.equals(userRepository.existsByEmail(req.email()))) {
            throw new RuntimeException("Email already taken");
        }
        if (Boolean.TRUE.equals(userRepository.existsByPhoneNumber(req.phoneNumber()))) {
            throw new RuntimeException("Phone number already taken");
        }
=======

//REGISTER
    public accountsAuthResponse register(@Valid newFiatAccountRequestDTO req) {
        if (userRepository.existsByEmail(req.email())) throw new RuntimeException("Email taken");
>>>>>>> update

        String hashedPassword = passwordEncoder.encode(req.password() + passwordPepper);
        String hashedPin = passwordEncoder.encode(req.pin() + pinPepper);

<<<<<<< HEAD
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
=======
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
>>>>>>> update
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 2. Verify password (incorporating your pepper)
        if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPassword())) {
<<<<<<< HEAD
           throw new RuntimeException("Invalid credentials");
        }

        // 3. Generate JWT
        String token = jwtService.generateToken(user.getEmail(), user.getUserId());

        return new usersAuthResponse(
                token,
=======
            throw new RuntimeException("Invalid credentials");
        }

        // 3. Generate JWT
        String token = jwtService.generateToken(user.getEmail());

        // 4. Return the DTO with the token and user details
        return new accountsAuthResponse(
                token,
                user.getUserId(),
>>>>>>> update
                user.getFullName(),
                user.getEmail(),
                user.getZentag()
        );
    }
}