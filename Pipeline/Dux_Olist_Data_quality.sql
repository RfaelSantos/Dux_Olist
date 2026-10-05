/* ============================================================
   DUX - DATA QUALITY ANALYSIS
   Base: Olist E-commerce Dataset
   ============================================================

   Objetivo:
   Avaliar a qualidade dos dados por meio de:
   
   1. Perfil e estrutura da base
   2. Completude e integridade referencial
   3. Consistência de domínio e valores
   4. Consistência temporal
   5. Consistência financeira

   Classificação das consultas:
   
   [ANÁLISE FINAL]
   Consulta que sustenta uma validação ou conclusão
   relevante para o projeto.

   [ANÁLISE EXPLORATÓRIA]
   Consulta utilizada para investigar ou detalhar
   um achado. Não necessariamente precisa ser enviada
   no conjunto principal de análises.
   ============================================================ */


/* ============================================================
   01. PERFIL E ESTRUTURA DA BASE
   ============================================================ */


/* ------------------------------------------------------------
   01.1 - Volume de registros e unicidade das chaves
   
   Objetivo:
   Verificar o volume de registros e a unicidade das
   principais chaves das tabelas.
   ------------------------------------------------------------ */

SELECT 'olist_orders' AS tabela,
       COUNT(*) AS registros,
       COUNT(DISTINCT order_id) AS chaves_unicas
FROM dbo.olist_orders

UNION ALL

SELECT 'olist_customers',
       COUNT(*),
       COUNT(DISTINCT customer_id)
FROM dbo.olist_customers

UNION ALL

SELECT 'olist_sellers',
       COUNT(*),
       COUNT(DISTINCT seller_id)
FROM dbo.olist_sellers

UNION ALL

SELECT 'olist_order_items',
       COUNT(*),
       COUNT(DISTINCT CONCAT(order_id, '-', order_item_id))
FROM dbo.olist_order_items

UNION ALL

SELECT 'olist_order_payments',
       COUNT(*),
       COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential))
FROM dbo.olist_order_payments

UNION ALL

SELECT 'olist_order_reviews',
       COUNT(*),
       COUNT(DISTINCT review_id)
FROM dbo.olist_order_reviews

UNION ALL

SELECT 'olist_products',
       COUNT(*),
       COUNT(DISTINCT product_id)
FROM dbo.olist_products

UNION ALL

SELECT 'olist_geolocation',
       COUNT(*),
       COUNT(DISTINCT CONCAT(
           geolocation_zip_code_prefix,
           '-',
           geolocation_lat,
           '-',
           geolocation_lng
       ))
FROM dbo.olist_geolocation;


/* ------------------------------------------------------------
   01.2 - Duplicidade de reviews
   ------------------------------------------------------------ */

SELECT
    review_id,
    COUNT(*) AS quantidade
FROM dbo.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY quantidade DESC;


/* ------------------------------------------------------------
   01.3 - Duplicidade de registros de geolocalização
   ------------------------------------------------------------ */

SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS quantidade
FROM dbo.olist_geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1
ORDER BY quantidade DESC;


/* ============================================================
   02. COMPLETUDE E INTEGRIDADE REFERENCIAL
   ============================================================ */


/* ------------------------------------------------------------
   02.1 - Valores nulos por tabela e coluna
   
   Objetivo:
   Identificar colunas que possuem valores nulos e medir
   sua frequência.
   ------------------------------------------------------------ */

DECLARE @sql NVARCHAR(MAX);

SELECT @sql =
    STRING_AGG(
        CAST(
            'SELECT
                ''' + TABLE_NAME + ''' AS tabela,
                ''' + COLUMN_NAME + ''' AS coluna,
                COUNT(*) AS total_registros,
                COUNT(*) - COUNT(' + QUOTENAME(COLUMN_NAME) + ') AS valores_nulos,
                CAST(
                    100.0 * (COUNT(*) - COUNT(' + QUOTENAME(COLUMN_NAME) + '))
                    / NULLIF(COUNT(*), 0)
                    AS DECIMAL(10,2)
                ) AS percentual_nulos
            FROM dbo.' + QUOTENAME(TABLE_NAME) + '
            HAVING COUNT(*) - COUNT(' + QUOTENAME(COLUMN_NAME) + ') > 0'
            AS NVARCHAR(MAX)
        ),
        ' UNION ALL '
    )
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN (
      'olist_orders',
      'olist_customers',
      'olist_sellers',
      'olist_order_items',
      'olist_geolocation',
      'olist_products',
      'olist_category_name_translation',
      'olist_order_payments',
      'olist_order_reviews'
  );

