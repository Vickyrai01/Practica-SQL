-- Crear una tabla temporal OrdenesTemp que contenga las siguientes columnas: cantidad de órdenes por
-- cada cliente, primera y última fecha de orden de compra (order_date) del cliente. Realizar una consulta de
-- la tabla temp OrdenesTemp en donde la primer fecha de compra sea anterior a '2015-05-23 00:00:00.000',
-- ordenada por fechaUltimaCompra en forma descendente.

SELECT customer_num, COUNT(order_num) cantidadOrdenes, MIN(order_date) primeraCompra, MAX(order_date) ultimaCompra 
INTO #OrdenesTemp 
FROM orders 
GROUP BY customer_num

SELECT * 
FROM #OrdenesTemp 
WHERE primeraCompra < '2015-05-23 00:00:00.000' 
ORDER BY ultimaCompra DESC;