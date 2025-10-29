/*
10. Seleccionar todos los clientes cuyo monto total comprado sea mayor al de su refererente durante el
año 2015. Mostrar número, nombre, apellido y los montos totales comprados de ambos durante ese
año. Tener en cuenta que un cliente puede no tener referente y que el referente pudo no haber
comprado nada durante el año 2015, mostrarlo igual.
*/


SELECT  c.customer_num, c.fname, c.lname, SUM(i.quantity * i.unit_price) total, COALESCE (c2.total_ref, 0) total_ref
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i ON (o.order_num = i.order_num)
	LEFT JOIN (SELECT c1.customer_num, SUM(i1.quantity * i1.unit_price) total_ref 
			   FROM customer c1
				INNER JOIN orders o1 ON (c1.customer_num = o1.customer_num)
				INNER JOIN items i1 ON (o1.order_num = i1.order_num)
				WHERE YEAR(o1.order_date) = 2015
			   GROUP BY c1.customer_num
				
				) c2 ON (c.customer_num_referedBy = c2.customer_num)
WHERE YEAR(o.order_date) = 2015
GROUP BY c.customer_num, c.fname, c.lname,c2.total_ref
HAVING SUM(i.quantity * i.unit_price) > c2.total_ref
