package com.rathnas.deepvalley.controller.admin;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/admin/v1")
public class AdminController {

    @GetMapping("/users")
    public ResponseEntity<java.util.List<Map<String, Object>>> getAllUsers(@AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(java.util.List.of(
            Map.of(
                "id", "1",
                "name", "John Doe",
                "email", "john@example.com",
                "roles", java.util.List.of("user"),
                "isActive", true,
                "createdAt", "2024-01-01",
                "updatedAt", "2024-01-01"
            ),
            Map.of(
                "id", "2",
                "name", "Jane Smith",
                "email", "jane@example.com",
                "roles", java.util.List.of("admin"),
                "isActive", true,
                "createdAt", "2024-01-01",
                "updatedAt", "2024-01-01"
            )
        ));
    }
}