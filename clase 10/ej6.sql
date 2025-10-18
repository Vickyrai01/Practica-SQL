/*
Se desean saber los fabricantes que vendieron mayor cantidad de un mismo
producto que la competencia según la cantidad vendida. Tener en cuenta que puede
existir un producto que no sea fabricado por ningún otro fabricante y que puede
haber varios fabricantes que tengan la misma cantidad máxima vendida.
Mostrar el código del producto, descripción del producto, código de fabricante,
cantidad vendida, monto total vendido. Ordenar el resultado código de producto, por
cantidad total vendida y por monto total, ambos en forma decreciente.
Nota: No se permiten utilizar funciones, ni tablas temporales.
*/

SELECT i.manu_code, i.stock_num, pt.description, SUM(i.quantity) cantidad_vendida, SUM(i.quantity * i.unit_price) total_vendido
FROM items i
	INNER JOIN products p ON (i.stock_num = p.stock_num AND i.manu_code = p.manu_code)
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
GROUP BY i.manu_code, i.stock_num, pt.description
HAVING SUM(i.quantity) >= COALESCE((
						SELECT TOP 1 SUM(quantity) cantidad_vendida
						FROM items i1
						WHERE i1.stock_num = i.stock_num AND i1.manu_code != i.manu_code
						GROUP BY i1.manu_code, i1.stock_num
						ORDER BY SUM(quantity) DESC
						),0)
ORDER BY i.manu_code, SUM(i.quantity), SUM(i.quantity * i.unit_price) DESC