package com.zentrapay.backend.service.user;

import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.security.AttemptLimiter;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.dto.user.*;
import com.zentrapay.backend.entity.LoginHistoryModel;
import com.zentrapay.backend.repository.LoginHistoryRepository;
import com.zentrapay.backend.security.JwtService;
import com.zentrapay.backend.service.gateway.FincraServices;
import com.zentrapay.backend.service.region.SupportedRegionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;


@Service
@RequiredArgsConstructor
public class UsersService {

    private static final Logger log = LoggerFactory.getLogger(UsersService.class);

    private final UserRepository userRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final LoginHistoryRepository loginHistoryRepository;
    private final VirtualAccountRepository accounts;
    private final CryptoAccountRepository cryptoAccountRepository;
    private final UserProfileRepository userProfileRepository;
    private final PinService pinService;
    private final AttemptLimiter attemptLimiter;
    private final SupportedRegionService supportedRegionService;
    private final KycVerificationService kycVerificationService;

    private final FincraServices fincraServices;
    private final SupportedIdentitiesServices supportedIdentitiesServices;
    private final UserProfileServices userProfileServices;

    @Value("${app.password.pepper}")
    private String passwordPepper;

    @Value("${app.pin.pepper}")
    private String pinPepper;

    // ========================================================================
    // REGISTER
    // ========================================================================
    @Transactional
    public usersAuthResponse register(@Valid RegisterRequestDTO req, HttpServletRequest httpRequest) {
        // Creates the user, their fiat + crypto wallets and default account, then returns a login token
        log.info("Registering a new user with email {}", req.email());

        // Check for existing uniqueness constraints before performing any database writes
        if (userRepository.existsByEmail(req.email())) {
            throw new IllegalArgumentException("Email already taken");
        }
        if (userRepository.existsByPhoneNumber(req.phoneNumber())) {
            throw new IllegalArgumentException("Phone number already taken");
        }

        if (!Boolean.TRUE.equals(req.termsConsent())) {
            throw new IllegalArgumentException("Please accept the Terms of use to continue");
        }

        // Validate and fetch the country BEFORE saving the user to avoid unnecessary DB inserts
        // The country must be one of the payment providers support AND that is switched on right now
        CountriesModel country = supportedRegionService.requireCountry(req.countryCode());

        // Initialize and populate the new User entity
        UserModel user = new UserModel();
        user.setFirstName(req.firstName());
        user.setLastName(req.lastName());
        user.setEmail(req.email());
        user.setPhoneNumber(req.phoneNumber());
        user.setCountryCode(country.getCode());
        user.setPasswordHash(passwordEncoder.encode(req.password() + passwordPepper));
        user.setTransactionPinHash(passwordEncoder.encode(req.pin() + pinPepper));
        user.setUserType(Datatypes.UserType.APP_USER);
        user.setStatus(Datatypes.UserStatus.ACTIVE);

        // Save the user record to the database
        user = userRepository.save(user);
        Map<String, Object> newProfile = userProfileServices.populateUserProfile(
                user.getUserId(),
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null);


        // Generate the authentication token and return the response DTO
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getPhoneNumber(), user.getCountryCode(), user.getUserType(), user.getFirstName(), user.getLastName());
        recordLogin(user.getUserId(), httpRequest, true);
        return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName());
    }

    // ========================================================================
    // LOGIN - records a LoginHistory row for every attempt, success or failure.
    // (Not one big @Transactional: the "failed attempt" row must survive the exception we throw.)
    // ========================================================================
    public usersAuthResponse login(@Valid LoginRequestDTO req, HttpServletRequest httpRequest) {
        // Guess protection is keyed on what the caller typed (not on whether the account exists),
        // so the lock looks the same for real and made-up accounts
        // The email wins when both are sent: email and phone are each unique, but together they could
        // point at two different accounts, which would make the lookup ambiguous
        boolean byEmail = req.email() != null && !req.email().isBlank();
        String identifier = (byEmail ? req.email() : req.phoneNumber() == null ? "" : req.phoneNumber()).trim();
        String limitKey = "login:" + identifier.toLowerCase();
        attemptLimiter.requireNotLocked(limitKey);

        UserModel user = userRepository.findByEmailOrPhoneNumber(byEmail ? identifier : null, byEmail ? null : identifier).orElse(null);

        // Same message for "no such user" and "wrong password" so nobody can probe which accounts exist
        if (user == null) {
            attemptLimiter.recordFailure(limitKey);
            log.warn("[USERS] Login attempt for an unknown account");
            throw new IllegalArgumentException("Invalid credentials");
        }
        if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPasswordHash())) {
            attemptLimiter.recordFailure(limitKey);
            recordLogin(user.getUserId(), httpRequest, false);
            log.info("[USERS] Login failed - invalid credentials for user {}", user.getUserId());
            throw new IllegalArgumentException("Invalid credentials");
        }
        attemptLimiter.recordSuccess(limitKey);
        if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
            recordLogin(user.getUserId(), httpRequest, false);
            throw new IllegalArgumentException("Your account is " + user.getStatus() + ". Please contact support.");
        }

        recordLogin(user.getUserId(), httpRequest, true);
        return authResponse(user);
    }

    // ========================================================================
    // REFRESH - a new token for an expired (but correctly signed) one
    // ========================================================================
    public usersAuthResponse refresh(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            throw new IllegalArgumentException("Missing or malformed Authorization header");
        }
        io.jsonwebtoken.Claims claims;
        try {
            claims = jwtService.parseAllowExpired(authorizationHeader.substring(7));
        } catch (io.jsonwebtoken.JwtException | IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid token");
        }
        // An old token may only be refreshed for 30 days after it expired
        if (claims.getExpiration() != null
                && claims.getExpiration().toInstant().isBefore(java.time.Instant.now().minus(30, java.time.temporal.ChronoUnit.DAYS))) {
            throw new IllegalArgumentException("Session expired, please log in again");
        }
        UserModel user = userRepository.findById(UUID.fromString(claims.getSubject()))
                .orElseThrow(() -> new IllegalArgumentException("Invalid token"));
        if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Your account is " + user.getStatus() + ". Please contact support.");
        }
        return authResponse(user);
    }

    // ========================================================================
    // PIN VERIFY - used before sensitive actions in the app
    // ========================================================================
    @Transactional(readOnly = true)
    public boolean verifyPin(UUID userId, String pin) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return pinService.matches(user, pin);
    }

    // The token + identity returned by register / login / refresh
    private usersAuthResponse authResponse(UserModel user) {
        String token = jwtService.generateToken(user.getUserId(), user.getEmail(), user.getPhoneNumber(),
                user.getCountryCode(), user.getUserType(), user.getFirstName(), user.getLastName());
        return new usersAuthResponse(token, user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName());
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

//    ========================================================================
//    GET /api/users/qr_me — identity bundle rendered into receive QR codes
//    ========================================================================

    /**
     * Everything the receive-QR payload needs: the caller's profile identity
     * plus the zentag of their default fiat account. The zentag cannot come
     * from the JWT ({@code JwtService#generateToken} never packs a zentag
     * claim, so {@code AuthenticatedUser#getZentag()} is always {@code null}).
     *
     * @param userId the JWT-authenticated caller
     * @return the QR bundle; {@code zentag} degrades to an empty string only
     * when the user has no wallet/default account yet (e.g. mid-registration)
     */
    @Transactional(readOnly = true)
    public UserQRInfo getQRInfo(UUID userId) {
        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return new UserQRInfo(
                user.getUserId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getPhoneNumber(),
                user.getCountryCode(),
                resolveDefaultZentag(userId),
                user.getUserType());
    }

    /**
     * Resolves the zentag minted on the wallet's default currency account
     * (same shape as registration/account creation:
     * {@code phoneNumber + "_" + currencyCode + "@zentrapay"}).
     */
    private String resolveDefaultZentag(UUID userId) {
        return accounts.getMerchantReferenceByUserId(userId);
    }

    //    GETTING USER INFROMATION
    @Transactional(readOnly = true)
    public UserInformation getMe(@Valid UUID userId) {
        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // Retrieve profile if present. The profile is optional — a row is only
        // created once the user submits their KYC details — so a missing row must
        // NOT null out the whole response. Always return the user; profile may be null.
        UserProfileModel up = userProfileRepository.getByUserId(userId);
        UserProfileDTO profile = toProfileDTO(up);
        return new UserInformation(toUserDTO(user), profile);
    }

    @Transactional
    public UserModel getUser(UUID userId) {
        return userRepository.getUserByUserId(userId)
                .orElseThrow(
                        () -> new RuntimeException("User now found.")
                );
    }

    // ========================================================================
    // PATCH /api/users/me — self-service editable account fields (name only).
    // ========================================================================
    @Transactional
    public UserDTO updateMe(UUID userId, UserMeUpdateDTO req) {
        UserModel user = userRepository.getUserByUserId(userId)
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
        return toProfileDTO(userProfileRepository.getByUserId(userId));
    }

    // ========================================================================
    // PUT /api/users/me/profile — upsert KYC profile fields, then recompute
    // the caller's kycTier (see recomputeKycTier). Every field is optional
    // (null = leave unchanged) so the KYC form can submit incrementally.
    // ========================================================================
    @Transactional
    public UserProfileDTO upsertKycProfile(UUID userId, UserProfileUpdateDTO req) {
        // Creates or updates the KYC profile of the user
        log.info("Saving the KYC profile of user {}", userId);
        UserModel user = userRepository.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        UserProfileModel profile = userProfileRepository.getByUserId(userId);
        if (profile == null) {
            profile = new UserProfileModel();
            profile.setUserId(userId);
        }

        if (req.dateOfBirth() != null) profile.setDateOfBirth(req.dateOfBirth());
        if (req.nationalityCountryCode() != null) profile.setNationalityCountryCode(req.nationalityCountryCode());
        if (req.identityDocumentType() != null) profile.setIdentityDocumentType(req.identityDocumentType());
        if (req.identityDocumentNumber() != null) profile.setIdentityDocumentNumber(req.identityDocumentNumber());
        if (req.identityDocumentIssuingCountryCode() != null)
            profile.setIdentityDocumentIssuingCountryCode(req.identityDocumentIssuingCountryCode());
        if (req.identityDocumentExpirationDate() != null)
            profile.setIdentityDocumentExpirationDate(req.identityDocumentExpirationDate());
        if (req.addressLine1() != null) profile.setAddressLine1(req.addressLine1());
        if (req.addressLine2() != null) profile.setAddressLine2(req.addressLine2());
        if (req.cityName() != null) profile.setCityName(req.cityName());
        if (req.stateOrRegion() != null) profile.setStateOrRegion(req.stateOrRegion());
        if (req.postalCode() != null) profile.setPostalCode(req.postalCode());
        if (req.occupationTitle() != null) profile.setOccupationTitle(req.occupationTitle());

        userProfileRepository.save(profile);
        recomputeKycTier(user, profile);
        // The information is now in the table. Read it back and check whether
        // everything the reviewer needs (fields + the three document images) is
        // there; if so the profile is queued for a verification officer.
        return toProfileDTO(kycVerificationService.checkSubmission(userId, false));
    }

    /**
     * Tiers 0 and 1 follow the profile: an untouched profile is tier 0 and
     * anything filled in is tier 1 ("started").
     * <p>
     * Tier 2 (unlocks sending/receiving money, see PaymentsService) is NEVER
     * granted here, however complete the profile is: uploading documents only
     * submits them for review. A verification officer checks the images and then
     * raises the tier (see {@link KycVerificationService#approve}), Likewise a
     * tier-2 user is never lowered by an edit - only an officer's decision can.
     */
    void recomputeKycTier(UserModel user, UserProfileModel profile) {
        if (user.getKycTier() >= 2) {
            return;
        }
        boolean started = profile != null && (profile.getDateOfBirth() != null
                || notBlank(profile.getAddressLine1())
                || notBlank(profile.getIdentityDocumentType())
                || notBlank(profile.getIdentityDocumentNumber())
                || notBlank(profile.getIdDocumentFrontPath())
                || notBlank(profile.getIdDocumentBackPath())
        );
        short newTier = started ? (short) 1 : (short) 0;
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
                kycVerificationService.missingRequirements(up),
                up.getKycReviewNote(),
                up.getCreatedAt(),
                up.getUpdatedAt()
        );
    }
}
