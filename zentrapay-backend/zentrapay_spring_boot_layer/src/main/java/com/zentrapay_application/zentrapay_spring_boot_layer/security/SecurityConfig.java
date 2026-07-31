package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration // Marks this class as a source of bean definitions
@EnableWebSecurity // Enables Spring Security's web security support
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthenticationFilter jwtAuthenticationFilter) throws Exception {
        http
                .csrf(csrf -> csrf.disable()) // Disabling CSRF for stateless APIs
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/api/users/register",
                                "/api/users/login",
                                "/actuator/**",
                                "/error"
                        ).permitAll()
                        .anyRequest().authenticated() // Ensures all requests are authenticated
                );

        return http.build();
    }
}
