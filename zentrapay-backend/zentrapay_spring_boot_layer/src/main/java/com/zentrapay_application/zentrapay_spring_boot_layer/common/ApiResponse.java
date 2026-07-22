package com.zentrapay_application.zentrapay_spring_boot_layer.common;

// common/response/ApiResponse.java
public record ApiResponse<T>(
        boolean success,
        String message,
        T data,
        long timestamp

) {
    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, message, data, System.currentTimeMillis());
    }
    // Inside your ApiResponse.java
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null, System.currentTimeMillis());
    }
}