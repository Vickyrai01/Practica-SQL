/*
4. Dados los productos con número de stock 5, 6 y 9 del fabricante 'ANZ' listar de a pares los clientes que
hayan solicitado el mismo producto, siempre y cuando, el primer cliente haya solicitado más cantidad del
producto que el 2do cliente.
Se deberá informar nro de stock, código de fabricante, Nro de Cliente y Apellido del primer cliente, Nro
de cliente y apellido del 2do cliente ordenado por stock_num y manu_code
*/

SELECT i.stock_num, i.manu_code, c.customer_num, c.lname, c2.customer_num, c2.lname
FROM items i 
	INNER JOIN orders o ON (o.order_num = i.order_num)
	INNER JOIN customer c ON (o.customer_num = c.customer_num)
	INNER JOIN items i2 ON (i.stock_num = i2.stock_num AND i.manu_code = i2.manu_code)
	INNER JOIN orders o2 ON (i2.order_num = o2.order_num)
	INNER JOIN customer c2 ON (o2.customer_num = c2.customer_num)
WHERE (i.stock_num IN (5,6,9)) 
	AND i.manu_code = 'ANZ'
	AND
	(SELECT SUM(i3.quantity) 
	 FROM items i3
		INNER JOIN orders o3 ON (i3.order_num = o3.order_num)
	 WHERE i3.manu_code = i.manu_code AND i3.stock_num = i.stock_num AND o3.customer_num = c.customer_num
	 GROUP BY i3.manu_code, i3.stock_num
	 ) 
	 >
	(SELECT SUM(i4.quantity) 
	 FROM items i4
		INNER JOIN orders o4 ON (i4.order_num = o4.order_num)
	 WHERE i4.manu_code = i.manu_code AND i4.stock_num = i.stock_num AND o4.customer_num = c2.customer_num
	 GROUP BY i4.manu_code, i4.stock_num
	 ) 
ORDER BY i.stock_num, i.manu_code