package com.zentrapay.backend.service.user;

import com.zentrapay.backend.dto.user.requests.UserProfileUpdateRequest;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.security.AttemptLimiter;
import com.zentrapay.backend.service.DigitalAccounts.AccountsServices;
import com.zentrapay.backend.service.DigitalAccounts.CurrenciesServices;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.dto.user.*;
import com.zentrapay.backend.entity.LoginHistoryModel;
import com.zentrapay.backend.repository.LoginHistoryRepository;
import com.zentrapay.backend.security.JwtService;
import com.zentrapay.backend.service.CountriesServices;
import com.zentrapay.backend.service.common.Utils;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;


@Service
@RequiredArgsConstructor
public class UsersService {

    private static final Logger log = LoggerFactory.getLogger(UsersService.class);

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final LoginHistoryRepository loginHistoryRepository;
    private final AccountsServices accountServices;
    private final UserProfileRepository userProfileRepository;
    private final PinService pinService;
    private final AttemptLimiter attemptLimiter;
    private final CountriesServices countriesServices;
    private final CurrenciesServices currenciesServices;
    private final KycDocumentsServices kycDocumentsServices;


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
        if (users.existsByEmail(req.email())) {
            throw new IllegalArgumentException("Email already taken");
        }
        if (users.existsByPhoneNumber(req.phoneNumber())) {
            throw new IllegalArgumentException("Phone number already taken");
        }

        if (!Boolean.TRUE.equals(req.termsConsent())) {
            throw new IllegalArgumentException("Please accept the Terms of use to continue");
        }

        // Validate and fetch the country BEFORE saving the user to avoid unnecessary DB inserts
        // The country must be one of the payment providers support AND that is switched on right now
        countriesServices.isCountrySupported(req.countryCode());

        // Initialize and populate the new User entity
        UserModel user = new UserModel();
        user.setFirstName(req.firstName());
        user.setLastName(req.lastName());
        user.setEmail(req.email());
        user.setPhoneNumber(req.phoneNumber());
        user.setCountryCode(req.countryCode());
        user.setPasswordHash(passwordEncoder.encode(req.password() + passwordPepper));
        user.setTransactionPinHash(passwordEncoder.encode(req.pin() + pinPepper));
        user.setUserType(Datatypes.UserType.APP_USER);
        user.setStatus(Datatypes.UserStatus.ACTIVE);

        // Save the user record to the database
        user = users.save(user);
        userProfileServices.initializeProfile(user.getId());
        String currencyCode = currenciesServices.getCurrency(user.getCountryCode());
        accountServices.createDefaultFiatAccount(
                "Default Account",
                user.getId(),
                user.getEmail(),
                currencyCode,
                Utils.getZentag(currencyCode, user.getPhoneNumber()),
                user.getPhoneNumber()
        );


        // Generate the authentication token and return the response DTO
//        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getPhoneNumber(), user.getCountryCode(), user.getUserType(), user.getFirstName(), user.getLastName());
        recordLogin(user.getId(), httpRequest, true);
        return authResponse(user);
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
        String limitKey = "login:" + (req.email().isBlank() ? req.phoneNumber() : req.email().toLowerCase(Locale.ROOT));
        attemptLimiter.requireNotLocked(limitKey);

        UserModel user = users.findByEmailOrPhoneNumber(req.email(), req.phoneNumber())
                .orElseGet(() -> {
                    attemptLimiter.recordFailure(limitKey);
                    log.warn("[USERS] Login attempt for an unknown account");
                    throw new IllegalArgumentException("Invalid credentials");
                });

