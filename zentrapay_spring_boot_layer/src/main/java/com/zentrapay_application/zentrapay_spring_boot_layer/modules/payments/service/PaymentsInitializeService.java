package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCustomerModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.GatewayCustomerReposittory;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.GatewayRepository;
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
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Inbound customer checkout (wallet funding) — POST /api/payments/initialize.
 * <p>
 * Paystack is the primary national gateway, with Flutterwave as the
 * universal failover. Before initializing, the caller is provisioned at the
 * selected gateway (local-first: an existing {@code gateway_customers} row
 * is reused, otherwise one is registered and cached), mirroring the same
 * pattern {@link PaymentsService#sendMoney} uses for outbound payouts. Every
 * initiated checkout is journaled as a pending "credit" transaction so the
 * record exists before the gateway webhook confirms it.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentsInitializeService {

    private static final String GATEWAY_PAYSTACK = "paystack";
    private static final String GATEWAY_FLUTTERWAVE = "flutterwave";

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final FlutterwaveClient flutterwaveClient;
    private final PaystackServices paystackServices;
    private final GatewayRepository gatewayRepository;
    private final GatewayCustomerReposittory gatewayCustomerReposittory;
    private final ObjectMapper objectMapper;

    public InitializePaymentResponseDTO initialize(UUID userId, InitializePaymentRequestDTO req) {
        UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String email = req.email() == null || req.email().isBlank() ? user.getEmail() : req.email();
        String currency = req.currencyCode().trim().toUpperCase(Locale.ROOT);
        String reference = generateReference();
        BigDecimal amountMajor = BigDecimal.valueOf(req.amount());

        // Local-first customer provisioning against Paystack (primary).
        GatewayModel paystackGateway = gatewayRepository.getGatewayProvider(GATEWAY_PAYSTACK);
        if (paystackGateway != null && Boolean.TRUE.equals(paystackGateway.getIsActive())) {
            getOrCreatePaystackCustomer(user, paystackGateway);
            log.info("Initializing Paystack checkout for user {} ref {}", userId, reference);

            PaystackInitializeResponseDTO response = paystackServices.initializeTransaction(email, amountMajor, currency, reference);
            if (response != null && response.status() && response.data() != null) {
                return journalPending(user, GATEWAY_PAYSTACK, currency, reference,
                        response.data().authorizationUrl(), response.data().accessCode(), req);
            }
            log.warn("Paystack initialize failed for {} — failing over to Flutterwave", reference);
        }

        try {
            FlutterwavePaymentResponseDTO response = flutterwaveClient.initializePayment(
                    email,
                    user.getFirstName() + " " + user.getLastName(),
                    user.getPhoneNumber(),
                    amountMajor, currency, reference, null);
            return journalPending(user, GATEWAY_FLUTTERWAVE, currency, reference,
                    response.data().link(), null, req);
        } catch (PaymentGatewayException failoverFailure) {
            log.error("All gateways failed for initialize {}: {}", reference, failoverFailure.getMessage());
            throw new IllegalArgumentException("Could not start the payment right now, please try again later");
        }
    }

    /** Local-first: reuse a cached gateway customer, or register + cache a new one. */
    private void getOrCreatePaystackCustomer(UserModel user, GatewayModel gateway) {
        Optional<GatewayCustomerModel> existing =
                gatewayCustomerReposittory.getByUserIdAndGatewayId(user.getUserId(), gateway.getProviderId());
        if (existing.isPresent()) {
            return;
        }
        var response = paystackServices.createCustomer(user, buildFauxRequestForCustomer(user));
        if (response == null || response.data() == null) {
            return;
        }
        GatewayCustomerModel newCustomer = new GatewayCustomerModel();
        newCustomer.setUserId(user.getUserId());
        newCustomer.setGatewayId(gateway.getProviderId());
        newCustomer.setGatewayName(gateway.getProviderName());
        newCustomer.setEmail(user.getEmail());
        newCustomer.setGatewayCustomerId(response.data().customerCode());
        gatewayCustomerReposittory.save(newCustomer);
    }

    /**
     * {@link PaystackServices#createCustomer} takes a {@code PaymentRequestDTO}
     * purely to read the recipient's email as an override — for checkout
     * (no transfer recipient involved) there is none, so a null recipient
     * (falls back to the user's own email) is all that's needed.
     */
    private com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDTO buildFauxRequestForCustomer(UserModel user) {
        return new com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDTO(
                "", null, null, null);
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
        leg.setAmount(BigDecimal.valueOf(req.amount()));
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
        // Comment: the `metadata` column is jsonb — it needs a real JSON
        // string, not Map#toString()'s "{key=value}" Java syntax.
        leg.setMetadata(objectMapper.writeValueAsString(metadata));
        transactionRepository.save(leg);

        return new InitializePaymentResponseDTO(
                leg.getTransactionId(),
                gateway,
                reference,
                authorizationUrl,
                accessCode,
                req.amount() == null ? BigDecimal.ZERO : BigDecimal.valueOf(req.amount()),
                currency,
                "processing");
    }

    private String generateReference() {
        String timestamp = LocalDateTime.now().toString().replaceAll("[^0-9]", "");
        String suffix = String.format("%04d", new java.security.SecureRandom().nextInt(10000));
        return "ZPI_" + timestamp + "_" + suffix;
    }
}
