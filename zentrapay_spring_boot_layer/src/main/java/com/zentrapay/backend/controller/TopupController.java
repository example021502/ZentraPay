package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.payment.CheckoutResponseDTO;
import com.zentrapay.backend.dto.payment.TopupRequestDTO;
import com.zentrapay.backend.dto.payment.SavedCardDTOs;
import com.zentrapay.backend.dto.payment.TopupVerifyDTO;
import com.zentrapay.backend.service.card.SavedCardChargeService;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.payment.WalletFundingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Wallet top-up, as called by the app's top-up screen.
 *
 * <pre>
 * POST /api/topup/paystack      start a top-up checkout on Paystack     -> accessCode (SDK) + authorizationUrl
 * POST /api/topup/flutterwave   start a top-up checkout on Flutterwave  -> authorizationUrl (hosted pay page)
 * POST /api/topup/card         top up by charging a saved card (PIN)       -> SUCCESS / PENDING / FAILED
 * GET  /api/topup/verify/{ref}  where the top-up stands (SUCCESS / PENDING / FAILED)
 * </pre>
 * Nothing is credited by these calls: the wallet is credited only after the gateway confirms the payment
 * (webhook, or {@code verify} asking the gateway directly), with the amount re-checked.
 */
@RestController
@RequestMapping("/api/topup")
@RequiredArgsConstructor
public class TopupController {

    private final WalletFundingService walletFundingService;
    private final SavedCardChargeService savedCardChargeService;

    @PostMapping("/paystack")
    public ResponseEntity<ApiResponse<CheckoutResponseDTO>> paystack(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody TopupRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                walletFundingService.startCheckout(user.getUserId(), request.amount(), request.currencyCode(),
                        Datatypes.PaymentGateway.PAYSTACK, Boolean.TRUE.equals(request.saveCard())),
                "Checkout created"));
    }

    @PostMapping("/flutterwave")
    public ResponseEntity<ApiResponse<CheckoutResponseDTO>> flutterwave(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody TopupRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                walletFundingService.startCheckout(user.getUserId(), request.amount(), request.currencyCode(),
                        Datatypes.PaymentGateway.FLUTTERWAVE, Boolean.TRUE.equals(request.saveCard())),
                "Checkout created"));
    }

    /** Tops up by charging a saved card; the transaction PIN authorises it. */
    @PostMapping("/card")
    public ResponseEntity<ApiResponse<TopupVerifyDTO>> card(
            @CurrentUser AuthenticatedUser user, @Valid @RequestBody SavedCardDTOs.ChargeCardRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                savedCardChargeService.chargeCard(user.getUserId(), request.cardId(), request.amount(),
                        request.currencyCode(), request.pin()),
                "Card charged"));
    }

    @GetMapping("/verify/{reference}")
    public ResponseEntity<ApiResponse<TopupVerifyDTO>> verify(
            @CurrentUser AuthenticatedUser user, @PathVariable String reference) {
        return ResponseEntity.ok(ApiResponse.success(
                walletFundingService.verifyTopup(user.getUserId(), reference), "Top-up status"));
    }
}