EXEC sp_executesql @sql;


/* ------------------------------------------------------------
   02.2 - Nulos em datas de pedidos por status
   ------------------------------------------------------------ */

SELECT
    order_status,
    COUNT(*) AS total_pedidos,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)
        AS sem_aprovacao,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)
        AS sem_envio_transportadora,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)
        AS sem_entrega_cliente
FROM dbo.olist_orders
GROUP BY order_status
ORDER BY total_pedidos DESC;


/* ------------------------------------------------------------
   02.3 - Pedidos sem cliente
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_sem_cliente
FROM dbo.olist_orders o
LEFT JOIN dbo.olist_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


/* ------------------------------------------------------------
   02.4 - Clientes sem pedido
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS clientes_sem_pedido
FROM dbo.olist_customers c
LEFT JOIN dbo.olist_orders o
    ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;


/* ------------------------------------------------------------
   02.5 - Pedidos sem itens
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_sem_itens
FROM dbo.olist_orders o
LEFT JOIN dbo.olist_order_items i
    ON o.order_id = i.order_id
WHERE i.order_id IS NULL;


/* ------------------------------------------------------------
   02.6 - Itens sem pedido
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS itens_sem_pedido
FROM dbo.olist_order_items i
LEFT JOIN dbo.olist_orders o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL;


/* ------------------------------------------------------------
   02.7 - Pedidos sem pagamento
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_sem_pagamento
FROM dbo.olist_orders o
LEFT JOIN dbo.olist_order_payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;


/* ------------------------------------------------------------
   02.8 - Pagamentos sem pedido
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pagamentos_sem_pedido
FROM dbo.olist_order_payments p
LEFT JOIN dbo.olist_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


/* ------------------------------------------------------------
   02.9 - Reviews sem pedido
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS reviews_sem_pedido
FROM dbo.olist_order_reviews r
LEFT JOIN dbo.olist_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


/* ------------------------------------------------------------
   02.10 - Pedidos sem review
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_sem_review
FROM dbo.olist_orders o
LEFT JOIN dbo.olist_order_reviews r
    ON o.order_id = r.order_id
WHERE r.order_id IS NULL;


/* ------------------------------------------------------------
   02.11 - Itens sem produto
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS itens_sem_produto
FROM dbo.olist_order_items i
LEFT JOIN dbo.olist_products p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL;


/* ------------------------------------------------------------
   02.12 - Produtos sem item
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS produtos_sem_item
FROM dbo.olist_products p
LEFT JOIN dbo.olist_order_items i
    ON p.product_id = i.product_id
WHERE i.product_id IS NULL;


/* ------------------------------------------------------------
   02.13 - Itens sem seller
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS itens_sem_seller
FROM dbo.olist_order_items i
LEFT JOIN dbo.olist_sellers s
    ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


/* ------------------------------------------------------------
   02.14 - Sellers sem item
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS sellers_sem_item
FROM dbo.olist_sellers s
LEFT JOIN dbo.olist_order_items i
    ON s.seller_id = i.seller_id
WHERE i.seller_id IS NULL;



/* ============================================================
   03. CONSISTÊNCIA DE DOMÍNIO E VALORES
   ============================================================ */


/* ------------------------------------------------------------
   03.1 - Domínio de order_status
   ------------------------------------------------------------ */

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM dbo.olist_orders
GROUP BY order_status
ORDER BY total_orders DESC;

/*
Resultado:
O campo order_status apresentou 8 categorias distintas,
sem valores inesperados ou inconsistências de domínio.
*/


/* ------------------------------------------------------------
   03.2 - Domínio de payment_type
   ------------------------------------------------------------ */

SELECT
    payment_type,
    COUNT(*) AS total_pagamentos
FROM dbo.olist_order_payments
GROUP BY payment_type
ORDER BY total_pagamentos DESC;

/* ------------------------------------------------------------
   03.3 - Domínio de review_score
   ------------------------------------------------------------ */

SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM dbo.olist_order_reviews
GROUP BY review_score
ORDER BY review_score;

/*
Resultado:
O campo review_score apresentou exclusivamente valores
entre 1 e 5.
*/


/* ------------------------------------------------------------
   03.4 - Valores de price e freight_value
   ------------------------------------------------------------ */

