/*
Crear un trigger que ante un borrado sobre la tabla ORDERS realice un borrado en cascada
sobre la tabla ITEMS, validando que sólo se borre 1 orden de compra.
Si detecta que están queriendo borrar más de una orden de compra, informará un error y
abortará la operación.
*/

CREATE TRIGGER borrar_items ON orders
INSTEAD OF DELETE AS
	DECLARE @order_num SMALLINT
BEGIN
	IF ((SELECT COUNT(*) FROM deleted) >1) 
		THROW 50000, 'No se puede eliminar mas de una orden a la vez', 1	
		
	ELSE
		BEGIN

			SELECT @order_num = order_num FROM deleted;

			DELETE FROM items WHERE order_num = @order_num;
			DELETE FROM orders WHERE order_num = @order_num
		END

END;