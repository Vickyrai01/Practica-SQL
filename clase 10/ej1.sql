/*
1) Crear una vista que devuelva:

	a) Código y Nombre (manu_code,manu_name) de los fabricante, posean o no productos
	(en tabla Products), cantidad de productos que fabrican (cant_producto) y la fecha de
	la última OC que contenga un producto suyo (ult_fecha_orden).
		 De los fabricantes que fabriquen productos sólo se podrán mostrar los que
		fabriquen más de 2 productos.
		 No se permite utilizar funciones definidas por usuario, ni tablas temporales, ni
		UNION.

	b) Realizar una consulta sobre la vista que devuelva manu_code, manu_name,
	cant_producto y si el campo ult_fecha_orden posee un NULL informar ‘No Posee
	Órdenes’ si no posee NULL informar el valor de dicho campo.
		 No se puede utilizar UNION para el SELECT.

*/

CREATE VIEW manufact_view AS
	SELECT m.manu_code, manu_name, COUNT(DISTINCT  p.stock_num) productos_vendidos, MAX(o.order_date) ultima_orden
	FROM manufact m 
		LEFT JOIN products p ON (p.manu_code = m.manu_code)
		LEFT JOIN items i ON (m.manu_code = i.manu_code AND p.stock_num = i.stock_num)
		LEFT JOIN orders o ON (i.order_num = o.order_num)
		GROUP BY m.manu_code, manu_name
		HAVING  COUNT(DISTINCT p.stock_num) = 0 OR COUNT(DISTINCT p.stock_num) > 2


SELECT manu_code, manu_name, productos_vendidos,
    COALESCE(CAST(ultima_orden AS VARCHAR(20)), 'No posee órdenes') ult_fecha_orden
FROM manufact_view ;