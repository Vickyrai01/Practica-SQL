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


'crear una consulta que devuelva:'
'Apellido, nombre AS CLIENTE,
suma de todo lo comprado por el cliente as totalCompra
apellido,nombre as ClienteReferido ,
suma de todo lo comprado por el referido * 0.05 AS totalComision'

SELECT c.lname + ', ' + c.fname Cliente, COALESCE(SUM(i.unit_price * i.quantity), 0) totalCompra,COALESCE( cr.ClienteReferido, 'No tiene') ClienteReferido,COALESCE(cr.totalComision, 0) totalComision
FROM customer c 
	LEFT JOIN orders o ON (o.customer_num = c.customer_num)
	LEFT JOIN items i ON (i.order_num = o.order_num)
	LEFT JOIN (SELECT c1.customer_num, c1.lname + ', ' + c1.fname ClienteReferido, SUM(i1.unit_price * i1.quantity) * 0.05 totalComision
				FROM customer c1
					INNER JOIN orders o1 ON (o1.customer_num = c1.customer_num)
					INNER JOIN items i1 ON (i1.order_num = o1.order_num)
				GROUP BY c1.customer_num,c1.lname,c1.fname) cr ON (cr.customer_num = c.customer_num_referedBy)
GROUP BY c.lname,c.fname, cr.ClienteReferido, cr.totalComision
ORDER BY Cliente


/*
Obtener los Tipos de Productos, monto total comprado por cliente y por sus referidos. 
Mostrar:
descripción del Tipo de Producto, Nombre y apellido del cliente, monto total comprado de ese
tipo de producto, Nombre y apellido de su cliente referido y el monto total comprado de su
referido. Ordenado por Descripción, Apellido y Nombre del cliente (Referente).
Nota: Si el Cliente no tiene referidos o sus referidos no compraron el mismo producto, 
mostrar -- ́como nombre y apellido del referido y 0 (cero) en la cantidad vendida.
*/


SELECT pt.description, c.fname + ', ' + c.lname nombre_cliente, SUM(i.quantity * i.unit_price) monto_total,  COALESCE(nombre_referido, 'No tiene') nombre_referido, COALESCE(monto_total_referido, 0) monto_total_referido
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i ON (i.order_num = o.order_num)
	INNER JOIN product_types pt ON (pt.stock_num = i.stock_num)
	LEFT JOIN (SELECT c1.customer_num, i1.stock_num,c1.fname + ', ' + c1.lname nombre_referido , SUM(i1.quantity * i1.unit_price) monto_total_referido
			   FROM customer c1
				  INNER JOIN orders o1 ON (c1.customer_num = o1.customer_num)
				  INNER JOIN items i1 ON (i1.order_num = o1.order_num)
				GROUP BY c1.customer_num, i1.stock_num,c1.fname, c1.lname) cr ON (cr.customer_num = c.customer_num_referedBy AND cr.stock_num = i.stock_num)
GROUP BY pt.description, c.fname, c.lname,nombre_referido, monto_total_referido
ORDER BY pt.description, nombre_referido


/*
4)
vista que muestre las tres primeras provincias que tengan la mayor cantidad de compras ,
mostrar nombre y apellido del cliente con mayor total de compra para esa provincia, 
total comprado y nombre de la provincia.
*/
GO

CREATE VIEW prov_mas_comprasVW AS
	SELECT c.fname, c.lname, SUM(i.quantity * i.unit_price) total_gastado, s.state
	FROM customer c
		INNER JOIN orders o ON (o.customer_num = c.customer_num)
		INNER JOIN items i ON (i.order_num = o.order_num)
		INNER JOIN (SELECT TOP 3 c1.state
					FROM customer c1
						INNER JOIN orders o1 ON (o1.customer_num = c1.customer_num)
						INNER JOIN items i1 ON (i1.order_num = o1.order_num)
					GROUP BY c1.state
					ORDER BY SUM(i1.quantity * i1.unit_price) DESC) s ON (c.state = s.state)
	WHERE c.customer_num IN (SELECT TOP 1 c2.customer_num
							 FROM customer c2
								INNER JOIN orders o2 ON (c2.customer_num = o2.customer_num)
								INNER JOIN items i2 ON (i2.order_num = o2.order_num)
							 WHERE c2.state = s.state
							 GROUP BY c2.customer_num
							 ORDER BY SUM(i2.quantity * i2.unit_price) DESC)
	GROUP BY c.fname, c.lname, s.state

	/*
5)
seleccionar codigo de fabricante, nombre fabricante, cantidad de ordenes del fabricante,
cantidad total vendida del fabricante, promedio de las cantidades vendidas de todos los 
fabricantes cuyas ventas totales sean mayores al promedio de las ventas de todos los 
fabricantes
mostrar el resultado ordenado por cantidad total vendida en forma descendente
*/

SELECT m.manu_code, 
	   m.manu_name, 
	   COUNT(DISTINCT i.order_num) cant_ordenes, 
	   SUM(i.quantity) cantidad_vendida, 
	   (SELECT AVG(i1.quantity)
		FROM items i1
		WHERE i1.manu_code IN(SELECT i2.manu_code 
							  FROM items i2
							  GROUP BY i2.manu_code
							  HAVING AVG(i2.quantity * i2.unit_price) > (SELECT AVG(i3.quantity * i3.unit_price) FROM items i3))) prom_cant_ventas
FROM manufact m 
	INNER JOIN items i ON (m.manu_code = i.manu_code)
GROUP BY m.manu_code, m.manu_name

SELECT m.manu_code, 
	   m.manu_name, 
	   COUNT(DISTINCT i.order_num) cant_ordenes, 
	   SUM(i.quantity) cantidad_vendida, 
	   (SELECT AVG(i1.quantity)
		FROM items i1
		WHERE i1.manu_code IN(SELECT i2.manu_code 
							  FROM items i2
							  GROUP BY i2.manu_code
							  HAVING AVG(i2.quantity * i2.unit_price) > (SELECT AVG(i3.quantity * i3.unit_price) FROM items i3))) prom_cant_ventas
FROM manufact m 
	INNER JOIN items i ON (m.manu_code = i.manu_code)
GROUP BY m.manu_code, m.manu_name

SELECT m.manu_code, 
	   m.manu_name, 
	   COUNT(DISTINCT i.order_num) cant_ordenes, 
	   SUM(i.quantity) cantidad_vendida, 
	   (SELECT AVG(i1.quantity)
		FROM items i1
		WHERE i1.manu_code IN(SELECT i2.manu_code 
							  FROM items i2
							  GROUP BY i2.manu_code
							  HAVING AVG(i2.quantity * i2.unit_price) > (SELECT AVG(i3.quantity * i3.unit_price) FROM items i3))) prom_cant_ventas
FROM manufact m 
	INNER JOIN items i ON (m.manu_code = i.manu_code)
GROUP BY m.manu_code, m.manu_name
ORDER BY cantidad_vendida DESC


SELECT m.manu_code, 
	   m.manu_name, 
	   COUNT(DISTINCT i.order_num) cant_ordenes, 
	   SUM(i.quantity) cantidad_vendida, (SELECT SUM(i1.quantity * i1.unit_price) / COUNT(DISTINCT i1.manu_code) FROM items i1) promedio_ventas_totales
FROM manufact m 
	INNER JOIN items i ON (m.manu_code = i.manu_code)
GROUP BY m.manu_code, m.manu_name
HAVING SUM(i.quantity * i.unit_price) > (SELECT SUM(i2.quantity * i2.unit_price) / COUNT(DISTINCT i2.manu_code) FROM items i2)
ORDER BY cantidad_vendida DESC