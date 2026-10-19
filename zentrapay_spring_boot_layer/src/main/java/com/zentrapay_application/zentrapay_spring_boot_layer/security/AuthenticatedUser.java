package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import lombok.Data;

import java.security.Principal;
import java.util.UUID;

/**
 * Identity resolved from a validated JWT's claims, set as the Authentication principal
 * by {@link JwtAuthenticationFilter} for every request except register/login.
 * <p>
 * Implements {@link Principal#getName()} as {@code userId.toString()} so that existing
 * {@code UUID.fromString(authentication.getName())} call sites keep working unchanged.
 */

public record AuthenticatedUser(
        UUID userId,
        String email,
        String phoneNumber,
        String countryCode,
        String firstName,
        String lastName,
        String zentag,
        Datatypes.UserType userType

) implements Principal {

    @Override
    public String getName() {
        return firstName + " " + lastName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public String getFirstName() {
        return firstName;
    }
    public String getLastName() {
        return lastName;
    }

    public Datatypes.UserType getUserType() {
        return userType;
    }

    public String getCountryCode() {
        return countryCode;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getEmail() {
        return email;
    }

    public String getZentag() {
        return zentag;
    }

}
