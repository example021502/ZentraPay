package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayAccountResult;
import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.MobileMoneyProvidersModel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.service.bank.BankCatalogService;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import com.zentrapay.backend.service.mobilemoney.MobileMoneyCatalogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Asks the payment providers who owns a bank account / mobile-money wallet BEFORE any money is
 * debited or any transfer is created.
 *
 * <p>Each provider is asked with ITS OWN code for the bank / network (the same bank has a different
 * code on every provider). The first provider that confirms the account wins. Onafriq has no
 * name-lookup call, so only Paystack and Flutterwave are asked.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AccountVerificationService {

    /** What the providers said about the account. {@code gateway} is the provider that answered. */
    public record Verified(String accountName, String accountNumber, String destinationName, GatewayModel gateway) {
    }

    private final GatewayServices gatewayServices;
    private final BankCatalogService bankCatalogService;
    private final MobileMoneyCatalogService mobileMoneyCatalogService;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;

    /**
     * Confirms a bank account. Throws when no provider can confirm it, so a payment never goes to an
     * account nobody has verified.
     */
    public Verified verifyBank(UUID bankId, String bankCode, String accountNumber, String countryCode) {
        BanksModel bank = bankCatalogService.findBank(bankId, bankCode, countryCode)
                .orElseThrow(() -> new IllegalArgumentException("This bank is not supported for transfers right now"));
        if (!Boolean.TRUE.equals(bank.getActive())) {
            throw new IllegalArgumentException(bank.getBankName() + " is not available for transfers right now");
        }

        PaymentGatewayException last = null;
        boolean asked = false;
        for (GatewayModel gateway : resolvers()) {
            String code = bankCatalogService.codeOnGateway(bank, gateway.getProviderName(), countryCode);
            if (code == null) {
                continue;
            }
            asked = true;
            try {
                GatewayAccountResult result = resolveOn(gateway, accountNumber, code);
                log.info("Account check: {} confirmed {} / {}", gateway.getProviderName(), bank.getBankName(), accountNumber);
                return new Verified(result.accountName(), accountNumber, bank.getBankName(), gateway);
            } catch (PaymentGatewayException e) {
                log.warn("Account check: {} could not confirm {} / {}: {}", gateway.getProviderName(), bank.getBankName(), accountNumber, e.getMessage());
                last = e;
            }
        }
        throw new PaymentGatewayException(!asked || last == null
                ? "We could not check this account right now. Please try again later."
                : "We could not confirm this account. Please check the account number and the bank.");
    }

    /**
     * Asks the providers about a mobile-money wallet. Returns empty when no provider offers a name
     * lookup for this network - the payout then still goes through the provider's own recipient
     * registration, which is a provider call too.
     */
    public Optional<Verified> verifyMobileMoney(UUID providerId, String providerCode, String phoneNumber, String countryCode) {
        MobileMoneyProvidersModel network = mobileMoneyCatalogService.findProvider(providerId, providerCode, countryCode)
                .orElseThrow(() -> new IllegalArgumentException("This mobile money network is not supported for transfers right now"));
        if (!Boolean.TRUE.equals(network.getActive())) {
            throw new IllegalArgumentException(network.getName() + " is not available for transfers right now");
        }

        for (GatewayModel gateway : resolvers()) {
            String code = mobileMoneyCatalogService.codeOnGateway(network, gateway.getProviderName());
            if (code == null) {
                continue;
            }
            try {
                GatewayAccountResult result = resolveOn(gateway, phoneNumber, code);
                log.info("Wallet check: {} confirmed {} / {}", gateway.getProviderName(), network.getName(), phoneNumber);
                return Optional.of(new Verified(result.accountName(), phoneNumber, network.getName(), gateway));
            } catch (PaymentGatewayException e) {
                log.info("Wallet check: {} has no name for {} / {}: {}", gateway.getProviderName(), network.getName(), phoneNumber, e.getMessage());
            }
        }
        return Optional.empty();
    }

    // Providers that can look an account up, best first. Providers that are switched off are skipped.
    private List<GatewayModel> resolvers() {
        List<GatewayModel> list = new ArrayList<>();
        for (Datatypes.PaymentGateway name : List.of(Datatypes.PaymentGateway.PAYSTACK, Datatypes.PaymentGateway.FLUTTERWAVE)) {
            try {
                list.add(gatewayServices.gatewayByName(name));
            } catch (PaymentGatewayException ignored) {
                // that provider is off right now
            }
        }
        if (list.isEmpty()) {
            throw new PaymentGatewayException("Account checks are unavailable right now, please try again later");
        }
        return list;
    }

    private GatewayAccountResult resolveOn(GatewayModel gateway, String accountNumber, String code) {
        return switch (gatewayServices.nameOf(gateway)) {
            case PAYSTACK -> paystackServices.resolveAccount(accountNumber, code);
            case FLUTTERWAVE -> flutterwaveServices.resolveAccount(accountNumber, code);
            case ONAFRIQ -> throw new PaymentGatewayException("Onafriq cannot look up account names");
        };
    }
}
