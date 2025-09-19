-- Mostrar en una lista de a pares, el código y descripción del producto, y los pares de
-- fabricantes que fabriquen el mismo producto. En el caso que haya un único fabricante
-- deberá mostrar el Código de fabricante 2 en nulo. Ordenar el resultado por código de
-- producto.
-- El listado debe tener el siguiente formato:
-- Nro. de Producto     Descripcion            Cód. de fabric. 1            Cód. de fabric. 2
--(stock_num)            (Description)          (manu_code)                   (manu_code)


SELECT p.stock_num, pt.description, p.manu_code fab1, p2.manu_code fab2 FROM products p
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
	LEFT JOIN products p2 ON (p.stock_num = p2.stock_num) AND (p.manu_code < p2.manu_code)
ORDER BY p.stock_num