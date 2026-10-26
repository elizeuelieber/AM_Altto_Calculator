-- Esboço da configuração de catálogo para migração futura a MySQL.
-- Não aplicado pelo MVP: banco/MySQL da arquitetura depende do schema existente
-- e do contexto AGENT_DATABASE_CONTEXT.md, que não foi anexado nesta conversa.
CREATE TABLE IF NOT EXISTS commercial_catalog_seed (
  sku VARCHAR(80) PRIMARY KEY,
  product_line VARCHAR(60) NOT NULL,
  product_name VARCHAR(120) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  unit_cost DECIMAL(12,4) NOT NULL,
  price_resale DECIMAL(12,2) NOT NULL,
  price_retail DECIMAL(12,2) NOT NULL,
  price_installer DECIMAL(12,2) NOT NULL,
  effective_from DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Não carregue os dados desta planilha em operação sem revisão e aprovação comercial/contábil.
