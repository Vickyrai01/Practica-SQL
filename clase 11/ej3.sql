/*
3. En función a la tabla temporal generada en el punto 2, obtener un listado que detalle para cada
producto existente en #ABC_Producto, la descripción del producto, mes de la orden en el que fue
solicitado, el cliente que lo solicitó (en formato 'Apellido, Nombre'), la cantidad de órdenes de compra
'Cant OC por mes', la cantidad del producto solicitado 'Unid Producto por mes' y el total en u$ solicitado
'u$ Producto por mes'.
Mostrar sólo aquellos clientes que vivan en el estado con mayor cantidad de clientes, ordenado por
mes en forma ascendente y por cantidad de productos en forma descendente.
*/

SELECT a.description, MONTH(o.order_date) 'mes donde fue solicitado', 
	   lname + ', ' + fname nombre, COUNT(distinct o.order_num) 'Cant OC por mes', 
	   SUM(quantity) 'Unid producto por mes',
	   SUM(quantity * unit_price) 'u$ Producto por mes'

FROM #ABC_Productos a
	INNER JOIN items i ON (a.stock_num = i.stock_num AND a.manu_code = i.manu_code)
	INNER JOIN orders o ON (o.order_num = i.order_num)
	INNER JOIN customer c ON (c.customer_num = o.customer_num)
WHERE c.state = (SELECT TOP 1 c1.state FROM customer c1 GROUP BY c1.state ORDER BY COUNT(c1.customer_num) DESC)
GROUP BY a.description, MONTH(o.order_date), lname, fname
ORDER BY MONTH(order_date), SUM(quantity) DESC