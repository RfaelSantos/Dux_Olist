/*
================================================================================
QUESTÃO C - TOP 3 CATEGORIAS DE PRODUTOS COM MAIOR CRESCIMENTO DE VENDAS
================================================================================

Pergunta:
    Liste as Top 3 categorias de produtos com maior crescimento de vendas
    nos últimos meses.

OBJETIVO:
    Identificar as três categorias de produtos que apresentaram o maior
    crescimento percentual de faturamento entre o primeiro e o último mês
    dos três meses mais recentes com vendas efetivamente entregues.

CRITÉRIO DE VENDAS:
    Para esta análise, "vendas" foi representado pelo faturamento.

    O faturamento é calculado a partir do campo price da tabela
    olist_order_items.

FÓRMULA:

    Crescimento (%) =
        ((Faturamento final - Faturamento inicial)
        / Faturamento inicial) * 100


METODOLOGIA:

    O cálculo foi dividido em três etapas principais:

    1. IDENTIFICAÇÃO DOS ÚLTIMOS 3 MESES

       - Utiliza a data de compra (order_purchase_timestamp)
         da tabela olist_orders.
       - São considerados somente pedidos com status "delivered".
       - Os meses são identificados dinamicamente, sem utilização de
         datas fixas.
       - Os três meses mais recentes com pedidos entregues são
         selecionados e armazenados na tabela temporária #ultimos_meses.

       Para a base analisada, os três últimos meses válidos são:

           2018/06
           2018/07
           2018/08


    2. CONSOLIDAÇÃO DO FATURAMENTO POR CATEGORIA E MÊS

       - Os pedidos dos três meses selecionados são armazenados
         em #pedidos.
       - Os pedidos são relacionados à tabela olist_order_items
         para identificar os produtos vendidos e seus respectivos preços.
       - A tabela olist_products é utilizada para identificar a categoria
         de cada produto.
       - O faturamento é calculado através da soma do campo price.
       - A quantidade de itens vendidos também é calculada como métrica
         complementar.

       O resultado é armazenado em #faturamento_categoria, contendo:

           - mês
           - categoria
           - faturamento
           - quantidade vendida


    3. CÁLCULO DO CRESCIMENTO

       Para cada categoria, são identificados:

           - faturamento inicial: faturamento do primeiro mês analisado;
           - faturamento final: faturamento do último mês analisado.

       Em seguida, é calculado o crescimento percentual entre esses
       dois períodos.

       As categorias são ordenadas pelo crescimento percentual em
       ordem decrescente e são selecionadas somente as três primeiras.


TRATAMENTO DOS PEDIDOS:

    Foram considerados somente pedidos com status "delivered".

    Essa regra foi adotada porque a análise busca representar vendas
    efetivamente realizadas/entregues.

    Pedidos com outros status, como "canceled", "shipped", "invoiced"
    ou "unavailable", não são considerados no faturamento da análise.


TRATAMENTO DAS CATEGORIAS:

    Foram desconsiderados produtos que não possuem categoria registrada
    (product_category_name IS NULL).

    Além disso, somente categorias que possuem registros nos três meses
    analisados são consideradas no cálculo do crescimento.

    Essa regra evita interpretar como crescimento uma categoria que
    simplesmente não possuía vendas em um dos meses.

    Exemplo:

        Junho  = sem vendas
        Julho  = R$ 500
        Agosto = R$ 1.000

    Esse comportamento não é considerado crescimento válido para esta
    análise.

    Por isso, foi utilizado:

        HAVING COUNT(*) = 3


IDENTIFICAÇÃO DO PERÍODO:

    O primeiro e o último mês são identificados dinamicamente através
    de MIN(mes) e MAX(mes) sobre a tabela #ultimos_meses.

    Dessa forma, a consulta não depende de datas fixas e pode ser
    executada novamente sobre uma base atualizada.


RESULTADO:

    O Top 3 categorias, considerando o crescimento percentual do
    faturamento entre o primeiro e o último mês analisado, foi:

        1. artigos_de_festas
           Faturamento inicial: R$ 84,80
           Faturamento final:   R$ 1.285,29
           Crescimento:         1.415,67%

        2. alimentos
           Faturamento inicial: R$ 1.371,18
           Faturamento final:   R$ 8.174,18
           Crescimento:         496,14%

        3. construcao_ferramentas_jardim
           Faturamento inicial: R$ 799,44
           Faturamento final:   R$ 3.688,76
           Crescimento:         361,42%


OBSERVAÇÃO:

    O crescimento percentual deve ser interpretado em conjunto com os
    valores absolutos de faturamento.

    A categoria "artigos_de_festas", apesar de apresentar o maior
    crescimento percentual (1.415,67%), parte de uma base inicial muito
    pequena, de apenas R$ 84,80.

    Portanto, um percentual elevado de crescimento não significa
    necessariamente que a categoria possui o maior impacto financeiro
    absoluto.

    Para esta questão, entretanto, o critério de classificação permanece
    sendo o crescimento percentual do faturamento, conforme solicitado.


================================================================================
*/

DROP TABLE IF EXISTS #ultimos_meses;

SELECT TOP 3
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    ) AS mes
INTO #ultimos_meses
FROM olist_orders
WHERE order_status = 'delivered'
GROUP BY
    DATEFROMPARTS(
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp),
        1
    )
ORDER BY mes DESC;

CREATE UNIQUE CLUSTERED INDEX IX_ultimos_meses
    ON #ultimos_meses(mes);



DROP TABLE IF EXISTS #pedidos;

SELECT
    o.order_id,
    DATEFROMPARTS(
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        1
    ) AS mes
INTO #pedidos
FROM olist_orders o
INNER JOIN #ultimos_meses um
    ON um.mes = DATEFROMPARTS(
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        1
    )
WHERE o.order_status = 'delivered';

CREATE CLUSTERED INDEX IX_pedidos_order_id
    ON #pedidos(order_id);



DROP TABLE IF EXISTS #faturamento_categoria;

SELECT
    p.mes,
    pr.product_category_name,
    SUM(oi.price) AS faturamento,
    COUNT(*) AS qtd_vendida
INTO #faturamento_categoria
FROM #pedidos p
INNER JOIN olist_order_items oi
    ON oi.order_id = p.order_id
INNER JOIN olist_products pr
    ON pr.product_id = oi.product_id
WHERE pr.product_category_name IS NOT NULL
GROUP BY
    p.mes,
    pr.product_category_name;


SELECT TOP 3
    fc.product_category_name,
    
    MAX(
        CASE 
            WHEN fc.mes = um.primeiro_mes 
            THEN fc.faturamento 
        END
    ) AS faturamento_inicial,

    MAX(
        CASE 
            WHEN fc.mes = um.ultimo_mes 
            THEN fc.faturamento 
        END
    ) AS faturamento_final,

    (
        (
            MAX(
                CASE 
                    WHEN fc.mes = um.ultimo_mes 
                    THEN fc.faturamento 
                END
            )
            -
            MAX(
                CASE 
                    WHEN fc.mes = um.primeiro_mes 
                    THEN fc.faturamento 
                END
            )
        )
        /
        MAX(
            CASE 
                WHEN fc.mes = um.primeiro_mes 
                THEN fc.faturamento 
            END
        )
    ) * 100 AS crescimento_percentual

FROM #faturamento_categoria fc

CROSS JOIN (
    SELECT
        MIN(mes) AS primeiro_mes,
        MAX(mes) AS ultimo_mes
    FROM #ultimos_meses
) um

GROUP BY
    fc.product_category_name

HAVING COUNT(*) = 3

ORDER BY crescimento_percentual DESC;