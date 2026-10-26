CREATE TABLE app_schema_migrations (
    version VARCHAR(100) NOT NULL PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(160) NOT NULL,
    email VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE product_lines (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(60) NOT NULL,
    name VARCHAR(120) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_product_lines_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE products (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_line_id BIGINT UNSIGNED NOT NULL,
    erp_product_id VARCHAR(100) NULL,
    sku VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    sales_unit VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    source_updated_at DATETIME NULL,
    synced_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_products_sku (sku),
    UNIQUE KEY uq_products_erp_id (erp_product_id),
    KEY ix_products_line_active (product_line_id, is_active),
    CONSTRAINT fk_products_line FOREIGN KEY (product_line_id) REFERENCES product_lines(id),
    CONSTRAINT ck_products_sales_unit CHECK (sales_unit IN ('m2', 'barra'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE sales_channels (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(60) NOT NULL,
    name VARCHAR(120) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_sales_channels_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Valores versionados por vigência; não sobrescrever versões usadas em cotações.
CREATE TABLE product_cost_versions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    kg_per_unit DECIMAL(14,6) NULL,
    raw_material_cost_per_kg DECIMAL(14,4) NULL,
    inbound_freight_per_kg DECIMAL(14,4) NOT NULL DEFAULT 0,
    packaging_cost_per_unit DECIMAL(14,4) NOT NULL DEFAULT 0,
    labor_structure_cost_per_unit DECIMAL(14,4) NOT NULL DEFAULT 0,
    cpv_per_unit DECIMAL(14,4) NOT NULL,
    source VARCHAR(40) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    UNIQUE KEY uq_product_cost_valid_from (product_id, valid_from),
    KEY ix_product_cost_validity (product_id, valid_from, valid_to),
    CONSTRAINT fk_product_cost_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_product_cost_user FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT ck_product_cost_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ck_product_cost_cpv CHECK (cpv_per_unit >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE product_price_versions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    sales_channel_id BIGINT UNSIGNED NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    price_per_unit DECIMAL(14,4) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'BRL',
    source VARCHAR(40) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    UNIQUE KEY uq_product_channel_price_start (product_id, sales_channel_id, valid_from),
    KEY ix_product_channel_price_validity (product_id, sales_channel_id, valid_from, valid_to),
    CONSTRAINT fk_price_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_price_channel FOREIGN KEY (sales_channel_id) REFERENCES sales_channels(id),
    CONSTRAINT fk_price_user FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT ck_product_price_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ck_product_price_nonnegative CHECK (price_per_unit >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Parâmetros comerciais gerais versionados. Criar dados só após validação contábil/comercial.
CREATE TABLE pricing_parameter_versions (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    valid_from DATE NOT NULL,
    valid_to DATE NULL,
    tax_rate DECIMAL(9,6) NOT NULL,
    sales_commission_rate DECIMAL(9,6) NOT NULL DEFAULT 0,
    fixed_cost_allocation_rate DECIMAL(9,6) NOT NULL DEFAULT 0,
    minimum_gross_margin_rate DECIMAL(9,6) NOT NULL,
    target_gross_margin_rate DECIMAL(9,6) NOT NULL,
    delivery_freight_default DECIMAL(14,4) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT UNSIGNED NULL,
    UNIQUE KEY uq_pricing_parameters_valid_from (valid_from),
    CONSTRAINT fk_pricing_parameters_user FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT ck_pricing_parameter_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ck_pricing_rates CHECK (
        tax_rate BETWEEN 0 AND 1 AND
        sales_commission_rate BETWEEN 0 AND 1 AND
        fixed_cost_allocation_rate BETWEEN 0 AND 1 AND
        minimum_gross_margin_rate BETWEEN 0 AND 1 AND
        target_gross_margin_rate BETWEEN 0 AND 1 AND
        target_gross_margin_rate >= minimum_gross_margin_rate
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE customers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    erp_customer_id VARCHAR(100) NULL,
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(240) NULL,
    tax_id VARCHAR(32) NULL,
    email VARCHAR(254) NULL,
    phone VARCHAR(40) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    source_updated_at DATETIME NULL,
    synced_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_customers_erp_id (erp_customer_id),
    KEY ix_customers_name (name),
    KEY ix_customers_tax_id (tax_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE quotes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    quote_number VARCHAR(40) NOT NULL,
    customer_id BIGINT UNSIGNED NULL,
    created_by BIGINT UNSIGNED NOT NULL,
    pricing_parameter_version_id BIGINT UNSIGNED NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'draft',
    quoted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NULL,
    currency CHAR(3) NOT NULL DEFAULT 'BRL',
    delivery_freight_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    gross_revenue_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    cpv_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    commission_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    gross_profit_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    contribution_margin_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    contribution_margin_rate DECIMAL(9,6) NULL,
    estimated_result_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    customer_name_snapshot VARCHAR(200) NULL,
    notes TEXT NULL,
    erp_order_id VARCHAR(100) NULL,
    erp_sync_status VARCHAR(24) NOT NULL DEFAULT 'not_requested',
    erp_sync_error TEXT NULL,
    erp_synced_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_quotes_number (quote_number),
    UNIQUE KEY uq_quotes_erp_order (erp_order_id),
    KEY ix_quotes_customer_date (customer_id, quoted_at),
    KEY ix_quotes_status_date (status, quoted_at),
    KEY ix_quotes_erp_sync (erp_sync_status, updated_at),
    CONSTRAINT fk_quotes_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
    CONSTRAINT fk_quotes_user FOREIGN KEY (created_by) REFERENCES users(id),
    CONSTRAINT fk_quotes_parameters FOREIGN KEY (pricing_parameter_version_id) REFERENCES pricing_parameter_versions(id),
    CONSTRAINT ck_quotes_status CHECK (status IN ('draft', 'submitted', 'approved', 'rejected', 'cancelled')),
    CONSTRAINT ck_quotes_erp_sync CHECK (erp_sync_status IN ('not_requested', 'pending', 'processing', 'sent', 'confirmed', 'failed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE quote_items (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    quote_id BIGINT UNSIGNED NOT NULL,
    line_number SMALLINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NULL,
    product_cost_version_id BIGINT UNSIGNED NULL,
    product_price_version_id BIGINT UNSIGNED NULL,
    sales_channel_id BIGINT UNSIGNED NULL,
    product_sku_snapshot VARCHAR(100) NULL,
    product_name_snapshot VARCHAR(200) NOT NULL,
    product_line_snapshot VARCHAR(120) NULL,
    sales_unit_snapshot VARCHAR(20) NOT NULL,
    sales_channel_snapshot VARCHAR(120) NULL,
    quantity DECIMAL(14,4) NOT NULL,
    list_unit_price DECIMAL(14,4) NOT NULL,
    discount_rate DECIMAL(9,6) NOT NULL DEFAULT 0,
    negotiated_unit_price DECIMAL(14,4) NULL,
    final_unit_price DECIMAL(14,4) NOT NULL,
    tax_rate_snapshot DECIMAL(9,6) NOT NULL,
    commission_rate_snapshot DECIMAL(9,6) NOT NULL DEFAULT 0,
    cpv_unit_snapshot DECIMAL(14,4) NOT NULL,
    gross_revenue_amount DECIMAL(14,4) NOT NULL,
    tax_amount DECIMAL(14,4) NOT NULL,
    cpv_amount DECIMAL(14,4) NOT NULL,
    commission_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    gross_profit_amount DECIMAL(14,4) NOT NULL,
    gross_margin_rate DECIMAL(9,6) NULL,
    delivery_freight_amount DECIMAL(14,4) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_quote_items_line (quote_id, line_number),
    KEY ix_quote_items_product (product_id),
    CONSTRAINT fk_quote_items_quote FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE,
    CONSTRAINT fk_quote_items_product FOREIGN KEY (product_id) REFERENCES products(id),
    CONSTRAINT fk_quote_items_cost_version FOREIGN KEY (product_cost_version_id) REFERENCES product_cost_versions(id),
    CONSTRAINT fk_quote_items_price_version FOREIGN KEY (product_price_version_id) REFERENCES product_price_versions(id),
    CONSTRAINT fk_quote_items_channel FOREIGN KEY (sales_channel_id) REFERENCES sales_channels(id),
    CONSTRAINT ck_quote_items_quantity CHECK (quantity > 0),
    CONSTRAINT ck_quote_items_discount CHECK (discount_rate BETWEEN 0 AND 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Fila durável para integração assíncrona com n8n/ERP; consumir via API, não por acesso direto às tabelas.
CREATE TABLE integration_outbox (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(60) NOT NULL,
    aggregate_id BIGINT UNSIGNED NOT NULL,
    idempotency_key VARCHAR(160) NOT NULL,
    payload JSON NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    attempts SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    available_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    locked_at DATETIME NULL,
    last_error TEXT NULL,
    processed_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_outbox_idempotency (idempotency_key),
    KEY ix_outbox_ready (status, available_at),
    CONSTRAINT ck_outbox_status CHECK (status IN ('pending', 'processing', 'sent', 'failed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Registro de eventos recebidos do n8n/ERP para deduplicação e auditoria de processamento.
CREATE TABLE integration_inbox (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(60) NOT NULL,
    provider_event_id VARCHAR(160) NOT NULL,
    entity_type VARCHAR(60) NOT NULL,
    source_entity_id VARCHAR(100) NULL,
    payload JSON NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'received',
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at DATETIME NULL,
    last_error TEXT NULL,
    UNIQUE KEY uq_inbox_provider_event (provider, provider_event_id),
    KEY ix_inbox_status_received (status, received_at),
    CONSTRAINT ck_inbox_status CHECK (status IN ('received', 'processing', 'processed', 'failed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO app_schema_migrations (version)
VALUES ('002_initial_schema');