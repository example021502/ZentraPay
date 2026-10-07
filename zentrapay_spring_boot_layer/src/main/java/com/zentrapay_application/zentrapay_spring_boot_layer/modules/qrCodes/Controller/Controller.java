package com.zentrapay_application.zentrapay_spring_boot_layer.modules.qrCodes.Controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.qrCodes.dto.qrCodeInformationResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.qrCodes.service.qrService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/qr")
@RequiredArgsConstructor
public class Controller {

    private final qrService qrService;

    @GetMapping("/new")
    public ResponseEntity<ApiResponse<qrCodeInformationResponseDTO>> qrCodeInformation(@CurrentUser AuthenticatedUser user) {
        qrCodeInformationResponseDTO info = qrService.getInfo(user.getUserId());
        return ResponseEntity.ok(ApiResponse.success(info, "Information retrieved"));
    }


}
