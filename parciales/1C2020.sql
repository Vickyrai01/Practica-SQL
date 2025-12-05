/*
Obtener los Tipos de Productos, monto total comprado por cliente y por sus referidos. Mostrar:
descripción del Tipo de Producto, Nombre y apellido del cliente, monto total comprado de ese
tipo de producto, Nombre y apellido de su cliente referido y el monto total comprado de su
referido. Ordenado por Descripción, Apellido y Nombre del cliente (Referente).
Nota: Si el Cliente no tiene referidos o sus referidos no compraron el mismo producto, mostrar
 ́-- ́ como nombre y apellido del referido y 0 (cero) en la cantidad vendida.
*/

SELECT pt.description, c.lname apellido, c.fname nombre, SUM(i.quantity * i.unit_price) montoTotal, 
	  COALESCE( cr.lname, '--') apellidoReferido,COALESCE( cr.fname , '--')nombreReferido, COALESCE (montoReferido, 0) montoReferido
FROM customer c
	INNER JOIN orders o ON (o.customer_num = c.customer_num)
	INNER JOIN items i  ON (i.order_num = o.order_num)
	INNER JOIN product_types pt ON (i.stock_num = pt.stock_num)
	LEFT JOIN (SELECT c.customer_num, c.lname, c.fname, i.stock_num, SUM(i.quantity * i.unit_price) montoReferido
			   FROM customer c
				INNER JOIN orders o ON (o.customer_num = c.customer_num)
				INNER JOIN items i  ON (i.order_num = o.order_num)
			   GROUP BY c.customer_num, c.lname, c.fname, i.stock_num) cr ON (c.customer_num_referedBy = cr.customer_num AND i.stock_num = cr.stock_num)
GROUP BY pt.description, c.lname, c.fname, cr.lname, cr.fname, montoReferido
ORDER BY pt.description, c.lname, c.fname

/*
d. Crear un procedimiento actualizaPrecios que reciba como parámetro una fecha a partir de la cual
procesar los registros de una tabla Novedades que contiene los nuevos precios de Productos con
la siguiente estructura/información.
FechaAlta, Manu_code, Stock_num, descTipoProducto, Unit_price
Por cada fila de la tabla Novedades
	Si no existe el Fabricante, devolver un error de Fabricante inexistente y descartar la novedad.

	Si no existe el stock_num (pero existe el Manu_code) darlo de alta en la tabla Product_types
	
	Si ya existe el Producto actualizar su precio
	
	Si no existe, Insertarlo en la tabla de productos.

Nota: Manejar una transacción por novedad y errores no contemplados.
*/


CREATE TABLE productosNovedades(
	fechaAlta DATE,
	manu_code CHAR(3),
	stock_num SMALLINT,
	descTipoProducto VARCHAR(20),
	unit_price DECIMAL
)

GO
CREATE PROCEDURE actualizarPreciosPR @fechaAlta DATE
AS
BEGIN

	DECLARE productCursor CURSOR FOR
		SELECT manu_code, stock_num, descTipoProducto, unit_price FROM productosNovedades WHERE fechaAlta >= @fechaAlta;

	DECLARE @manu_code CHAR(3), @stock_num SMALLINT, @descTipoProducto VARCHAR(20), @unit_price DECIMAL;
	
	OPEN productCursor;
	FETCH NEXT FROM productCursor INTO @manu_code, @stock_num, @descTipoProducto, @unit_price;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		
		BEGIN TRAN
		BEGIN TRY

			IF NOT EXISTS(SELECT 1 FROM manufact WHERE manu_code = @manu_code)
				THROW 50001, 'No existe este fabricante', 1;


			IF NOT EXISTS (SELECT 1 FROM product_types WHERE stock_num = @stock_num)
			BEGIN
				INSERT INTO product_types VALUES (@stock_num, @descTipoProducto)
			END

			IF EXISTS (SELECT 1 FROM products WHERE stock_num = @stock_num AND manu_code = @manu_code)
			BEGIN
				UPDATE products SET unit_price = @unit_price WHERE manu_code = @manu_code AND stock_num = @stock_num
			END
			ELSE
			BEGIN

				INSERT INTO products (stock_num, manu_code, unit_price) VALUES (@stock_num, @manu_code, @unit_price)
			END


			COMMIT TRAN
		END TRY
		BEGIN CATCH
			
			PRINT 'Ha ocurrido el siguiente error: ' + ERROR_MESSAGE();
			ROLLBACK

		
		END CATCH
		
		FETCH NEXT FROM productCursor INTO @manu_code, @stock_num, @descTipoProducto, @unit_price;
	END


	CLOSE productCursor;
	DEALLOCATE productCursor;

