package com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.PaymentChannel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.PaymentChannelRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/**
 * Refreshes the {@code payment_channels} directory from Paystack's bank-list API
 * (GET /bank) so the GH bank/mobile-money select UIs don't depend on a live call
 * per keystroke. Upserts by channel_code.
 * <p>
 * NOTE: this class is annotated {@link Scheduled}, but {@code @EnableScheduling}
 * has not been added anywhere in this codebase yet — it must live on the main
 * {@code @SpringBootApplication} class, which is out of scope for this module
 * to touch. Until a coordinator adds {@code @EnableScheduling}, this job simply
 * never fires (harmless no-op), and the seeded rows from V3__seed_providers.sql
 * remain the only channel data. See final report.
 */
@Service
public class PaymentChannelSyncService {

    private static final Logger log = LoggerFactory.getLogger(PaymentChannelSyncService.class);

    private final PaymentChannelRepository paymentChannelRepository;
    private final RestTemplate restTemplate;

    @Value("${paystack.base-url:https://api.paystack.co}")
    private String paystackBaseUrl;

    @Value("${paystack.secret-key}")
    private String paystackSecretKey;

    public PaymentChannelSyncService(PaymentChannelRepository paymentChannelRepository, RestTemplate restTemplate) {
        this.paymentChannelRepository = paymentChannelRepository;
        this.restTemplate = restTemplate;
    }

    /**
     * Runs once a day. Pulls Paystack's full bank list (Ghana + Nigeria corridors
     * covered by this project's Paystack integration) and upserts each entry into
     * {@code payment_channels}, keyed by Paystack's own bank code as our channel_code.
     */
    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void syncPaystackChannels() {
        log.info("[PAYMENT_CHANNEL_SYNC] Starting Paystack bank-list sync");
        try {
            syncCountry("GH");
            syncCountry("NG");
        } catch (Exception e) {
            log.error("[PAYMENT_CHANNEL_SYNC] Sync failed: {}", e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    private void syncCountry(String countryCode) {
        String url = paystackBaseUrl + "/bank?country=" + (countryCode.equals("GH") ? "ghana" : "nigeria");
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + paystackSecretKey);

        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
        Map<String, Object> body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("status"))) {
            log.warn("[PAYMENT_CHANNEL_SYNC] Paystack /bank returned no data for {}", countryCode);
            return;
        }
        List<Map<String, Object>> banks = (List<Map<String, Object>>) body.get("data");
        if (banks == null) {
            return;
        }
        int upserted = 0;
        for (Map<String, Object> bank : banks) {
            String code = String.valueOf(bank.get("code"));
            String name = String.valueOf(bank.get("name"));
            String type = Boolean.TRUE.equals(bank.get("is_deleted")) ? null : "BANK";
            if (type == null || code == null || code.isBlank()) {
                continue;
            }
            PaymentChannel channel = paymentChannelRepository.findById(code).orElseGet(PaymentChannel::new);
            channel.setChannelCode(code);
            channel.setChannelName(name);
            channel.setChannelType("BANK");
            channel.setCountryCode(countryCode);
            channel.setGateway("PAYSTACK");
            channel.setActive(true);
            paymentChannelRepository.save(channel);
            upserted++;
        }
        log.info("[PAYMENT_CHANNEL_SYNC] Upserted {} channels for {}", upserted, countryCode);
    }
}
