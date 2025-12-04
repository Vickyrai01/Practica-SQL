/*
Query.
Seleccionar número y apellido del cliente, código de fabricante, tipo de producto y cantidad de
producto comprados a los fabricantes HSK y NRG. Solo se deben mostrar aquellos clientes 
que hayan comprado TODOS los productos de ambos fabricantes.
Ordenar la salida por número de cliente y cantidad comprada en forma descendente, Ej.
*/

SELECT c.customer_num, c.lname,i.manu_code, pt.description, c.cantidad FROM
(SELECT c.customer_num, c.lname, SUM(quantity) cantidad
FROM customer c 
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i  ON (i.order_num = o.order_num)
WHERE i.manu_code IN ('HSK','NRG')
GROUP BY c.customer_num, c.lname
HAVING COUNT(DISTINCT i.stock_num) = (SELECT COUNT(DISTINCT p1.stock_num) 
								      FROM products p1 
									  WHERE p1.manu_code IN ('HSK','NRG'))) c
									  INNER JOIN orders o ON (o.customer_num = c.customer_num)
									  INNER JOIN items i ON (o.order_num = i.order_num)
									  INNER JOIN product_types pt ON (i.stock_num = pt.stock_num)

-- es lo mejor que pude hacer, hasta aca llegue

SELECT
    c.customer_num,
    c.lname,
    i.manu_code,
    i.stock_num,
    SUM(i.quantity) AS cantidad
FROM customer c
JOIN orders o ON o.customer_num = c.customer_num
JOIN items i ON i.order_num = o.order_num
WHERE c.customer_num IN (
    SELECT c1.customer_num
    FROM customer c1
    JOIN orders o1 ON o1.customer_num = c1.customer_num
    JOIN items i1 ON i1.order_num = o1.order_num
	WHERE i1.manu_code IN ('HSK','NRG')
	GROUP BY c1.customer_num
	HAVING COUNT(DISTINCT i1.stock_num) = (SELECT COUNT(DISTINCT p1.stock_num) 
										  FROM products p1 
									      WHERE p1.manu_code IN ('HSK','NRG'))

    ) 
GROUP BY c.customer_num, c.lname, i.manu_code, i.stock_num
ORDER BY c.customer_num, cantidad DESC
-- Esto esta mucho mejor

/*
3. Query.
Mostrar código y nombre del fabricante, código y descripción del tipo de producto y la cantidad de unidades vendidas de 2 fabricantes, 
del que más y que menos cantidad de unidades vendieron. Listar solo los productos que la cantidad de unidades vendidas sea mayor a 2.
No tener en cuenta aquellos fabricantes que no tuvieron ventas.
Mostrar el resultado ordenado por el código del fabricante y la cantidad de unidades vendidas por producto en forma descendente. 
Nota: No se puede utilizar la clausula WITH.
*/

SELECT m.manu_code, m.manu_name, p.stock_num, pt.description, SUM(i.quantity) cantidad_vendida
FROM manufact m
	INNER JOIN products p ON (m.manu_code = p.manu_code)
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
	INNER JOIN items i ON (i.stock_num = p.stock_num)
WHERE m.manu_code IN (
						SELECT TOP 1 i1.manu_code FROM items i1 GROUP BY i1.manu_code ORDER BY SUM(i1.quantity) DESC
						UNION
						SELECT TOP 1 i2.manu_code FROM items i2 GROUP BY i2.manu_code ORDER BY SUM(i2.quantity) ASC)
GROUP BY m.manu_code, m.manu_name, p.stock_num, pt.description
HAVING SUM(i.quantity) > 2
ORDER BY m.manu_code, SUM(i.quantity) DESC


/*
Procedure
Crear un procedimiento actualiza ClientePR el cuál tomará de una tabla "NovedadesClientes" 
la siguiente información: Customer_num, Iname, fname, Company
Por cada fila de la tabla NovedadesClientes se deberá evaluar:
Si el cliente existe en la tabla Customer, se deberá modificar dicho cliente en la tabla Customer con 
los datos leídos de la tabla NovedadesClientes. Si el cliente no existe, se deberá insertar el cliente 
en la tabla Customer con los datos leídos de la tabla NovedadesClientes.
Además, el procedimiento deberá almacenar por cada una de las operaciones realizadas, 
una fila en una tabla Auditoría con los siguientes atributos:
IdAuditoria (Identity), operación (I 6 M), customer_num, Iname, fname
Ante cualquier error, informarlo y seguir procesando las novedades (Manejar UNA transacción por cada novedad).
*/

CREATE TABLE NovedadesClientes(
	customer_num SMALLINT,
	lname VARCHAR(15),
	fname VARCHAR(15),
	company VARCHAR(20)
)
CREATE TABLE customer_audit(
	id_auditoria INT PRIMARY KEY IDENTITY(1,1),
	operacion CHAR(1) CHECK(operacion IN ('I', 'M')),
	customer_num SMALLINT,
	lname VARCHAR(15),
	fname VARCHAR(15)
)
GO 

CREATE PROCEDURE clientePR AS
BEGIN

	DECLARE customer_cursor CURSOR FOR
		SELECT * FROM NovedadesClientes;

	DECLARE @customer_num SMALLINT, @lname VARCHAR(15), @fname VARCHAR(15), @company VARCHAR(20)

	DECLARE @estado CHAR(1);

	OPEN customer_cursor;
	FETCH NEXT FROM customer_cursor INTO @customer_num, @lname, @fname, @company;

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SET @estado = 'M'

		BEGIN TRY
			BEGIN TRAN
				
				IF EXISTS (SELECT 1 FROM customer WHERE customer_num = @customer_num)
				BEGIN
					UPDATE customer SET lname = @lname, fname = @fname, company = @company
				
				END
				ELSE
				BEGIN
					INSERT INTO customer (customer_num, lname, fname, company) VALUES (@customer_num, @lname, @fname, @company)
					SET @estado = 'I'
				END

				INSERT INTO customer_audit VALUES (@estado, @customer_num, @lname, @fname)
			COMMIT

		END TRY
		BEGIN CATCH

			ROLLBACK;
			DECLARE @errorDescription VARCHAR(100);
			SET @errorDescription = 'Error en la operacion con customer_num ' + CAST(@customer_num AS CHAR(5)) + ERROR_MESSAGE();
			THROW 50099, @errorDescription, 1

		END CATCH
	
		FETCH NEXT FROM customer_cursor INTO @customer_num, @lname, @fname, @company;
	END

	CLOSE customer_cursor;
	DEALLOCATE customer_cursor;
END