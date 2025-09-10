-- Para cada estado, obtener la cantidad de clientes referidos. Mostrar sólo los clientes que hayan sido
-- referidos cuya compañía empiece con una letra que este en el rango de ‘A’ a ‘L’.

SELECT state, COUNT(*) cantClientes 
FROM customer 
WHERE company LIKE '[A-L]%' AND customer_num_referedBy IS NOT NULL 
GROUP BY state