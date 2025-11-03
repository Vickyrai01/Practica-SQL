/*
2.a Se requiere crear una tabla temporal #ABC_Productos con las siguientes columnas: Nro. de Stock,
Código de fabricante, descripción del producto, Nombre de Fabricante, Monto total del producto
vendido 'u$ por Producto' y Cantidad del producto pedido 'Unid. por Producto' para los productos
fabricados por fabricantes que fabriquen al menos 10 productos diferentes.
2.b Listar los datos generados en la tablas #ABC_Productos ordenados en forma descendente por 'u$
por Producto' y en forma ascendente por stock_num y manu_code.
*/

CREATE TABLE #ABC_Productos(
	stock_num INT PRIMARY KEY,
	manu_code CHAR(3),
	description VARCHAR(15),
	manu_name VARCHAR(15),
	us_por_producto INT, 
	unid_por_producto INT
)

INSERT INTO #ABC_Productos (stock_num,
							manu_code,
							description,
							manu_name,
							us_por_producto, 
							unid_por_producto)
SELECT p.stock_num, m.manu_code, pt.description, m.manu_name, SUM(i.quantity * i.unit_price), SUM(i.quantity)
FROM products p
	INNER JOIN manufact m ON (p.manu_code = m.manu_code)
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
	INNER JOIN items i ON (p.manu_code = i.manu_code AND i.stock_num = p.stock_num)
GROUP BY p.stock_num, m.manu_code, pt.description, m.manu_name
HAVING (SELECT COUNT(*) FROM products p1 WHERE p1.manu_code = m.manu_code) >=10


SELECT * 
FROM #ABC_Productos
ORDER BY us_por_producto DESC, stock_num ASC, manu_code ASC