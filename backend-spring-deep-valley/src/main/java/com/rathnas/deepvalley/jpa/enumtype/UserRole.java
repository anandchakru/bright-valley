package com.rathnas.deepvalley.jpa.enumtype;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.apache.commons.lang3.StringUtils;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

public enum UserRole {
    ROOT("root"),
    ADMIN("admin"), 
    USER("user");
    
    private final String value;
    
    UserRole(String value) {
        this.value = value;
    }
    
    public String getValue() {
        return value;
    }
    
    public static UserRole fromValue(String value) {
        for (UserRole role : UserRole.values()) {
            if (role.getValue().equalsIgnoreCase(value)) {
                return role;
            }
        }
        throw new IllegalArgumentException("Invalid UserRole value: " + value);
    }
    
    @jakarta.persistence.Converter(autoApply = true)
    public static class Converter implements AttributeConverter<List<UserRole>, String> {
        
        private static final String DELIMITER = ",";
        
        @Override
        public String convertToDatabaseColumn(List<UserRole> roles) {
            if (roles == null || roles.isEmpty()) {
                return null;
            }
            return roles.stream()
                    .map(UserRole::getValue)
                    .collect(Collectors.joining(DELIMITER));
        }
        
        @Override
        public List<UserRole> convertToEntityAttribute(String rolesString) {
            if (StringUtils.isBlank(rolesString)) {
                return Collections.emptyList();
            }
            return Arrays.stream(rolesString.split(DELIMITER))
                    .map(String::trim)
                    .filter(StringUtils::isNotBlank)
                    .map(UserRole::fromValue)
                    .collect(Collectors.toList());
        }
    }
}