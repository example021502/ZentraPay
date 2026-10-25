package com.zentrapay.backend.dto.common;

/**
 * The one response envelope every endpoint returns: {@code {success, message, data}}.
 *
 * @param <T> the type of the {@code data} object (null when there is nothing to return)
 */
public record ApiResponse<T>(
        boolean success,
        String message,
        T data
) {

    /** Successful response carrying data. */
    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, message, data);
    }

    /** Successful response with only a message. */
    public static <T> ApiResponse<T> success(String message) {
        return new ApiResponse<>(true, message, null);
    }

    /** Failed response with only a message. */
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null);
    }
}
