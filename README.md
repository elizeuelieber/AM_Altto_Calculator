# Altto — Calculadora Comercial

Aplicação web responsiva e autônoma para cadastrar clientes, linhas e produtos, custos versionados, preços de tabela por canal e parâmetros gerais; criar cotações com faixa mínima/máxima esperada; e consultar o Mapa de Margens em perfil gestor. Preserva o visual Altto da versão anterior e opera sem depender de ERP ou n8n. A API permanece separada da interface para permitir integração futura.

## Áreas e regras de acesso

- **Orçamento:** visão comercial com valor, faixa mínima/máxima, itens e farol; não exibe custos nem margem.
- **Mapa de Margens:** visão restrita à gestão, com custo, preço, mínimo, alvo, resultado, margem e desconto máximo.
- **Cadastros:** clientes associados a um canal, linhas, produtos, custos por produto, preço de tabela por produto/canal e parâmetros comerciais versionados.
- **Cotações abertas:** podem ser visualizadas e editadas; vendedores alteram apenas as próprias cotações e gestores podem consultar todas. A visão simples mostra dados do pedido e itens; a composição gerencial segue restrita ao gestor.
- **Fechamento:** gestores podem fechar uma cotação como **Ganho** ou **Perdido**. Após o fechamento, a edição é bloqueada pela API; o histórico identifica responsável e data do fechamento.
- **Histórico e versões:** snapshots de valores, faixa, composição por item e parâmetros usados são guardados na cotação; futuras alterações cadastrais não alteram o que já foi salvo. Cadastros simples (cliente, linha, produto) podem ser editados. Custos, preços e parâmetros preservam versões históricas: versões de hoje/futuras podem ser ajustadas ou substituídas; novas vigências só aceitam hoje ou datas futuras.

A faixa é calculada no servidor com parâmetros ativos. O modelo de margem usa o custo unitário dividido pela parcela restante após impostos, comissão, rateio fixo e margem desejada. Esta é uma fórmula técnica configurável a validar: a planilha fornecida tem premissas e inconsistências apontadas na própria aba Auditoria. Nenhum imposto, custo, preço ou taxa da planilha foi carregado como premissa aprovada. O banco não recebe parâmetros inicialmente; o gestor deve cadastrar os valores deliberadamente aprovados antes de iniciar os cálculos.

Farol do item: vermelho abaixo do mínimo, amarelo entre mínimo e máximo, verde no máximo ou acima. No pedido, prevalece o item de situação mais crítica. O preço de tabela é cadastrado separadamente de CPV/custos.

## Banco e preparação

Requer Node.js 20+ e MySQL 8.x. Faça backup antes de qualquer alteração. A aplicação usa o schema enviado (`customers`, `sales_channels`, `product_lines`, `products`, tabelas de versões de custos/preços/parâmetros) e não cria cadastro duplicado de clientes/produtos. Em uma base nova, aplique primeiro `db/002_initial_schema.sql`, depois `db/004_standalone_commercial.sql`. Em uma base existente, verifique quais tabelas e alterações já foram aplicadas; **não reaplique `ALTER TABLE`** sem conferir, pois DDL duplicado falhará.

`db/002_initial_schema.sql` é o schema enviado como referência. `db/004_standalone_commercial.sql` associa `customers` a `sales_channels`, insere os canais padrão Instalador/Revendedor/Lojista caso não existam e adiciona colunas de faixa esperada ao schema de cotações original. A aplicação atual conserva a cotação completa e seu snapshot em `altto_app_quotes`, criada pelo mesmo SQL. Não execute a antiga `003_commercial_admin.sql` para o fluxo novo: ela cria cadastros paralelos que não são usados.

Copie `.env.example` para `.env`, informe `DB_USER`, `DB_PASSWORD`, `APP_SECRET` com pelo menos 32 caracteres aleatórios e senhas de usuários. Configure `DB_HOST`, `DB_PORT` e `DB_NAME` conforme a instância local. Instale dependências e inicie com `node --env-file=.env server.js`; abra `http://localhost:3000`. `/api/health` deve retornar `ok: true` e `mode: mysql`. A conta MySQL da aplicação precisa de SELECT/INSERT/UPDATE nas tabelas descritas pela migração.

Depois do primeiro login como gestor, cadastre: linhas e produtos; CPV para cada produto; preço de tabela por produto e canal; parâmetros gerais com sua vigência; e clientes associados aos canais. Todos os itens comerciais e parâmetros precisam de registros vigentes para liberar o cálculo.

## Demonstração

Para navegar sem MySQL, configure `DEMO_MODE=true`, defina `APP_SECRET` e uma senha forte em `DEMO_PASSWORD`, então execute o servidor. A demonstração usa dados fictícios em memória, perde os dados ao reiniciar e não deve ser usada para operação real. No modo MySQL, acesso ao banco e migrações são obrigatórios.

## Docker e VPS

No Docker Desktop, configure `DB_HOST_DOCKER=host.docker.internal`; em Linux/VPS, use o endereço do MySQL alcançável pelo contêiner. Rode `docker compose up -d --build`. Para produção, use HTTPS, `COOKIE_SECURE=true`, segredos exclusivos, firewall e backup testado; não exponha MySQL publicamente. Variáveis de novos usuários devem ser incluídas no `docker-compose.yml`.

Usuários são configurados por variáveis de ambiente, por exemplo `USER_ELIZEU_PASSWORD` com `USER_ELIZEU_ROLE=manager`; perfis sellers recebem cotações próprias e não podem chamar endpoints administrativos ou o Mapa de Margens. Gestores têm acesso ao mapa e aos cadastros.

A aplicação não integra ERP/n8n nesta fase, não inclui fluxo de aprovação formal e ainda requer validação das fórmulas e dados comerciais/fiscais por Comercial e Contabilidade antes de uso em negociação real.
