package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.GatewayCustomerModel;
import com.zentrapay.backend.entity.GatewayModel;
import com.zentrapay.backend.entity.GatewayRecipientsModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.service.bank.BankCatalogService;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.GatewayServices;
import com.zentrapay.backend.service.gateway.OnafriqServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import com.zentrapay.backend.service.mobilemoney.MobileMoneyCatalogService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * The rule for a bank / mobile-money cash-out: the gateway that VERIFIED the account is tried first
 * (with its own bank code); the rest of the routing order is only the fallback.
 *
 * <p>Plain unit test - no database, no Spring, no network: every collaborator is a mock.
 */
class BankTransferGatewayOrderTest {

    private GatewayServices gatewayServices;
    private BankCatalogService bankCatalogService;
    private BankTransferServices service;

    private GatewayModel paystack;
    private GatewayModel flutterwave;
    private final BanksModel bank = mock(BanksModel.class);

    @BeforeEach
    void setUp() {
        gatewayServices = mock(GatewayServices.class);
        bankCatalogService = mock(BankCatalogService.class);
        service = new BankTransferServices(gatewayServices, mock(LedgerOperations.class), bankCatalogService,
                mock(MobileMoneyCatalogService.class), mock(PaystackServices.class),
                mock(FlutterwaveServices.class), mock(OnafriqServices.class));

        paystack = gateway("PAYSTACK");
        flutterwave = gateway("FLUTTERWAVE");
        // Normal routing order for a domestic payout: Paystack, then Flutterwave
        when(gatewayServices.gatewaysFor(false, "GH")).thenReturn(List.of(paystack, flutterwave));

        // The bank is in the catalogue and has a code on both gateways
        when(bankCatalogService.findBank(any(), anyString(), eq("GH"))).thenReturn(Optional.of(bank));
        when(bankCatalogService.codeOnGateway(bank, "PAYSTACK", "GH")).thenReturn("PS-044");
        when(bankCatalogService.codeOnGateway(bank, "FLUTTERWAVE", "GH")).thenReturn("FW-044");

        // Creating the customer / recipient works on either gateway
        when(gatewayServices.getOrCreateCustomer(any(), any())).thenReturn(mock(GatewayCustomerModel.class));
        when(gatewayServices.getOrCreateRecipient(any(), any())).thenReturn(mock(GatewayRecipientsModel.class));
    }

    @Test
    void withoutAVerifyingGatewayThePaystackFirstOrderApplies() {
        BankTransferServices.Prepared prepared = service.prepare(payout(null));
        assertEquals("PAYSTACK", prepared.gateway().getProviderName());
    }

    @Test
    void theVerifyingGatewayIsTriedFirstEvenWhenItIsNotTheDefault() {
        BankTransferServices.Prepared prepared = service.prepare(payout(flutterwave.getProviderId()));
        assertEquals("FLUTTERWAVE", prepared.gateway().getProviderName());
    }

    @Test
    void whenTheVerifyingGatewayHasNoCodeForTheBankTheOtherGatewayIsUsed() {
        when(bankCatalogService.codeOnGateway(bank, "FLUTTERWAVE", "GH")).thenReturn(null);
        BankTransferServices.Prepared prepared = service.prepare(payout(flutterwave.getProviderId()));
        assertEquals("PAYSTACK", prepared.gateway().getProviderName());
    }

    @Test
    void aGatewayIdThatIsNotInTheRoutingListIsIgnored() {
        // e.g. a tampered or stale id: the normal order is used, nothing is promoted
        BankTransferServices.Prepared prepared = service.prepare(payout(UUID.randomUUID()));
        assertEquals("PAYSTACK", prepared.gateway().getProviderName());
    }

    private static GatewayModel gateway(String name) {
        GatewayModel g = new GatewayModel();
        g.setProviderId(UUID.randomUUID());
        g.setProviderName(name);
        g.setActive(true);
        return g;
    }

    private BankTransferServices.Payout payout(UUID gatewayId) {
        return new BankTransferServices.Payout("BANK", mock(UserModel.class), false, UUID.randomUUID(), "044", "GH",
                "GHS", "0123456789", "Ama Mensah", new BigDecimal("10.00"), "test", gatewayId);
    }
}
