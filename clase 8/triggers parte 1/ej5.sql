/*
Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante
(manu_code) del producto a comprar no existe en la tabla manufact, inserte una fila en dicha
tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’
donde 999 corresponde al nro. de la orden de compra a la que pertenece el ítem y en el campo
lead_time el valor 1.
*/

CREATE TRIGGER manu_code_inexistente ON items
AFTER INSERT AS
BEGIN

	DECLARE item_cursor CURSOR FOR SELECT manu_code, order_num FROM inserted;
	DECLARE @manu_code CHAR(3), @order_num SMALLINT;

	OPEN item_cursor;
	FETCH NEXT FROM item_cursor INTO @manu_code, @order_num;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		IF NOT EXISTS (SELECT 1 FROM manufact WHERE manu_code = @manu_code)
		BEGIN

			INSERT INTO manufact (manu_code, manu_name, lead_time) VALUES (@manu_code, 'Manu Orden ' + trim(str(@order_num)), 1)

		END

		FETCH NEXT FROM item_cursor INTO @manu_code, @order_num;

	END

	CLOSE item_cursor;
	DEALLOCATE item_cursor;

END;