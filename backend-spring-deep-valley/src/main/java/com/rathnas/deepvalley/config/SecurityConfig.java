package com.rathnas.deepvalley.config;

import com.rathnas.deepvalley.jpa.enumtype.UserRole;
import com.rathnas.deepvalley.model.User;
import com.rathnas.deepvalley.service.UserService;
import com.rathnas.deepvalley.jpa.entity.UserEntity;
import com.google.common.collect.Lists;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;

import java.io.IOException;
import java.text.ParseException;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Slf4j
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final UserService userService;

    @Value("${app.cors.origins}")
    private List<String> allowedOriginPatterns;

    @Value("${app.auth0.domain}")
    private String issuerAuth0;

    @Value("${app.auth0.audience}")
    private String audienceAuth0;

    @Value("${app.auth0.jwt.role.claim.key}")
    private String roleClaimKeyAuth0;

    @Value("${app.uris.public}")
    private String[] publicUris;
    
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.OPTIONS).permitAll()
                        .requestMatchers(publicUris).permitAll()
                        .requestMatchers("/api/**").hasAnyRole(UserRole.USER.name(), UserRole.ADMIN.name(), UserRole.ROOT.name())
                        .requestMatchers("/admin/**").hasAnyRole(UserRole.ADMIN.name(), UserRole.ROOT.name())
                        .requestMatchers("/root/**").hasRole(UserRole.ROOT.name())
                        .anyRequest().authenticated())
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
                .csrf(AbstractHttpConfigurer::disable)
                .cors(c -> c.configurationSource(request -> {
                    CorsConfiguration config = new CorsConfiguration();
                    config.setAllowedOriginPatterns(Lists.newArrayList(allowedOriginPatterns));
                    config.setAllowedMethods(Lists.newArrayList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
                    config.setAllowedHeaders(Lists.newArrayList("*"));
                    config.setAllowCredentials(true);
                    config.setMaxAge(Duration.ofHours(24)); // 24 hours
                    return config;
                }))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .addFilterBefore(new OncePerRequestFilter() {
                    @Override
                    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                                    FilterChain filterChain) throws ServletException, IOException {
                        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
                            response.setStatus(HttpServletResponse.SC_OK);
                            return;
                        }

                        String token = request.getHeader("Authorization");
                        if (token != null && token.startsWith("Bearer ")) {
                            Jwt jwt = null;
                            try {
                                jwt = jwtDecoder().decode(token.substring(7));
                                assignSecurityContext(jwt, token.substring(7));
                            } catch (Exception e) {
                                log.error("Error decoding JWT token for {}", request.getRequestURI(), e);
                            }
                        }
                        filterChain.doFilter(request, response);
                    }
                }, BasicAuthenticationFilter.class);
        return http.build();
    }

    private String getClaim(Map<String, Object> claims, String key) {
        if (claims != null) {
            Object value = claims.get(key);
            if (value instanceof String) {
                return (String) value;
            }
        }
        return null;
    }

    /**
     * Sets the SecurityContextHolder with our custom AuthToken.
     */
    private void assignSecurityContext(Jwt jwt, String accessToken) throws ParseException {
        if (jwt == null || jwt.getClaims() == null) {
            log.warn("JWT is null, skipping assignSecurityContext.");
            return;
        }
        
        String userId = getClaim(jwt.getClaims(), "sub");
        String tenantId = getClaim(jwt.getClaims(), "azp");
        String issuer = jwt.getIssuer().toString();
        
        // First check if user already exists in database using sub claim
        Optional<UserEntity> existingUser = 
            userService.findByExternalAuth(issuer, userId);
        
        String email = null;
        String name = null;
        String firstName = null;
        String lastName = null;
        String picture = null;
        
        if (existingUser.isPresent()) {
            // User exists, use stored information
            UserEntity user = existingUser.get();
            email = user.getEmail();
            name = user.getFullName();
            firstName = user.getFirstName();
            lastName = user.getLastName();
            picture = user.getPicture();
            log.debug("Found existing user in database: {}", email);
        } else {
            // User not found, fetch from Auth0 userinfo endpoint and create new user
            log.debug("User not found in database, fetching from Auth0 userinfo for sub: {}", userId);
            Map<String, Object> userInfo = fetchUserInfoFromAuth0(accessToken);
            
            if (userInfo != null) {
                email = (String) userInfo.get("email");
                name = (String) userInfo.get("name");
                firstName = (String) userInfo.get("given_name");
                lastName = (String) userInfo.get("family_name");
                picture = (String) userInfo.get("picture");
                
                // Create new user in database
                try {
                    if (email != null) {
                        userService.createOrUpdateUser(tenantId, email, issuer, userId, firstName, lastName, picture);
                        log.info("Created new user in database: {}", email);
                    }
                } catch (Exception e) {
                    log.error("Failed to create new user for {}", email, e);
                }
            } else {
                log.warn("Failed to fetch user info from Auth0 for sub: {}", userId);
            }
        }
        
        SecurityContextHolder.getContext().setAuthentication(new AuthToken(
                User.builder().email(email).name(name).tenantId(tenantId).id(userId).build(),
                SecurityContextHolder.getContext().getAuthentication(),
                getAuthorities(jwt.getClaims()),
                jwt.getTokenValue()
        ));
    }
    
    /**
     * Fetches user information from Auth0's userinfo endpoint
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> fetchUserInfoFromAuth0(String accessToken) {
        try {
            RestTemplate restTemplate = restTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.add("Authorization", "Bearer " + accessToken);
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            String userInfoUrl = "https://" + issuerAuth0 + "/userinfo";
            ResponseEntity<Map> response = restTemplate.exchange(
                userInfoUrl, 
                HttpMethod.GET, 
                entity, 
                Map.class
            );
            
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                log.debug("Successfully fetched user info from Auth0: {}", response.getBody().get("email"));
                return response.getBody();
            }
        } catch (Exception e) {
            log.error("Failed to fetch user info from Auth0 userinfo endpoint", e);
        }
        return null;
    }

    /**
     * Determines the proper role claim key based on the token issuer and returns the authorities.
     */
    @SuppressWarnings("unchecked")
    private List<SimpleGrantedAuthority> getAuthorities(Map<String, Object> claims) {
        // Auth0 role handling
        Object rolesObject = claims.get(roleClaimKeyAuth0);
        if (rolesObject instanceof List<?>) {
            return ((List<?>) rolesObject).stream()
                    .filter(item -> item instanceof String)
                    .map(item -> (String) item)
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()))
                    .toList();
        }
        
        // Default to USER role if no roles found
        return Lists.newArrayList(new SimpleGrantedAuthority("ROLE_USER"));
    }

    /**
     * JwtDecoder for Auth0 with audience validation
     */
    @Bean
    public JwtDecoder jwtDecoder() {
        NimbusJwtDecoder jwtDecoderAuth0 = null;
        try {
            jwtDecoderAuth0 = JwtDecoders.fromOidcIssuerLocation("https://" + issuerAuth0 + "/");
            jwtDecoderAuth0.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                    JwtValidators.createDefaultWithIssuer("https://" + issuerAuth0 + "/"),
                    AudienceValidator.builder().audiences(Set.of(audienceAuth0)).build()
            ));
        } catch (Exception e) {
            log.error("Failed to create Auth0 JwtDecoder", e);
        }

        NimbusJwtDecoder finalJwtDecoderAuth0 = jwtDecoderAuth0;
        return new JwtDecoder() {
            @Override
            public Jwt decode(String token) throws JwtException {
                if (finalJwtDecoderAuth0 == null) {
                    throw new JwtException("JWT Decoder not properly configured");
                }
                return finalJwtDecoderAuth0.decode(token);
            }
        };
    }

    @Data
    @Builder
    static class AudienceValidator implements OAuth2TokenValidator<Jwt> {
        private Set<String> audiences;

        @Override
        public OAuth2TokenValidatorResult validate(Jwt jwt) {
            for (String aud : jwt.getAudience()) {
                if (audiences.contains(aud)) {
                    return OAuth2TokenValidatorResult.success();
                }
            }
            return OAuth2TokenValidatorResult
                    .failure(new OAuth2Error("audience_mismatch", "Expected audience: " + audiences, null));
        }
    }
}