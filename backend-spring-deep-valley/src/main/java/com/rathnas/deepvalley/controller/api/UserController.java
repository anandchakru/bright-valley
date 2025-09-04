package com.rathnas.deepvalley.controller.api;

import com.rathnas.deepvalley.model.User;
import com.rathnas.deepvalley.jpa.entity.UserEntity;
import com.rathnas.deepvalley.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/v1/user")
@RequiredArgsConstructor
public class UserController {
    
    private final UserService userService;
    
    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> getUserProfile(@AuthenticationPrincipal User user) {
        try {
            Optional<UserEntity> userOpt = userService.findByEmail(user.getEmail());
            
            if (userOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            UserEntity userEntity = userOpt.get();
            return ResponseEntity.ok(Map.of(
                    "id", userEntity.getId(),
                    "email", userEntity.getEmail(),
                    "firstName", userEntity.getFirstName() != null ? userEntity.getFirstName() : "",
                    "lastName", userEntity.getLastName() != null ? userEntity.getLastName() : "",
                    "fullName", userEntity.getFullName() != null ? userEntity.getFullName() : "",
                    "picture", userEntity.getPicture() != null ? userEntity.getPicture() : "",
                    "roles", userEntity.getRoles(),
                    "slug", userEntity.getSlug(),
                    "createdAt", userEntity.getCreatedAt(),
                    "modifiedAt", userEntity.getModifiedAt()
            ));
            
        } catch (Exception e) {
            log.error("Error getting user profile", e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to get user profile", "message", e.getMessage()));
        }
    }
    
    @GetMapping("/profile/{slug}")
    public ResponseEntity<Map<String, Object>> getUserProfileBySlug(@PathVariable String slug) {
        try {
            Optional<UserEntity> userOpt = userService.findBySlug(slug);
            
            if (userOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            UserEntity user = userOpt.get();
            return ResponseEntity.ok(Map.of(
                    "id", user.getId(),
                    "email", user.getEmail(),
                    "firstName", user.getFirstName() != null ? user.getFirstName() : "",
                    "lastName", user.getLastName() != null ? user.getLastName() : "",
                    "fullName", user.getFullName() != null ? user.getFullName() : "",
                    "picture", user.getPicture() != null ? user.getPicture() : "",
                    "roles", user.getRoles(),
                    "slug", user.getSlug(),
                    "createdAt", user.getCreatedAt()
            ));
            
        } catch (Exception e) {
            log.error("Error getting user profile by slug: {}", slug, e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", "Failed to get user profile", "message", e.getMessage()));
        }
    }
}