END


/*
Triggers
Se desea llevar en tiempo real la cantidad de llamadas/reclamos (Cust_calls) de los Clientes
(Customers) que se producen por cada mes del año y por cada tipo (Call_code).
Ante este requerimiento, se solicita realizar un trigger que cada vez que se produzca un Alta o
Modificación en la tabla Cust_calls, se actualice una tabla ResumenLLamadas donde se lleve en
tiempo real la cantidad de llamadas por Año, Mes y Tipo de llamada.
Ejemplo. Si se da de alta una llamada, se debe sumar 1 a la cantidad de ese Año, Mes y Tipo de
llamada. En caso de ser una modificación y se modifica el tipo de llamada (por ejemplo por una
mala clasificación del operador), se deberá restar 1 al tipo anterior y sumarle 1 al tipo nuevo. Si
no se modifica el tipo de llamada no se deberá hacer nada.

Tabla ResumenLLamadas
	Anio decimal(4) PK,
	Mes decimal(2) PK,
	Call_code char(1) PK,
	Cantidad int
Nota: No se modifica la PK de la tabla de llamadas. Tener en cuenta altas y modificaciones
múltiples.

*/



CREATE TABLE ResumenLLamadas(
	Anio decimal(4),
	Mes decimal(2),
	Call_code char(1),
	Cantidad int
)

GO
CREATE TRIGGER llamadasTR ON cust_calls
AFTER INSERT, UPDATE AS
BEGIN

	DECLARE @anio DECIMAL(4), @mes DECIMAL(2), @call_codeINS CHAR(1), @call_codeDEL CHAR(1);

	IF NOT EXISTS (SELECT 1 FROM deleted)
	BEGIN
		DECLARE callCursor CURSOR FOR 
			SELECT YEAR(call_dtime), MONTH(call_dtime), call_code FROM inserted;

		OPEN callCursor;
		FETCH NEXT FROM callCursor INTO @anio, @mes, @call_codeINS;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF EXISTS (
                SELECT 1 FROM ResumenLLamadas
                WHERE Anio = @anio AND Mes = @mes AND Call_code = @call_codeINS
            )
            BEGIN
                UPDATE ResumenLLamadas
                SET Cantidad = Cantidad + 1
                WHERE Anio = @anio AND Mes = @mes AND Call_code = @call_codeINS;
            END
            ELSE
            BEGIN
                INSERT INTO ResumenLLamadas (Anio, Mes, Call_code, Cantidad)
                VALUES (@anio, @mes, @call_codeINS, 1);
            END

            FETCH NEXT FROM callCursor INTO @anio, @mes, @call_codeINS;
        END

		CLOSE callCursor;
		DEALLOCATE callCursor;

	END
	ELSE
	BEGIN

		DECLARE callCursor CURSOR FOR
			SELECT YEAR(d.call_dtime), MONTH(d.call_dtime), i.call_code, d.call_code
			FROM deleted d
			LEFT JOIN inserted i ON (i.customer_num = d.customer_num AND i.call_dtime = d.call_dtime)
			WHERE d.call_code <> i.call_code

		OPEN callCursor;
		FETCH NEXT FROM callCursor INTO @anio, @mes, @call_codeINS, @call_codeDEL;

		WHILE(@@FETCH_STATUS =0)
		BEGIN
			
			UPDATE ResumenLLamadas SET Cantidad = Cantidad + 1
			WHERE Anio = @anio AND Mes = @mes AND Call_code = @call_codeINS

			UPDATE ResumenLLamadas SET Cantidad = Cantidad - 1
			WHERE Anio = @anio AND Mes = @mes AND Call_code = @call_codeDEL

			FETCH NEXT FROM callCursor INTO @anio, @mes, @call_codeDEL;

		END
		
		CLOSE callCursor;
		DEALLOCATE callCursor;

	END

END