SELECT
    MIN(price) AS preco_min,
    MAX(price) AS preco_max,
    MIN(freight_value) AS frete_min,
    MAX(freight_value) AS frete_max,
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END)
        AS preco_zero_ou_negativo,
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END)
        AS frete_negativo
FROM dbo.olist_order_items;

/*
Resultado:
Não foram identificados valores negativos.
Frete igual a zero é permitido e pode representar
frete gratuito.
*/


/* ------------------------------------------------------------
   03.5 - Valores de payment_value
   ------------------------------------------------------------ */

SELECT
    MIN(payment_value) AS pgto_min,
    MAX(payment_value) AS pgto_max,
    SUM(CASE WHEN payment_value <= 0 THEN 1 ELSE 0 END)
        AS pgto_zero_ou_negativo
FROM dbo.olist_order_payments;

/* ============================================================
   04. CONSISTÊNCIA TEMPORAL
   ============================================================ */


/* ------------------------------------------------------------
   04.1 - Sequência temporal dos eventos do pedido
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_inconsistentes
FROM dbo.olist_orders
WHERE
       order_approved_at < order_purchase_timestamp
    OR order_delivered_carrier_date < order_approved_at
    OR order_delivered_customer_date < order_delivered_carrier_date;


/* ------------------------------------------------------------
   04.2 - Separação das inconsistências temporais
   ------------------------------------------------------------ */

SELECT
    SUM(CASE
        WHEN order_approved_at < order_purchase_timestamp
        THEN 1 ELSE 0
    END) AS aprovado_antes_compra,

    SUM(CASE
        WHEN order_delivered_carrier_date < order_approved_at
        THEN 1 ELSE 0
    END) AS carregado_antes_aprovacao,

    SUM(CASE
        WHEN order_delivered_customer_date < order_delivered_carrier_date
        THEN 1 ELSE 0
    END) AS entregue_antes_carregamento
FROM dbo.olist_orders;


/*
Resultado:
aprovado_antes_compra = 0
carregado_antes_aprovacao = 1.359
entregue_antes_carregamento = 23

Os 1.359 casos de carregado_antes_aprovacao foram
investigados separadamente.
*/

/* ------------------------------------------------------------
   04.3 - Compra → aprovação
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS total_pedidos,
    SUM(
        CASE
            WHEN order_approved_at < order_purchase_timestamp
            THEN 1
            ELSE 0
        END
    ) AS aprovado_antes_compra,
    MIN(
        DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_approved_at
        )
    ) AS min_horas_compra_p_aprovacao,
    MAX(
        DATEDIFF(
            HOUR,
            order_purchase_timestamp,
            order_approved_at
        )
    ) AS max_horas_compra_p_aprovacao
FROM dbo.olist_orders;

/*
Resultado:
Não foram identificadas aprovações anteriores à compra.
*/

/* ------------------------------------------------------------
   04.4 - Estimativa de entrega anterior à compra
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_inconsistentes
FROM dbo.olist_orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;


/* ------------------------------------------------------------
   04.5 - Entrega ao cliente anterior à compra
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_inconsistentes
FROM dbo.olist_orders
WHERE order_delivered_customer_date < order_purchase_timestamp;


/* ------------------------------------------------------------
   04.6 - shipping_limit_date anterior à compra
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_inconsistentes
FROM dbo.olist_order_items oi
INNER JOIN dbo.olist_orders o
    ON oi.order_id = o.order_id
WHERE oi.shipping_limit_date < o.order_purchase_timestamp;


/* ------------------------------------------------------------
   04.7 - Envio à transportadora após shipping_limit_date
   
   Observação:
   Este resultado representa atraso operacional,
   não necessariamente erro de qualidade de dados.
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS itens_atrasados
FROM dbo.olist_order_items oi
INNER JOIN dbo.olist_orders o
    ON oi.order_id = o.order_id
WHERE
    o.order_delivered_carrier_date IS NOT NULL
    AND o.order_delivered_carrier_date > oi.shipping_limit_date;



/* ============================================================
   05. CONSISTÊNCIA FINANCEIRA × STATUS
   ============================================================ */


/* ------------------------------------------------------------
   05.1 - Pedidos cancelados × pagamento
   ------------------------------------------------------------ */

SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS pedidos,
    COUNT(DISTINCT p.order_id) AS pedidos_com_pgto
FROM dbo.olist_orders o
LEFT JOIN dbo.olist_order_payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'canceled'
GROUP BY o.order_status;


