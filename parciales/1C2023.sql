/*
3. Query
Por cada estado (state) seleccionar los dos clientes que mayores montos compraron. Se
deberá mostrar el código del estado, nro de cliente, nombre y apellido del cliente y monto total
comprado.
Mostrar la información ordenada por provincia y por monto comprado en forma descendente.
Notas: No se puede usar Store procedures, ni funciones de usuarios, ni tablas temporales.
*/

SELECT s.state, c.customer_num, c.fname + ' ' + c.lname 'Nombre y apellido', SUM(i.quantity * unit_price) 'Monto total gastado'
FROM state s
	INNER JOIN customer c ON (c.state = s.state)
	INNER JOIN orders   o ON (c.customer_num = o.customer_num)
	INNER JOIN items	i ON (i.order_num = o.order_num)
WHERE c.customer_num IN (SELECT TOP 2 o1.customer_num
						 FROM orders o1
							INNER JOIN items i1 ON (i1.order_num = o1.order_num)
							INNER JOIN customer c1 ON (c1.customer_num = o1.customer_num)
						 WHERE c1.state = s.state
						 GROUP BY o1.customer_num
						 ORDER BY SUM(i1.quantity * i1.unit_price) DESC)
GROUP BY s.state, c.customer_num, c.fname, c.lname
ORDER BY s.state, SUM(i.quantity * unit_price) DESC


/*
4. Store Procedure
Crear un procedimiento BorrarProd que en base a una tabla ProductosDeprecados que
contiene filas con Productos a borrar realice el borrado lógico de los mismos de la tabla
Products asignando el valor ‘D’ al estatus del mismo. El procedimiento deberá guardar en
una tabla de auditoria AuditProd (stock_num, manu_code, Mensaje) el producto y un mensaje
que podrá ser: ‘Deprecado’, ‘Deprecado con ventas’ o cualquier mensaje de error que se
produjera. Crear las tablas Productos Deprecados y AuditProd.
Deberá manejar una transacción por registro. Ante un error deshacer lo realizado y seguir
procesando los demás registros. Asimismo, deberá manejar excepciones ante cualquier error
que ocurra.
*/
CREATE TABLE productsDeprecados(
	stock_num SMALLINT,
	manu_code CHAR(3),
	unit_price DECIMAL,
	unit_code SMALLINT
)

CREATE TABLE auditProducts(
	stock_num SMALLINT,
	manu_code CHAR(3),
	mensaje VARCHAR(250)
)
GO
CREATE PROCEDURE BorrarProdPR 
AS
BEGIN

	DECLARE productCursor CURSOR FOR
		SELECT stock_num, manu_code FROM productsDeprecados;

	DECLARE @stock_num SMALLINT, @manu_code CHAR(3);
	
	OPEN productCursor;
	FETCH NEXT FROM productCursor INTO @stock_num, @manu_code;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN

		BEGIN TRAN
		BEGIN TRY
	
			DECLARE @mensaje VARCHAR(250) = 'Deprecado'

			IF EXISTS (SELECT 1 FROM items WHERE manu_code = @manu_code AND stock_num = @stock_num)
			BEGIN
				SET @mensaje = 'Deprecado con ventas'
			END

			UPDATE products SET status = 'D' WHERE manu_code = @manu_code AND stock_num = @stock_num

			INSERT INTO auditProducts VALUES (@stock_num, @manu_code, @mensaje)
		

        	COMMIT TRAN
			FETCH NEXT FROM productCursor INTO @stock_num, @manu_code;

		END TRY
		BEGIN CATCH
			ROLLBACK

			PRINT 'Ha ocurrido el siguiente error: ' + ERROR_MESSAGE();
			INSERT INTO auditProducts VALUES (@stock_num, @manu_code, ERROR_MESSAGE())
			
			FETCH NEXT FROM productCursor INTO @stock_num, @manu_code;

		END CATCH
	END

	CLOSE productCursor;
	DEALLOCATE productCursor;

END

/*
Crear un trigger que ante un cambio de precios en un producto inserte un nuevo registro con
el precio anterior (no el nuevo) en la tabla PRECIOS_HIST.
La estructura de la tabla PRECIOS_HIST es (stock_num, manu_code, fechaDesde,
fechaHasta, precio_unit). La fecha desde del nuevo registro será la fecha hasta del último
cambio de precios de ese producto y su fecha hasta será la fecha del dia. SI no tuviese un
registro de precio anterior ingrese como fecha desde ‘2000-01-01’.
Nota: Las actualizaciones de precios pueden ser masivas.
*/

CREATE TABLE preciosHistoricos(
	stock_num SMALLINT,
	manu_code CHAR(3),
	fechaDesde DATE,
	fechaHasta DATE,
	precio_unit DECIMAL
)

GO
CREATE TRIGGER cambioPreciosTR ON products
AFTER update AS
BEGIN
	
	DECLARE productCursor CURSOR FOR
		SELECT d.manu_code, d.stock_num, d.unit_price
		FROM inserted i
			INNER JOIN deleted d ON (d.stock_num = i.stock_num AND d.manu_code = i.manu_code)
		WHERE d.unit_price <> i.unit_price

	DECLARE @manu_code CHAR(3), @stock_num SMALLINT, @unit_price DECIMAL;

	OPEN productCursor;
	FETCH NEXT FROM productCursor INTO @manu_code, @stock_num, @unit_price;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		
		IF NOT EXISTS(SELECT 1 FROM preciosHistoricos WHERE manu_code = @manu_code AND stock_num = @stock_num)
		BEGIN

			INSERT INTO preciosHistoricos VALUES (@stock_num, @manu_code, '2000-01-01', GETDATE(), @unit_price)
		END
		ELSE
		BEGIN

			DECLARE @fecha DATE;
			SELECT @fecha = MAX(fechaHasta) FROM preciosHistoricos WHERE manu_code = @manu_code AND stock_num = @stock_num

			INSERT INTO preciosHistoricos VALUES (@stock_num, @manu_code, @fecha, GETDATE(), @unit_price)

		END
	
		FETCH NEXT FROM productCursor INTO @manu_code, @stock_num, @unit_price;
	END

	CLOSE productCursor;
	DEALLOCATE productCursor;


END