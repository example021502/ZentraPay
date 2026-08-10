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
 * Refreshes the {@code payment_channels} directory (banks / mobile-money channels) from
 * each configured gateway's own directory API, so the bank/mobile-money select UIs — and
 * the Pay-section search's "supported banks in the user's country" results — don't depend
 * on a live call per keystroke. Upserts by channel_code. Each gateway runs on its own
 * schedule (staggered, so they don't all hammer three third-party APIs at once) and its
 * own failure is isolated — one gateway being down/misconfigured doesn't block the others.
 * <p>
 * {@code @EnableScheduling} is present on {@code ZentrapaySpringBootLayerApplication}, so
 * these jobs do fire.
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

    @Value("${flutterwave.base-url:https://api.flutterwave.com/v3}")
    private String flutterwaveBaseUrl;

    @Value("${flutterwave.secret-key}")
    private String flutterwaveSecretKey;

    @Value("${onafriq.base-url:https://api.onafriq.com/v1}")
    private String onafriqBaseUrl;

    @Value("${onafriq.secret-key}")
    private String onafriqSecretKey;

    // Corridors this project actually serves — kept in one place so adding a
    // country later is a one-line change, not a hunt through three methods.
    private static final List<String> SYNC_COUNTRIES = List.of("GH", "NG", "KE");

    public PaymentChannelSyncService(PaymentChannelRepository paymentChannelRepository, RestTemplate restTemplate) {
        this.paymentChannelRepository = paymentChannelRepository;
        this.restTemplate = restTemplate;
    }

    /**
     * Runs daily at 03:00. Pulls Paystack's bank list per corridor and upserts each
     * entry into {@code payment_channels}, keyed by Paystack's own bank code.
     */
    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void syncPaystackChannels() {
        log.info("[PAYMENT_CHANNEL_SYNC] Starting Paystack bank-list sync");
        for (String countryCode : SYNC_COUNTRIES) {
            // Paystack only actually covers GH/NG; other corridors are skipped rather
            // than sent to an endpoint that would just 400.
            if (!countryCode.equals("GH") && !countryCode.equals("NG")) continue;
            try {
                syncPaystackCountry(countryCode);
            } catch (Exception e) {
                log.error("[PAYMENT_CHANNEL_SYNC] Paystack sync failed for {}: {}", countryCode, e.getMessage(), e);
            }
        }
    }

    /**
     * Runs daily at 03:20 (offset from Paystack so the two don't fire in the same
     * second). Flutterwave's bank-directory endpoint is public and documented:
     * {@code GET /v3/banks/{country}} — one call per country, no pagination.
     */
    @Scheduled(cron = "0 20 3 * * *")
    @Transactional
    public void syncFlutterwaveChannels() {
        log.info("[PAYMENT_CHANNEL_SYNC] Starting Flutterwave bank-list sync");
        for (String countryCode : SYNC_COUNTRIES) {
            try {
                syncFlutterwaveCountry(countryCode);
            } catch (Exception e) {
                log.error("[PAYMENT_CHANNEL_SYNC] Flutterwave sync failed for {}: {}", countryCode, e.getMessage(), e);
            }
        }
    }

    /**
     * Runs daily at 03:40. Onafriq is a private partner API (no public REST docs to
     * verify against from here) — this calls {@code GET /banks?country=} on the
     * configured {@code onafriq.base-url} following the same shape as the other two
     * gateways' directory endpoints, but that exact path has NOT been confirmed
     * against Onafriq's real API reference. If it 404s/shape-mismatches in practice,
     * that's expected until someone with Onafriq API docs corrects the path below —
     * failures here are caught and logged, never thrown, so a wrong endpoint can't
     * take down the other two syncs or the scheduler itself.
     */
    @Scheduled(cron = "0 40 3 * * *")
    @Transactional
    public void syncOnafriqChannels() {
        log.info("[PAYMENT_CHANNEL_SYNC] Starting Onafriq bank-list sync");
        for (String countryCode : SYNC_COUNTRIES) {
            try {
                syncOnafriqCountry(countryCode);
            } catch (Exception e) {
                log.error("[PAYMENT_CHANNEL_SYNC] Onafriq sync failed for {} (endpoint unverified — see class Javadoc): {}",
                        countryCode, e.getMessage());
            }
        }
    }

    @SuppressWarnings("unchecked")
    private void syncPaystackCountry(String countryCode) {
        String country = switch (countryCode) {
            case "GH" -> "ghana";
            case "NG" -> "nigeria";
            default -> countryCode.toLowerCase();
        };
        String url = paystackBaseUrl + "/bank?country=" + country;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + paystackSecretKey);

        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
        Map<String, Object> body = response.getBody();
        if (body == null || !Boolean.TRUE.equals(body.get("status"))) {
            log.warn("[PAYMENT_CHANNEL_SYNC] Paystack /bank returned no data for {}", countryCode);
            return;
        }
        List<Map<String, Object>> banks = (List<Map<String, Object>>) body.get("data");
        if (banks == null) return;

        int upserted = 0;
        for (Map<String, Object> bank : banks) {
            String code = String.valueOf(bank.get("code"));
            String name = String.valueOf(bank.get("name"));
            if (Boolean.TRUE.equals(bank.get("is_deleted")) || code == null || code.isBlank()) continue;
            upsertChannel(code, name, "BANK", countryCode, "PAYSTACK");
            upserted++;
        }
        log.info("[PAYMENT_CHANNEL_SYNC] Upserted {} Paystack channels for {}", upserted, countryCode);
    }

    @SuppressWarnings("unchecked")
    private void syncFlutterwaveCountry(String countryCode) {
        String url = flutterwaveBaseUrl + "/banks/" + countryCode;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + flutterwaveSecretKey);

        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
        Map<String, Object> body = response.getBody();
        if (body == null || !"success".equals(body.get("status"))) {
            log.warn("[PAYMENT_CHANNEL_SYNC] Flutterwave /banks returned no data for {}", countryCode);
            return;
        }
        List<Map<String, Object>> banks = (List<Map<String, Object>>) body.get("data");
        if (banks == null) return;

        int upserted = 0;
        for (Map<String, Object> bank : banks) {
            Object codeObj = bank.get("code");
            String code = codeObj == null ? null : String.valueOf(codeObj);
            String name = String.valueOf(bank.get("name"));
            if (code == null || code.isBlank()) continue;
            // Namespaced so a bank code that happens to collide with Paystack's for the
            // same institution doesn't silently overwrite the other gateway's row.
            upsertChannel("FLW-" + code, name, "BANK", countryCode, "FLUTTERWAVE");
            upserted++;
        }
        log.info("[PAYMENT_CHANNEL_SYNC] Upserted {} Flutterwave channels for {}", upserted, countryCode);
    }

    @SuppressWarnings("unchecked")
    private void syncOnafriqCountry(String countryCode) {
        String url = onafriqBaseUrl + "/banks?country=" + countryCode;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + onafriqSecretKey);

        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
        Map<String, Object> body = response.getBody();
        if (body == null) {
            log.warn("[PAYMENT_CHANNEL_SYNC] Onafriq /banks returned no data for {}", countryCode);
            return;
        }
        Object dataObj = body.get("data") != null ? body.get("data") : body.get("banks");
        if (!(dataObj instanceof List)) return;
        List<Map<String, Object>> banks = (List<Map<String, Object>>) dataObj;

        int upserted = 0;
        for (Map<String, Object> bank : banks) {
            Object codeObj = bank.getOrDefault("code", bank.get("bankCode"));
            String code = codeObj == null ? null : String.valueOf(codeObj);
            Object nameObj = bank.getOrDefault("name", bank.get("bankName"));
            String name = nameObj == null ? "Unknown" : String.valueOf(nameObj);
            if (code == null || code.isBlank()) continue;
            upsertChannel("ONF-" + code, name, "BANK", countryCode, "ONAFRIQ");
            upserted++;
        }
        log.info("[PAYMENT_CHANNEL_SYNC] Upserted {} Onafriq channels for {}", upserted, countryCode);
    }

    private void upsertChannel(String channelCode, String channelName, String channelType, String countryCode, String gateway) {
        PaymentChannel channel = paymentChannelRepository.findById(channelCode).orElseGet(PaymentChannel::new);
        channel.setChannelCode(channelCode);
        channel.setChannelName(channelName);
        channel.setChannelType(channelType);
        channel.setCountryCode(countryCode);
        channel.setGateway(gateway);
        channel.setActive(true);
        paymentChannelRepository.save(channel);
    }
}
