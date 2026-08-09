package com.zentrapay_application.zentrapay_spring_boot_layer.modules.secure.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LoginHistory;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * API contract §16 — {@code GET /api/secure/login-history}: backed by real
 * {@code login_history} rows written by {@code UsersService#login}.
 */
public record LoginHistoryDTO(
        UUID loginId,
        String ipAddress,
        String deviceInfo,
        String location,
        boolean success,
        LocalDateTime createdAt
) {
    public static LoginHistoryDTO from(LoginHistory entry) {
        return new LoginHistoryDTO(
                entry.getLoginId(),
                entry.getIpAddress(),
                entry.getDeviceInfo(),
                entry.getLocation(),
                entry.isSuccess(),
                entry.getCreatedAt()
        );
    }
}
