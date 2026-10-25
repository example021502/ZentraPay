package com.zentrapay.backend.exception;

import com.zentrapay.backend.dto.common.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Turns every exception into the standard {@code {success, message, data}}
 * envelope. Spring picks the most specific handler, so the order below does
 * not matter; the two broad ones at the bottom are only safety nets.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** What a customer sees when the real reason is an internal / third-party detail. */
    private static final String GENERIC_MESSAGE = "Something went wrong. Please try again in a moment.";

    // Words that mean a message was written for developers: exception types,
    // transport / database details, and the names of the providers we run on.
    private static final List<String> TECHNICAL_MARKERS = List.of(
            "exception", "stacktrace", "afriqlink", "paystack", "flutterwave", "onafriq", "privy",
            "gateway", "http", "status code", "sql", "jdbc", "hibernate", "spring", "timeout",
            "timed out", "connection", "jwt", "endpoint", "api key", "secret", "refused", "socket");
    private static final Pattern NULL_WORD = Pattern.compile("\\bnull\\b", Pattern.CASE_INSENSITIVE);

    /**
     * Passes a business message ("Insufficient balance", "You have already linked
     * this bank") through untouched, but replaces anything that exposes how the
     * system is built so internals never reach the customer.
     */
    static String userSafe(String message) {
        if (message == null || message.isBlank()) {
            return GENERIC_MESSAGE;
        }
        String lower = message.toLowerCase();
        if (message.length() > 200 || NULL_WORD.matcher(message).find()
                || TECHNICAL_MARKERS.stream().anyMatch(lower::contains)) {
            return GENERIC_MESSAGE;
        }
        return message;
    }

    // 404 - also used for ownership failures so we never leak that a row exists
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNotFound(ResourceNotFoundException ex) {
        return build(HttpStatus.NOT_FOUND, ex.getMessage());
    }

    // 400 - @Valid failures on request bodies
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Object>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining("; "));
        return build(HttpStatus.BAD_REQUEST, message.isBlank() ? "Validation failed" : message);
    }

    // 400 - unreadable JSON, missing params, wrong param types
    @ExceptionHandler({HttpMessageNotReadableException.class,
            MissingServletRequestParameterException.class,
            MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ApiResponse<Object>> handleBadRequest(Exception ex) {
        log.warn("Bad request: {}", ex.getMessage());
        return build(HttpStatus.BAD_REQUEST, "Invalid or incomplete request");
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResponse<Object>> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex) {
        return build(HttpStatus.METHOD_NOT_ALLOWED, "This action isn't available");
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<Object>> handleNoResource(NoResourceFoundException ex) {
        return build(HttpStatus.NOT_FOUND, "Resource not found");
    }

    // 502 - a payment gateway / open-banking provider failed
    @ExceptionHandler(PaymentGatewayException.class)
    public ResponseEntity<ApiResponse<Object>> handleGateway(PaymentGatewayException ex) {
        log.error("Gateway error: {}", ex.getMessage());
        return build(HttpStatus.BAD_GATEWAY, userSafe(ex.getMessage()));
    }

    // 409 - unique / foreign-key violations (duplicate rows)
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Object>> handleIntegrity(DataIntegrityViolationException ex) {
        log.error("Data integrity violation: {}", ex.getMostSpecificCause().getMessage());
        return build(HttpStatus.CONFLICT, "This record conflicts with an existing one");
    }

    // 400 - business-rule failures thrown as IllegalArgumentException / RuntimeException
    // with a user-facing message (e.g. "Invalid PIN", "Insufficient balance")
    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<ApiResponse<Object>> handleBusiness(RuntimeException ex) {
        log.warn("Request rejected: {}", ex.getMessage());
        return build(HttpStatus.BAD_REQUEST, userSafe(ex.getMessage()));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Object>> handleRuntimeException(RuntimeException ex) {
        log.warn("Request failed: {}", ex.getMessage(), ex);
        return build(HttpStatus.BAD_REQUEST, userSafe(ex.getMessage()));
    }

    // Safety net - log the real cause, never leak it to the client
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Object>> handleGenericException(Exception ex) {
        log.error("Unexpected error", ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred");
    }

    private ResponseEntity<ApiResponse<Object>> build(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(ApiResponse.error(message));
    }
}
