package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.UserRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.FlutterwavePaymentResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.InitializePaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.InitializePaymentResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackInitializeResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Inbound customer checkout (wallet funding) — POST /api/payments/initialize.
 * <p>
 * Routing mirrors TransfersService: the caller's registration country
 * selects Paystack as the primary national gateway, with Flutterwave as the
 * universal failover (Onafriq is outbound/international only). Before
 * initializing, the caller is provisioned at the selected gateway through
 * {@link GatewayCustomerService} (local-first, per business rule 1). Every
 * initiated checkout is journaled as a pending "credit" transaction so the
 * record exists before the gateway webhook confirms it.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentsInitializeService {

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final GatewayCustomerService gatewayCustomerService;
    private final PaystackClient paystackClient;
    private final FlutterwaveClient flutterwaveClient;

    private final SecureRandom random = new SecureRandom();

    public InitializePaymentResponseDTO initialize(UUID userId, InitializePaymentRequestDTO req) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String email = req.email() == null || req.email().isBlank() ? user.getEmail() : req.email();
        String currency = req.currencyCode().trim().toUpperCase(Locale.ROOT);
        String reference = generateReference();

        // Local-first customer provisioning (business rule 1) — registers the
        // user at Paystack on first contact and caches the customer ID in
        // user_payment_gateways.
        String gatewayCustomerCode =
                gatewayCustomerService.getOrCreateGatewayCustomer(user, GatewayCustomerService.GATEWAY_PAYSTACK);
        log.info("Initializing Paystack checkout for user {} (customer {})", userId, gatewayCustomerCode);

        try {
            PaystackInitializeResponseDTO response = paystackClient.initializeTransaction(
                    email, req.amount(), currency, reference);
            return journalPending(user, GatewayCustomerService.GATEWAY_PAYSTACK, currency, reference,
                    response.data().authorizationUrl(), response.data().accessCode(), req);
        } catch (PaymentGatewayException paystackFailure) {
            log.warn("Paystack initialize failed for {}: {} — failing over to Flutterwave",
                    reference, paystackFailure.getMessage());
            try {
                FlutterwavePaymentResponseDTO response = flutterwaveClient.initializePayment(
                        email,
                        user.getFirstName() + " " + user.getLastName(),
                        user.getPhoneNumber(),
                        req.amount(), currency, reference, null);
                return journalPending(user, GatewayCustomerService.GATEWAY_FLUTTERWAVE, currency, reference,
                        response.data().link(), null, req);
            } catch (PaymentGatewayException failoverFailure) {
                log.error("All gateways failed for initialize {}: primary=[{}] failover=[{}]",
                        reference, paystackFailure.getMessage(), failoverFailure.getMessage());
                throw new IllegalArgumentException("Could not start the payment right now, please try again later");
            }
        }
    }

    /** Persists the pending inbound leg and builds the checkout response. */
    private InitializePaymentResponseDTO journalPending(
            UserModel user,
            String gateway,
            String currency,
            String reference,
            String authorizationUrl,
            String accessCode,
            InitializePaymentRequestDTO req) {
        TransactionModel leg = new TransactionModel();
        leg.setEntryId(reference);
        leg.setAmount(req.amount());
        leg.setGateway(gateway);
        leg.setStatus("processing");
        leg.setTransactionType("credit");
        leg.setSenderId(user.getUserId());
        leg.setReceiverId(user.getUserId()); // inbound funding: payer == local user
        leg.setSenderName(user.getFirstName() + " " + user.getLastName());
        leg.setReceiverName(user.getFirstName() + " " + user.getLastName());
        leg.setSourceCurrencyCode(currency);
        leg.setDestinationCurrencyCode(currency);
        leg.setPurpose(req.purpose() == null || req.purpose().isBlank() ? "Wallet funding" : req.purpose());
        leg.setSenderEmail(user.getEmail());
        leg.setSenderPhoneNumber(user.getPhoneNumber());
        leg.setReceiverEmail(user.getEmail());
        leg.setReceiverPhoneNumber(user.getPhoneNumber());
        leg.setInternalReferenceId(reference);
        leg.setExternalReferenceId(""); // filled by the confirmation webhook
        leg.setDestinationIdentifier(user.getEmail());
        leg.setFailureReason("");
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("channel", "checkout");
        metadata.put("gateway", gateway);
        metadata.put("payerEmail", req.email());
        leg.setMetadata(metadata.toString());
        transactionRepository.save(leg);

        return new InitializePaymentResponseDTO(
                leg.getTransactionId(),
                gateway,
                reference,
                authorizationUrl,
                accessCode,
                req.amount(),
                currency,
                "processing");
    }

    private String generateReference() {
        String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
        String suffix = String.format("%04d", random.nextInt(10000));
        return "ZPI_" + timestamp + "_" + suffix;
    }
}