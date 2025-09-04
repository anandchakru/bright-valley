package com.rathnas.deepvalley.controller.api;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class ProtectedController {

    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> getUserProfile(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(Map.of(
            "message", "This is a protected endpoint",
            "user", jwt.getSubject(),
            "claims", jwt.getClaims(),
            "auth", "required"
        ));
    }
}