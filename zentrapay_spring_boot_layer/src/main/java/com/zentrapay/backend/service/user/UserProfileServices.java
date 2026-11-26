package com.zentrapay.backend.service.user;

import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.service.common.Datatypes;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;


@Service
@RequiredArgsConstructor
public class UserProfileServices {

    private static final Logger log = LoggerFactory.getLogger(UserProfileServices.class);

    private final UserProfileRepository profiles;

    public void initializeProfile(UUID userId) {
        checkProfileExistence(userId);
        UserProfileModel p = new UserProfileModel();
        p.setUserId(userId);
        profiles.save(p);
    }

    private void checkProfileExistence(UUID userId) {
        boolean exists = profiles.existsByUserId(userId);
        if (exists) {
            throw new RuntimeException("User profile already exists. Profile initialization failed.");
        }
    }

    // ========================================================================
    // POPULATING THE USER PROFILE TABLE
    // ========================================================================
    @Transactional
    public void populateUserProfile(UUID userId,
                                    LocalDate dateOfBirth,
                                    String countryCode,
                                    String address1,
                                    String address2,
                                    String cityName,
                                    String stateOrRegion,
                                    String postalCode,
                                    String occupationTitle
    ) {
        // Creates the user, their fiat + crypto wallets and default account, then returns a login token
        log.info("===== COLLECTING THE USER ID NUMBER FOR ACCOUNT CREATION =====");
        if (userId == null) {
            log.info("==== USER ID MISSING =====");
            throw new RuntimeException("Something went wrong. Profile update failed.");
        }

        UserProfileModel p = getUserProfile(userId);
        if (dateOfBirth != null) {
            p.setDateOfBirth(dateOfBirth);
        }
        if (countryCode != null) {
            p.setCountryCode(countryCode);
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

        profiles.save(p);
    }

    public UserProfileModel getUserProfile(UUID userId) {
        UserProfileModel profile = profiles.getByUserId(userId);
        if (profile != null) {
            return profile;
        }
        UserProfileModel p = new UserProfileModel();
        p.setUserId(userId);
        return p;
    }

}
