-------------------------------------- 2/7/2025 ---------------------------------------------------------
/*
Query.
Seleccionar número y apellido del cliente, código de fabricante, tipo de producto y cantidad de
producto comprados a los fabricantes HSK y NRG. Solo se deben mostrar aquellos clientes 
que hayan comprado TODOS los productos de ambos fabricantes.
Ordenar la salida por número de cliente y cantidad comprada en forma descendente, Ej.
*/

SELECT c.customer_num, c.lname, i.manu_code, i.stock_num, SUM(i.quantity) cantidad
FROM customer c 
	INNER JOIN orders o ON (o.customer_num = c.customer_num)
	INNER JOIN items i  ON (i.order_num = o.order_num)
WHERE i.manu_code IN ('HSK', 'NRG')
GROUP BY c.customer_num, c.lname, i.manu_code, i.stock_num
HAVING NOT EXISTS(
		SELECT 1
		FROM products p
		WHERE p.manu_code IN ('HSK', 'NRG') AND
			NOT EXISTS(
					SELECT 1
					FROM orders o1 
						INNER JOIN items i1 ON (o1.order_num = i1.order_num)
					WHERE o1.customer_num = c.customer_num AND
						  i1.stock_num = p.stock_num AND
						  i1.manu_code = p.manu_code))
ORDER BY c.customer_num, SUM(i.quantity) DESC


/*
4. Procedure
Crear un procedimiento registraProductoPR al que se le envíe como parámetros stock_num, manu_code, unit_price,
unit_code, status, cat_descr, cat_picture, cat_advert.
Si el producto no existe en la tabla de Productos crearlo y si ya existe modificarlo. 
Además ingresar un nuevo registro del producto en la tabla de Catalogo.
Ante cualquier error abortar todas las operaciones y mostrar el número y descripción del error.
*/
GO


CREATE PROCEDURE registraProductoPR 
	@stock_num INT, 
	@manu_code CHAR(3), 
	@unit_price DECIMAL, 
	@unit_code SMALLINT, 
	@status CHAR(1), 
	@cat_descr VARCHAR(250), 
	@cat_picture VARCHAR(250),
	@cat_advert VARCHAR(250)
AS
BEGIN


	BEGIN TRAN
	BEGIN TRY

		IF NOT EXISTS(SELECT 1 FROM products WHERE @manu_code = manu_code AND @stock_num = stock_num)
		BEGIN
			INSERT INTO products (stock_num, manu_code, unit_price, unit_code, status) VALUES (@stock_num, @manu_code, @unit_price, @unit_code, @status)
			
		END
		ELSE
		BEGIN
			UPDATE products SET unit_price = @unit_price, unit_code = @unit_code, status = @status WHERE manu_code = @manu_code AND stock_num = @stock_num
		END

		INSERT INTO catalog (stock_num, manu_code, cat_descr, cat_picture, cat_advert) VALUES (@stock_num, @manu_code, @cat_descr, @cat_picture, @cat_advert)

		COMMIT TRAN

	END TRY

	BEGIN CATCH
		ROLLBACK
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorMessage NVARCHAR(250) = ERROR_MESSAGE();
        RAISERROR('Error %d: %s', 16, 1, @ErrorNumber, @ErrorMessage);

	END CATCH

END

GO

/*
5. Trigger
Órdenes
Cree las tablas Clientes_BK y Ordenes_BK que sean copias de las tablas Clientes y respectivamente. 
Asuma que estas tablas están en bases de datos diferentes. Realice los triggers que crea necesarios para asegurar 
la integridad referencial entre ambas tablas.
*/

CREATE TABLE Clientes_BK (
	[customer_num] [smallint] NOT NULL,
	[fname] [varchar](15) NULL,
	[lname] [varchar](15) NULL,
	[company] [varchar](20) NULL,
	[address1] [varchar](20) NULL,
	[address2] [varchar](20) NULL,
	[city] [varchar](15) NULL,
	[state] [char](2) NULL,
	[zipcode] [char](5) NULL,
	[phone] [varchar](18) NULL,
	[customer_num_referedBy] [smallint] NULL,
	[status] [char](1) NULL,
)
CREATE TABLE Ordenes_BK(
	[order_num] [smallint] NOT NULL,
	[order_date] [datetime] NULL,
	[customer_num] [smallint] NOT NULL,
	[ship_instruct] [varchar](40) NULL,
	[backlog] [char](1) NULL,
	[po_num] [varchar](10) NULL,
	[ship_date] [datetime] NULL,
	[ship_weight] [decimal](8, 2) NULL,
	[ship_charge] [decimal](6, 2) NULL,
	[paid_date] [datetime] NULL,
	[flag_baja] [bit] NULL,
	[fecha_baja] [datetime] NULL,
	[user_baja] [varchar](100) NULL,
)

-- verificar que cuando se cree un orden exista el cliente LISTO
-- verificar que cuando se modifique la orden el cliente siga existiendo en la tabla clientes
-- ante un delete en la tabla cliente, verificar que no tenga ninguna orden
GO
CREATE TRIGGER ordenesInsTR ON Ordenes_BK
INSTEAD OF insert, update AS
BEGIN

	IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM Clientes_BK c WHERE c.customer_num = i.customer_num))
		THROW 50001, 'Cliente inexistente', 1

	DELETE FROM Ordenes_BK
	WHERE order_num IN (SELECT order_num FROM deleted);

	INSERT INTO Ordenes_BK SELECT * FROM inserted;

