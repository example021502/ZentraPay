package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto.PageResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto.TransactionResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.service.TransactionsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Generic transaction feed — a read-only view over the canonical Transaction ledger.
 * Supersedes {@code /api/history/*} (API contract §5).
 */
@RestController
@RequestMapping("/api/transactions")
public class TransactionsController {

    private final TransactionsService transactionsService;

    public TransactionsController(TransactionsService transactionsService) {
        this.transactionsService = transactionsService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponseDTO<TransactionResponseDTO>>> getTransactions(
            @CurrentUser AuthenticatedUser user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status) {
        return ResponseEntity.ok(ApiResponse.success(
                transactionsService.getUserTransactions(user.userId(), page, size, type, status),
                "Transactions retrieved"));
    }

    @GetMapping("/{transactionId}")
    public ResponseEntity<ApiResponse<TransactionResponseDTO>> getTransaction(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID transactionId) {
        return ResponseEntity.ok(ApiResponse.success(
                transactionsService.getUserTransaction(user.userId(), transactionId),
                "Transaction retrieved"));
    }
}
