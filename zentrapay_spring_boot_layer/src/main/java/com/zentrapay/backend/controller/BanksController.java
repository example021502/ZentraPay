package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.bank.AccountsResponseDTO;
import com.zentrapay.backend.dto.bank.LinkNewBankRequestDTO;
import com.zentrapay.backend.dto.bank.UserAccountsDTO;
import com.zentrapay.backend.dto.bank.UserAccountsResponseDTO;
import com.zentrapay.backend.service.bank.BankAccountsServices;
import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * ZBank Lite — the user's linked bank accounts (API_CONTRACT.md §3, ZBank).
 *
 * <pre>
 * GET    /api/zbanking/userAccounts   -> primary account + every linked account
 * POST   /api/zbanking/link           -> link a bank (first link is auto-primary)
 * POST   /api/zbanking/primary/{id}   -> promote a linked account to primary
 * DELETE /api/zbanking/unlink/{id}    -> unlink an account
 * </pre>
 *
 * The {@code {id}} path segment is the user's link row id ({@code userBankId}),
 * NOT the catalog {@code bankId} — that keeps promotion/unlink scoped to this
 * user's row.
 */
@RestController
@RequestMapping("/api/zbanking")
@RequiredArgsConstructor
public class BanksController {

    private final BankAccountsServices bankAccountsServices;

    /** Primary account + all linked accounts, for the ZBank header and strip. */
    @GetMapping("/userAccounts")
    public ResponseEntity<ApiResponse<UserAccountsResponseDTO>> getUserAccounts(
            @CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                bankAccountsServices.getUserAccounts(user.getUserId()),
                "Bank accounts retrieved"));
    }

    /** Links a bank to the user. The first link becomes primary automatically. */
    @PostMapping("/link")
    public ResponseEntity<ApiResponse<UserAccountsDTO>> linkBank(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody LinkNewBankRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                bankAccountsServices.linkBank(user.getUserId(), request),
                "Bank linked"));
    }

    /** Promotes one of the user's linked accounts to be the primary. */
    @PostMapping("/primary/{userBankId}")
    public ResponseEntity<ApiResponse<UserAccountsDTO>> setPrimary(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID userBankId) {
        return ResponseEntity.ok(ApiResponse.success(
                bankAccountsServices.setPrimary(user.getUserId(), userBankId),
                "Primary account updated"));
    }

    /** Unlinks one of the user's banks. */
    @DeleteMapping("/unlink/{userBankId}")
    public ResponseEntity<ApiResponse<Void>> unlinkBank(
            @CurrentUser AuthenticatedUser user,
            @PathVariable UUID userBankId) {
        bankAccountsServices.unlinkBank(user.getUserId(), userBankId);
        return ResponseEntity.ok(ApiResponse.success(null, "Bank account unlinked"));
    }
}
