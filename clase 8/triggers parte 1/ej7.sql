/*
Crear la vista Productos_x_fabricante que tenga los siguientes atributos:
Stock_num, description, manu_code, manu_name, unit_price
Crear un trigger de Insert sobre la vista anterior que ante un insert, inserte una fila en la tabla
Products, pero si el manu_code no existe en la tabla manufact, inserte además una fila en dicha
tabla con el campo lead_time en 1.
*/

CREATE VIEW Productos_x_fabricante AS
SELECT p.stock_num, pt.description, m.manu_code, m.manu_name, p.unit_price  FROM products p 
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
	INNER JOIN manufact m ON (p.manu_code = m.manu_code)


CREATE TRIGGER Productos_x_fabricante_trigger ON Productos_x_fabricante
INSTEAD OF INSERT AS
BEGIN

	DECLARE @stock_num smallint
	DECLARE @manu_code char(3)
	DECLARE @description varchar(15)
	DECLARE @manu_name varchar(15)
	DECLARE @unit_price decimal(6,2)
	
	DECLARE insert_cursor CURSOR FOR
		SELECT stock_num, manu_code, description, manu_name, unit_price
		FROM inserted

	OPEN insert_cursor;
	FETCH NEXT FROM insert_cursor INTO @stock_num, @manu_code, @description, @manu_name, @unit_price;
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
	
		IF NOT EXISTS (SELECT 1 FROM manufact WHERE manu_code = @manu_code)
		BEGIN 
			INSERT INTO manufact (manu_code, manu_name, lead_time) VALUES (@manu_code, @manu_name, 1)
		END
	
	INSERT INTO products (stock_num, manu_code, unit_price) VALUES (@stock_num, @manu_code, @unit_price)

	FETCH NEXT FROM insert_cursor INTO @stock_num, @manu_code, @description, @manu_name, @unit_price;
	END

	CLOSE insert_cursor;
	DEALLOCATE insert_cursor;
END