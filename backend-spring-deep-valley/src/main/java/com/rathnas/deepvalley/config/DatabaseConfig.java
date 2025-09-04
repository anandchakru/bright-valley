package com.rathnas.deepvalley.config;

import liquibase.integration.spring.SpringLiquibase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

@Slf4j
@Configuration
public class DatabaseConfig {
    
    @Value("${spring.datasource.url}")
    private String jdbcUrl;

    @Value("${spring.datasource.username}")
    private String username;

    @Value("${spring.datasource.password}")
    private String password;

    @Value("${spring.liquibase.default-schema}")
    private String schema;

    @Bean
    public SpringLiquibase liquibase(DataSource dataSource) {
        createSchema();
        SpringLiquibase liquibase = new SpringLiquibase();
        liquibase.setDataSource(dataSource);
        liquibase.setDefaultSchema(schema);
        liquibase.setChangeLog("classpath:db/changelog/db.changelog-master.yaml");
        return liquibase;
    }

    private void createSchema() {
        String baseUrl = jdbcUrl.replaceAll("(?i)[?&]currentSchema=[^&]*", "");
        if (baseUrl.contains("?")) {
            baseUrl = baseUrl + "&currentSchema=public";
        } else {
            baseUrl = baseUrl + "?currentSchema=public";
        }
        
        try (Connection conn = DriverManager.getConnection(baseUrl, username, password)) {
            // Explicitly manage transaction
            conn.setAutoCommit(false);
            
            try (Statement stmt = conn.createStatement()) {
                
                log.info("Creating schema: {}", schema);
                stmt.execute("CREATE SCHEMA IF NOT EXISTS " + schema);
                log.info("Schema {} created successfully", schema);
                
                // Grant proper permissions
                stmt.execute("GRANT USAGE ON SCHEMA " + schema + " TO \"" + username + "\"");
                stmt.execute("GRANT CREATE ON SCHEMA " + schema + " TO \"" + username + "\"");
                stmt.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA " + schema + " TO \"" + username + "\"");
                stmt.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA " + schema + " TO \"" + username + "\"");
                stmt.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA " + schema + " GRANT ALL ON TABLES TO \"" + username + "\"");
                stmt.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA " + schema + " GRANT ALL ON SEQUENCES TO \"" + username + "\"");
                log.info("Granted permissions on schema {} to user {}", schema, username);
                
                // Create necessary extensions in the schema
                stmt.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" SCHEMA " + schema);
                stmt.execute("CREATE EXTENSION IF NOT EXISTS \"pg_trgm\" SCHEMA " + schema);
                log.info("PostgreSQL extensions created in schema: {}", schema);
                
                // Explicitly commit the transaction
                conn.commit();
                log.info("Schema creation transaction committed successfully");
                
            } catch (SQLException e) {
                // Rollback on error
                try {
                    conn.rollback();
                    log.error("Schema creation transaction rolled back due to error", e);
                } catch (SQLException rollbackEx) {
                    log.error("Failed to rollback schema creation transaction", rollbackEx);
                }
                throw e;
            }
            
        } catch (SQLException e) {
            log.error("Failed to create schema: {}", schema, e);
            throw new RuntimeException("Failed to create schema: " + schema, e);
        }
    }
}