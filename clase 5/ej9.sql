-- Se requiere un listado de las todas las órdenes de pedido con los siguientes datos: Número de
-- orden (order_num), fecha de la orden (order_date), número de ítem (item_num), descripción de
-- cada producto (description), cantidad (quantity) y precio total (unit_price*quantity).

SELECT o.order_num, o.order_date, i.item_num, pt.description, i.quantity, i.unit_price * i.quantity precioTotal 
FROM orders o
	INNER JOIN items i ON (o.order_num = i.order_num)
	INNER JOIN product_types pt ON (i.stock_num = pt.stock_num)