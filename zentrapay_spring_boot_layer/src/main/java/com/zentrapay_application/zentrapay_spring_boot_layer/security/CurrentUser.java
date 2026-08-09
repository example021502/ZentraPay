package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a controller method parameter to be resolved as the {@link AuthenticatedUser}
 * of the currently authenticated request (i.e. the JWT-validated principal).
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface CurrentUser {
}
