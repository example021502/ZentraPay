package com.zentrapay.backend.service.user;

import com.zentrapay.backend.dto.user.*;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;


@Service
@RequiredArgsConstructor
public class SupportedIdentitiesServices {

    private static final Logger log = LoggerFactory.getLogger(SupportedIdentitiesServices.class);
    private final SupportedIdentitiesRepository supportedIdentitiesRepository;

    // ========================================================================
    // GET IDENTITY
    // ========================================================================
    public String getIdentityType(String countryCode) {
        log.info("===== GETTINT THE IDENTITY TYPE FOR A {} USER.", countryCode);

        return supportedIdentitiesRepository.getIdentityTypeByCountryCode(countryCode);
    }

}