/* ------------------------------------------------------------
   05.2 - Valor total pago em pedidos cancelados
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_cancelados,
    SUM(
        CASE
            WHEN total_pgto > 0 THEN 1
            ELSE 0
        END
    ) AS cancelados_com_pagto,
    SUM(
        CASE
            WHEN total_pgto = 0 THEN 1
            ELSE 0
        END
    ) AS cancelados_sem_pagto,
    MIN(total_pgto) AS pgto_min,
    MAX(total_pgto) AS pgto_max
FROM (
    SELECT
        o.order_id,
        COALESCE(SUM(p.payment_value), 0) AS total_pgto
    FROM dbo.olist_orders o
    LEFT JOIN dbo.olist_order_payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'canceled'
    GROUP BY o.order_id
) x;


/* ------------------------------------------------------------
   05.3 - Pedidos entregues × pagamento
   ------------------------------------------------------------ */

SELECT
    COUNT(*) AS pedidos_entregues,
    SUM(
        CASE
            WHEN total_pgto > 0 THEN 1
            ELSE 0
        END
    ) AS entregues_com_pgto,
    SUM(
        CASE
            WHEN total_pgto = 0 THEN 1
            ELSE 0
        END
    ) AS entregues_sem_pgto
FROM (
    SELECT
        o.order_id,
        COALESCE(SUM(p.payment_value), 0) AS total_pgto
    FROM dbo.olist_orders o
    LEFT JOIN dbo.olist_order_payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
) x;

/*
Resultado:
Foi identificado 1 pedido delivered sem pagamento
registrado.

Esse pedido possui itens no valor de R$143,46,
caracterizando uma inconsistência financeira objetiva.
*/

/* ============================================================
   06. CONSISTÊNCIA DE STATUS
   ============================================================ */


/* ------------------------------------------------------------
   06.1 - Distribuição dos status
   ------------------------------------------------------------ */

SELECT
    order_status,
    COUNT(*) AS total_pedidos
FROM dbo.olist_orders
GROUP BY order_status
ORDER BY total_pedidos DESC;

/*
Resultado:
Foram identificados 8 valores de order_status,
sem valores inesperados ou inconsistências de domínio.
*/


/* ------------------------------------------------------------
   06.2 - created / approved com data de entrega
   
   Regra:
   Pedidos em estados iniciais não deveriam possuir
   uma entrega ao cliente registrada.
   ------------------------------------------------------------ */

SELECT
    order_status,
    COUNT(*) AS pedidos_inconsistentes
FROM dbo.olist_orders
WHERE order_status IN ('created', 'approved')
  AND order_delivered_customer_date IS NOT NULL
GROUP BY order_status;

/*
Resultado:
Nenhum caso encontrado.
*/

/* ============================================================
   07. ANÁLISE DE OUTLIERS
   ============================================================ 
*/

--Preço

SELECT
    COUNT(*) AS total_items,
    MIN(price) AS preco_min,
    MAX(price) AS preco_max,
    AVG(price) AS media_preco
FROM olist_order_items;

SELECT
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY price)
        OVER () AS q1_preco,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY price)
        OVER () AS mediana_preco,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY price)
        OVER () AS q3_preco
FROM olist_order_items;

SELECT
    COUNT(*) AS outlier_items,
    CAST(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_order_items)
        AS DECIMAL(10,2)
    ) AS outlier_percentual
FROM olist_order_items
WHERE price > 277.40;

SELECT TOP 20
    price,
    COUNT(*) AS total_items
FROM olist_order_items
WHERE price > 277.40
GROUP BY price
ORDER BY price DESC;

SELECT TOP 20
    oi.order_id,
    oi.product_id,
    oi.price,
    p.product_category_name
FROM olist_order_items oi
LEFT JOIN olist_products p
    ON oi.product_id = p.product_id
WHERE oi.price > 277.40
ORDER BY oi.price DESC;

/*
Outliers de preço: O critério de Tukey identificou 8.427 itens (7,48%) com preço superior a R$ 277,40. 
Apesar da distância em relação à mediana de R$ 74,99, os maiores valores estão associados a categorias de produtos compatíveis com preços elevados. 
Não foram identificadas, nesta etapa, evidências suficientes para classificá-los como erros de dados. Os registros devem ser mantidos para as análises subsequentes.
*/

-- Frete
SELECT
    COUNT(*) AS total_items,
    MIN(freight_value) AS frete_min,
    MAX(freight_value) AS frete_max,
    AVG(freight_value) AS media_frete
