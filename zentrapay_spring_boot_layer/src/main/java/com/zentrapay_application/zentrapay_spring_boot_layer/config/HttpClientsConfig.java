package com.zentrapay_application.zentrapay_spring_boot_layer.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.time.Duration;

/**
 * {@link RestClient} bean for the gateway clients written against it
 * (Paystack, Onafriq) — {@code RestTemplate} already has a bean in
 * {@code ZentrapaySpringBootLayerApplication} for the client written against
 * that (Flutterwave), but nothing registered a {@code RestClient} bean, so
 * every Paystack/Onafriq call failed application startup with
 * "No qualifying bean of type RestClient".
 */
@Configuration
public class HttpClientsConfig {

    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(10);
    private static final Duration READ_TIMEOUT = Duration.ofSeconds(30);

    @Bean
    public RestClient restClient() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) CONNECT_TIMEOUT.toMillis());
        factory.setReadTimeout((int) READ_TIMEOUT.toMillis());
        return RestClient.builder()
                .requestFactory(factory)
                .build();
    }
}
