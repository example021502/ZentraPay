package com.zentrapay_application.zentrapay_spring_boot_layer.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.jspecify.annotations.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class ApiKeyFilter extends OncePerRequestFilter {

    @Value("${app.internal.header_name}")
    private String headerName;

    @Value("${app.internal.secret_key}")
    private String secretValue;

    @Override
    protected void doFilterInternal(HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String requestSecret = request.getHeader(headerName);
        String path = request.getRequestURI();

        System.out.println("[API_KEY_FILTER] path=" + path + " header=" + headerName + " secretPresent=" + (requestSecret != null));

        if (secretValue.equals(requestSecret)) {
            System.out.println("[API_KEY_FILTER] secret matched for path=" + path);
            filterChain.doFilter(request, response);
        } else {
            System.out.println("[API_KEY_FILTER] secret mismatch or missing for path=" + path);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Unauthorized: Invalid or missing API key");
        }
    }
}