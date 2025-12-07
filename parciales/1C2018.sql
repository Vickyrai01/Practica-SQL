/*
c.	Crear una consulta que devuelva:
La siguientes cuatro atributos

Apellido, Nombre AS Cliente, 
Suma de todo lo comprado por el cliente AS totalCompra,
Apellido, Nombre AS ClienteReferido,
Suma de lo comprado por el referido*0.05 AS totalComision

Consideraciones.
•	En el caso que un no tenga OCs deberá mostrar 0 en el campo totalCompra
•	En el caso que un Cliente no tenga Referidos deberá mostrar al mismo con NULL en las columnas ClienteReferido y totalComision.
•	Para calcular la comisión del cliente se deberán sumar (cant*precio) de todos los productos comprados por el ClienteReferido cuyo stock_num sea 1,4,5,6,9. La comisión es del 5%.
•	Se deberá ordenar la salida por el Apellido y Nombre del Cliente.

No se pueden utilizar tablas temporales, ni funciones de usuario.

*/
SELECT	cr.lname, cr.fname, cr.totalGastadoReferente,
		c.lname, c.fname,SUM(
							CASE 
								WHEN i.stock_num IN (1,4,5,6,9) 
								THEN i.quantity * i.unit_price * 0.05
								ELSE 0
							END) totalComision
FROM customer c 
	LEFT JOIN orders o ON (o.customer_num = c.customer_num)
	LEFT JOIN items i ON (i.order_num = o.order_num)
	RIGHT JOIN (SELECT c.customer_num, c.lname, c.fname, COALESCE( SUM(i.quantity * i.unit_price), 0) totalGastadoReferente
				FROM customer c 
					LEFT JOIN orders o ON (o.customer_num = c.customer_num)
					LEFT JOIN items i ON (i.order_num = o.order_num)
				GROUP BY c.customer_num, c.lname, c.fname) cr ON (c.customer_num_referedBy = cr.customer_num)
GROUP BY cr.lname, cr.fname, cr.totalGastadoReferente, c.lname, c.fname
ORDER BY c.lname, c.fname


/*
d.	Stored Procedures

Desarrollar un stored procedure maneje la inserción o modificación de un producto determinado.
Parámetros de Entrada STOCK_NUM, MANU_CODE, UNIT_PRICE, UNIT_CODE, DESCRIPTION

Si existe el producto en la tabla PRODUCTS actualizar los atributos que no pertenecen a la clave primaria.
Si no existe el producto en la tabla PRODUCTS Insertar fila en la tabla, previamente validar lo siguiente:
•	EXISTENCIA de MANU_CODE en Tabla MANUFACT - Informando Error por Fabricante Inexistente.
•	EXISTENCIA de STOCK_NUM en Tabla PRODUCT_TYPES - Si no existe Insertar un registro en la tabla STOCK_NUM, 
	si existe realizar UPDATE del atributo ‘description’.
•	EXISTENCIA del atributo  UNIT_CODE en la Tabla UNITS - Informando Error por Código de Unidad Inexistente.
*/
GO
CREATE PROCEDURE insertarProductosPR @stock_num SMALLINT, @manu_code CHAR(3), @unit_price DECIMAL, @unit_code SMALLINT, @description VARCHAR(15)
AS
BEGIN

	IF EXISTS (SELECT 1 FROM products WHERE manu_code = @manu_code AND stock_num = @stock_num)
	BEGIN

		UPDATE products SET unit_price = @unit_price, unit_code = @unit_code WHERE manu_code = @manu_code AND stock_num = @stock_num;
		UPDATE product_types SET description = @description WHERE stock_num= @stock_num
	END
	ELSE
	BEGIN

		IF NOT EXISTS (SELECT 1 FROM manufact WHERE manu_code = @manu_code)
			THROW 500001, 'No existe este fabricante', 1

		IF NOT EXISTS (SELECT 1 FROM units WHERE unit_code = @unit_code)
			THROW 500002, 'No existe este unit code', 1

		IF NOT EXISTS (SELECT 1 FROM product_types WHERE stock_num = @stock_num)
		BEGIN

			INSERT INTO product_types VALUES (@stock_num, @description)
		END
		ELSE
		BEGIN

			UPDATE product_types SET description = @description WHERE stock_num= @stock_num
		END

		INSERT INTO products (stock_num, manu_code, unit_price, unit_code) VALUES (@stock_num, @manu_code, @unit_price, @unit_code)

	END

END


CREATE TRIGGER llamadasTR1 ON v_Productos INSTEAD OF INSERT AS
BEGIN

	DECLARE llamadaCursor CURSOR FOR
		SELECT customer_num, fname, lname, state , call_dtime, user_id, call_code, call_descr, code_descr FROM inserted;

	DECLARE @customer_num SMALLINT, @fname VARCHAR(15), @lname VARCHAR(15), @state CHAR(2), @call_dtime DATETIME,
			@user_id CHAR(32), @call_code CHAR(1), @call_descr VARCHAR(30), @code_description VARCHAR(30);

	
	OPEN llamadaCursor;
	FETCH NEXT FROM llamadaCursor INTO @customer_num, @fname, @lname, @state, @call_dtime,
										@user_id, @call_code, @call_descr, @code_description;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		
		IF (@customer_num IS NULL OR @call_code IS NULL OR @state IS NULL)
			THROW 500001, 'Las claves primarias no pueden ser nulas ', 1

		IF NOT EXISTS (SELECT 1 FROM call_type WHERE call_code = @call_code)
			THROW 500002, 'No existe el codigo de la llamada que se quiere insertar ', 1

		IF NOT EXISTS (SELECT 1 FROM state WHERE state = @state)
			THROW 500003, 'No existe el estado que se quiere insertar', 1

		IF EXISTS(SELECT 1 FROM customer WHERE customer_num = @customer_num)
		BEGIN
			UPDATE customer SET fname = @fname, lname = @lname, state = @state WHERE customer_num = @customer_num
		END
		ELSE
		BEGIN
			INSERT INTO customer (customer_num, fname, lname, state) VALUES (@customer_num, @fname, @lname, @state)
		END


		INSERT INTO cust_calls (customer_num, call_dtime, user_id, call_code, call_descr) VALUES (@customer_num, @call_dtime, @user_id, @call_code, @call_descr)

		IF NOT EXISTS (SELECT 1 FROM call_type WHERE call_code = @call_code)
		BEGIN
			INSERT INTO call_type (call_code, code_descr)
			VALUES (@call_code, @code_description);
		END


		FETCH NEXT FROM llamadaCursor INTO @customer_num, @fname, @lname, @state, @call_dtime,
										@user_id, @call_code, @call_descr, @code_description;
	END

	CLOSE llamadaCursor;
	DEALLOCATE llamadaCursor;
END