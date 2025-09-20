-- Crear una Vista llamada ClientesConMultiplesOrdenes basada en la consulta realizada en
-- el punto 3.b con los nombres de atributos solicitados en dicho punto.

CREATE VIEW ClientesConMultoplesOrdenes AS

SELECT c.customer_num Numero_de_Cliente, fname Nombre, lname Apellido 
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
GROUP BY c.customer_num, fname, lname
HAVING COUNT(*) > 1