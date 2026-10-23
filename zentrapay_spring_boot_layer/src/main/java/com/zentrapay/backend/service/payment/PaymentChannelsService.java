package com.zentrapay.backend.service.payment;

import com.zentrapay.backend.dto.payment.GatewayAccountResult;
import com.zentrapay.backend.dto.payment.PaymentChannelDTO;
import com.zentrapay.backend.dto.payment.ResolveAccountResponseDTO;
import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.entity.PaymentChannel;
import com.zentrapay.backend.exception.PaymentGatewayException;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.PaymentChannelRepository;
import com.zentrapay.backend.service.bank.BankCatalogService;
import com.zentrapay.backend.service.gateway.FlutterwaveServices;
import com.zentrapay.backend.service.gateway.PaystackServices;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * The bank / mobile-money picker list and the "who owns this account?" check
 * shown before the user confirms a bank transfer.
 *
 * <p>The account-name check asks Paystack first and Flutterwave if Paystack cannot answer,
 * using each gateway's OWN code for the bank. (AfriqLink is only used to LINK a bank account.)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentChannelsService {

    private final PaymentChannelRepository paymentChannelRepository;
    private final BankCatalogService bankCatalogService;
    private final PaystackServices paystackServices;
    private final FlutterwaveServices flutterwaveServices;

    /** Active channels for a country, optionally only BANK or MOBILE_MONEY. */
    public List<PaymentChannelDTO> listChannels(String countryCode, String type) {
        List<PaymentChannel> channels = (type == null || type.isBlank())
                ? paymentChannelRepository.findByCountryCode(countryCode)
                : paymentChannelRepository.findByCountryCodeAndChannelType(countryCode, type.toUpperCase());

        return channels.stream()
                .filter(PaymentChannel::isActive)
                .map(c -> new PaymentChannelDTO(c.getChannelCode(), c.getChannelName(), c.getChannelType(), c.getCountryCode(), c.getGateway()))
                .toList();
    }

    /** Looks up the account holder's name for a bank account number. */
    public ResolveAccountResponseDTO resolveAccount(String channelCode, String accountNumber) {
        PaymentChannel channel = paymentChannelRepository.findById(channelCode)
                .orElseThrow(() -> new ResourceNotFoundException("Unknown payment channel: " + channelCode));
        if (!"BANK".equalsIgnoreCase(channel.getChannelType())) {
            throw new IllegalArgumentException("Account name lookup is only available for bank accounts");
        }

        Optional<BanksModel> bank = bankCatalogService.findBank(null, channelCode, channel.getCountryCode());
        PaymentGatewayException lastError = null;

        // Paystack first, then Flutterwave - each with its own code for this bank
        for (String gateway : List.of("PAYSTACK", "FLUTTERWAVE")) {
            String code = bank.map(b -> bankCatalogService.codeOnGateway(b, gateway, channel.getCountryCode()))
                    .orElse("PAYSTACK".equals(gateway) ? channelCode : null);
            if (code == null) {
                continue;
            }
            try {
                GatewayAccountResult result = "PAYSTACK".equals(gateway)
                        ? paystackServices.resolveAccount(accountNumber, code)
                        : flutterwaveServices.resolveAccount(accountNumber, code);
                return new ResolveAccountResponseDTO(result.accountName(), result.accountNumber() == null ? accountNumber : result.accountNumber());
            } catch (PaymentGatewayException e) {
                log.info("{} could not resolve {} / {}: {}", gateway, code, accountNumber, e.getMessage());
                lastError = e;
            }
        }
        throw new PaymentGatewayException(lastError == null
                ? "Could not verify that account number, please check and try again"
                : "Could not verify that account number: " + lastError.getMessage());
    }
}
