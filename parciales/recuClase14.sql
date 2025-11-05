/*
1. Query.
Mostrar código y descripción del Estado, código y descripción del tipo de
producto y la cantidad de unidades vendidas del tipo de producto, de los tipos
de productos más comprados (por cantidad) en cada Estado
Mostrar el resultado ordenado por el nombre (o Descripción) del Estado.
*/

SELECT s.state, s.sname, p.stock_num, pt.description, SUM(i.quantity) total_vendido 
FROM state s
	INNER JOIN manufact m ON (s.state = m.state)
	INNER JOIN products p ON (m.manu_code = p.manu_code)
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
	INNER JOIN items i ON (p.stock_num = i.stock_num)
WHERE p.stock_num = (
	SELECT TOP 1 p1.stock_num
	FROM products p1
		INNER JOIN manufact m1 ON (p1.manu_code = m1.manu_code)
		INNER JOIN items i1 ON (p1.stock_num = i1.stock_num)
		INNER JOIN state s1 ON (m1.state = s1.state)
	WHERE s1.state = s.state
	GROUP BY p1.stock_num
	ORDER BY SUM(i1.quantity) DESC
)
GROUP BY s.state, s.sname, p.stock_num, pt.description
ORDER BY s.state, s.sname

/*
2 Trigger
Dada la vista:
Create View OrdenItems as
select o.order_num, o.order_date, o.customer_num, o.paid_date,
i.item_num, i.stock_num, i.manu_code, i.quantity, i.unit_price

from orders o join items i on o.order_num = i.order_num;
Se quieren controlar las altas sobre la vista anterior.
Los controles a realizar son los siguientes:
a. No se permitirá que una Orden contenga ítems de fabricantes de más de
dos estados en la misma orden.
b. Por otro parte los Clientes del estado de ALASKA no podrán realizar
compras a fabricantes fuera de ALASKA.
Notas:
 Las altas son de una misma Orden y de un mismo Cliente pero pueden
tener varias líneas de ítems.
 Ante el incumplimiento de una validación, deshacer TODA la transacción.
*/