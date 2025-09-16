package com.example.investmentdatastreamservice.config;

import javax.sql.DataSource;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import com.zaxxer.hikari.HikariDataSource;

/**
 * Конфигурация дополнительного пула подключений (stream) для высоконагруженных записей.
 */
@Configuration
public class AdditionalDataSourceConfig {

    @Bean
    @ConfigurationProperties("spring.datasource.stream")
    public DataSourceProperties streamDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean(name = "streamDataSource")
    public DataSource streamDataSource(DataSourceProperties streamDataSourceProperties) {
        return streamDataSourceProperties.initializeDataSourceBuilder().type(HikariDataSource.class)
                .build();
    }

    @Bean(name = "streamJdbcTemplate")
    public JdbcTemplate streamJdbcTemplate(DataSource streamDataSource) {
        return new JdbcTemplate(streamDataSource);
    }
}


