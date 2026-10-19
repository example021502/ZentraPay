package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.PaymentChannel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.PaymentChannelRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.AfriqLinkVerifyResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentChannelDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.ResolveAccountResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Bank / mobile-money directory backing the bank-transfer picker
 * ({@code payment_channels} table, seeded per country/gateway) and live
 * account-name resolution before a payout is confirmed.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentChannelsService {

    private final PaymentChannelRepository paymentChannelRepository;
    private final AfriqLinkClient afriqLinkClient;

    public List<PaymentChannelDTO> listChannels(String countryCode, String type) {
        List<PaymentChannel> channels = (type == null || type.isBlank())
                ? paymentChannelRepository.findByCountryCode(countryCode)
                : paymentChannelRepository.findByCountryCodeAndChannelType(countryCode, type.toUpperCase());

        return channels.stream()
                .filter(PaymentChannel::isActive)
                .map(c -> new PaymentChannelDTO(c.getChannelCode(), c.getChannelName(), c.getChannelType(), c.getCountryCode(), c.getGateway()))
                .toList();
    }

    /**
     * Resolves an account number against <b>AfriqLink</b> — the project's
     * single open-banking provider. Account lookup is a bank-data service, so
     * the settlement gateways (Paystack / Flutterwave) are deliberately NOT
     * called here even though the channel catalog still records which gateway
     * owns each payout channel. The channel's own {@code channelCode} doubles
     * as the provider's bank code.
     */
    public ResolveAccountResponseDTO resolveAccount(String channelCode, String accountNumber) {
        paymentChannelRepository.findById(channelCode)
                .orElseThrow(() -> new ResourceNotFoundException("Unknown payment channel: " + channelCode));

        AfriqLinkVerifyResponseDTO response = afriqLinkClient.verifyAccount(accountNumber, channelCode);
        if (response.data() == null
                || response.data().accountName() == null
                || response.data().accountName().isBlank()) {
            throw new PaymentGatewayException("Could not verify that account number, please check and try again");
        }
        return new ResolveAccountResponseDTO(
                response.data().accountName(), response.data().accountNumber());
    }
}
