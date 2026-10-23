package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.provider.ServiceProviderDTO;
import com.zentrapay.backend.service.provider.ServiceProvidersServices;
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
