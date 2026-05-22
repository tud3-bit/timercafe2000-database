# ☕ TIMERCAFE2000 — Sistema de Gestão para Lan House

> Projeto de banco de dados relacional desenvolvido para automatizar e gerenciar as operações diárias de uma Lan House, controlando o uso de computadores, tempo dos clientes, vendas de produtos e sessões de acesso.

---

## 🚀 Sobre o Projeto

O **TIMERCAFE2000** foi concebido para resolver o problema de gerenciamento de tempo e consumo em ambientes de Lan House. O sistema mapeia desde o cadastro de clientes e reserva de máquinas (estações de trabalho) até o controle de estoque de produtos (snacks, bebidas) e faturamento de sessões.

### 🛠️ Tecnologias e Ferramentas

* **Modelagem:** [Draw.io](https://app.diagrams.net/)
* **SGBD:** MySQL (versão 8.0+)
* **Ambiente de Desenvolvimento:** Visual Studio Code (VS Code)

---

## 📐 Modelagem do Banco de Dados

### 1. Diagrama Entidade-Relacionamento (DER)

![Diagrama Entidade Relacionamento] commit - DER-TIMERCAFE.pdf

### 2. Modelo Entidade-Relacionamento (MER)

![Modelo Entidade Relacionamento] commit - MER-TIMERCAFE.pdf
---

## 💾 Estrutura de Arquivos

O projeto está organizado em scripts SQL sequenciais para facilitar a implantação:

* `01_schema.sql`: Contém a estrutura do banco de dados (DDL - `CREATE DATABASE`, `CREATE TABLE`, etc.).
* `02_data.sql`: Contém a carga inicial de dados e registros de teste (DML - `INSERT INTO`).

---

## ⚡ Como Executar o Projeto

Para rodar o projeto localmente, certifique-se de ter o **MySQL Server** instalado em sua máquina.

1. **Clone o repositório:**
   
```bash
   git clone [https://github.com/seu-usuario/timercafe2000.git](https://github.com/seu-usuario/timercafe2000.git)
   cd timercafe2000
