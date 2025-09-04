package com.rathnas.deepvalley.config;

import com.rathnas.deepvalley.model.User;
import lombok.Getter;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

@Getter
public class AuthToken implements Authentication {
    
    private final User user;
    private final Authentication originalAuth;
    private final Collection<? extends GrantedAuthority> authorities;
    private final String token;
    private boolean authenticated = true;
    
    public AuthToken(User user, Authentication originalAuth, 
                    Collection<? extends GrantedAuthority> authorities, String token) {
        this.user = user;
        this.originalAuth = originalAuth;
        this.authorities = authorities;
        this.token = token;
    }
    
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }
    
    @Override
    public Object getCredentials() {
        return token;
    }
    
    @Override
    public Object getDetails() {
        return user;
    }
    
    @Override
    public Object getPrincipal() {
        return user;
    }
    
    @Override
    public boolean isAuthenticated() {
        return authenticated;
    }
    
    @Override
    public void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException {
        this.authenticated = isAuthenticated;
    }
    
    @Override
    public String getName() {
        return user != null ? user.getEmail() : null;
    }
}