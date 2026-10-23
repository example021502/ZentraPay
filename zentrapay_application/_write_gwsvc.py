import io

PATH = r"C:\Users\Desire\Desktop\Zentrapay_Workspace\zentrapay_spring_boot_layer\src\main\java\com\zentrapay\backend\service\gateway\GatewayServices.java"

HEADER = '''package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.dto.payment.FlutterwaveCustomerResponseDTO;
import com.zentrapay.backend.dto.payment.PaystackCustomerResponseDTO;
import com.zentrapay.backend.entity.GatewayCustomerModel;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.GatewayCustomerRepository;
import com.zentrapay.backend.repository.GatewayRepository;
import com.zentrapay.backend.repository.UserRepository;
import jakarta.transaction.Transactional;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Gateway customer provisioning with Paystack-first / Flutterwave-failover.
 *
 * <p>A customer is registered with the gateway that will later be asked to
 * charge them. Paystack is the primary gateway for national payments and
 * Flutterwave the failover, so registration tries Paystack first and only
 * falls through to Flutterwave when Paystack rejects the request or is
 * unreachable.
 *
 * <p>The resulting mapping is persisted in {@code gateway_customers} so a
 * repeat call for the same (user, gateway) pair reuses the existing
 * gateway-side customer instead of creating a duplicate.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GatewayServices {
    private final RestClient client;

    @Value("${paystack.public-key}")
    private String paystackSK;
    @Value("${paystack.base-url}")
    private String paystackBaseUrl;

    private final GatewayCustomerRepository gatewayCustomerRepository;
    private final GatewayRepository gatewayRepository;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;
    private final UserRepository userRepository;

    public record UserInforRecord(@NotBlank(message = "Email missing") String email, String firstName, String lastName,
                                  String phoneNumber) {
    }
'''


BODY_1 = '''
    /**
     * Returns the gateway customer for the given user, registering one with
     * the primary gateway (and failing over to the secondary one) when the
     * user has no gateway customer yet.
     */
    @Transactional
    public GatewayCustomerModel createOrGetCustomer(Map<String, Object> info) {
        UUID userId = (UUID) info.get("userId");
        String name = String.valueOf(info.get("name"));
        String phoneNumber = String.valueOf(info.get("phoneNumber"));
        String email = String.valueOf(info.get("email"));

        GatewayModel gateway = _resolvePrimaryGateway();
        UUID gatewayId = gateway.getProviderId();

        return gatewayCustomerRepository.getByUserIdAndGatewayId(userId, gatewayId)
                .orElseGet(() -> _createCustomer(userId, gatewayId, gateway.getProviderName(),
                        email, phoneNumber, name));
    }

    /**
     * Resolves the primary gateway row, falling back to the failover
     * gateway when the primary is not seeded in {@code gateway_providers}.
     */
    private GatewayModel _resolvePrimaryGateway() {
        Optional<GatewayModel> primary = gatewayRepository.getPrimaryGateway();
        if (primary.isPresent()) {
            return primary.get();
        }
        log.info("================== Primary gateway resolution failed, getting the secondary gateway... ======================");
        return gatewayRepository.getSecondaryGateway()
                .orElseThrow(() -> new RuntimeException("Gateway resolution failed, internal error!"));
    }
'''

BODY_2 = '''
    /**
     * Registers the customer with Paystack and, if Paystack refuses, with
     * Flutterwave. The persisted row records which gateway actually issued
     * the customer id.
     */
    private GatewayCustomerModel _createCustomer(UUID userId, UUID gatewayId, String gatewayName,
                                                 String email, String phoneNumber, String name) {
        PaystackCustomerResponseDTO paystackCustomer = paystackServices.createCustomer(email, phoneNumber, name);
        if (paystackCustomer != null && paystackCustomer.status()) {
            PaystackCustomerResponseDTO.CustomerData data = paystackCustomer.data();
            return _persistCustomer(userId, gatewayId, "PAYSTACK",
                    data.customerCode(), email, phoneNumber);
        }

        log.warn("Paystack customer creation failed for user {} — failing over to Flutterwave", userId);
        FlutterwaveCustomerResponseDTO flutterwaveCustomer =
                flutterwaveServices.createCustomer(email, name, phoneNumber);
        if (flutterwaveCustomer == null || !flutterwaveCustomer.status()) {
            throw new RuntimeException("Transaction failed. Our service providers are down at the moment. Please try again later.");
        }
        FlutterwaveCustomerResponseDTO.CustomerData fData = flutterwaveCustomer.data();
        return _persistCustomer(userId, gatewayId, "FLUTTERWAVE",
                fData.id(), email, phoneNumber);
    }

    /**
     * Writes the gateway-issued customer id to {@code gateway_customers}.
     */
    private GatewayCustomerModel _persistCustomer(UUID userId, UUID gatewayId, String gatewayName,
                                                   String gatewayCustomerId, String email, String phoneNumber) {
        GatewayCustomerModel customer = new GatewayCustomerModel();
        customer.setUserId(userId);
        customer.setGatewayId(gatewayId);
        customer.setEmail(email);
        customer.setPhoneNumber(phoneNumber);
        customer.setGatewayCustomerId(gatewayCustomerId == null ? "" : gatewayCustomerId);
        return gatewayCustomerRepository.save(customer);
    }
}
'''

with io.open(PATH, "w", encoding="utf-8", newline="\n") as fh:
    fh.write(HEADER + BODY_1 + BODY_2)
print("written")
