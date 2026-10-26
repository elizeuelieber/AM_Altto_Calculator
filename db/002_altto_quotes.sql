-- Tabela isolada da aplicação; não altera tabelas existentes do banco.
-- Revise a convenção de nomenclatura antes de aplicar em qualquer ambiente.
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