FROM olist_order_items;

SELECT
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY freight_value)
        OVER () AS q1_frete,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY freight_value)
        OVER () AS mediana_frete,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY freight_value)
        OVER () AS q3_frete
FROM olist_order_items;

SELECT
    COUNT(*) AS outlier_items,
    CAST(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_order_items)
        AS DECIMAL(10,2)
    ) AS outlier_percentual
FROM olist_order_items
WHERE freight_value > 33.255;

SELECT TOP 20
    freight_value,
    COUNT(*) AS total_items
FROM olist_order_items
WHERE freight_value > 33.255
GROUP BY freight_value
ORDER BY freight_value DESC;

SELECT TOP 20
    oi.order_id,
    oi.product_id,
    oi.freight_value,
    p.product_category_name,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM olist_order_items oi
LEFT JOIN olist_products p
    ON oi.product_id = p.product_id
WHERE oi.freight_value > 33.255
ORDER BY oi.freight_value DESC;

/*
Outliers de frete: O critério de Tukey identificou 11.613 itens (10,31%) com freight_value superior a R$ 33,26. 
Apesar da quantidade significativa de valores classificados estatisticamente como extremos, 
a análise dos maiores fretes demonstrou associação com produtos de maior peso e/ou dimensões elevadas, 
fornecendo uma justificativa operacional para os valores observados. Não foram encontradas, nesta etapa, 
evidências suficientes para classificá-los como erros ou anomalias de dados. Os valores devem ser mantidos.
*/

--payment_value
SELECT
    COUNT(*) AS total_pagamentos,
    MIN(payment_value) AS pgto_min,
    MAX(payment_value) AS pgto_max,
    AVG(payment_value) AS media_pgto
FROM olist_order_payments

SELECT
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY payment_value)
        OVER () AS q1_pgto,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY payment_value)
        OVER () AS mediana_pgto,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY payment_value)
        OVER () AS q3_pgto
FROM olist_order_payments;

SELECT
    COUNT(*) AS outlier_pgto,
    CAST(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM olist_order_payments)
        AS DECIMAL(10,2)
    ) AS outlier_percentual
FROM olist_order_payments
WHERE payment_value > 344.415;

SELECT TOP 20
    payment_value,
    COUNT(*) AS total_pgto
FROM olist_order_payments
WHERE payment_value > 344.415
GROUP BY payment_value
ORDER BY payment_value DESC;

SELECT TOP 20
    order_id,
    payment_value,
    payment_type,
    payment_installments
FROM olist_order_payments
WHERE payment_value > 344.415
ORDER BY payment_value DESC;

WITH total_itens_pedido AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS total_itens_pedido
    FROM olist_order_items
    GROUP BY order_id
),

total_pagamentos_pedido AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_pagamentos_pedido
    FROM olist_order_payments
    GROUP BY order_id
),

pedidos_outliers AS (
    SELECT DISTINCT
        order_id
    FROM olist_order_payments
    WHERE payment_value > 344.415
)

SELECT
    COUNT(*) AS total_pedidos_outliers,

    SUM(
        CASE
            WHEN ABS(
                p.total_pagamentos_pedido - i.total_itens_pedido
            ) > 0.01
            THEN 1
            ELSE 0
        END
    ) AS pedidos_com_diferenca,

    CAST(
        SUM(
            CASE
                WHEN ABS(
                    p.total_pagamentos_pedido - i.total_itens_pedido
                ) > 0.01
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS percentual_com_diferenca

FROM pedidos_outliers o

LEFT JOIN total_itens_pedido i
    ON o.order_id = i.order_id

LEFT JOIN total_pagamentos_pedido p
    ON o.order_id = p.order_id;

/*
Outliers de valor de pagamento: O critério de Tukey identificou 7.981 pagamentos (7,68%) acima de R$ 344,42. 
A análise dos maiores valores demonstrou que os pagamentos extremos estão associados a pedidos de alto valor e apresentam formas de pagamento e quantidade de parcelas plausíveis. 
Na validação de reconciliação, apenas 28 registros (0,35% dos pagamentos classificados como outliers) apresentaram diferença entre o total dos pagamentos e o valor de itens + frete. 
Dessa forma, os valores extremos são considerados predominantemente compatíveis com o comportamento da operação e devem ser mantidos. 
Os 28 casos podem ser direcionados posteriormente para uma análise específica de consistência financeira, caso necessário.
*/