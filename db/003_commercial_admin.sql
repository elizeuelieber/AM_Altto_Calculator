-- Cadastros comerciais e regras de preço para cotações.
-- Aplicar uma vez ao banco am_altto_calculator usando credencial autorizada.
-- Se o usuário MySQL da aplicação for separado, conceda SELECT/INSERT/UPDATE para clientes e produtos,
-- SELECT para preços e INSERT/UPDATE para preços (o CRUD de preço usa transações de aplicação).
CREATE TABLE IF NOT EXISTS altto_app_clients (
  id CHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  channel ENUM('Instalador','Revendedor','Lojista') NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_altto_clients_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS altto_app_products (
  id CHAR(36) NOT NULL PRIMARY KEY,
  sku VARCHAR(80) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  unit VARCHAR(24) NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS altto_app_prices (
  product_id CHAR(36) NOT NULL,
  channel ENUM('Instalador','Revendedor','Lojista') NOT NULL,
  table_price DECIMAL(14,2) NOT NULL,
  minimum_price DECIMAL(14,2) NOT NULL,
  target_price DECIMAL(14,2) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id, channel),
  CONSTRAINT fk_altto_prices_product FOREIGN KEY (product_id) REFERENCES altto_app_products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

