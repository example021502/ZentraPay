package com.zentrapay_application.zentrapay_spring_boot_layer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.client.RestTemplate;

/**
 * Zentrapay Spring Boot Layer Application
 * 
 * Main application class that bootstraps the Spring Boot backend.
 * All payment modules, controllers, and services are auto-scanned from
 * the package structure:
 *   - com.zentrapay_application.zentrapay_spring_boot_layer.modules.*
 * 
 * Gateway Architecture:
 * - Paystack (Primary): Ghanaian national transactions (GHS)
 * - Onafriq (Primary): International transactions
 * - Flutterwave (Failover): Secondary gateway for both
 * 
 * All transaction recording happens within @Transactional boundaries
 * to ensure data consistency and atomicity.
 */
@SpringBootApplication
@EnableConfigurationProperties
public class ZentrapaySpringBootLayerApplication {

	public static void main(String[] args) {
		SpringApplication.run(ZentrapaySpringBootLayerApplication.class, args);
	}

	@Bean
	public PasswordEncoder passwordEncoder() {
		return new BCryptPasswordEncoder();
	}

	/**
	 * RestTemplate bean used by {@code PaystackClient} for outbound HTTP calls
	 * to the Paystack API.
	 */
	@Bean
	public RestTemplate restTemplate() {
		return new RestTemplate();
	}

}
