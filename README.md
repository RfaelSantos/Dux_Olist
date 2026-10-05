# DUX Olist — Análise de Dados de E-commerce

Projeto desenvolvido para análise de dados do e-commerce brasileiro da Olist, contemplando **pipeline de dados, validação de qualidade, análises SQL, dashboard em Power BI e geração de insights de negócio**.

---

## Estrutura do projeto

```text
Dux_Olist/
│
├── BI/
│   ├── DUX_Olist_Dashboard.pbix
│   ├── background_pagina_1.png
│   └── background_pagina_2.png
│
├── Data/
│   ├── olist_customers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   └── product_category_name_translation.csv
│
├── Perguntas/
│   ├── Pergunta_a.sql
│   ├── Pergunta_b.sql
│   ├── Pergunta_c.sql
│   └── Pergunta_d.sql
│
├── Pipeline/
│   ├── Dux_Olist_Data_quality.sql
│   ├── Dux_Olist_Load.py
│   └── Dux_Olist_Tables.sql
│
└── Insights e Oportunidades de Negócio.pdf
```

---

## Tecnologias utilizadas

- **Python**
  - Pandas
  - PyODBC
- **SQL Server**
- **SQL**
- **Power BI**
- **DAX**

---

## Fonte dos dados

O projeto utiliza o dataset **Brazilian E-Commerce Public Dataset by Olist**, contendo informações sobre pedidos, clientes, produtos, vendedores, pagamentos, avaliações e localização.

Os arquivos utilizados na análise estão disponíveis na pasta `Data`.

---

## Pipeline de dados

O pipeline foi estruturado em três etapas principais:

### 1. Criação das tabelas

Arquivo:

```text
Pipeline/Dux_Olist_Tables.sql
```

Responsável pela criação das tabelas utilizadas no banco de dados SQL Server.

### 2. Carga dos dados

Arquivo:

```text
Pipeline/Dux_Olist_Load.py
```

O script utiliza Pandas para leitura dos arquivos CSV e PyODBC para carregamento dos dados no SQL Server.

A carga é realizada em chunks para reduzir o consumo de memória durante a importação dos arquivos.

### 3. Data Quality

Arquivo:

```text
Pipeline/Dux_Olist_Data_quality.sql
```

Antes das análises, foram realizadas validações de qualidade dos dados, incluindo verificações de:

- duplicidades;
- integridade dos registros;
- pedidos sem itens;
- pedidos sem pagamento;
- inconsistências temporais;
- datas de entrega;
- diferenças entre prazo estimado e entrega efetiva;
- identificação de outliers.

Os resultados dessas validações foram considerados antes da realização das análises de negócio.

---

## Configuração do SQL Server

O projeto utiliza SQL Server com autenticação do Windows.

Antes de executar o pipeline, ajuste as configurações no arquivo:

```text
Pipeline/Dux_Olist_Load.py
```

Exemplo:

```python
SERVER = r"localhost\SQLEXPRESS"
DATABASE = "DUX_olist"
```

Substitua `SERVER` pela instância do SQL Server disponível no ambiente local.

O banco de dados utilizado pelo projeto é:

```text
DUX_olist
```

### Diretório dos dados

Os arquivos CSV devem permanecer dentro da pasta:

```text
Dux_Olist/Data/
```

O script utiliza o diretório do próprio projeto para localizar os arquivos, evitando caminhos absolutos específicos do computador do usuário.

---

## Execução

A sequência recomendada para reproduzir o projeto é:

### 1. Criar as tabelas

Executar:

```text
Pipeline/Dux_Olist_Tables.sql
```

### 2. Configurar e executar a carga

Ajustar `SERVER` no:

```text
Pipeline/Dux_Olist_Load.py
```

e executar o script.

### 3. Executar as validações de Data Quality

Executar:

```text
Pipeline/Dux_Olist_Data_quality.sql
```

### 4. Executar as análises

As respostas das questões estão organizadas individualmente:

```text
Perguntas/Pergunta_a.sql
Perguntas/Pergunta_b.sql
Perguntas/Pergunta_c.sql
Perguntas/Pergunta_d.sql
```

Cada arquivo contém a consulta correspondente e sua documentação.

---

## Power BI

O dashboard está disponível em:

```text
BI/DUX_Olist_Dashboard.pbix
```

O relatório possui duas páginas:

### Página 1 — Desempenho comercial e evolução das vendas

Apresenta:

- Faturamento;
- Pedidos;
- Ticket médio;
- Clientes;
- Participação do frete;
- Evolução mensal do faturamento;
- Evolução mensal dos pedidos;
- Faturamento por categoria;
- Faturamento por estado.

### Página 2 — Comportamento dos clientes e desempenho logístico

Apresenta:

- Clientes recorrentes;
- Percentual de clientes recorrentes;
- Tempo médio de entrega por estado;
- Participação do frete por estado;
- Pedidos atrasados por estado.

As métricas utilizadas no Power BI seguem as mesmas regras de negócio estabelecidas e validadas nas análises SQL.

---

## Insights e oportunidades de negócio

A análise dos dados resultou em quatro principais linhas de investigação:

1. **Baixa recorrência de clientes** — apenas 3,21% dos clientes foram classificados como recorrentes, indicando uma possível oportunidade de estratégias de retenção e recompra.

2. **Experiência do cliente e avaliações** — o cruzamento entre avaliações e indicadores logísticos pode ajudar a investigar fatores associados a experiências insatisfatórias.

3. **Oportunidade logística no Norte e Nordeste** — diversos estados apresentam níveis elevados de tempo de entrega, participação do frete e pedidos atrasados, indicando uma oportunidade para avaliar alternativas de melhoria logística.

4. **São Paulo: desempenho comercial e logística** — São Paulo concentra o maior faturamento e apresenta indicadores logísticos favoráveis. Essa relação é tratada como uma hipótese a ser investigada, e não como uma relação causal comprovada.

A documentação completa dos insights, recomendações e limitações está disponível em:

```text
Insights e Oportunidades de Negócio.pdf
```

---

## Limitações

Os dados permitem identificar **padrões e associações**, mas não permitem estabelecer relações de causalidade entre os indicadores analisados.

As hipóteses e recomendações apresentadas devem ser validadas por análises adicionais antes de decisões de implementação.

---

## Reprodutibilidade

Para reproduzir o projeto em outro ambiente:

1. manter a estrutura de pastas;
2. disponibilizar os arquivos CSV na pasta `Data`;
3. configurar a instância local do SQL Server no `Dux_Olist_Load.py`;
4. executar a criação das tabelas;
5. executar a carga dos dados;
6. executar as validações de qualidade;
7. executar as análises SQL;
8. abrir o arquivo do Power BI para exploração dos resultados.

O projeto evita dependências de caminhos absolutos para os arquivos de dados, permitindo que a pasta `Dux_Olist` seja movida para outro diretório ou computador sem necessidade de alterar os caminhos dos CSVs.
