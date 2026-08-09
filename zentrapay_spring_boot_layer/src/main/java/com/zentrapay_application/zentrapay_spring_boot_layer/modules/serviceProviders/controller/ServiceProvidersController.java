package com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.dtos.ServiceProviderDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.serviceProviders.services.ServiceProvidersServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Service Providers Controller — API_CONTRACT.md §9 (path unchanged from before).
 */
@RestController
@RequestMapping("/api/service-providers")
@RequiredArgsConstructor
public class ServiceProvidersController {

    private final ServiceProvidersServices serviceProvidersServices;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ServiceProviderDTO>>> getProviders(
            @RequestParam(required = false) String countryCode,
            @RequestParam(required = false) String categoryCode) {
        return ResponseEntity.ok(ApiResponse.success(
                serviceProvidersServices.getProviders(countryCode, categoryCode), "Service providers retrieved"));
    }
}
