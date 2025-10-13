/*
Crear un procedimiento ‘migraClientes’ que reciba dos parámetros
customer_numDES y customer_numHAS y que dependiendo el tipo de cliente y la
cantidad de órdenes los inserte en las tablas clientesCalifornia, clientesNoCaBaja,
clienteNoCAAlta.

	• El procedimiento deberá migrar de la tabla customer todos los
	clientes de California a la tabla clientesCalifornia, los clientes que no
	son de California pero tienen más de 999u$ en OC en
	clientesNoCaAlta y los clientes que tiene menos de 1000u$ en OC en
	la tablas clientesNoCaBaja.
	• Se deberá actualizar un campo status en la tabla customer con valor
	‘P’ Procesado, para todos aquellos clientes migrados.
	• El procedimiento deberá contemplar toda la migración como un lote,
	en el caso que ocurra un error, se deberá informar el error ocurrido y
	abortar y deshacer la operación.

*/

CREATE TABLE clientesCalifornia(
	customer_num SMALLINT PRIMARY KEY,
	fname VARCHAR(15),
	lname VARCHAR(15),
	company VARCHAR(20),
	address1 VARCHAR(20),
	address2 VARCHAR(20),
	city VARCHAR(15),
	state CHAR(2),
	zipcode CHAR(5),
	phone VARCHAR(18),
)

CREATE TABLE clientesNoCaBaja(
	customer_num SMALLINT PRIMARY KEY,
	fname VARCHAR(15),
	lname VARCHAR(15),
	company VARCHAR(20),
	address1 VARCHAR(20),
	address2 VARCHAR(20),
	city VARCHAR(15),
	state CHAR(2),
	zipcode CHAR(5),
	phone VARCHAR(18),
)

CREATE TABLE clienteNoCAAlta(
	customer_num SMALLINT PRIMARY KEY,
	fname VARCHAR(15),
	lname VARCHAR(15),
	company VARCHAR(20),
	address1 VARCHAR(20),
	address2 VARCHAR(20),
	city VARCHAR(15),
	state CHAR(2),
	zipcode CHAR(5),
	phone VARCHAR(18),
)

CREATE PROCEDURE migraClientes
	@customer_numDES SMALLINT, 
	@customer_numHAS SMALLINT
AS
BEGIN

	DECLARE customer_cursor CURSOR FOR
		SELECT customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone  FROM customer WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS;

	DECLARE @customer_num SMALLINT, 
		    @fname VARCHAR(15), 
			@lname VARCHAR(15), 
			@company VARCHAR(20), 
			@address1 VARCHAR(20), 
			@address2 VARCHAR(20), 
			@city VARCHAR(15), 
			@state CHAR(2), 
			@zipcode CHAR(5),
			@phone VARCHAR(18);

	BEGIN TRY

		OPEN customer_cursor;

		BEGIN TRAN
		FETCH NEXT FROM customer_cursor INTO @customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone;
	
		WHILE (@@FETCH_STATUS = 0)
			
			BEGIN
				
				IF @state = 'CA'
					BEGIN
						INSERT INTO clientesCalifornia (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone) 
						VALUES (@customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone)
					END
				ELSE
					BEGIN

						IF (SELECT SUM(i.quantity * i.unit_price)
						FROM orders o
						INNER JOIN items i ON o.order_num = i.order_num
						WHERE o.customer_num = @customer_num) > 999
						BEGIN
							INSERT INTO clienteNoCAAlta (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone) 
							VALUES (@customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone)
						END
						ELSE
						BEGIN
							INSERT INTO clientesNoCaBaja (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone) 
							VALUES (@customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone)
						END
					
					END
			
			UPDATE customer SET status = 'P' WHERE customer_num = @customer_num;

			FETCH NEXT FROM customer_cursor INTO @customer_num, @fname, @lname, @company, @address1, @address2, @city, @state, @zipcode, @phone;
			END

		COMMIT TRAN
		
		CLOSE customer_cursor;
        DEALLOCATE customer_cursor;
		
	END TRY

		BEGIN CATCH
			CLOSE customer_cursor
			DEALLOCATE customer_cursor
			ROLLBACK TRANSACTION

			DECLARE @errorDescripcion VARCHAR(100)
			SELECT @errorDescripcion = 'Error en Cliente '+ CAST(@customer_num AS
			CHAR(5)) ;
			THROW 50000, @errorDescripcion, 1 

		END CATCH
END;

EXECUTE  migraClientes @customer_numDES = 101, @customer_numHAS = 104

SELECT * FROM  clientesCalifornia;
SELECT * FROM  clientesNoCaBaja;
SELECT * FROM  clienteNoCAAlta;