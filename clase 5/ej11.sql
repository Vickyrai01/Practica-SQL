-- Obtener la fecha de embarque (ship_date), Apellido (lname) y Nombre (fname) del Cliente
-- separado por coma y la cantidad de órdenes del cliente. Para aquellos clientes que viven en el
-- estado con descripción (sname) “California” y el código postal está entre 94000 y 94100 inclusive.
-- Ordenado por fecha de embarque y, Apellido y nombre.

SELECT o.ship_date, c.lname + ', ' + c.fname cliente, COUNT(*) cantOrdenes 
FROM orders o
	INNER JOIN customer c ON (o.customer_num = c.customer_num)
	INNER JOIN state s ON (c.state = s.state)
WHERE s.sname = 'California' AND c.zipcode BETWEEN 94000 AND 94100
GROUP BY o.ship_date, c.lname, c.fname
ORDER BY o.ship_date, c.lname, c.fname