package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto.ConversionHistoryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto.ConvertRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto.ConvertResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto.RatesResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.service.ConverterService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Currency Converter / FX — API_CONTRACT.md §11. Backed by the real
 * {@code exchange_rates}/{@code conversions} tables (see {@link ConverterService}).
 */
@RestController
@RequestMapping("/api/converter")
@RequiredArgsConstructor
public class ConverterController {

    private final ConverterService converterService;

    @GetMapping("/rates")
    public ResponseEntity<ApiResponse<RatesResponseDTO>> getRates(@RequestParam(defaultValue = "USD") String base) {
        String baseCode = base.toUpperCase();
        return ResponseEntity.ok(ApiResponse.success(new RatesResponseDTO(baseCode, converterService.getRates(baseCode)), "Rates retrieved"));
    }

    @PostMapping("/convert")
    public ResponseEntity<ApiResponse<ConvertResponseDTO>> convert(@CurrentUser AuthenticatedUser user,
                                                                    @Valid @RequestBody ConvertRequestDTO request) {
        ConvertResponseDTO response = converterService.convert(user.userId(), request.from(), request.to(), request.amount());
        return ResponseEntity.ok(ApiResponse.success(response, "Conversion successful"));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<ConversionHistoryDTO>>> getHistory(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(converterService.getHistory(user.userId()), "Conversion history retrieved"));
    }
}
