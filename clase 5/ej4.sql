-- Se desea listar todos los clientes que posean órdenes de compra. Los datos a listar son los
-- siguientes: número de orden, número de cliente, nombre, apellido y compañía.

SELECT order_num, o.customer_num, fname, lname, company 
FROM orders o INNER JOIN customer c 
ON (o.customer_num = c.customer_num)