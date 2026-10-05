/*
================================================================================
QUESTÃO D - PERÍODO ENTRE COMPRAS DOS CLIENTES RECORRENTES
================================================================================

Pergunta:
    Qual o período entre compras dos clientes recorrentes?

OBJETIVO:
    Calcular o intervalo de tempo entre compras consecutivas dos clientes
    recorrentes, utilizando a média e a mediana como medidas de tendência central.

DEFINIÇÃO:
    Foram considerados clientes recorrentes aqueles que realizaram
    2 ou mais pedidos.

METODOLOGIA:
    1. Identificação dos clientes recorrentes:
       - Utilizado o campo customer_unique_id para identificar o cliente.
       - Foram considerados recorrentes os clientes com pelo menos 2 pedidos.

    2. Identificação da compra anterior:
       - Utilizada a função LAG() para obter o pedido e a data da compra
         imediatamente anterior de cada cliente.
       - A ordenação foi realizada pela data da compra e, em caso de empate,
         pelo order_id.

    3. Cálculo do intervalo:
       - O intervalo entre compras foi calculado em segundos e convertido
         para dias, preservando a diferença real entre os timestamps.
       - Dessa forma, diferenças inferiores a um dia não são truncadas.

    4. Tratamento dos intervalos iguais a zero:
       - Foram identificados 292 intervalos de 0 dias entre um total de
         3.345 intervalos.
       - A validação demonstrou que esses casos correspondem a pedidos
         distintos do mesmo cliente realizados exatamente no mesmo
         timestamp.
       - Portanto, esses intervalos foram mantidos no cálculo.

    5. Medidas calculadas:
       - Média: calculada com AVG().
       - Mediana: calculada utilizando PERCENTILE_CONT(0.5).

RESULTADO:
    Média entre compras:   78,23 dias
    Mediana entre compras: 28,33 dias

INTERPRETAÇÃO:
    O intervalo médio entre compras dos clientes recorrentes foi de
    aproximadamente 78,23 dias, enquanto a mediana foi de 28,33 dias.

    A diferença entre média e mediana indica que a distribuição dos
    intervalos possui valores elevados que aumentam a média. Dessa forma,
    a mediana representa melhor o intervalo típico observado entre as
    compras dos clientes recorrentes.

CONCLUSÃO:
    Considerando a mediana, o período típico entre compras dos clientes
    recorrentes foi de aproximadamente 28,33 dias.
================================================================================
*/

WITH clientes_recorrentes AS (
    SELECT 
        oc.customer_unique_id,
        COUNT(*) AS qtd_pedidos
    FROM olist_orders o
    INNER JOIN olist_customers oc
        ON o.customer_id = oc.customer_id
    GROUP BY oc.customer_unique_id
    HAVING COUNT(*) >= 2
),

data_compra_anterior AS (
    SELECT
    oc.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp AS data_compra,
    LAG(o.order_id) OVER (
        PARTITION BY oc.customer_unique_id
        ORDER BY o.order_purchase_timestamp, o.order_id
    ) AS order_id_anterior,
    LAG(o.order_purchase_timestamp) OVER (
        PARTITION BY oc.customer_unique_id
        ORDER BY o.order_purchase_timestamp, o.order_id
    ) AS data_compra_anterior
    FROM
        clientes_recorrentes cr
    INNER JOIN olist_customers oc ON ( cr.customer_unique_id = oc.customer_unique_id)
    INNER JOIN olist_orders o ON ( oc.customer_id = o.customer_id)

),

intervalos AS (    
    SELECT
        dc.customer_unique_id,
        dc.order_id,
        dc.order_id_anterior,
        dc.data_compra,
        dc.data_compra_anterior,
        DATEDIFF(SECOND, dc.data_compra_anterior, dc.data_compra) / 86400.0 AS diferenca_dias
    FROM data_compra_anterior dc
    WHERE dc.data_compra_anterior IS NOT NULL 
),

mediana AS (
    SELECT
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY i.diferenca_dias)
            OVER () AS mediana
    FROM intervalos i
),

media AS (
    SELECT
        AVG(i.diferenca_dias) AS media
    FROM intervalos i
)

SELECT DISTINCT
    m.media,
    md.mediana
FROM
    media M
CROSS JOIN mediana md