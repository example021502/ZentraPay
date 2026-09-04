package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.PaymentChannel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.PaymentChannelRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
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
    private final PaystackServices paystackServices;
    private final FlutterwaveClient flutterwaveClient;

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
     * Resolves an account number against whichever gateway owns the chosen
     * channel — Paystack's {@code bank_code} or Flutterwave's
     * {@code account_bank} is the channel's own {@code channelCode}.
     */
    public ResolveAccountResponseDTO resolveAccount(String channelCode, String accountNumber) {
        PaymentChannel channel = paymentChannelRepository.findById(channelCode)
                .orElseThrow(() -> new ResourceNotFoundException("Unknown payment channel: " + channelCode));

        if ("FLUTTERWAVE".equalsIgnoreCase(channel.getGateway())) {
            var response = flutterwaveClient.resolveAccount(accountNumber, channelCode);
            if (response == null || response.data() == null || !"success".equalsIgnoreCase(response.status())) {
                throw new PaymentGatewayException("Could not verify that account number, please check and try again");
            }
            return new ResolveAccountResponseDTO(response.data().account_name(), response.data().account_number());
        }

        var response = paystackServices.resolveAccount(accountNumber, channelCode);
        if (response == null || response.data() == null || !response.status()) {
            throw new PaymentGatewayException("Could not verify that account number, please check and try again");
        }
        return new ResolveAccountResponseDTO(response.data().accountName(), response.data().accountNumber());
    }
}