        if (!passwordEncoder.matches(req.password() + passwordPepper, user.getPasswordHash())) {
            attemptLimiter.recordFailure(limitKey);
            recordLogin(user.getId(), httpRequest, false);
            log.info("[USERS] Login failed - invalid credentials for user {}", user.getId());
            throw new IllegalArgumentException("Invalid credentials");
        }
        attemptLimiter.recordSuccess(limitKey);
        if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
            recordLogin(user.getId(), httpRequest, false);
            throw new IllegalArgumentException("Your account is " + user.getStatus() + ". Please contact support.");
        }

        recordLogin(user.getId(), httpRequest, true);
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
        UserModel user = users.findById(UUID.fromString(claims.getSubject()))
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
        UserModel user = users.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return pinService.matches(user, pin);
    }

    // The token + identity returned by register / login / refresh
    private usersAuthResponse authResponse(UserModel user) {
        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getPhoneNumber(),
                user.getCountryCode(), user.getUserType(), user.getFirstName(), user.getLastName());
        return new usersAuthResponse(token, user.getId(), user.getEmail(), user.getFirstName(), user.getLastName());
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

    // CHECKING IF USER ACCOUNT IS ACTIVE
    public void requireActiveUser(UserModel user) throws IllegalAccessException {
        if (!Datatypes.UserStatus.ACTIVE.equals(user.getStatus())) {
            throw new IllegalAccessException("Your account is " + user.getStatus() + " at the moment");
        }
    }

    // CHECKING THE KYC STATUS OF THE USER
    public void checkKycStatus(UserModel user) throws IllegalAccessException {
        if (user.getKycTier() < (short) 2) {
            throw new IllegalAccessException("Your kyc level is currently(" + user.getKycTier() + ") low for this feature. Upload you identity documents to continue");
        }
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
    public UserQRInfo getQRInfo(UUID userId, String currencyCode) {
        UserModel user = users.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        return new UserQRInfo(
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getPhoneNumber(),
                user.getCountryCode(),
                accountServices.getZentag(userId, currencyCode),
                user.getUserType());
    }

    //    GETTING USER INFROMATION
    @Transactional(readOnly = true)
    public UserInformation getMe(@Valid UUID userId) {
        UserModel user = users.getUserByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        UserProfileModel up = userProfileRepository.getByUserId(userId);
        return new UserInformation(toUserDTO(user), toProfileDTO(up));
    }

    @Transactional(readOnly = true)
    public UserModel getUser(UUID userId) {
        return users.getUserByUserId(userId)
                .orElseThrow(
                        () -> new RuntimeException("User now found.")
                );
    }

    @Transactional(readOnly = true)
    public void requireEligibleSender(UserModel user) {
        if (user.getKycTier() < (short) 2) {
            throw new RuntimeException("You are currently not eligible. Complete you kyc process first.");
        }

    }


    // ========================================================================
    // PATCH /api/users/me — self-service editable account fields (name only).
    // ========================================================================
    @Transactional
    public UserDTO updateMe(UUID userId, UserProfileUpdateRequest req) {
        UserModel user = getUser(userId);
        // updating the kyc documents
        if (
                req.documentType() != null
                        || notBlank(req.documentNumber())
                        || notBlank(req.documentIssuingCountryCode())
                        || req.documentExpirationDate() != null) {
            kycDocumentsServices.updateDocuments(
                    userId,
                    req.documentType(),
                    req.documentNumber(),
                    req.documentExpirationDate(),
                    req.documentIssuingCountryCode()
            );
        }
        // updating the user information
        if (notBlank(req.firstName())) {
            user.setFirstName(req.firstName());
        }
        if (notBlank(req.lastName())) {
            user.setLastName(req.lastName());
        }

        if (notBlank(req.email())) {
            user.setEmail(req.email());
        }
        if (notBlank(req.phoneNumber()) && user.getCountryCode().equalsIgnoreCase(req.countryCode())) {
            user.setPhoneNumber(req.phoneNumber());
        } else if (notBlank(req.phoneNumber()) && !user.getCountryCode().equalsIgnoreCase(req.countryCode())) {
            throw new RuntimeException("You provided an invalid phone number. Only phone numbers for your country (" + countriesServices.getCountryNameByCode(user.getCountryCode()).toUpperCase() + ") are valid.");
        }

        //updating the user profile informaiton
        if (
                req.dateOfBirth() != null
                        || notBlank(req.countryCode())
                        || notBlank(req.addressLine1())
                        || notBlank(req.addressLine2())
                        || notBlank(req.cityName())
                        || notBlank(req.stateOrRegion())
                        || notBlank(req.postalCode())
                        || notBlank(req.occupationTitle())
        ) {
            userProfileServices.populateUserProfile(
                    userId,
                    req.dateOfBirth(),
                    req.countryCode(),
                    req.addressLine1(),
                    req.addressLine2(),
                    req.cityName(),
                    req.stateOrRegion(),
                    req.postalCode(),
                    req.occupationTitle()
            );
        }
        return toUserDTO(user);
    }

    // ========================================================================
    // GET /api/users/me/profile — KYC profile, null until first submitted.
    // ========================================================================
    @Transactional(readOnly = true)
    public UserProfileDTO getKycProfile(UUID userId) {
        return toProfileDTO(userProfileRepository.getByUserId(userId));
    }

    // MODIFYING THE KYC LEVEL
    void recomputeKycTier(UserModel user, UserProfileModel profile) {
        if (user.getKycTier() >= 2) {
            return;
        }
        KYCDocumentModel d = kycDocumentsServices.getKycDocument(user.getId());
        if (
                notBlank(d.getFrontImageUrl())
                        && notBlank(d.getBackImageUrl())
                        && profile != null
                        && (notBlank(profile.getAddressLine1()) || notBlank(profile.getAddressLine2()))
                        && profile.getAntiMoneyLaunderingStatus().equals(Datatypes.AntiMoneyStatuses.CLEAR)
                        && notBlank(profile.getPostalCode())
                        && notBlank(profile.getStateOrRegion())
                        && notBlank(profile.getCityName()
                )
        ) {
            if (user.getKycTier() != 2) {
                user.setKycTier((short) 2);
                users.save(user);
            }
        } else if (
                !notBlank(d.getFrontImageUrl())
                        || !notBlank(d.getBackImageUrl())
                        || profile == null
                        || !(notBlank(profile.getAddressLine1()) && notBlank(profile.getAddressLine2()))
                        || profile.getAntiMoneyLaunderingStatus().equals(Datatypes.AntiMoneyStatuses.CLEAR)
                        || !notBlank(profile.getPostalCode())
                        || !notBlank(profile.getStateOrRegion())
                        || !notBlank(profile.getCityName())
        ) {
            if (user.getKycTier() != 1) {
                user.setKycTier((short) 1);
                users.save(user);
            }
        }

    }

    private boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private UserDTO toUserDTO(UserModel u) {
        return new UserDTO(
                u.getId(),
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
                up.getCountryCode(),
                up.getAddressLine1(),
                up.getAddressLine2(),
                up.getCityName(),
                up.getStateOrRegion(),
                up.getPostalCode(),
                up.getOccupationTitle(),
                up.getAntiMoneyLaunderingStatus(),
                up.isPoliticallyExposedPerson(),
                up.getRiskScoreLevel(),
                up.getCreatedAt(),
                up.getUpdatedAt()
        );
    }
}
