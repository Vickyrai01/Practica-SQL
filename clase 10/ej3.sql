/*
Crear una vista que devuelva
Para cada cliente mostrar (customer_num, lname, company), cantidad de órdenes
de compra, fecha de su última OC, monto total comprado y el total general
comprado por todos los clientes.
De los clientes que posean órdenes sólo se podrán mostrar los clientes que tengan
alguna orden que posea productos que son fabricados por más de dos fabricantes y
que tengan al menos 3 órdenes de compra.

Ordenar el reporte de tal forma que primero aparezcan los clientes que tengan
órdenes por cantidad de órdenes descendente y luego los clientes que no tengan
órdenes.

No se permite utilizar funciones, ni tablas temporales.

*/


CREATE VIEW viewC10E4 AS
	SELECT c.customer_num, lname, company, COUNT(DISTINCT o.order_num) cantidad_ordenes, 
		   MAX(order_date) ultima_orden, COALESCE(SUM(i.quantity * i.unit_price), 0) total_gastado, 
		   SUM(SUM(i.quantity * i.unit_price)) OVER () total_general
	FROM customer c
		LEFT JOIN orders o ON (c.customer_num = o.customer_num)
		LEFT JOIN items i ON (i.order_num = o.order_num)
	GROUP BY c.customer_num, lname, company
	HAVING (COUNT(DISTINCT o.order_num) >= 3
			AND
			EXISTS (SELECT 1 FROM items i2 INNER JOIN orders o2 ON (o2.order_num = i2.order_num)
					WHERE o2.customer_num = c.customer_num 
					GROUP BY i2.order_num
					HAVING COUNT(DISTINCT i2.manu_code) > 2))
			OR (COUNT(DISTINCT o.order_num) = 0)
	
SELECT * FROM viewC10E4
	ORDER BY cantidad_ordenes DESC