END

GO
CREATE TRIGGER clientesDelTR ON Clientes_BK
INSTEAD OF delete
AS
BEGIN
	
	DECLARE customerCursor CURSOR FOR SELECT customer_num FROM deleted;
	DECLARE @customer_num SMALLINT;

	OPEN customerCursor;
	FETCH NEXT FROM customerCursor INTO @customer_num;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		
		IF EXISTS (SELECT 1 FROM Ordenes_BK WHERE customer_num = @customer_num)
		BEGIN
			CLOSE customerCursor;
			DEALLOCATE customerCursor;
			THROW 50001, 'No se puede borrar el cliente porque tiene ordenes asociadas', 1
		END
		DELETE FROM Clientes_BK WHERE customer_num = @customer_num
		FETCH NEXT FROM customerCursor INTO @customer_num;
		
	END
	
	CLOSE customerCursor;
	DEALLOCATE customerCursor;

END

GO

-------------------------------------- 16/7/2025 ---------------------------------------------------------
/*
3. Query.
Mostrar código y nombre del fabricante, código y descripción del tipo de producto y la cantidad de unidades vendidas de 2 fabricantes, 
del que más y que menos cantidad de unidades vendieron. Listar solo los productos que la cantidad de unidades vendidas sea mayor a 2. 
No tener en cuenta aquellos fabricantes que no tuvieron ventas.
Mostrar el resultado ordenado por el código del fabricante y la cantidad de unidades vendidas por producto en forma descendente. 
Nota: No se puede utilizar la clausula WITH.
*/

SELECT m.manu_code, m.manu_name, i.stock_num, pt.description, SUM(i.quantity) cantidadVendida
FROM manufact m 
	INNER JOIN items i ON (i.manu_code = m.manu_code)
	INNER JOIN product_types pt ON (i.stock_num = pt.stock_num)

WHERE m.manu_code IN (SELECT TOP 1 i1.manu_code FROM items i1 GROUP BY i1.manu_code ORDER BY SUM(i1.quantity) DESC
					   UNION
					   SELECT TOP 1 i2.manu_code FROM items i2 GROUP BY i2.manu_code ORDER BY SUM(i2.quantity) ASC)
GROUP BY m.manu_code, m.manu_name, i.stock_num, pt.description
HAVING SUM(i.quantity) > 2
ORDER BY SUM(i.quantity), m.manu_code DESC

/*
4. Procedure
Crear un procedimiento actualiza ClientePR el cuál tomará de una tabla "NovedadesClientes" la siguiente información: 
Customer_num, Iname, fname, Company
Por cada fila de la tabla NovedadesClientes se deberá evaluar:
Si el cliente existe en la tabla Customer, se deberá modificar dicho cliente en la tabla Customer con los datos leídos de 
la tabla NovedadesClientes. Si el cliente no existe, se deberá insertar el cliente en la tabla Customer con los datos leídos 
de la tabla NovedadesClientes.
Además, el procedimiento deberá almacenar por cada una de las operaciones realizadas, una fila en una tabla Auditoría con los siguientes atributos:
IdAuditoria (Identity), operación (1 ó M), customer_num, Iname, fname
Ante cualquier error, informarlo y seguir procesando las novedades (Manejar UNA transacción por cada novedad).
*/

CREATE TABLE NovedadesClientes(
	customer_num SMALLINT, 
	lname VARCHAR(30),
	fname VARCHAR(30),
	company VARCHAR(30)
)

CREATE TABLE clientesAudit(
	id_autditoria INT IDENTITY(1,1),
	operacion CHAR(1) CHECK (operacion IN ('I', 'M')),
	customer_num SMALLINT,
	lname VARCHAR(40),
	fname VARCHAR(40)
)

GO
CREATE PROCEDURE ClientePR
AS
BEGIN
	
	DECLARE customerCursor CURSOR FOR
		SELECT * FROM NovedadesClientes;

	DECLARE @customer_num SMALLINT, @lname VARCHAR(30), @fname VARCHAR(30), @company VARCHAR(30);

	OPEN customerCursor;
	FETCH NEXT FROM customerCursor INTO @customer_num, @lname, @fname, @company;


	WHILE(@@FETCH_STATUS =0)
	BEGIN
		
		BEGIN TRAN
		BEGIN TRY
			DECLARE @operacion CHAR(1) = 'M'

			IF EXISTS (SELECT 1 FROM customer WHERE customer_num = @customer_num)
			BEGIN

				UPDATE customer SET lname = @lname, fname = @fname, company = @company WHERE customer_num = @customer_num
			END
			ELSE
			BEGIN

				INSERT INTO customer (customer_num, lname, fname, company) VALUES (@customer_num, @lname, @fname, @company)
				SET @operacion = 'I'
			END

			INSERT INTO clientesAudit VALUES (@operacion, @customer_num, @lname, @fname)

			COMMIT TRAN

		END TRY
		BEGIN CATCH
			
			ROLLBACK

			DECLARE @ErrorNumber VARCHAR(100) = ERROR_NUMBER();
			DECLARE @ErrorMessage VARCHAR(100) = ERROR_MESSAGE();
			RAISERROR('Error %d: %s', 16, 1, @ErrorNumber, @ErrorMessage);

		END CATCH

		FETCH NEXT FROM customerCursor INTO @customer_num, @lname, @fname, @company;

	END

	CLOSE customerCursor;
	DEALLOCATE customerCursor;

END
GO