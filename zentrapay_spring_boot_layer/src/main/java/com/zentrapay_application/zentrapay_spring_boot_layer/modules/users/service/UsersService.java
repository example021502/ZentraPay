package com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LoginHistoryModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.LoginHistoryRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.JwtService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;


@Service
@RequiredArgsConstructor
public class UsersService {

    private static final Logger log = LoggerFactory.getLogger(UsersService.class);

    private final UserRepository userRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final LoginHistoryRepository loginHistoryRepository;
    private final FiatAccountRepository fiatAccountRepository;
    private final CryptoAccountRepository cryptoAccountRepository;
    private final UserProfileRepository userProfileRepository;


    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    // ========================================================================
    // REGISTER
    // ========================================================================
    @Transactional
    public usersAuthResponse register(@Valid RegisterRequestDTO req, String ipAddress) {
        // Log the incoming registration form payload
        System.out.println("THE REGISTER FORM DATA:: data=" + req);

        // Check for existing uniqueness constraints before performing any database writes
        if (userRepository.existsByEmail(req.email())) {
            throw new RuntimeException("Email already taken");
        }
        if (userRepository.existsByPhoneNumber(req.phoneNumber())) {
            throw new RuntimeException("Phone number already taken");
        }

        if(req.termsConsent() == false){
            throw new RuntimeException("Please accept the Terms of use to continue");
        }

        // Validate and fetch the country BEFORE saving the user to avoid unnecessary DB inserts
        GatewayCountryModel country = gatewayCountriesRepository.findFirstByCountryCode(req.countryCode())
                .orElseThrow(() -> new IllegalArgumentException("Unsupported or invalid Country"));

        System.out.println("Found country: " + country.getCountryCode());

        // Initialize and populate the new User entity
        UserModel user = new UserModel();
        user.setFirstName(req.firstName());
        user.setLastName(req.lastName());
        user.setEmail(req.email());
        user.setPhoneNumber(req.phoneNumber());
        user.setCountryCode(req.countryCode());
        user.setPasswordHash(passwordEncoder.encode(req.password() + passwordPepper));
        user.setTransactionPinHash(passwordEncoder.encode(req.pin() + pinPepper));
        user.setUserType("app-user");
        user.setStatus("active");

        // Save the user record to the database
        user = userRepository.save(user);


//        FIAT WALLET CREATION
        if (!fiatWalletRepository.existsByUserId(user.getUserId()) && !cryptoWalletRepository.existsByUserId(user.getUserId())) {
            FiatWalletModel fiatWallet = new FiatWalletModel();
            fiatWallet.setUserId(user.getUserId());
            fiatWallet.setCountryCode(req.countryCode());
            fiatWallet.setWalletName("Zentrapay_Wallet");
           fiatWallet = fiatWalletRepository.save(fiatWallet);
//            CRYPTO WALLET CREATION
            CryptoWalletModel cryptoWallet = new CryptoWalletModel();
            cryptoWallet.setUserId(user.getUserId());
            cryptoWallet.setStatus("active");
            cryptoWallet = cryptoWalletRepository.save(cryptoWallet);

           final String currencyCode = gatewayCurrenciesRepository
                    .getCurrencyCodesByCountryCode(user.getCountryCode()).stream()
                    .findFirst()
                    .orElse("GHS");
           final String zentag = req.phoneNumber() + "_" + currencyCode +"@zentrapay";
            FiatAccountModel fiatAccount = new FiatAccountModel();
            fiatAccount.setWalletId(fiatWallet.getWalletId());
            fiatAccount.setAccountName("Default Account");
            fiatAccount.setCurrencyCode(currencyCode);
            fiatAccount.setZentag(zentag);
            fiatAccount.setBalance(BigDecimal.ZERO);
            fiatAccount.setDefault(true);
            fiatAccount.setStatus("active");
            fiatAccountRepository.save(fiatAccount);

            CryptoAccountModel cryptoAccount = new CryptoAccountModel();
            cryptoAccount.setWalletId(cryptoWallet.getWalletId());
            cryptoAccount.setNetwork("unknown");
            cryptoAccount.setCurrencyCode("Unknown");
            cryptoAccount.setWalletAddress("pending-" + user.getUserId());
            cryptoAccount.setBalance(BigDecimal.ZERO);
            cryptoAccount.setIsDefault(true);
            cryptoAccount.setStatus("active");
            cryptoAccountRepository.save(cryptoAccount);
        }else{
            throw new RuntimeException("Something went wrong. Fiat wallet and Crypto wallet for this user already exist!");
        }

        // Generate the authentication token and return the response DTO
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName());
        return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName());
    }

    // ========================================================================
    // LOGIN — records a LoginHistory row for every attempt, success or failure.
    // ========================================================================
    @Transactional
    public usersAuthResponse login(@Valid LoginRequestDTO req, HttpServletRequest httpRequest) {
        UserModel user = null;
        try {
            user = userRepository.findByEmailOrPhoneNumber(req.email(), req.phoneNumber())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPasswordHash())) {
                recordLogin(user.getUserId(), httpRequest, false);
                throw new RuntimeException("Invalid credentials");
            }

            recordLogin(user.getUserId(), httpRequest, true);

            String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName());
            return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName());
        } catch (RuntimeException e) {
            if (user == null) {
                log.warn("[USERS] Login attempt failed for unknown identifier email={}, phone={}", req.email(), req.phoneNumber());
            }
            throw e;
        }
    }

    private void recordLogin(UUID userId, HttpServletRequest httpRequest, boolean success) {
        LoginHistoryModel entry = new LoginHistoryModel();
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

//    GETTING USER INFROMATION
    @Transactional(readOnly = true)
public UserInformation getMe(@Valid UUID userId) {
        UserModel user = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Retrieve profile if present. The profile is optional — a row is only
        // created once the user submits their KYC details — so a missing row must
        // NOT null out the whole response. Always return the user; profile may be null.
        UserProfileModel up = userProfileRepository.getBtUserId(userId);
        UserProfileDTO profile = toProfileDTO(up);
        return new UserInformation(toUserDTO(user), profile);
    }

    // ========================================================================
    // PATCH /api/users/me — self-service editable account fields (name only).
    // ========================================================================
    @Transactional
    public UserDTO updateMe(UUID userId, UserMeUpdateDTO req) {
        UserModel user = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (req.firstName() != null && !req.firstName().isBlank()) {
            user.setFirstName(req.firstName());
        }
        if (req.lastName() != null && !req.lastName().isBlank()) {
            user.setLastName(req.lastName());
        }
        user = userRepository.save(user);
        return toUserDTO(user);
    }

    // ========================================================================
    // GET /api/users/me/profile — KYC profile, null until first submitted.
    // ========================================================================
    @Transactional(readOnly = true)
    public UserProfileDTO getKycProfile(UUID userId) {
        return toProfileDTO(userProfileRepository.getBtUserId(userId));
    }

    // ========================================================================
    // PUT /api/users/me/profile — upsert KYC profile fields, then recompute
    // the caller's kycTier (see recomputeKycTier). Every field is optional
    // (null = leave unchanged) so the KYC form can submit incrementally.
    // ========================================================================
    @Transactional
    public UserProfileDTO upsertKycProfile(UUID userId, UserProfileUpdateDTO req) {
        UserModel user = userRepository.getUserById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        UserProfileModel profile = userProfileRepository.getBtUserId(userId);
        if (profile == null) {
            profile = new UserProfileModel();
            profile.setUserId(userId);
        }

        if (req.dateOfBirth() != null) profile.setDateOfBirth(req.dateOfBirth());
        if (req.nationalityCountryCode() != null) profile.setNationalityCountryCode(req.nationalityCountryCode());
        if (req.identityDocumentType() != null) profile.setIdentityDocumentType(req.identityDocumentType());
        if (req.identityDocumentNumber() != null) profile.setIdentityDocumentNumber(req.identityDocumentNumber());
        if (req.identityDocumentIssuingCountryCode() != null) profile.setIdentityDocumentIssuingCountryCode(req.identityDocumentIssuingCountryCode());
        if (req.identityDocumentExpirationDate() != null) profile.setIdentityDocumentExpirationDate(req.identityDocumentExpirationDate());
        if (req.addressLine1() != null) profile.setAddressLine1(req.addressLine1());
        if (req.addressLine2() != null) profile.setAddressLine2(req.addressLine2());
        if (req.cityName() != null) profile.setCityName(req.cityName());
        if (req.stateOrRegion() != null) profile.setStateOrRegion(req.stateOrRegion());
        if (req.postalCode() != null) profile.setPostalCode(req.postalCode());
        if (req.occupationTitle() != null) profile.setOccupationTitle(req.occupationTitle());

        profile = userProfileRepository.save(profile);
        recomputeKycTier(user, profile);
        return toProfileDTO(profile);
    }

    /**
     * Tier 2 (unlocks sending/receiving money, see PaymentsService) requires
     * a complete profile — DOB, address, occupation, ID document type+number
     * — AND all three Tier-2 documents uploaded (front, back, selfie; see
     * DocumentsService). This is a deliberately generic bar, the same for
     * every country, rather than an attempt to encode real per-country KYC
     * regulation. Anything short of that but with at least one field filled
     * in is tier 1 ("started"); an untouched profile stays tier 0.
     */
    void recomputeKycTier(UserModel user, UserProfileModel profile) {
        short newTier;
        if (profile == null) {
            newTier = 0;
        } else {
            boolean complete = profile.getDateOfBirth() != null
                    && notBlank(profile.getAddressLine1())
                    && notBlank(profile.getCityName())
                    && notBlank(profile.getOccupationTitle())
                    && notBlank(profile.getIdentityDocumentType())
                    && notBlank(profile.getIdentityDocumentNumber())
                    && notBlank(profile.getIdDocumentFrontPath())
                    && notBlank(profile.getIdDocumentBackPath())
                    && notBlank(profile.getSelfiePath());
            boolean started = profile.getDateOfBirth() != null
                    || notBlank(profile.getAddressLine1())
                    || notBlank(profile.getIdentityDocumentType())
                    || notBlank(profile.getIdDocumentFrontPath());
            newTier = complete ? (short) 2 : started ? (short) 1 : (short) 0;
        }
        if (user.getKycTier() != newTier) {
            user.setKycTier(newTier);
            userRepository.save(user);
        }
    }

    private boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private UserDTO toUserDTO(UserModel u) {
        return new UserDTO(
                u.getUserId(),
                u.getFirstName(),
                u.getLastName(),
                u.getEmail(),
                u.getPhoneNumber(),
                u.getCountryCode(),
                u.getCreatedAt(),
                u.getStatus(),
                u.getUserType(),
                u.getKycTier()
        );
    }

    private UserProfileDTO toProfileDTO(UserProfileModel up) {
        if (up == null) {
            return null;
        }
        return new UserProfileDTO(
                up.getDateOfBirth(),
                up.getNationalityCountryCode(),
                up.getIdentityDocumentType(),
                up.getIdentityDocumentNumber(),
                up.getIdentityDocumentIssuingCountryCode(),
                up.getIdentityDocumentExpirationDate(),
                up.getAddressLine1(),
                up.getAddressLine2(),
                up.getCityName(),
                up.getStateOrRegion(),
                up.getPostalCode(),
                up.getOccupationTitle(),
                up.getAntiMoneyLaunderingStatus(),
                up.isPoliticallyExposedPerson(),
                up.getRiskScoreLevel(),
                up.getKYCStatus(),
                notBlank(up.getIdDocumentFrontPath()),
                notBlank(up.getIdDocumentBackPath()),
                notBlank(up.getSelfiePath()),
                up.getCreatedAt(),
                up.getUpdatedAt()
        );
    }
}
