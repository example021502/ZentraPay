package com.zentrapay.backend.service.user;

import com.zentrapay.backend.dto.gateway.FincraNewAccountResponse;
import com.zentrapay.backend.dto.user.*;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.security.AttemptLimiter;
import com.zentrapay.backend.security.JwtService;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.gateway.FincraServices;
import com.zentrapay.backend.service.region.SupportedRegionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cglib.core.Local;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;


@Service
@RequiredArgsConstructor
public class UserProfileServices {

    private static final Logger log = LoggerFactory.getLogger(UserProfileServices.class);

    private final UserProfileRepository userProfileRepository;

    // ========================================================================
    // POPULATING THE USER PROFILE TABLE
    // ========================================================================
    @Transactional
    public Map<String, Object> populateUserProfile(UUID userId,
                                                   LocalDate dateOfBirth,
                                                   String countryCode,
                                                   String identityDocumentType,
                                                   String identityDocumentNumber,
                                                   String identityDocumentIssuingCountry,
                                                   LocalDate identityDocumentExpirationDate,
                                                   String address1,
                                                   String address2,
                                                   String cityName,
                                                   String stateOrRegion,
                                                   String postalCode,
                                                   String occupationTitle,
                                                   Datatypes.AntiMoneyStatuses antiMoneyLaunderyStatus,
                                                   Boolean isPoliticallyExposedPerson,
                                                   String riskScoreLevel,
                                                   String kycStatus,
                                                   String identityDocumentFrontPath,
                                                   String identityDocumentBackPath,
                                                   String selfiePath,
                                                   LocalDateTime kycSubmittedAt,
                                                   LocalDateTime kycReviewedAt,
                                                   String kycReviewNote) {
        // Creates the user, their fiat + crypto wallets and default account, then returns a login token
        log.info("===== COLLECTING THE USER ID NUMBER FOR ACCOUNT CREATION =====");
        if (userId == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "Critical user profile information missing. Please upload your kyc documents to continue");
            return error;
        }

        UserProfileModel p = getUserProfile(userId);
        if (dateOfBirth != null) {
            p.setDateOfBirth(dateOfBirth);
        }
        if (countryCode != null) {
            p.setNationalityCountryCode(countryCode);
        }
        if (identityDocumentType != null) {
            p.setIdentityDocumentType(identityDocumentType);
        }
        if (identityDocumentNumber != null) {
            p.setIdentityDocumentNumber(identityDocumentNumber);
        }
        if (identityDocumentIssuingCountry != null) {
            p.setIdentityDocumentIssuingCountryCode(identityDocumentIssuingCountry);
        }
        if (identityDocumentExpirationDate != null) {
            p.setIdentityDocumentExpirationDate(identityDocumentExpirationDate);
        }
        if (address1 != null) {
            p.setAddressLine1(address1);
        }
        if (address2 != null) {
            p.setAddressLine2(address2);
        }
        if (cityName != null) {
            p.setCityName(cityName);
        }
        if (stateOrRegion != null) {
            p.setStateOrRegion(stateOrRegion);
        }
        if (postalCode != null) {
            p.setPostalCode(postalCode);
        }
        if (occupationTitle != null) {
            p.setOccupationTitle(occupationTitle);
        }
        if (antiMoneyLaunderyStatus != null) {
            p.setAntiMoneyLaunderingStatus(antiMoneyLaunderyStatus);
        }
        if (isPoliticallyExposedPerson != null) {
            p.setPoliticallyExposedPerson(isPoliticallyExposedPerson);
        }
        if (riskScoreLevel != null) {
            p.setRiskScoreLevel(riskScoreLevel);
        }
        if (kycStatus != null) {
            p.setKYCStatus(kycStatus);
        }
        if (identityDocumentFrontPath != null) {
            p.setIdDocumentFrontPath(identityDocumentFrontPath);
        }
        if (identityDocumentBackPath != null) {
            p.setIdDocumentBackPath(identityDocumentBackPath);
        }
        if (selfiePath != null) {
            p.setSelfiePath(selfiePath);
        }
        if (kycSubmittedAt != null) {
            p.setKycSubmittedAt(kycSubmittedAt);
        }
        if (kycReviewedAt != null) {
            p.setKycReviewedAt(kycReviewedAt);
        }
        if (kycReviewNote != null) {
            p.setKycReviewNote(kycReviewNote);
        }

        userProfileRepository.save(p);
        Map<String, Object> success = new HashMap<>();
        success.put("success", true);
        success.put("message", "Profile updated.");

        return success;
    }

    public UserProfileModel getUserProfile(UUID userId) {
        UserProfileModel profile = userProfileRepository.getByUserId(userId);
        if (profile != null) {
            return profile;
        }
        UserProfileModel p = new UserProfileModel();
        p.setUserId(userId);
        return p;
    }

}
