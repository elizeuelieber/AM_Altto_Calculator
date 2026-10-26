-- Cadastro autônomo e regras comerciais versionadas para a Calculadora Altto.
-- Requer o schema inicial 002_initial_schema.sql previamente aplicado.
-- Não popula valores fiscais, custos, preços ou margens: cadastre apenas premissas aprovadas.

ALTER TABLE customers
  ADD COLUMN sales_channel_id BIGINT UNSIGNED NULL AFTER is_active,
  ADD KEY ix_customers_sales_channel (sales_channel_id),
  ADD CONSTRAINT fk_customers_sales_channel
    FOREIGN KEY (sales_channel_id) REFERENCES sales_channels(id)
    ON UPDATE CASCADE ON DELETE RESTRICT;

INSERT INTO sales_channels (code, name, is_active)
VALUES ('instalador', 'Instalador', TRUE), ('revendedor', 'Revendedor', TRUE), ('lojista', 'Lojista', TRUE)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- O mínimo e o alvo são derivados do CPV e dos parâmetros vigentes.
-- product_cost_versions, product_price_versions e pricing_parameter_versions
-- existentes guardam histórico de vigência e não devem ser sobrescritos.

ALTER TABLE quotes
  ADD COLUMN min_expected_amount DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER delivery_freight_amount,
  ADD COLUMN max_expected_amount DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER min_expected_amount;

ALTER TABLE quote_items
  ADD COLUMN min_expected_unit_price DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER final_unit_price,
  ADD COLUMN max_expected_unit_price DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER min_expected_unit_price,
  ADD COLUMN min_expected_line_amount DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER max_expected_unit_price,
  ADD COLUMN max_expected_line_amount DECIMAL(14,4) NOT NULL DEFAULT 0 AFTER min_expected_line_amount;

-- Tabela operacional isolada do schema de negócio: conserva snapshots comerciais
-- enquanto o restante das tabelas quotes/quote_items é preparado para integração futura.
CREATE TABLE IF NOT EXISTS altto_app_quotes (
  id VARCHAR(40) NOT NULL PRIMARY KEY,
  owner VARCHAR(60) NOT NULL,
  status VARCHAR(24) NOT NULL,
  total DECIMAL(14,2) NOT NULL,
  signal_color VARCHAR(10) NOT NULL,
  created_at DATETIME(3) NOT NULL,
  payload JSON NOT NULL,
  INDEX idx_altto_quotes_owner_created (owner, created_at),
  INDEX idx_altto_quotes_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
