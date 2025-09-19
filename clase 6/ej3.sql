-- Listar todos los clientes que hayan tenido más de una orden.
-- a) En primer lugar, escribir una consulta usando una subconsulta.
-- b) Reescribir la consulta utilizando GROUP BY y HAVING.
-- La consulta deberá tener el siguiente formato:
-- Número_de_Cliente     Nombre        Apellido
-- (customer_num)		 (fname)        (lname)


SELECT c.customer_num Numero_de_Cliente, fname Nombre, lname Apellido 
FROM customer c
WHERE c.customer_num IN (SELECT o.customer_num FROM orders o GROUP BY o.customer_num HAVING COUNT(*) > 1)


SELECT c.customer_num Numero_de_Cliente, fname Nombre, lname Apellido 
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
GROUP BY c.customer_num, fname, lname
HAVING COUNT(*) > 1