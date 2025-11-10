/*
Mostrar Nombre, Apellido y promedio de orden de compra del cliente referido, 
nombre Apellido y promedio de orden de compra del cliente referente. 
De todos aquellos referidos cuyo promedio de orden de compra sea mayor al de su referente. 
Mostrar la información ordenada por Nombre y Apellido del referido.
El promedio es el total de monto comprado (p x q) / cantidad de órdenes.
Si el cliente no tiene referente, no mostrarlo.
Notas: No usar Store procedures, ni funciones de usuarios, ni tablas temporales. 
*/

SELECT c.fname + ', ' + c.lname nombre_referido, 
	   SUM(i.unit_price * i.quantity) / COUNT(DISTINCT i.order_num) 'Promedio cliente referido',
	   cr.nombre_referente, cr.[Promedio referente]
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i  ON (o.order_num = i.order_num)
	INNER JOIN (SELECT c1.customer_num, c1.fname + ', ' + c1.lname nombre_referente, SUM(i1.unit_price * i1.quantity) / COUNT(DISTINCT i1.order_num) 'Promedio referente'
			    FROM customer c1 
					INNER JOIN orders o1 ON (c1.customer_num = o1.customer_num)
					INNER JOIN items i1  ON (o1.order_num = i1.order_num)
				GROUP BY c1.customer_num, c1.fname, c1.lname
				) cr ON (cr.customer_num = c.customer_num_referedBy)
GROUP BY c.fname, c.lname, cr.nombre_referente, cr.[Promedio referente]
HAVING SUM(i.unit_price * i.quantity) / COUNT(DISTINCT i.order_num) > cr.[Promedio referente]
ORDER BY nombre_referido


/*
Dada la siguiente tabla de auditoria:

Se pide realizar un proceso de “rollback” que realice las operaciones inversas a las leídas en la tabla de auditoría 
hasta una fecha y hora enviada como parámetro.
Si es una accion de Insert ("I"), se deberá hacer un Delete.
Si es una accion de Update, se deberán modificar la fila actual con los datos cuya accion sea "O" (Old).
Si la acción es un delete "D", se deberá insertar el registro en la tabla.
Las filas a “Rollbackear” deberán ser tomados desde el instante actual hasta la fecha y  hora pasada por parámetro.
En el caso que por cualquier motivo haya un error, se deberá cancelar la operación completa e informar el mensaje de error.
*/
CREATE TABLE audit_fabricante(
	nro_audit BIGINT IDENTITY PRIMARY KEY,
	fecha DATETIME DEFAULT getDate(),
	accion CHAR(1) CHECK (accion IN ('I','O','N','D')),
	manu_code char(3),
	manu_name varchar(30),
	lead_time smallint,
	state char(2),
	usuario VARCHAR(30) DEFAULT USER,
);
GO

CREATE PROCEDURE rollbackPR 
	@fechaMax DATETIME,
	@fechaMin DATETIME
AS
BEGIN

	DECLARE manu_cursor CURSOR FOR
		SELECT accion, manu_code, manu_name, lead_time, state FROM audit_fabricante WHERE  fecha BETWEEN @fechaMax AND @fechaMin;

	DECLARE @accion CHAR(1), @manu_code CHAR(3), @manu_name varchar(30), @leat_time SMALLINT, @state CHAR(2);

	OPEN manu_cursor;
	FETCH NEXT FROM manu_cursor INTO @accion, @manu_code, @manu_name, @leat_time, @state;

	BEGIN TRY
		BEGIN TRAN

			WHILE(@@FETCH_STATUS = 0)
			BEGIN
		
				IF(@accion = 'I') BEGIN DELETE FROM manufact WHERE manu_code = @manu_code END

				IF(@accion = 'O')
				BEGIN
				
					UPDATE manufact SET manu_name = @manu_name, lead_time = @leat_time, state = @state
					WHERE manu_code = @manu_code
				END

				IF(@accion = 'D') BEGIN INSERT INTO manufact (manu_code, manu_name, lead_time, state) VALUES (@manu_code, @manu_name, @leat_time, @state) END

				FETCH NEXT FROM manu_cursor INTO @accion, @manu_code, @manu_name, @leat_time, @state;
			END
		
		COMMIT TRAN

	END TRY
	BEGIN CATCH 

		ROLLBACK;
		DECLARE @errorDescription VARCHAR(100);
		SET @errorDescription = 'Error durante el rollback de datos con manu_code ' + @manu_code;
		THROW 50099, @errorDescription, 1

	END CATCH

	CLOSE manu_cursor;
	DEALLOCATE manu_cursor;
END

/*
El responsable del área de ventas nos informó que necesita cambiar el sistema para que a partir de ahora 
no se borren físicamente las órdenes de compra sino que el borrado sea lógico.
Nuestro gerente solicitó que este requerimiento se realice con triggers pero sin modificar el código del sistema actual.
Para ello se agregaron 3 atributos a la tabla ORDERS, flag_baja (0 false / 1 baja lógica), fecha_baja (fecha de la baja), 
user_baja (usuario que realiza la baja).
Se requiere realizar un trigger que cuando se realice una baja que involucre uno o más filas de la tabla ORDERS, 
realice la baja lógica de dicha/s fila/s.
Solo se podrán borrar las órdenes que pertenezcan a clientes que tengan menos de 5 órdenes. 
Para los clientes que tengan 5 o más ordenes se deberá insertar en una tabla BorradosFallidos el customer_num, order_num, fecha_baja y user_baja.
Nota: asumir que ya existe la tabla BorradosFallidos y la tabla ORDERS está modificada.
Ante algún error informarlo y deshacer todas las operaciones.
*/

SELECT * FROM orders

ALTER TABLE orders ADD flag_baja BIT;
ALTER TABLE orders ADD fecha_baja DATETIME;
ALTER TABLE orders ADD user_baja VARCHAR(100);

CREATE TABLE BorradosFallidos(
	customer_num SMALLINT,
	order_num SMALLINT,
	fecha_baja DATETIME,
	user_baja VARCHAR(100)
)
GO

CREATE TRIGGER borradoOrdenesTR ON orders
INSTEAD OF DELETE  AS
BEGIN

	DECLARE order_cursor CURSOR FOR
		SELECT customer_num, order_num FROM deleted;

	DECLARE @customer_num SMALLINT, @order_num SMALLINT;

	OPEN order_cursor;
	FETCH NEXT FROM order_cursor INTO @customer_num, @order_num;

	
	BEGIN TRY

		WHILE(@@FETCH_STATUS = 0)
		BEGIN

			IF ((SELECT COUNT(DISTINCT order_num) FROM orders WHERE customer_num = @customer_num) > 5)
			BEGIN

				INSERT INTO BorradosFallidos VALUES (@customer_num, @order_num, GETDATE(), USER_NAME())

			END
			ELSE
			BEGIN

				UPDATE orders SET flag_baja = 1, fecha_baja = GETDATE(), user_baja = USER_NAME()
				WHERE order_num = @order_num
			END

			FETCH NEXT FROM order_cursor INTO @customer_num, @order_num;
		END
		CLOSE order_cursor;
		DEALLOCATE order_cursor;
	
	END TRY
	BEGIN CATCH

		DECLARE @errorDescription VARCHAR(100);
		SET @errorDescription = 'Error durante el borrado para ' + @order_num;

		CLOSE order_cursor;
		DEALLOCATE order_cursor;

		THROW 50099, @errorDescription, 1

	END CATCH

END