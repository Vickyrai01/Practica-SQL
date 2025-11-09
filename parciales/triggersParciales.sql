'Se desea llevar en tiempo real la cantidad de llamadas/reclamos (Cust_calls) de los
Clientes (Customers) que se producen por cada mes del año y por cada tipo (Call_code).

Ante este requerimiento, se solicita realizar un trigger que cada vez que se produzca un 
Alta o Modificación en la tabla Cust_calls, se actualice una tabla donde se lleva la cuenta 
por Año, Mes y Tipo de llamada.

Ejemplo. Si se da de alta una llamada, se debe sumar 1 a la cuenta de ese Año, Mes y Tipo de 
llamada. En caso de ser una modificación y se modifica el tipo de llamada (por ejemplo por 
una mala clasificación del operador), se deberá restar 1 al tipo anterior y sumarle 1 al 
tipo nuevo. Si no se modifica el tipo de llamada no se deberá hacer nada.

Tabla ResumenLLamadas
Anio   decimal(4) PK,
Mes    decimal(2) PK,
Call_code char(1) PK,
Cantidad   int 

Nota: No se modifica la PK de la tabla de llamadas. Tener en cuenta altas y modificaciones múltiples.'

CREATE TABLE ResumenLLamadas (
	anio DECIMAL(4),
	mes DECIMAL(2),
	call_code char(1),
	cantidad INT
)

CREATE TRIGGER callsTR ON cust_calls
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE callsINS CURSOR FOR
		SELECT call_code, YEAR(call_dtime), MONTH(call_dtime) FROM inserted;

	DECLARE @call_code CHAR(1), @anio DECIMAL(4), @mes DECIMAL(2);

	DECLARE callsDEL CURSOR FOR
		SELECT call_code, customer_num, call_dtime FROM deleted;

	DECLARE @customer_num SMALLINT, @call_dtime DATETIME;

	OPEN callsINS;
	FETCH NEXT FROM callsINS INTO @call_code, @anio, @mes;
	
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		UPDATE ResumenLLamadas SET cantidad += 1 WHERE anio = @anio AND 
													   mes = @mes AND
													   call_code = @call_code
	FETCH NEXT FROM callsINS INTO @call_code, @anio, @mes;
	END

	CLOSE callsINS;
	DEALLOCATE callsINS;

	OPEN callsDEL;
	FETCH NEXT FROM callsDEL INTO @call_code, @customer_num, @call_dtime;
	
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT 1 FROM cust_calls WHERE customer_num = @customer_num AND call_dtime = @call_dtime AND call_code <> @call_code)
		BEGIN
			UPDATE ResumenLLamadas SET cantidad = cantidad - 1 WHERE call_code = @call_code AND anio = YEAR(@call_dtime) AND  mes = MONTH(@call_dtime)
		
		END
	FETCH NEXT FROM callsDEL INTO @call_code, @customer_num, @call_dtime;
	END

	CLOSE callsDEL;
	DEALLOCATE callsDEL;
END


'dada la tabla custoemr y customer_audit'
'ante deletes y updates de los campos lname, fname, state o customer_num_refered de la 
tabla customer, auditar los cambios colocando en los campos NEW los valores nuevos y guardar 
en los campos OLD los valores que tenian antes de su borrado/modificacion'.
'en los campos apeyNom se deben guardar los nombres y apellidos concatenados respectivos
en el campo update_date guardar la fecha y hora ctual y en update_user el usuario que realiza 
el update.
verificar en las modificaiones la validez de las claves foraneas ingresdas y en caso de error 
informarlo y deshacer la operacion'
'nota'; 'asumir que ya existe la tabla de auditoria, las modificaciones pueden ser masivas 
y en caso de error solo se debe deshacer la operacion actual'

CREATE TABLE customer_audit (
	apeyNomNEW VARCHAR(100),
	stateNEW CHAR(2),
	customer_num_referedNEW SMALLINT,
	apeyNomOLD VARCHAR(100),
	stateOLD CHAR(2),
	customer_num_referedOLD SMALLINT,
	update_date DATETIME,
	update_user VARCHAR(50)
)
go

