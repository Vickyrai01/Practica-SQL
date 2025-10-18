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