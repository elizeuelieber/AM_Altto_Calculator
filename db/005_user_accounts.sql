-- Contas locais do sistema e senhas derivadas com scrypt (80 bytes binários: salt + hash).
-- Aplicar uma vez no banco am_altto_calculator antes de iniciar a nova versão.
CREATE TABLE IF NOT EXISTS altto_app_users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(60) NOT NULL UNIQUE,
  display_name VARCHAR(120) NOT NULL,
  role ENUM('admin','seller') NOT NULL,
  password_hash BINARY(80) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_altto_users_role_active (role,is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Mantém compatibilidade com a tabela atual de cotações. O owner existente guarda
-- o nome do usuário; a aplicação consulta nome e login para acomodar registros antigos.
