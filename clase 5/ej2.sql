-- Listar los ítems de la orden número 1004, incluyendo una descripción de cada uno. El listado debe
-- contener: Número de orden (order_num), Número de Item (item_num), Descripción del producto
-- (product_types.description), Código del fabricante (manu_code), Cantidad (quantity), Precio total
-- (unit_price*quantity).

SELECT o.order_num, item_num, p.description, i.manu_code, i.quantity, unit_price*quantity total
FROM orders o 
	INNER JOIN items i ON (o.order_num = i.order_num) 
	INNER JOIN product_types p ON (i.stock_num = p.stock_num)
WHERE o.order_num = 1004