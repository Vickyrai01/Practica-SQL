/*
1. Query.
Mostrar código y descripción del Estado, código y descripción del tipo de
producto y la cantidad de unidades vendidas del tipo de producto, de los tipos
de productos más comprados (por cantidad) en cada Estado
Mostrar el resultado ordenado por el nombre (o Descripción) del Estado.

Yo lo que entiendo es que me esta pidiendo el producto mas vendido de cada estado
*/

SELECT s.state, s.sname, i.stock_num, pt.description, SUM(i.quantity) CantidadVendida
FROM state s
	INNER JOIN manufact m ON (s.state = m.state)
	INNER JOIN items i ON (i.manu_code = m.manu_code)
	INNER JOIN product_types pt ON (i.stock_num = pt.stock_num)
GROUP BY s.state, s.sname, i.stock_num, pt.description
HAVING i.stock_num = (SELECT TOP 1 i1.stock_num
					   FROM state s1 
						INNER JOIN manufact m1 ON (s1.state = m1.state)
						INNER JOIN items i1	   ON (m1.manu_code = i1.manu_code)
					   WHERE s1.state = s.state
					   GROUP BY i1.stock_num
					   ORDER BY SUM(i1.quantity) DESC)
ORDER BY s.sname


/*
2 Trigger
Dada la vista:

Create View OrdenItems as
	select o.order_num, o.order_date, o.customer_num, o.paid_date,
	i.item_num, i.stock_num, i.manu_code, i.quantity, i.unit_price
from orders o join items i on o.order_num = i.order_num;

Se quieren controlar las altas sobre la vista anterior.
Los controles a realizar son los siguientes:
a. No se permitirá que una Orden contenga ítems de fabricantes de más de
dos estados en la misma orden.
b. Por otro parte los Clientes del estado de ALASKA no podrán realizar
compras a fabricantes fuera de ALASKA.
Notas:
 Las altas son de una misma Orden y de un mismo Cliente pero pueden
tener varias líneas de ítems.
 Ante el incumplimiento de una validación, deshacer TODA la transacción.

*/
GO
Create View OrdenItems as
	select o.order_num, o.order_date, o.customer_num, o.paid_date,
	i.item_num, i.stock_num, i.manu_code, i.quantity, i.unit_price
from orders o join items i on o.order_num = i.order_num;
GO

CREATE TRIGGER ordenItemsTR ON OrdenItems
INSTEAD OF INSERT AS
BEGIN

	IF ((SELECT COUNT(DISTINCT m.state) FROM inserted oi INNER JOIN manufact m ON (m.manu_code = oi.manu_code)) > 2)
		THROW 500001, 'No pueden cargarse ordenes con fafricantes de mas de dos estados',1

	IF EXISTS (SELECT 1 FROM inserted i 
			   INNER JOIN customer c ON (c.customer_num = i.customer_num) 
			   INNER JOIN manufact m ON (m.manu_code = i.manu_code)
			   WHERE c.state = 'AK' AND m.state <> 'AK')
		THROW 500002, 'Los clientes de alaska solo pueden comprarles a fabricantes de alaska, pete',1
	
	INSERT INTO orders (order_num, order_date, customer_num, paid_date)
		SELECT DISTINCT order_num, order_date, customer_num, paid_date FROM inserted

	INSERT INTO items (order_num, item_num, stock_num, manu_code, quantity, unit_price)
		SELECT order_num, item_num, stock_num, manu_code, quantity, unit_price FROM inserted
END


/*
4. Store Procedure
Crear un procedimiento actualizaCliente el cuál tomará de una tabla “clientesAltaOnline”
previamente cargada por otro proceso, la siguiente información:
Customer_num, lname, fname, Company, address1, city, state
Por cada fila de la tabla clientesAltaOnline se deberá evaluar:
Si el cliente existe en la tabla Customer, se deberá modificar dicho cliente en la tabla Customer
con los datos leídos de la tabla clientesAltaOnline.
Si el cliente no existe en la tabla customer, se deberá insertar el cliente en la tabla Customer
con los datos leídos de la tabla clientesAltaOnline.

El procedimiento deberá almacenar por cada operación realizada una fila en la una tabla
Auditoría con los siguientes atributos
IdAuditoria (Identity), operación (I ó M), customer_num, lname, fname, address1, city,
state.
Manejar UNA transacción por cada novedad.
*/

GO
CREATE TABLE clientesAltaOnline(
	[customer_num] [smallint] NULL,
	[lname] [varchar](50) NULL,
	[fname] [varchar](50) NULL,
	[company] [varchar](20) NULL,
	[address1] [varchar](20) NULL,
	[city] [varchar](15) NULL,
	[state] [char](2) NULL
) ON [PRIMARY]
GO

CREATE TABLE auditoriaClientesAlta(
	idAuditoria INT IDENTITY(1,1),
	operacion CHAR(1),
	customer_num SMALLINT,
	lname VARCHAR(15),
	fname VARCHAR(15),
	address1 VARCHAR(30),
	city VARCHAR(15),
	state CHAR(2)
)

GO
CREATE PROCEDURE actualizaClienteAnashe AS
BEGIN

	DECLARE clienteCursor CURSOR FOR 
		SELECT customer_num, lname, fname, company, address1, city, state FROM clientesAltaOnline;

	DECLARE @customer_num SMALLINT, @lname VARCHAR(15), @fname VARCHAR(15), @company VARCHAR(30), @address1 VARCHAR(30), @city VARCHAR(15), @state CHAR(2)

	OPEN clienteCursor;
	FETCH NEXT FROM clienteCursor INTO @customer_num, @lname, @fname, @company, @address1, @city, @state;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @operacion CHAR(1) = 'I'

		BEGIN TRAN
		BEGIN TRY
			
		IF EXISTS (SELECT 1 FROM customer WHERE customer_num = @customer_num)
		BEGIN
			UPDATE customer SET lname = @lname, fname = @fname, company = @company, address1 = @address1, city = @city, state  = @state
			WHERE customer_num = @customer_num

			SET @operacion = 'M'
		END
		ELSE
		BEGIN
			INSERT INTO customer (customer_num, lname, fname, company, address1, city, state) 
			VALUES (@customer_num, @lname, @fname, @company, @address1, @city, @state)
		END

		INSERT INTO auditoriaClientesAlta (operacion, customer_num, lname, fname, address1, city, state) 
		VALUES (@operacion, @customer_num, @lname, @fname, @company, @address1, @city, @state )

		COMMIT TRAN

		END TRY
		BEGIN CATCH
			ROLLBACK
			PRINT 'Ocurrio el siguiente error con el cliente ' + CAST( @customer_num AS VARCHAR(4))
			


		END CATCH

		FETCH NEXT FROM clienteCursor INTO @customer_num, @lname, @fname, @company, @address1, @city, @state;
	END

	CLOSE clienteCursor;
	DEALLOCATE clienteCursor;

END