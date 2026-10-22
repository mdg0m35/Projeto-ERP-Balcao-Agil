# 🏢 Balcão Ágil - SaaS ERP & PDV para Materiais de Construção

Sistema completo de gestão comercial (ERP / PDV) voltado para depósitos de materiais de construção, madeireiras e marcenarias. A aplicação soluciona desafios do varejo físico através de controle logístico de entregas por peso, cálculo dinâmico de ponto de equilíbrio financeiro e fechamento ágil de vendas.

---
## 🌐 Demonstração Online

Aceda à versão em produção para avaliar a aplicação em funcionamento:

* **Link da Aplicação:** [https://balcaoagil1408.mdgomesapps.workers.dev/](https://balcaoagil1408.mdgomesapps.workers.dev/)
* **Utilizador / E-mail:** `admin.demo@balcaoagil.com`
* **Palavra-passe:** `demo123456`
* **Perfil:** Administrador Geral
* **Loja Modelo:** Loja Modelo - Demonstração ERP
---

## 🚀 Principais Funcionalidades

### 🛒 1. PDV & Balcão Ágil
* Interface visual intuitiva com categorização por departamentos (Básicos, Acabamento, Hidráulica, etc.).
* Campo de busca em tempo real por nome do material ou produto.
* Carrinho dinâmico com ajuste rápido de quantidades e inclusão de observações por item.
* Controle de estoque integrado com baixa automática no momento da venda.
* Cálculo automático do peso total da compra para estimativa precisa de frete.

### 📄 2. Gestão de Orçamentos & WhatsApp
* Emissão de orçamentos com validade personalizada e desconto escalonado.
* Envio do resumo formatado diretamente para o WhatsApp do cliente com um clique.
* Geração de documentos em PDF para impressão térmica ou padrão A4.

### 🚚 3. Logística & Entregas Fracionadas (Obra)
* Controle de pedidos com entregas parciais programadas por data.
* Painel de separação indicando saldo restante e histórico de remessas entregues.
* Registro de peso acumulado da carga para dimensionamento de freteiros e carretos.

### 📊 4. Engenharia de Preços & Ponto de Equilíbrio
* Painel de monitoramento do ponto de equilíbrio com meta visual do mês.
* Sugestão orientativa de preço de venda (Markup Divisor) considerando rateio de custos fixos (aluguel, água, energia, salários).
* Projeção de retorno bruto sobre compras de lotes com fornecedores.

---

## 🛠️ Tecnologias Utilizadas

* **Frontend:** Flutter Web (Dart)
* **Gerenciamento de Estado:** Provider
* **Backend as a Service:** Supabase (PostgreSQL, Auth e Row Level Security - RLS)
* **Hospedagem & Deploy:** Cloudflare Workers / Pages
* **Bibliotecas Adicionais:** `fl_chart` (Gráficos), `pdf` & `printing` (Impressão e Documentos)

---

## 🔒 Arquitetura & Segurança

* **Multi-tenant Seguro:** Isolamento estrito de dados por loja via políticas de Row Level Security (RLS) no PostgreSQL.
* **Sessões Isoladas:** Perfis distintos para Administradores/Donos e Funcionários de balcão.

---
## 💻 Como Rodar Localmente

1. Clone o repositório:
   ```bash
   git clone [https://github.com/mdg0m35/Projeto-ERP-Balcao-Agil.git](https://github.com/mdg0m35/Projeto-ERP-Balcao-Agil.git)