CREATE TRIGGER customerTR ON customer
AFTER DELETE, UPDATE
AS
BEGIN

	DECLARE customer_cursor CURSOR FOR
		SELECT  i.lname + ', ' + i.fname nombre_nuevo, i.state estado_nuevo, i.customer_num_referedBy referenciado_nuevo,
				d.lname + ', ' + d.fname nombre_viejo, d.state estado_viejo, d.customer_num_referedBy referenciado_viejo
		FROM deleted d  
			LEFT JOIN inserted i ON (i.customer_num = d.customer_num);

	DECLARE @nombre_nuevo VARCHAR(100), @estado_nuevo CHAR(2), @referenciado_nuevo SMALLINT,
			@nombre_viejo VARCHAR(100), @estado_viejo CHAR(2), @referenciado_viejo SMALLINT;

	OPEN customer_cursor;
	FETCH NEXT FROM customer_cursor INTO @nombre_nuevo, @estado_nuevo, @referenciado_nuevo,
										 @nombre_viejo, @estado_viejo, @referenciado_viejo;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
	
		IF((@estado_nuevo IN (SELECT state FROM state) OR @estado_nuevo IS NULL) AND (@referenciado_nuevo IN (SELECT customer_num FROM customer) OR @referenciado_nuevo IS NULL))
		BEGIN
		
			IF(@nombre_nuevo <> @nombre_viejo OR @estado_nuevo <> @estado_viejo OR @referenciado_nuevo <> @referenciado_viejo)
			BEGIN
				INSERT INTO customer_audit VALUES (@nombre_nuevo, @estado_nuevo, @referenciado_nuevo,
													@nombre_viejo, @estado_viejo, @referenciado_viejo, GETDATE(), USER_NAME())
			END
		END
		ELSE THROW 50099, 'El estado o el customer_num del referenciado son incorrectos', 1;

		FETCH NEXT FROM customer_cursor INTO @nombre_nuevo, @estado_nuevo, @referenciado_nuevo,
											 @nombre_viejo, @estado_viejo, @referenciado_viejo;
	END

	CLOSE customer_cursor;
	DEALLOCATE customer_cursor;
END

'ante un insert validar la existencia de claves primarias en las tablas relacionadas, fabricante 
unit_code y product_types.
si no existe el fabricante, devolver un mensaje de error y deshacer la transaccion para 
ese registro. en caso de no existir en units y product types, insertar el registro correspondiente 
y continuar la operacion '
GO

CREATE TRIGGER productsTR ON products
INSTEAD OF INSERT AS
BEGIN

	DECLARE product_cursor CURSOR FOR
		SELECT stock_num, manu_code, unit_price, unit_code FROM inserted;

	DECLARE @stock_num SMALLINT, @manu_code CHAR(3), @unit_price DECIMAL, @unit_code SMALLINT;

	OPEN product_cursor;
	FETCH NEXT FROM product_cursor INTO @stock_num, @manu_code, @unit_price, @unit_code;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
	
		BEGIN TRY
		BEGIN TRANSACTION
			IF NOT EXISTS(SELECT 1 FROM manufact WHERE manu_code = @manu_code) THROW 50099, 'No existe fabricante con ese manu_code ', 1;
			ELSE
			BEGIN
			
				IF NOT EXISTS (SELECT 1 FROM units WHERE unit_code = @unit_code)
				BEGIN
					INSERT INTO units (unit_code) VALUES (@unit_code)
				END
				IF NOT EXISTS (SELECT 1 FROM product_types WHERE stock_num = @stock_num)
				BEGIN
				
					INSERT INTO product_types (stock_num) VALUES (@stock_num)

				END

				INSERT INTO products (stock_num, manu_code, unit_price, unit_code) VALUES (@stock_num, @manu_code, @unit_price, @unit_code)
				COMMIT TRANSACTION 
			END
		
		END TRY
		BEGIN CATCH
		ROLLBACK TRANSACTION;
		--DECLARE @errorDescripcion VARCHAR(100)
		--SELECT @errorDescripcion = 'No existe el manu_code '+ @manu_code;
		--THROW 50100, @errorDescripcion , 1;

		END CATCH
		
		FETCH NEXT FROM product_cursor INTO @stock_num, @manu_code, @unit_price, @unit_code;
	END

	CLOSE product_cursor;
	DEALLOCATE product_cursor;

END