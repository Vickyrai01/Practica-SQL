/*
Mostrar Nombre, Apellido y promedio de orden de compra del cliente referido, 
nombre Apellido y promedio de orden de compra del cliente referente. 
De todos aquellos referidos cuyo promedio de orden de compra sea mayor al de su referente. 
Mostrar la información ordenada por Nombre y Apellido del referido.
El promedio es el total de monto comprado (p x q) / cantidad de órdenes.
Si el cliente no tiene referente, no mostrarlo.
Notas: No usar Store procedures, ni funciones de usuarios, ni tablas temporales. 
*/

SELECT c.fname + ', ' + c.lname nombre_referido, 
	   SUM(i.unit_price * i.quantity) / COUNT(DISTINCT i.order_num) 'Promedio cliente referido',
	   cr.nombre_referente, cr.[Promedio referente]
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i  ON (o.order_num = i.order_num)
	INNER JOIN (SELECT c1.customer_num, c1.fname + ', ' + c1.lname nombre_referente, SUM(i1.unit_price * i1.quantity) / COUNT(DISTINCT i1.order_num) 'Promedio referente'
			    FROM customer c1 
					INNER JOIN orders o1 ON (c1.customer_num = o1.customer_num)
					INNER JOIN items i1  ON (o1.order_num = i1.order_num)
				GROUP BY c1.customer_num, c1.fname, c1.lname
				) cr ON (cr.customer_num = c.customer_num_referedBy)
GROUP BY c.fname, c.lname, cr.nombre_referente, cr.[Promedio referente]
HAVING SUM(i.unit_price * i.quantity) / COUNT(DISTINCT i.order_num) > cr.[Promedio referente]
