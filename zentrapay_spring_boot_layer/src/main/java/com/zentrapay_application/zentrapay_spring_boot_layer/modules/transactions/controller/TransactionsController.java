package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dtos.TransactionPageDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.service.TransactionsQueryService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Transaction history — API_CONTRACT.md §5.
 * GET /api/transactions?page=&size= -> paginated history for the authenticated user
 */
@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionsController {

    private final TransactionsQueryService transactionsQueryService;

    @GetMapping
    public ResponseEntity<ApiResponse<TransactionPageDTO>> history(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "5") int size) {
        TransactionPageDTO result = transactionsQueryService.getHistory(user.getUserId(), page, size);
        return ResponseEntity.ok(ApiResponse.success(result, "Transactions retrieved"));
    }
}
