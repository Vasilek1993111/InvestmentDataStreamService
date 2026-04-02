package com.example.investmentdatastreamservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.util.StringUtils;

/**
 * Security hardening for public and administrative HTTP endpoints.
 */
@Configuration
public class ApiSecurityConfig {

    @Value("${app.security.admin.username:}")
    private String adminUsername;

    @Value("${app.security.admin.password:}")
    private String adminPassword;

    @Bean
    @Order(1)
    public SecurityFilterChain adminApiSecurityFilterChain(HttpSecurity http) throws Exception {
        http.securityMatcher(
                "/api/cache/**",
                "/api/stream/**",
                "/api/limit-monitor/**",
                "/api/instruments/limits/cache-stats",
                "/actuator/**");

        http.csrf(AbstractHttpConfigurer::disable);
        http.sessionManagement(
                session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        http.authorizeHttpRequests(authorize -> {
            authorize.requestMatchers("/actuator/health", "/actuator/info").permitAll();
            if (hasAdminCredentials()) {
                authorize.anyRequest().authenticated();
            } else {
                authorize.anyRequest().denyAll();
            }
        });

        if (hasAdminCredentials()) {
            http.httpBasic(Customizer.withDefaults());
        } else {
            http.httpBasic(AbstractHttpConfigurer::disable);
        }

        return http.build();
    }

    @Bean
    @Order(2)
    public SecurityFilterChain applicationSecurityFilterChain(HttpSecurity http) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable);
        http.sessionManagement(
                session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.authorizeHttpRequests(authorize -> authorize.anyRequest().permitAll());
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService(PasswordEncoder passwordEncoder) {
        if (!hasAdminCredentials()) {
            return new InMemoryUserDetailsManager();
        }

        UserDetails adminUser = User.withUsername(adminUsername)
                .password(passwordEncoder.encode(adminPassword))
                .roles("ADMIN")
                .build();

        return new InMemoryUserDetailsManager(adminUser);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    private boolean hasAdminCredentials() {
        return StringUtils.hasText(adminUsername) && StringUtils.hasText(adminPassword);
    }
}
