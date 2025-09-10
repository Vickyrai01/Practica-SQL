-- Se requiere listar para armar una nueva lista de precios los siguientes datos: nombre del fabricante
-- (manu_name), número de stock (stock_num), descripción
-- (product_types.description), unidad (units.unit), precio unitario (unit_price) y Precio Junio (precio
-- unitario + 20%).

SELECT m.manu_name, p.stock_num, pt.description, u.unit, p.unit_price, p.unit_price * 1,20 precioJunio 
FROM  products p 
	INNER JOIN manufact m ON (p.manu_code = p.manu_code)
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
	INNER JOIN units u ON (p.unit_code = u.unit_code)