/*
================================================================================
QUESTÃO B - TEMPO MÉDIO DE ENTREGA E ESTADOS COM MAIOR ATRASO
================================================================================

Pergunta:
    Calcule a média de dias entre a compra e a entrega efetiva por estado
    do cliente. Identifique os 5 estados com maior atraso.

OBJETIVO:
    1. Calcular, por estado do cliente, a média de dias entre a compra e
       a entrega efetiva do pedido.
    2. Identificar os 5 estados com maior atraso médio em relação à data
       estimada de entrega.

FÓRMULAS:

    Tempo de entrega (dias) =
        Data de entrega efetiva - Data da compra

    Atraso (dias) =
        Data de entrega efetiva - Data estimada de entrega

    Média de atraso =
        Média dos dias de atraso dos pedidos que efetivamente atrasaram

METODOLOGIA:
    O cálculo foi realizado a partir das tabelas:

    1. olist_orders
       - Utiliza order_purchase_timestamp como data da compra.
       - Utiliza order_delivered_customer_date como data de entrega efetiva.
       - Utiliza order_estimated_delivery_date como data estimada de entrega.

    2. olist_customers
       - Utiliza customer_state para identificar o estado do cliente.

    As tabelas foram relacionadas por customer_id.

    Para cada pedido entregue, foram calculadas duas diferenças:

    - tempo_entrega: quantidade de dias entre a compra e a entrega efetiva.
    - atraso_dias: quantidade de dias entre a data estimada e a data efetiva.

TRATAMENTO DOS PEDIDOS:

    Foram considerados somente pedidos que possuem data de entrega efetiva
    (order_delivered_customer_date IS NOT NULL).

    Para o cálculo do tempo médio de entrega, todos os pedidos entregues
    são considerados, independentemente de terem sido entregues antes,
    no prazo ou depois da data estimada.

    Para o cálculo do atraso médio, foram considerados somente os pedidos
    em que:

        atraso_dias > 0

    Ou seja, somente pedidos cuja entrega efetiva ocorreu após a data
    estimada.

JUSTIFICATIVA DO CÁLCULO DO ATRASO:

    O atraso foi definido em relação à data estimada de entrega, e não
    simplesmente pelo tempo total entre compra e entrega.

    Dessa forma, um pedido que demorou muitos dias para ser entregue,
    mas foi entregue antes da data estimada, não é classificado como
    pedido atrasado.

RANKING DOS ESTADOS:

    Os 5 estados com maior atraso foram identificados utilizando a
    MÉDIA DE DIAS DE ATRASO como critério de ordenação.

    Portanto, o ranking não é baseado na quantidade de pedidos atrasados
    de cada estado.

    A quantidade de pedidos atrasados é apresentada apenas como informação
    complementar para contextualizar o resultado.

RESULTADO:

    Os 5 estados com maior média de atraso foram:

        1. AP - 72 dias
        2. RR - 36 dias
        3. AM - 30 dias
        4. AC - 18 dias
        5. SE - 16 dias

OBSERVAÇÃO:

    Os estados AP, RR, AM e AC apresentam quantidade relativamente pequena
    de pedidos atrasados. Portanto, suas médias são influenciadas por um
    número menor de observações.

    Essa característica não altera o ranking solicitado pela questão,
    uma vez que o critério utilizado é a MÉDIA DE DIAS DE ATRASO.

================================================================================
*/


WITH dias_entrega AS (
	SELECT
		o.order_purchase_timestamp,
		o.order_estimated_delivery_date,
		o.order_delivered_customer_date,
		c.customer_state AS estado,
		DATEDIFF(
			DAY,
			o.order_purchase_timestamp,
			o.order_delivered_customer_date) AS tempo_entrega,
		DATEDIFF(
			DAY,
			o.order_estimated_delivery_date,
			o.order_delivered_customer_date) AS atraso_dias
	FROM
		olist_orders o
	INNER JOIN olist_customers c
		ON o.customer_id = c.customer_id
	WHERE
		o.order_delivered_customer_date IS NOT NULL
)


SELECT
	estado,
	AVG(tempo_entrega) AS media_tempo_entrega,
	AVG(
		CASE
			WHEN atraso_dias > 0 THEN atraso_dias 
		END ) AS media_tempo_atraso
FROM
	dias_entrega
GROUP BY estado
ORDER BY media_tempo_atraso DESC
