/*
================================================================================
A - PARTICIPAÇÃO PERCENTUAL DO FRETE NO VALOR TOTAL PAGO POR MÊS
================================================================================

Pergunta:
    Qual a participação percentual do frete no valor total pago pelo cliente
    por mês?

OBJETIVO:
    Calcular, para cada mês, quanto o valor do frete representa
    percentualmente do valor total pago pelos clientes.

FÓRMULA:
    Participação do frete (%) =
        (Total de frete do mês / Total pago no mês) * 100


METODOLOGIA:
    O cálculo foi dividido em duas agregações independentes:

    1. PAGAMENTO MENSAL
       - Utiliza o valor de payment_value da tabela
         olist_order_payments.
       - O valor é agregado por mês da compra
         (order_purchase_timestamp da tabela olist_orders).

    2. FRETE MENSAL
       - Utiliza o valor de freight_value da tabela
         olist_order_items.
       - O valor é agregado por mês da compra
         (order_purchase_timestamp da tabela olist_orders).

    Após as duas agregações, os resultados são relacionados pelo mês.

JUSTIFICATIVA DA SEPARAÇÃO:
    As tabelas olist_order_items e olist_order_payments podem possuir
    múltiplos registros para um mesmo pedido.

    Por isso, não foi realizado um JOIN direto entre itens e pagamentos
    antes das agregações, pois isso poderia multiplicar as linhas de um
    mesmo pedido e provocar a duplicação dos valores de frete e/ou pagamento.

    Dessa forma, cada fonte é primeiro consolidada por mês e somente
    depois os resultados são relacionados.

TRATAMENTO DE PAGAMENTOS SEM FRETE:
    O total de pagamentos é calculado de forma independente do total de
    frete. Dessa forma, pagamentos de pedidos que não possuem registros
    de itens/frete não são excluídos do valor total pago do mês.

    Foi utilizado LEFT JOIN a partir de pagamento_mensal para preservar
    os meses que possuem pagamentos mesmo quando não existe registro de
    frete correspondente.

    Quando não existe registro de frete para determinado mês, o resultado
    permanece NULL. Isso indica ausência de registro de frete para o cálculo,
    e não que o valor do frete seja necessariamente zero.

    Exemplo:
        2018/10
        Pagamento = 589,67
        Frete     = NULL
        % Frete   = NULL

    Portanto, não foi atribuído artificialmente o valor zero ao frete.

RESULTADO:
    Para os meses em que existem registros de pagamento e frete, a
    participação percentual é calculada pela divisão do total de frete
    pelo total pago no mês, multiplicada por 100.

OBSERVAÇÃO:
    Os meses de 2016/09, 2016/12 e 2018/09 apresentam volumes de pagamento
    significativamente menores que os demais meses da série. Portanto,
    seus percentuais devem ser interpretados considerando o baixo volume
    financeiro registrado nesses períodos.

================================================================================
*/


WITH pagamento_mensal AS (
    SELECT
        FORMAT(CAST(o.order_purchase_timestamp AS datetime), 'yyyy/MM') AS data,
        SUM(op.payment_value) AS total_pagamento
    FROM olist_orders o
    INNER JOIN olist_order_payments op
        ON o.order_id = op.order_id
    GROUP BY
        FORMAT(CAST(o.order_purchase_timestamp AS datetime), 'yyyy/MM')
),

frete_mensal AS (
    SELECT
        FORMAT(CAST(lo.order_purchase_timestamp AS datetime), 'yyyy/MM') AS data,
        SUM(oi.freight_value) AS total_frete
    FROM olist_orders lo
    INNER JOIN olist_order_items oi
        ON lo.order_id = oi.order_id
    GROUP BY
        FORMAT(CAST(lo.order_purchase_timestamp AS datetime), 'yyyy/MM')
)

SELECT
    p.data,
    SUM(total_pagamento) 'Pagamento',
    SUM(total_frete) 'Frete',
    ROUND((SUM(total_frete)/SUM(total_pagamento)) * 100, 2) '% Frete'
FROM
    pagamento_mensal p
LEFT JOIN frete_mensal f ON (p.data = f.data)
GROUP BY
    p.data
ORDER BY
    p.data
