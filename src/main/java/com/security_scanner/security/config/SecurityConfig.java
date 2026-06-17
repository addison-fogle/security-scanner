package com.security_scanner.security.config;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Configuration
public class SecurityConfig {

    private static final String API_KEY_HEADER = "X-API-Key";

    @Value("${scanner.api-key}")
    private String apiKey;

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/", "/actuator/health", "/actuator/health/**", "/actuator/info").permitAll()
                        .requestMatchers("/api/**").authenticated()
                        .anyRequest().denyAll())
                .addFilterBefore(apiKeyFilter(), org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class)
                .httpBasic(Customizer.withDefaults())
                .build();
    }

    private OncePerRequestFilter apiKeyFilter() {
        return new OncePerRequestFilter() {
            @Override
            protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
                    throws ServletException, IOException {
                if (!request.getRequestURI().startsWith("/api/")) {
                    filterChain.doFilter(request, response);
                    return;
                }

                String providedKey = request.getHeader(API_KEY_HEADER);
                if (!apiKey.equals(providedKey)) {
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid API key");
                    return;
                }

                var authentication = new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        "api-key", null, java.util.List.of());
                org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(authentication);
                filterChain.doFilter(request, response);
            }
        };
    }
}
