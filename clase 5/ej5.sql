-- Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son los
-- siguientes: número de cliente, nombre, apellido y compañía. Se requiere sólo una fila por cliente.

SELECT DISTINCT c.customer_num, fname, lname, company, order_num 
FROM orders  o INNER JOIN customer c 
ON (c.customer_num = o.customer_num)