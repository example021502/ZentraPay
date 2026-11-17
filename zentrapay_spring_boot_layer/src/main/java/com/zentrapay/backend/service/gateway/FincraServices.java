package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.dto.gateway.FincraNewAccountResponse;
import com.zentrapay.backend.dto.gateway.FincranAccountConfirmResponse;
import com.zentrapay.backend.dto.payment.*;
import com.zentrapay.backend.entity.VirtualAccountModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.repository.VirtualAccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Paystack API calls - the PRIMARY gateway for national payments.
 * This class only talks to Paystack; deciding WHEN to use it (and failing over
 * to Flutterwave) is done by GatewayServices / BankTransferServices.
 *
 * <p>Paystack wants amounts in minor units (pesewas / kobo), so every amount
 * is multiplied by 100 on the way out.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FincraServices {

    private static final String GATEWAY = "FINCRAN";

    private final GatewayHttp http;
    private final VirtualAccountRepository accounts;

    @Value("${fincra.secret-key}")
    private String secretKey;
    @Value("${fincra.test-url}")
    private String baseUrl;


    // ------------------------------------------------------------------
    // Customers
    // ------------------------------------------------------------------

    /**
     * Creates the customer on Paystack and returns its customer code (CUS_xxx).
     * If Paystack refuses (for example the email already exists), the existing
     * customer is fetched instead.
     */
    public VirtualAccountModel createNewAccount(UUID userId, String email, String firstName, String lastName, String currency, String identityNumber, String identityType, String accountType, String accountReference) {
        log.info("Fincran creating virtual account for: {} {}", firstName, lastName);

        confirmAccount(accountReference, currency);

        Map<String, Object> kycInfo = new HashMap<>();
        kycInfo.put("firstName", firstName);
        kycInfo.put("lastName", lastName);
        kycInfo.put("email", email);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("accountType", accountType);
        body.put("currency", currency);
        body.put("merchantReference", accountReference);
        body.put("KYCInformation", kycInfo);

        if (currency.equalsIgnoreCase("ngn")) {
            body.put("bvn", identityNumber);
        } else {
            body.put("identityNumber", identityNumber);
            body.put("identityType", identityType);
        }

        try {
            FincraNewAccountResponse account = http.post(GATEWAY, baseUrl + "/profile/virtual-accounts/requests", secretKey, body, FincraNewAccountResponse.class);
            if (account.success() && account.data().isActive()) {
                return saveAccount(account, userId);
            }
            log.info("=== FAILED TO CREATE THE ACCOUNT : {}", account.message());
            throw new RuntimeException("Bank account creation failed.");
        } catch (Exception e) {
            log.info("FINCRAN FAILED TO CREATE THE USER VIRTUAL ACCOUNT: ({})", e.getMessage());
            throw new RuntimeException("Virtual account creation failed. try again");
        }
    }

    // ------------------------------------------------------------------
    // CONFIRM ACCOUNT EXISTENCE
    // ------------------------------------------------------------------

    /**
     * Registers a bank account / mobile-money wallet and returns its recipient code (RCP_xxx).
     */
    public void confirmAccount(String accountReference, String currency) {
        log.info("====== CHECKING IF THE VIRTUAL ACCOUNT ALREADY EXISTS =====");

        if (accounts.existsByMerchantReferenceAndCurrencyCode(accountReference, currency)) {
            throw new RuntimeException("Account of type " + currency + "already exists.");
        }

    }

    @Transactional
    public VirtualAccountModel saveAccount(FincraNewAccountResponse a, UUID userId) {
        log.info("====== SAVING BANK ACCOUNT TO DATABASE =====");
        VirtualAccountModel b = new VirtualAccountModel();
        b.setUserId(userId);
        b.setMerchantReference(a.data().merchantReference());
        b.setCurrencyCode(a.data().currency());
        b.setStatus(a.data().status());
        b.setLabel("Default Account");
        b.setAccountType(a.data().accountType());
        b.setAccountNumber(a.data().accountInformation().accountNumber());
        b.setBankName(a.data().accountInformation().bankName());
        b.setEmail(a.data().kycInformation().email());
        b.setActive(a.data().isActive());
        b.setBalance(BigDecimal.ZERO);
        return b;
    }


}
