'se requiere crear una vista "comprasFabricanteLider" en la qu se oculten los nombres de 
campos reales y que detalle  : nombre del fabricante, apellido y nombre del cliente, descripcion 
del tipo de producto, la sumatoria del monto total (p x q) y la sumatoria del campo quantity
ese informe debera mostrar solo los productos cuyo nombre contenga el substring "ball" y 
que el fabricante sea el lider en ventas(osea, al cual le haya comprado mas productos en pesos)
ademas, solo se deberan mostrar aquellos registros que el promedio en pesos de productos vendidos 
a cada cliente sea mayor a 150 pesos por unidad.'

GO


CREATE VIEW comprasFabricanteLider AS
SELECT m.manu_name nombre_fabricante, c.lname + ', ' + c.fname nombre_cliente, pt.description descripcion_producto, SUM(i.unit_price * i.quantity) monto_total, SUM(quantity) cantidad
FROM orders o
	INNER JOIN items i ON (o.order_num = i.order_num)
	INNER JOIN manufact m ON (m.manu_code = i.manu_code)
	INNER JOIN product_types pt ON (pt.stock_num = i.stock_num)
	INNER JOIN customer c ON (o.customer_num = c.customer_num)
WHERE m.manu_code IN (SELECT TOP 1 m1.manu_code AS total_ventas
						FROM manufact m1 
							INNER JOIN items i1 ON (m1.manu_code = i1.manu_code)
							INNER JOIN orders o1 ON (i1.order_num = o1.order_num)
						WHERE o1.customer_num = c.customer_num
						GROUP BY m1.manu_code
						ORDER BY SUM(i1.unit_price * i1.quantity)  DESC ) AND pt.description LIKE '%ball%'
GROUP BY m.manu_name, c.lname, c.fname, pt.description
HAVING SUM(i.unit_price * i.quantity)/ SUM(quantity) > 150 

-- Yo asumi que esta buscando el lider de ventas para ese cliente en especifico, en caso contrario solo habria que sacar el where de la subconsulta