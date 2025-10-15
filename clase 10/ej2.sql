/*
Desarrollar una consulta ABC de fabricantes que:
Liste el código y nombre del fabricante, la cantidad de órdenes de compra que contengan
sus productos y el monto total de los productos vendidos.
Mostrar sólo los fabricantes cuyo código comience con A ó con N y posea 3 letras, y los
productos cuya descripción posean el string “tennis” ó el string “ball” en cualquier parte del
nombre y cuyo monto total vendido sea mayor que el total de ventas promedio de todos
los fabricantes (Cantidad * precio unitario / Cantidad de fabricantes que vendieron sus
productos).
Mostrar los registros ordenados por monto total vendido de mayor a menor.

*/

SELECT m.manu_code, manu_name, COUNT(DISTINCT order_num) cant_ordenes, SUM(i.quantity * i.unit_price) monto_total
FROM manufact m
	INNER JOIN products p ON (m.manu_code = p.manu_code)
	INNER JOIN items i ON (p.stock_num = i.stock_num AND m.manu_code = i.manu_code)
	INNER JOIN product_types pt ON (pt.stock_num = p.stock_num)
WHERE  m.manu_code LIKE '[AN]__' 
   AND (description LIKE '%tennis%' OR description LIKE '%ball%')
GROUP BY m.manu_code,manu_name, p.stock_num
HAVING SUM(i.quantity * i.unit_price) > (SELECT SUM(i.quantity * i.unit_price)/ COUNT(DISTINCT manu_code) FROM items i)
