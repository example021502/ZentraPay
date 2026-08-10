package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.JwtService;
import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UsersService {

    private static final Logger log = LoggerFactory.getLogger(UsersService.class);

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final MerchantProfileRepository merchantProfileRepository;
    private final WalletRepository walletRepository;
    private final CountryRepository countryRepository;
    private final LoginHistoryRepository loginHistoryRepository;
    private final LinkedFundingSourceRepository linkedFundingSourceRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    // ========================================================================
    // REGISTER
    // ========================================================================
    @Transactional
    public usersAuthResponse register(@Valid RegisterRequestDTO req) {
        // Log the incoming registration form payload
        System.out.println("THE REGISTER FORM DATA:: data=" + req);

        // Check for existing uniqueness constraints before performing any database writes
        if (userRepository.existsByEmail(req.email())) {
            throw new RuntimeException("Email already taken");
        }
        if (userRepository.existsByPhoneNumber(req.phoneNumber())) {
            throw new RuntimeException("Phone number already taken");
        }
        if (userRepository.existsByZentag(req.zentag())) {
            throw new RuntimeException("Zentag already taken");
        }

        // Validate and fetch the country BEFORE saving the user to avoid unnecessary DB inserts
        Country country = countryRepository.findFirstByCountryIsoCode(req.countryCode())
                .orElseThrow(() -> new IllegalArgumentException("Unsupported or invalid Country"));

        System.out.println("Found country: " + country.getCountryIsoCode());

        // Initialize and populate the new User entity
        User user = new User();
        user.setFirstName(req.firstName());
        user.setLastName(req.lastName());
        user.setEmail(req.email());
        user.setPhoneNumber(req.phoneNumber());
        user.setCountryCode(req.countryCode());
        user.setPasswordHash(passwordEncoder.encode(req.password() + passwordPepper));
        user.setTransactionPinHash(passwordEncoder.encode(req.pin() + pinPepper));
        user.setZentag(req.zentag());
        user.setUserType("INDIVIDUAL");
        user.setStatus("ACTIVE");

        // Save the user record to the database
        user = userRepository.save(user);

        // Automatically create a default wallet if it doesn't already exist for this user
        if (!walletRepository.existsByUserIdAndWalletName(user.getUserId(), "Default Wallet")) {
            Wallet wallet = new Wallet();
            wallet.setUserId(user.getUserId());
            wallet.setWalletName("Default Wallet");
            wallet.setCurrencyCode(req.countryCode());
            wallet.setCountryCode(req.countryCode());
            wallet.setDefault(true);
            wallet.setStatus("ACTIVE");
            walletRepository.save(wallet);
        }

        // Generate the authentication token and return the response DTO
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getFullName(), user.getZentag());
        return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFullName(), user.getZentag());
    }

    // ========================================================================
    // LOGIN — records a LoginHistory row for every attempt, success or failure.
    // ========================================================================
    @Transactional
    public usersAuthResponse login(@Valid LoginRequestDTO req, HttpServletRequest httpRequest) {
        User user = null;
        try {
            user = findByEmailOrPhone(req.email(), req.phoneNumber())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPasswordHash())) {
                recordLogin(user.getUserId(), httpRequest, false);
                throw new RuntimeException("Invalid credentials");
            }

            recordLogin(user.getUserId(), httpRequest, true);

            String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getFullName(), user.getZentag());
            return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFullName(), user.getZentag());
        } catch (RuntimeException e) {
            if (user == null) {
                log.warn("[USERS] Login attempt failed for unknown identifier email={}, phone={}", req.email(), req.phoneNumber());
            }
            throw e;
        }
    }

    private java.util.Optional<User> findByEmailOrPhone(String email, String phoneNumber) {
        if (email != null && !email.isBlank()) {
            java.util.Optional<User> byEmail = userRepository.findByEmail(email);
            if (byEmail.isPresent()) {
                return byEmail;
            }
        }
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            return userRepository.findByPhoneNumber(phoneNumber);
        }
        return java.util.Optional.empty();
    }

    private void recordLogin(UUID userId, HttpServletRequest httpRequest, boolean success) {
        LoginHistory entry = new LoginHistory();
        entry.setUserId(userId);
        entry.setSuccess(success);
        if (httpRequest != null) {
            entry.setIpAddress(resolveClientIp(httpRequest));
            String userAgent = httpRequest.getHeader("User-Agent");
            entry.setDeviceInfo(userAgent != null ? userAgent.substring(0, Math.min(userAgent.length(), 200)) : null);
        }
        loginHistoryRepository.save(entry);
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        if (forwardedFor != null && !forwardedFor.isBlank()) {
            return forwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    // ========================================================================
    // REFRESH — exchanges a still (validly-signed, possibly expired) JWT for a new one.
    // ========================================================================
    public usersAuthResponse refresh(String bearerToken) {
        Claims claims = jwtService.parseAllowExpired(bearerToken);
        UUID userId = UUID.fromString(claims.getSubject());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getFullName(), user.getZentag());
        return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFullName(), user.getZentag());
    }

    // ========================================================================
    // PROFILE (basic identity) — GET/PATCH /api/users/me
    // ========================================================================
    @Transactional(readOnly = true)
    public UserProfileDTO getMe(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return toProfileDTO(user);
    }

    /**
     * Backs the Home "Receive" sheet: zentag + a QR payload the client renders
     * locally, plus the user's own linked funding sources (bank accounts) so a
     * sender paying by bank transfer can see where it lands. No server-side QR
     * image generation — {@code qrPayload} is a deep link the app's QR widget
     * encodes client-side.
     */
    @Transactional(readOnly = true)
    public ReceiveInfoDTO getReceiveInfo(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        var linkedAccounts = linkedFundingSourceRepository.findByUserId(userId).stream()
                .map(f -> new ReceiveInfoDTO.LinkedAccountDTO(
                        f.getSourceId().toString(),
                        f.getSourceName(),
                        f.getAccountIdentifier(),
                        f.getSourceType(),
                        f.isVerified()))
                .toList();

        String qrPayload = "zentrapay://receive?zentag=" + user.getZentag() + "&userId=" + user.getUserId();

        return new ReceiveInfoDTO(
                user.getUserId().toString(),
                user.getFullName(),
                user.getZentag(),
                qrPayload,
                linkedAccounts
        );
    }

    @Transactional
    public UserProfileDTO updateMe(UUID userId, UserMeUpdateDTO req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (req.firstName() != null && !req.firstName().isBlank()) {
            user.setFirstName(req.firstName());
        }
        if (req.lastName() != null && !req.lastName().isBlank()) {
            user.setLastName(req.lastName());
        }
        user = userRepository.save(user);
        return toProfileDTO(user);
    }

    private UserProfileDTO toProfileDTO(User user) {
        return new UserProfileDTO(
                user.getUserId(),
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getCountryCode(),
                user.getZentag(),
                user.getUserType(),
                user.getStatus(),
                user.getKycTier()
        );
    }

    // ========================================================================
    // KYC PROFILE — GET/PUT /api/users/me/profile
    // ========================================================================
    @Transactional(readOnly = true)
    public UserProfileDetailsDTO getKycProfile(UUID userId) {
        return userProfileRepository.findById(userId)
                .map(this::toProfileDetailsDTO)
                .orElseGet(() -> new UserProfileDetailsDTO(null, null, null, null, null, null, null, null, null, null, null, false));
    }

    @Transactional
    public UserProfileDetailsDTO upsertKycProfile(UUID userId, UserProfileDetailsDTO req) {
        if (!userRepository.existsById(userId)) {
            throw new ResourceNotFoundException("User not found");
        }
        UserProfile profile = userProfileRepository.findById(userId).orElseGet(UserProfile::new);
        profile.setUserId(userId);
        profile.setDateOfBirth(req.dateOfBirth());
        profile.setIdDocumentType(req.idDocumentType());
        profile.setIdDocumentNumber(req.idDocumentNumber());
        profile.setIdDocumentCountryCode(req.idDocumentCountryCode());
        profile.setAddressLine1(req.addressLine1());
        profile.setAddressLine2(req.addressLine2());
        profile.setCity(req.city());
        profile.setRegionState(req.regionState());
        profile.setPostalCode(req.postalCode());
        profile.setOccupation(req.occupation());
        if (req.amlStatus() != null && !req.amlStatus().isBlank()) {
            profile.setAmlStatus(req.amlStatus());
        }
        profile.setPep(req.isPep());
        profile = userProfileRepository.save(profile);
        return toProfileDetailsDTO(profile);
    }

    private UserProfileDetailsDTO toProfileDetailsDTO(UserProfile profile) {
        return new UserProfileDetailsDTO(
                profile.getDateOfBirth(),
                profile.getIdDocumentType(),
                profile.getIdDocumentNumber(),
                profile.getIdDocumentCountryCode(),
                profile.getAddressLine1(),
                profile.getAddressLine2(),
                profile.getCity(),
                profile.getRegionState(),
                profile.getPostalCode(),
                profile.getOccupation(),
                profile.getAmlStatus(),
                profile.isPep()
        );
    }

    // ========================================================================
    // MERCHANT PROFILE — GET/PUT /api/users/me/merchant-profile
    // ========================================================================
    @Transactional(readOnly = true)
    public MerchantProfileDTO getMerchantProfile(UUID userId) {
        return merchantProfileRepository.findById(userId)
                .map(this::toMerchantProfileDTO)
                .orElse(null);
    }

    @Transactional
    public MerchantProfileDTO upsertMerchantProfile(UUID userId, MerchantProfileDTO req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        MerchantProfile profile = merchantProfileRepository.findById(userId).orElseGet(MerchantProfile::new);
        profile.setUserId(userId);
        profile.setBusinessName(req.businessName());
        profile.setBusinessRegistrationNumber(req.businessRegistrationNumber());
        profile.setTaxIdentificationNumber(req.taxIdentificationNumber());
        profile.setBusinessCategoryCode(req.businessCategoryCode());
        profile.setBusinessCountryCode(req.businessCountryCode() != null ? req.businessCountryCode() : user.getCountryCode());
        profile.setBusinessAddress(req.businessAddress());
        profile = merchantProfileRepository.save(profile);

        if (!"MERCHANT".equals(user.getUserType())) {
            user.setUserType("MERCHANT");
            userRepository.save(user);
        }

        return toMerchantProfileDTO(profile);
    }

    private MerchantProfileDTO toMerchantProfileDTO(MerchantProfile profile) {
        return new MerchantProfileDTO(
                profile.getBusinessName(),
                profile.getBusinessRegistrationNumber(),
                profile.getTaxIdentificationNumber(),
                profile.getBusinessCategoryCode(),
                profile.getBusinessCountryCode(),
                profile.getBusinessAddress()
        );
    }

    // ========================================================================
    // PIN VERIFICATION
    // ========================================================================
    @Transactional(readOnly = true)
    public PinVerifyResponseDTO verifyPin(UUID userId, String pin) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        boolean valid = passwordEncoder.matches(pin + pinPepper, user.getTransactionPinHash());
        return new PinVerifyResponseDTO(valid);
    }
}