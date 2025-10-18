/*
1. Se pide: Crear un trigger que valide que ante un insert de una o más filas en la tabla
ítems, realice la siguiente validación:

	 Si la orden de compra a la que pertenecen los ítems ingresados corresponde a
	clientes del estado de California, se deberá validar que estas órdenes puedan tener
	como máximo 5 registros en la tabla ítem.

	 Si se insertan más ítems de los definidos, el resto de los ítems se deberán insertar
	en la tabla items_error la cual contiene la misma estructura que la tabla ítems más
	un atributo fecha que deberá contener la fecha del día en que se trató de insertar.

Ej. Si la Orden de Compra tiene 3 items y se realiza un insert masivo de 3 ítems más, el
trigger deberá insertar los 2 primeros en la tabla ítems y el restante en la tabla ítems_error.
Supuesto: En el caso de un insert masivo los items son de la misma orden.

*/

CREATE TABLE items_error (
	item_num SMALLINT PRIMARY KEY,
	order_num SMALLINT,
	stock_num SMALLINT,
	manu_code CHAR(3),
	quantity SMALLINT,
	unit_price DECIMAL(8,2),
	fecha DATETIME
)

CREATE TRIGGER triggerC10T2E1
ON items 
INSTEAD OF INSERT AS
BEGIN

	DECLARE items_cursor CURSOR FOR SELECT * FROM inserted

	DECLARE @item_num SMALLINT, 
			@order_num SMALLINT, 
			@stock_num SMALLINT, 
			@manu_code CHAR(3),	
			@quantity SMALLINT,
			@unit_price DECIMAL(8,2),
			@contador SMALLINT;

	OPEN items_cursor;
	FETCH NEXT FROM intems_cursor INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT 1 FROM orders o
					  INNER JOIN customer c ON (c.customer_num = o.customer_num)
				   WHERE o.order_num = @order_num AND c.state = 'CA')
		BEGIN
			IF (SELECT COUNT(DISTINCT i.item_num) FROM items i GROUP BY i.order_num) >= 5
			BEGIN
				INSERT INTO items_error VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price, GETDATE())
			END
			ELSE
			BEGIN
				INSERT INTO items VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price)
			END
	
		END
		
	   ELSE
	   BEGIN
	    	INSERT INTO items VALUES (@item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price)
	   END
	   
	   FETCH NEXT FROM intems_cursor INTO @item_num, @order_num, @stock_num, @manu_code, @quantity, @unit_price;

	END

	CLOSE items_cursor;
	DEALLOCATE items_cursor;
	
END