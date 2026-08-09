package com.zentrapay_application.zentrapay_spring_boot_layer.common;

public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}