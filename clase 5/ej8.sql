-- Informar el nombre del fabricante (manu_name) y el tiempo de envío (lead_time) de los ítems de
-- las Órdenes del cliente 104.

SELECT o.customer_num, m.manu_name, m.lead_time 
FROM orders o 
	INNER JOIN items i ON (o.order_num = i.order_num)
	INNER JOIN manufact m ON (i.manu_code = m.manu_code)
WHERE o.customer_num = 104