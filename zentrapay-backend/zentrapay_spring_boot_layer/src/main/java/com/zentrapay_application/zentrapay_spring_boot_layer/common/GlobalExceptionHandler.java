package com.zentrapay_application.zentrapay_spring_boot_layer.common;

// Fix: Import the ApiResponse class
import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;

// Fix: Import your custom exception (make sure this file actually exists!)
import com.zentrapay_application.zentrapay_spring_boot_layer.common.ResourceNotFoundException;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;


@RestControllerAdvice
public class GlobalExceptionHandler {

    // Handles your custom "Resource Not Found" exceptions
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(ex.getMessage()));
    }

    // Handles general RuntimeExceptions (like the "Email taken" or "Invalid credentials" from your UserService)
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Object>> handleRuntimeException(RuntimeException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(ex.getMessage()));
    }
}