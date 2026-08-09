package com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.PaymentChannel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.PaymentChannelRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.dto.PaymentChannelDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.dto.ResolveAccountResponseDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.List;
import java.util.Map;

/**
 * Bank / mobile-money channel directory (API_CONTRACT.md §7).
 * <p>
 * The list endpoint is served from the {@code payment_channels} table (kept fresh by
 * {@link PaymentChannelSyncService}); {@code resolve} is a live passthrough to Paystack's
 * bank-resolve API, since Paystack is the simplest gateway already configured in this project
 * (see {@code paystack.*} properties).
 */
@Service
@Slf4j
@Transactional(readOnly = true)
public class PaymentChannelsService {

    private final PaymentChannelRepository paymentChannelRepository;
    private final RestTemplate restTemplate;

    @Value("${paystack.base-url:https://api.paystack.co}")
    private String paystackBaseUrl;

    @Value("${paystack.secret-key}")
    private String paystackSecretKey;

    public PaymentChannelsService(PaymentChannelRepository paymentChannelRepository, RestTemplate restTemplate) {
        this.paymentChannelRepository = paymentChannelRepository;
        this.restTemplate = restTemplate;
    }

    public List<PaymentChannelDTO> listChannels(String countryCode, String channelType) {
        List<PaymentChannel> channels;
        if (countryCode != null && !countryCode.isBlank() && channelType != null && !channelType.isBlank()) {
            channels = paymentChannelRepository.findByCountryCodeAndChannelType(countryCode.toUpperCase(), channelType.toUpperCase());
        } else if (countryCode != null && !countryCode.isBlank()) {
            channels = paymentChannelRepository.findByCountryCode(countryCode.toUpperCase());
        } else {
            channels = paymentChannelRepository.findAll();
        }
        return channels.stream()
                .filter(PaymentChannel::isActive)
                .map(c -> new PaymentChannelDTO(c.getChannelCode(), c.getChannelName(), c.getChannelType(), c.getCountryCode(), c.getGateway()))
                .toList();
    }

    /**
     * Live account-name resolution, passed through to the owning gateway. Only Paystack is
     * wired up in this pass (it's the gateway already configured with a secret key in
     * application.properties); channels belonging to other gateways fall back to a
     * not-implemented error rather than a fake/mocked account name.
     */
    @SuppressWarnings("unchecked")
    public ResolveAccountResponseDTO resolveAccount(String channelCode, String accountNumber) {
        PaymentChannel channel = paymentChannelRepository.findById(channelCode)
                .orElseThrow(() -> new ResourceNotFoundException("Unknown payment channel: " + channelCode));

        if (!"PAYSTACK".equalsIgnoreCase(channel.getGateway())) {
            throw new IllegalStateException("Account resolution for gateway " + channel.getGateway() + " is not implemented yet");
        }

        String url = UriComponentsBuilder.fromUriString(paystackBaseUrl + "/bank/resolve")
                .queryParam("account_number", accountNumber)
                .queryParam("bank_code", channel.getChannelCode())
                .toUriString();

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + paystackSecretKey);

        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
        Map<String, Object> body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("status"))) {
            throw new IllegalStateException("Account resolution failed for channel " + channelCode);
        }
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String accountName = data != null ? String.valueOf(data.get("account_name")) : null;
        return new ResolveAccountResponseDTO(accountName);
    }
}
