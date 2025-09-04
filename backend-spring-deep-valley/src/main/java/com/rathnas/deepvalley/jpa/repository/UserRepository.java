package com.rathnas.deepvalley.jpa.repository;

import com.rathnas.deepvalley.jpa.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, Long> {
    
    Optional<UserEntity> findByEmailAndDeletedFalse(String email);
    
    Optional<UserEntity> findByExternalAuthProviderAndExternalAuthIdAndDeletedFalse(
            String provider, String externalId);
    
    Optional<UserEntity> findBySlugAndDeletedFalse(String slug);
    
    List<UserEntity> findByTenantIdAndDeletedFalse(String tenantId);
    
    @Query("SELECT u FROM UserEntity u WHERE u.deleted = false AND u.roles LIKE %:role%")
    List<UserEntity> findByRoleAndDeletedFalse(@Param("role") String role);
    
    boolean existsByEmailAndDeletedFalse(String email);
    
    boolean existsBySlugAndDeletedFalse(String slug);
}