/*
Ejercicio 1 (warm-up, SELECT escalar): Para cada customer, mostrar total_gastado y cantidad_ordenes (usa dos subconsultas escalares). 
Hint: SUM en una, COUNT(DISTINCT) en otra, ambas correlacionadas por customer_num.
*/

SELECT c.customer_num,
					(
						SELECT SUM(i.quantity * i.unit_price) FROM orders o
							INNER JOIN items i ON (o.order_num = i.order_num)
							WHERE o.customer_num = c.customer_num
					) total_gastado,
					(SELECT COUNT(DISTINCT o2.order_num) 
					 FROM orders o2
					 WHERE o2.customer_num = c.customer_num
					 )


FROM customer c

/*
Ejercicio 2 (WHERE correlacionado): Listar órdenes cuyo total supera el promedio 
de todas las órdenes de su mismo cliente. 
Hint: subconsulta en HAVING con AVG de una subconsulta agrupada por order_num.
*/

SELECT o.order_num, o.customer_num FROM orders o 
	INNER JOIN items i ON (i.order_num = o.order_num)
GROUP BY o.order_num, o.customer_num
HAVING SUM(i.quantity *i.unit_price) > (
										SELECT AVG(total_orden)
										FROM(
										SELECT SUM(i2.quantity * i2.unit_price) total_orden FROM orders o2
											INNER JOIN items i2 ON (i2.order_num = o2.order_num)
										WHERE o2.customer_num = o.customer_num
										GROUP BY o2.order_num) total_de_orden_cliente)

/*
Ejercicio 3 (NOT EXISTS): Clientes que solo compraron de un único fabricante en TODAS sus órdenes. 
Hint: NOT EXISTS de un par de fabricantes distintos para el mismo cliente y la misma orden, 
o bien agrupar por (cliente, orden) y exigir COUNT DISTINCT = 1 y luego asegurar que no exista alguna orden con >1.
*/

SELECT c.customer_num, i.manu_code
FROM customer c
	INNER JOIN orders o ON (o.customer_num = c.customer_num)
	INNER JOIN items i  ON (i.order_num = o.order_num)
WHERE NOT EXISTS (SELECT 1 
				  FROM orders o2 
					INNER JOIN items i2 ON (o2.order_num = i2.order_num)
					WHERE (o.customer_num = o2.customer_num) AND (i2.manu_code != i.manu_code))
GROUP BY c.customer_num, i.manu_code


-- D3. Clientes con última orden (por paid_date) > promedio de sus anteriores.

SELECT c.customer_num, o.paid_date ultima_orden FROM customer c
	INNER JOIN orders o ON (o.customer_num = c.customer_num)
	INNER JOIN items  i ON (o.order_num = i.order_num)
WHERE o.paid_date = (
  SELECT MAX(o1.paid_date)
  FROM orders o1
  WHERE o1.customer_num = c.customer_num
)
GROUP BY c.customer_num, o.order_num,o.paid_date
HAVING SUM(i.quantity * i.unit_price) > (SELECT AVG(total_orden) 
										 FROM (SELECT SUM(i2.quantity * i2.unit_price) total_orden FROM orders o2
												 INNER JOIN items i2 ON (o2.order_num = i2.order_num)
											   WHERE o2.customer_num = c.customer_num AND o2.paid_date < o.paid_date
											   GROUP BY o2.order_num)total_ordenes) 


/*
Listar los customers que no posean órdenes de compra y aquellos cuyas últimas
órdenes de compra superen el promedio de todas las anteriores.
Mostrar customer_num, fname, lname, paid_date y el monto total de la orden que
supere el promedio de las anteriores. Ordenar el resultado por monto total en forma
descendiente.
*/


SELECT c.customer_num, c.fname, c.lname, o.paid_date ultima_orden, SUM(i.quantity * i.unit_price) monto_total 
FROM customer c
	INNER JOIN orders o ON (o.customer_num = c.customer_num)
	INNER JOIN items  i ON (o.order_num = i.order_num)
WHERE o.paid_date = (
  SELECT MAX(o1.paid_date)
  FROM orders o1
  WHERE o1.customer_num = c.customer_num
)
GROUP BY c.customer_num, c.fname, c.lname, o.paid_date
HAVING SUM(i.quantity * i.unit_price) >= (SELECT SUM(i1.unit_price * i1.quantity)/count(distinct o2.order_num) 
										 FROM orders o2
											INNER JOIN items i1 ON (o2.order_num = i1.order_num)
									     WHERE o2.customer_num = c.customer_num AND o2.paid_date < o.paid_date) 
UNION
SELECT c.customer_num, c.fname, c.lname, NULL ultima_orden, 0 monto_total
FROM customer c
WHERE c.customer_num NOT IN (SELECT customer_num FROM orders)
ORDER BY 5 DESC