package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto.CountryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto.CurrencyDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto.ProviderCategoryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.service.ReferenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Reference/lookup data — API_CONTRACT.md §2. All endpoints are Public;
 * requires a matching permitAll entry in SecurityConfig for "/api/reference/**"
 * (out of scope for this module to add — see final report).
 */
@RestController
@RequestMapping("/api/reference")
@RequiredArgsConstructor
public class ReferenceController {

    private final ReferenceService referenceService;

    @GetMapping("/countries")
    public ResponseEntity<ApiResponse<List<CountryDTO>>> getCountries() {
        return ResponseEntity.ok(ApiResponse.success(referenceService.getCountries(), "Countries retrieved"));
    }

    @GetMapping("/currencies")
    public ResponseEntity<ApiResponse<List<CurrencyDTO>>> getCurrencies() {
        return ResponseEntity.ok(ApiResponse.success(referenceService.getCurrencies(), "Currencies retrieved"));
    }

    @GetMapping("/provider-categories")
    public ResponseEntity<ApiResponse<List<ProviderCategoryDTO>>> getProviderCategories() {
        return ResponseEntity.ok(ApiResponse.success(referenceService.getProviderCategories(), "Provider categories retrieved"));
    }
}
