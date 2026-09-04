package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration // Marks this class as a source of bean definitions
@EnableWebSecurity // Enables Spring Security's web security support
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthenticationFilter jwtAuthenticationFilter,
                                            CorsConfigurationSource corsConfigurationSource) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource))
                .csrf(csrf -> csrf.disable()) // Disabling CSRF for stateless APIs
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/api/users/register",
                                "/api/users/login",
                                "/api/payments/paystack/webhook",
                                "/api/payments/flutterwave/webhook",
                                "/api/secure/tips",
                                "/api/reference/**",
                                "/actuator/**",
                                "/error"
                        ).permitAll()
                        .anyRequest().authenticated() // Ensures all requests are authenticated
                );

        return http.build();
    }
}
