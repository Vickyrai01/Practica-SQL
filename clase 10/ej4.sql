/*
Crear una consulta que devuelva los 5 STATES relacionados a los Customers de
mayor facturación, el tipo de producto de mayor facturación de ese estado, el monto
total facturado del producto y el monto total facturado del state.
	
	i) Mostrar la información ordenada por el monto total facturado del State en
	forma descendente.
	
	ii) Nota: No se permite utilizar funciones, ni tablas temporales.

*/

SELECT producto_mas_facturado.estado,producto_mas_facturado.stock_num, producto_mas_facturado.description,total_facturado_producto,total_facturado_estado FROM
(
-- monto total facturado por el estado
SELECT TOP 5 s.state estado,SUM(quantity * unit_price) total_facturado_estado
FROM customer c
	INNER JOIN state s ON (s.state = c.state)
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i ON (o.order_num = i.order_num)
	GROUP BY s.state
	ORDER BY SUM(i.quantity * i.unit_price) DESC
) estado_facturado
INNER JOIN 
(
-- producto mas facturado por estado
SELECT s2.state estado, i2.stock_num,  pt.description, SUM(quantity * unit_price) total_facturado_producto
FROM customer c2
	INNER JOIN state s2 ON (s2.state = c2.state)
	INNER JOIN orders o2 ON (c2.customer_num = o2.customer_num)
	INNER JOIN items i2 ON (o2.order_num = i2.order_num)
	INNER JOIN product_types pt ON (i2.stock_num = pt.stock_num)
	GROUP BY s2.state, i2.stock_num, pt.description
	HAVING i2.stock_num = (
		SELECT TOP 1 i3.stock_num
		FROM items i3
			JOIN orders   o3 ON o3.order_num    = i3.order_num
			JOIN customer c3 ON c3.customer_num = o3.customer_num
		WHERE c3.state = s2.state
		GROUP BY i3.stock_num
		ORDER BY SUM(i3.quantity * i3.unit_price) DESC
  )
			) producto_mas_facturado ON (producto_mas_facturado.estado = estado_facturado.estado)
ORDER BY total_facturado_estado DESC