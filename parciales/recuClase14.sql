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

/*
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

Create View OrdenItems as
select o.order_num, 
	   o.order_date, 
	   o.customer_num, 
	   o.paid_date,
	   i.item_num, 
	   i.stock_num, 
	   i.manu_code, 
	   i.quantity, 
	   i.unit_price
from orders o 
	join items i on o.order_num = i.order_num;

GO

SELECT * FROM OrdenItems;
SELECT * FROM state
GO


CREATE TRIGGER simTR ON OrdenItems 
INSTEAD OF INSERT
AS
BEGIN

	DECLARE viewCursor CURSOR FOR
		SELECT order_num, order_date, customer_num, paid_date, item_num, stock_num, manu_code, quantity, unit_price FROM inserted;

	DECLARE @order_num SMALLINT,@order_date DATETIME,@customer_num SMALLINT, @paid_date DATETIME, @item_num SMALLINT, @stock_num SMALLINT, @manu_code CHAR(3), @quantity INT, @unit_price DECIMAL;


	BEGIN TRANSACTION
	OPEN viewCursor;
	FETCH NEXT FROM viewCursor INTO @order_num, @order_date, @customer_num, @paid_date, @item_num, @stock_num, @manu_code, @quantity, @unit_price;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM inserted i INNER JOIN manufact m ON (m.manu_code = i.manu_code)  
					   WHERE @customer_num = customer_num AND @order_num = order_num GROUP BY order_num HAVING COUNT(DISTINCT m.state) > 2)
		   AND NOT EXISTS (SELECT 1 FROM inserted i INNER JOIN customer c ON(i.customer_num = c.customer_num) INNER JOIN manufact m ON (m.manu_code = i.manu_code)
							WHERE c.state = 'AK' AND @customer_num = i.customer_num GROUP BY i.order_num HAVING SUM(CASE WHEN m.state <> 'AK' THEN 1 ELSE 0 END) > 0)
		BEGIN
			INSERT INTO OrdenItems (order_num, order_date, customer_num, paid_date, item_num,stock_num, 
									manu_code, quantity, unit_price) 
									VALUES
									(@order_num, @order_date, @customer_num, @paid_date, 
									 @item_num, @stock_num, @manu_code, @quantity, @unit_price)	
		END
		
		ELSE BEGIN ROLLBACK RETURN END

		FETCH NEXT FROM viewCursor INTO @order_num, @order_date, @customer_num, @paid_date, @item_num, @stock_num, @manu_code, @quantity, @unit_price;

	
	END
	COMMIT
	CLOSE viewCursor;
	DEALLOCATE viewCursor;

END

GO