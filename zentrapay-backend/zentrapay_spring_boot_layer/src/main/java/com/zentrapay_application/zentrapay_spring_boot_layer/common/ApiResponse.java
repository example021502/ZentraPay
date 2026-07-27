package com.zentrapay_application.zentrapay_spring_boot_layer.common;

/**
 * Generic API response wrapper for all endpoints.
 * 
 * @param <T> The type of data being returned
 */
public record ApiResponse<T>(
        boolean success,
        T data,
        String message
) {
    /**
     * Create a successful response with data.
     */
    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, data, message);
    }

    /**
     * Create a successful response with only a message.
     */
    public static <T> ApiResponse<T> success(String message) {
        return new ApiResponse<>(true, null, message);
    }

    /**
     * Create an error response.
     */
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, null, message);
    }
}