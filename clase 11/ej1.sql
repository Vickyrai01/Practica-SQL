/*
1. Listar Número de Cliente, apellido y nombre, Total Comprado por el cliente ‘Total del Cliente’,
Cantidad de Órdenes de Compra del cliente ‘OCs del Cliente’ y la Cantidad de Órdenes de Compra de
todos los clientes ‘Cant. Total OC’, de todos aquellos clientes cuyo promedio de compra por Orden
supere al promedio de órdenes de compra general, tenga al menos 2 órdenes y su zipcode comience
con 94.
*/

SELECT c.customer_num, 
	   fname, 
	   lname, 
	   SUM(i.quantity* i.unit_price) total_gastado, 
	   COUNT(DISTINCT o.order_num) OCs_cliente, 
	   (SELECT COUNT(DISTINCT o1.order_num) FROM orders o1) total_ordenes
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i ON (o.order_num = i.order_num)
WHERE zipcode LIKE '94%'
GROUP BY c.customer_num, fname, lname
HAVING COUNT(DISTINCT o.order_num) >= 2 
		AND
	   AVG(i.quantity* i.unit_price) > (SELECT SUM(i2.quantity* i2.unit_price)/ COUNT(DISTINCT o2.order_num)
										FROM orders o2
											INNER JOIN items i2 ON (o2.order_num = i2.order_num))