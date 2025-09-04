package com.rathnas.deepvalley.jpa.entity;

import com.rathnas.deepvalley.model.User;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@MappedSuperclass
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public abstract class BaseEntity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;
    
    @Builder.Default
    @Column(name = "deleted")
    private Boolean deleted = false;
    
    @Column(name = "delete_reason")
    private String deleteReason;
    
    @Column(name = "tenant_id")
    private String tenantId;
    
    @Column(name = "created_at")
    private Long createdAt;
    
    @Column(name = "modified_at")
    private Long modifiedAt;
    
    @Column(name = "created_by")
    private String createdBy;
    
    @Column(name = "modified_by")
    private String modifiedBy;
    
    @Column(name = "slug", unique = true, nullable = false, insertable = false, updatable = false)
    private String slug;
    
    
    @PrePersist
    public void prePersist() {
        long now = System.currentTimeMillis();
        String user = getLoggedUser();

        createdAt = now;
        createdBy = user;
        
        modifiedAt = now;
        modifiedBy = user;
        
        if (deleted == null) {
            deleted = false;
        }
    }
    
    @PreUpdate
    public void preUpdate() {
        modifiedAt = System.currentTimeMillis();
        modifiedBy = getLoggedUser();
    }

    private String getLoggedUser() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null) {
                return "~";
            }
            if (auth instanceof JwtAuthenticationToken jwt) {
                return jwt.getName();
            }
            if (auth.getPrincipal() instanceof User user) {
                return user.getEmail();
            }
            return "~";
        } catch (Exception e) {
            return "~";
        }
    }
}