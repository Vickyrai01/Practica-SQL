-- Obtener por cada fabricante (manu_name) y producto (description), la cantidad vendida y el
-- Monto Total vendido (unit_price * quantity). Sólo se deberán mostrar los ítems de los fabricantes
-- ANZ, HRO, HSK y SMT, para las órdenes correspondientes a los meses de mayo y junio del 2015.
-- Ordenar el resultado por el monto total vendido de mayor a menor.

SELECT m.manu_name, p.description, SUM(i.quantity) canVendida, SUM(i.unit_price * i.quantity) montoTotal 
FROM items i 
	INNER JOIN manufact m ON (i.manu_code = m.manu_code)
	INNER JOIN product_types p ON (i.stock_num = p.stock_num)
	INNER JOIN orders o ON (i.order_num = o.order_num)
WHERE m.manu_code IN ('ANZ', 'HRO', 'SMT')  AND o.order_date BETWEEN '2015-05-01' AND '2015-06-30'
GROUP BY m.manu_name, p.description
ORDER BY montoTotal DESC