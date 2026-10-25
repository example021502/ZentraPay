package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.qr.qrCodeInformationResponseDTO;
import com.zentrapay.backend.service.qr.qrService;
import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/qr")
@RequiredArgsConstructor
public class QrController {

    private final qrService qrService;

    @GetMapping("/new")
    public ResponseEntity<ApiResponse<qrCodeInformationResponseDTO>> qrCodeInformation(@CurrentUser AuthenticatedUser user) {
        qrCodeInformationResponseDTO info = qrService.getInfo(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(info, "Information retrieved"));
    }


}
