-- Se requiere un listado de los items de la orden de pedido Nro. 1004 con los siguientes datos:
-- Número de item (item_num), descripción de cada producto
-- (product_types.description), cantidad (quantity) y precio total (unit_price*quantity).

SELECT order_num, item_num, pt.description, quantity, unit_price * quantity total 
FROM items i INNER JOIN product_types pt 
ON (i.stock_num = pt.stock_num)
WHERE order_num = 1004