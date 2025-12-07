/*
Mostrar Nombre, Apellido y promedio de orden de compra del cliente referido, 
nombre Apellido y promedio de orden de compra del cliente referente. 
De todos aquellos referidos cuyo promedio de orden de compra sea mayor al de su referente. 
Mostrar la información ordenada por Nombre y Apellido del referido.
El promedio es el total de monto comprado (p x q) / cantidad de órdenes.
Si el cliente no tiene referente, no mostrarlo.
Notas: No usar Store procedures, ni funciones de usuarios, ni tablas temporales. 
*/


SELECT c.lname, c.fname, SUM(i.quantity * i.unit_price) / COUNT(DISTINCT o.order_num) 'Promedio oc referido',
	   cr.lname, cr.fname, cr.[Promedio oc referente]
FROM customer c 
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items  i ON (i.order_num = o.order_num)
	INNER JOIN(SELECT c.customer_num,c.lname, c.fname, SUM(i.quantity * i.unit_price) / COUNT(DISTINCT o.order_num) 'Promedio oc referente'
			   FROM customer c 
				INNER JOIN orders o ON (c.customer_num = o.customer_num)
				INNER JOIN items  i ON (i.order_num = o.order_num)
			   GROUP BY c.customer_num, c.lname, c.fname) cr ON (c.customer_num_referedBy =cr.customer_num)
GROUP BY c.lname, c.fname, cr.lname, cr.fname, cr.[Promedio oc referente]
HAVING (SUM(i.quantity * i.unit_price) / COUNT(DISTINCT o.order_num)) > cr.[Promedio oc referente]
ORDER BY c.lname, c.fname


/*
3. Store Procedure
Dada la siguiente tabla de auditoria:

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
CREATE PROCEDURE rollbackFab @fechaHasta DATETIME AS
BEGIN

	DECLARE fabCursor CURSOR FOR
		SELECT accion, manu_code, manu_name, lead_time, state 
		FROM audit_fabricante 
		WHERE fecha BETWEEN @fechaHasta AND GETDATE() 
		ORDER BY nro_audit DESC;
	
	DECLARE @accion CHAR(1), @manu_code CHAR(3), @manu_name VARCHAR(30), @lead_time SMALLINT, @state CHAR(2);

	OPEN fabCursor;
	FETCH NEXT FROM fabCursor INTO @accion, @manu_code, @manu_name, @lead_time, @state;

	BEGIN TRAN
	BEGIN TRY

		WHILE(@@FETCH_STATUS = 0)
		BEGIN

			IF(@accion = 'I')
			BEGIN
				DELETE FROM manufact WHERE manu_code = @manu_code
			END

			IF(@accion = 'D')
			BEGIN
				INSERT INTO manufact (manu_code, manu_name, lead_time, state) VALUES (@manu_code, @manu_name, @lead_time, @state)
			END
			IF(@accion = 'O')
			BEGIN

				UPDATE manufact SET manu_name = @manu_name, lead_time = @lead_time, state = @state WHERE manu_code = @manu_code
			END

			FETCH NEXT FROM fabCursor INTO @accion, @manu_code, @manu_name, @lead_time, @state;

		END

		CLOSE fabCursor;
		DEALLOCATE fabCursor;

		COMMIT TRAN

	END TRY
	BEGIN CATCH

		ROLLBACK;

		CLOSE fabCursor;
		DEALLOCATE fabCursor;

		DECLARE @mensajeError VARCHAR(250) = 'Ocurrio un error en el proceso de rollback: ' + ERROR_MESSAGE();

		THROW 500001, @mensajeError, 1 

	END CATCH

END


/*
4. Triggers
El responsable del área de ventas nos informó que necesita cambiar el sistema para que a partir de ahora 
no se borren físicamente las órdenes de compra sino que el borrado sea lógico.
Nuestro gerente solicitó que este requerimiento se realice con triggers pero sin modificar el código del sistema actual.
Para ello se agregaron 3 atributos a la tabla ORDERS, flag_baja (0 false / 1 baja lógica), fecha_baja (fecha de la baja), 
user_baja (usuario que realiza la baja).
Se requiere realizar un trigger que cuando se realice una baja que involucre uno o más filas de la tabla ORDERS, 
realice la baja lógica de dicha/s fila/s.
Solo se podrán borrar las órdenes que pertenezcan a clientes que tengan menos de 5 órdenes. 
Para los clientes que tengan 5 o más ordenes se deberá insertar en una tabla BorradosFallidos el customer_num, order_num, 
fecha_baja y user_baja.
Nota: asumir que ya existe la tabla BorradosFallidos y la tabla ORDERS está modificada.
Ante algún error informarlo y deshacer todas las operaciones.
*/

SELECT * FROM orders

GO

CREATE TABLE [dbo].[BorradosFallidos](
	[customer_num] [smallint] NULL,
	[order_num] [smallint] NULL,
	[fecha_baja] [datetime] NULL,
	[user_baja] [varchar](100) NULL
) ON [PRIMARY]
GO

CREATE TRIGGER borradoOrdersTR ON orders
INSTEAD OF DELETE AS
BEGIN

	DECLARE orderCursor CURSOR FOR
		SELECT order_num, customer_num FROM deleted;

	DECLARE @order_num SMALLINT, @customer_num SMALLINT;

	OPEN orderCursor;
	FETCH NEXT FROM orderCursor INTO @order_num, @customer_num;

	BEGIN TRY

		WHILE(@@FETCH_STATUS = 0)
		BEGIN

			IF EXISTS (SELECT 1 FROM orders WHERE customer_num = @customer_num GROUP BY customer_num HAVING COUNT(DISTINCT order_num) >= 5)
			BEGIN

				INSERT INTO BorradosFallidos (customer_num, order_num, fecha_baja, user_baja) VALUES (@customer_num, @order_num, GETDATE(), SYSTEM_USER);
			END
			ELSE
			BEGIN

				UPDATE orders SET flag_baja = 1, fecha_baja = GETDATE(), user_baja = SYSTEM_USER WHERE order_num = @order_num
			END


		FETCH NEXT FROM orderCursor INTO @order_num, @customer_num;
		END

		CLOSE orderCursor;
		DEALLOCATE orderCursor;
	END TRY
	BEGIN CATCH

		CLOSE orderCursor;
		DEALLOCATE orderCursor;

		DECLARE @mensajeError VARCHAR(250) = 'Ocurrio un error en el borrado de ordenes: ' + ERROR_MESSAGE();
		
		THROW 500001, @mensajeError, 1

	END CATCH

END