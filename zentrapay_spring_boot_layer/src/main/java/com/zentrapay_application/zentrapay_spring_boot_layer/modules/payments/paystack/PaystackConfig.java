package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.paystack;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration properties for Paystack API integration.
 * <p>
 * Values are sourced from {@code application.properties} under the {@code paystack.*} prefix.
 * <p>
 * Supports the African market with multi-currency disbursements via Paystack's
 * Transfer Recipient and Transfer APIs.
 */
@Configuration
@ConfigurationProperties(prefix = "paystack")
public class PaystackConfig {

    /** Paystack API base URL (e.g., https://api.paystack.co) */
    private String baseUrl;

    /** Paystack secret key for server-to-server authentication */
    private String secretKey;

    /** Default currency for disbursements (e.g., NGN, GHS, ZAR, USD) */
    private String defaultCurrency;

    /** Callback URL for transfer status webhooks */
    private String callbackUrl;

    // --- Getters & Setters ---

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getSecretKey() {
        return secretKey;
    }

    public void setSecretKey(String secretKey) {
        this.secretKey = secretKey;
    }

    public String getDefaultCurrency() {
        return defaultCurrency;
    }

    public void setDefaultCurrency(String defaultCurrency) {
        this.defaultCurrency = defaultCurrency;
    }

    public String getCallbackUrl() {
        return callbackUrl;
    }

    public void setCallbackUrl(String callbackUrl) {
        this.callbackUrl = callbackUrl;
    }
}