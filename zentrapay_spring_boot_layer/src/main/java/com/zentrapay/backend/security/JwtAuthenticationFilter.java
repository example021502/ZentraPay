package com.zentrapay.backend.security;

import com.zentrapay.backend.service.common.Datatypes;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.jspecify.annotations.NonNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.UUID;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtService jwtService;

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.equals("/api/users/register")
                || path.equals("/api/users/login")
                // Refresh must work on an expired-but-validly-signed token (API contract §1);
                // UsersService#refresh performs its own signature validation via
                // JwtService#parseAllowExpired, so this filter must not reject it first.
                || path.equals("/api/users/refresh")
                || path.equals("/api/payments/paystack/webhook")
                || path.equals("/api/payments/flutterwave/webhook")
                || path.equals("/api/payments/onafriq/webhook")
                || path.equals("/api/secure/tips")
                || path.startsWith("/api/reference/")
                || path.startsWith("/actuator/")
                || path.equals("/error");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            writeUnauthorized(response, "Missing or malformed Authorization header");
            return;
        }

        AuthenticatedUser authenticatedUser;
        try {
            authenticatedUser = authenticate(authHeader.substring(7));
        } catch (ExpiredJwtException e) {
            writeUnauthorized(response, "Token expired");
            return;
        } catch (JwtException | IllegalArgumentException | NullPointerException e) {
            // A null/malformed claim must degrade to 401, never to a 500 that
            // aborts the filter chain (a 500 here blocked every authenticated
            // endpoint, i.e. no data could load at all).
            writeUnauthorized(response, "Invalid token");
            return;
        }

        request.setAttribute("authenticatedUser", authenticatedUser);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(authenticatedUser, null, Collections.emptyList()));

        // Outside the try on purpose: an error thrown by the endpoint itself must never be
        // reported to the client as an "Invalid token"
        filterChain.doFilter(request, response);
    }

    private AuthenticatedUser authenticate(String token) {
        Claims claims = jwtService.parseAndValidate(token);
        // The role is stored under the "userType" claim (see JwtService#generateToken). Tokens
        // without it (the retired Node.js layer's tokens) fall back to APP_USER.
        String userTypeClaim = claims.get("userType", String.class);
        Datatypes.UserType userType = userTypeClaim == null
                ? Datatypes.UserType.APP_USER
                : Datatypes.UserType.valueOf(userTypeClaim);
        return new AuthenticatedUser(
                UUID.fromString(claims.getSubject()),
                claims.get("email", String.class),
                claims.get("phoneNumber", String.class),
                claims.get("countryCode", String.class),
                claims.get("firstName", String.class),
                claims.get("lastName", String.class),
                claims.get("zentag", String.class),
                userType);
    }

    // 401 in the standard {success, message, data} envelope so the app can parse it like any other response
    private void writeUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"success\":false,\"message\":\"" + message + "\",\"data\":null}");
    }
}
