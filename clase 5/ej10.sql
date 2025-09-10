-- Obtener un listado con la siguiente información: Apellido (lname) y Nombre (fname) del Cliente
-- separado por coma, Número de teléfono (phone) en formato (999) 999-9999. Ordenado por
-- apellido y nombre.

SELECT lname + ', ' + fname cliente,  '(' + SUBSTRING(phone,1,3) + ') ' + SUBSTRING(phone,5,12) 
FROM customer
ORDER BY lname, fname