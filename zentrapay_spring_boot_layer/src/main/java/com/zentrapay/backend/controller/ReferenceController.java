package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.reference.BankDTO;
import com.zentrapay.backend.dto.reference.CountryDTO;
import com.zentrapay.backend.dto.reference.CurrencyDTO;
import com.zentrapay.backend.dto.reference.ProviderCategoryDTO;
import com.zentrapay.backend.service.reference.ReferenceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Reference/lookup data — API_CONTRACT.md §2. All endpoints are Public;
 * SecurityConfig already permits "/api/reference/**" (and
 * JwtAuthenticationFilter#shouldNotFilter skips it), so no token is required.
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

    /**
     * Bank catalog for the ZBank "link a bank" sheet — API_CONTRACT.md §2.
     * {@code ?query=} filters by name/code/country/gateway; {@code ?country=GH}
     * narrows to one ISO country. Public, like the rest of /api/reference.
     */
    @GetMapping("/banks")
    public ResponseEntity<ApiResponse<List<BankDTO>>> getBanks(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String country) {
        return ResponseEntity.ok(ApiResponse.success(referenceService.getBanks(query, country), "Banks retrieved"));
    }
}
