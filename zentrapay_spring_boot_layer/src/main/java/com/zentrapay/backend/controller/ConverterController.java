package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.converter.ConverterDTOs.*;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.fx.ConverterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Currency converter.
 * <pre>
 * GET  /api/converter/rates?base=GHS   live rates from one currency to all others
 * POST /api/converter/convert an amount (saved in history)
 * GET  /api/converter/history          my recent conversions
 * </pre>
 */
@RestController
@RequestMapping("/api/converter")
@RequiredArgsConstructor
public class ConverterController {

    private final ConverterService converterService;

    @GetMapping("/rates")
    public ResponseEntity<ApiResponse<RatesDTO>> rates(@RequestParam String base) {
        return ResponseEntity.ok(ApiResponse.success(converterService.rates(base), "Rates retrieved"));
    }

    @PostMapping("/convert")
    public ResponseEntity<ApiResponse<ConvertResponseDTO>> convert(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody ConvertRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(converterService.convert(user.getUserId(), request), "Converted"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<ConversionHistoryDTO>>> history(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(converterService.history(user.getUserId()), "History retrieved"));
    }
}
