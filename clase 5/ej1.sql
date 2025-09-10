-- Obtener el número de cliente, la compañía, y número de orden de todos los clientes que tengan
-- órdenes. Ordenar el resultado por número de cliente.

SELECT c.customer_num, c.company, order_num 
FROM orders o INNER JOIN customer c 
ON (c.customer_num = o.customer_num)
ORDER BY c.customer_num