-- Seleccionar todas las Órdenes de compra cuyo Monto total (Suma de p x q de sus items)
-- sea menor al precio total promedio (avg p x q) de todas las líneas de las ordenes.
-- Formato de la salida: Nro. de Orden       Total
--                        (order_num)       (suma)

SELECT o.order_num AS Nro_de_orden, SUM(i.quantity * i.unit_price) AS total
FROM orders o
	INNER JOIN items i ON (o.order_num = i.order_num)
GROUP BY o.order_num
HAVING SUM(i.quantity * i.unit_price) < (
    SELECT AVG(total_orden)
    FROM (
        SELECT SUM(i2.quantity * i2.unit_price) AS total_orden
        FROM orders o2
        INNER JOIN items i2 ON o2.order_num = i2.order_num
        GROUP BY o2.order_num
    ) x
)