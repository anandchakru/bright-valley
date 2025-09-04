package com.rathnas.deepvalley.jpa.entity;

import com.rathnas.deepvalley.jpa.enumtype.UserRole;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.SuperBuilder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "deep-valley_user")
public class UserEntity extends BaseEntity {
    
    @Column(name = "external_auth_provider")
    private String externalAuthProvider;
    
    @Column(name = "external_auth_id")
    private String externalAuthId;
    
    @Column(name = "picture")
    private String picture;
    
    @Column(name = "email")
    private String email;
    
    @Column(name = "first_name")
    private String firstName;
    
    @Column(name = "last_name")
    private String lastName;
    
    @Column(name = "full_name")
    private String fullName;
    
    @Convert(converter = UserRole.Converter.class)
    @Column(name = "roles")
    private List<UserRole> roles;
    
    @PrePersist
    @PreUpdate
    public void updateFullName() {
        if (firstName != null || lastName != null) {
            fullName = String.format("%s %s", 
                firstName != null ? firstName : "",
                lastName != null ? lastName : "").trim();
        }
        super.prePersist();
    }
}