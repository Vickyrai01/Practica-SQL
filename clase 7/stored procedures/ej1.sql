/*
Crear la siguiente tabla CustomerStatistics con los siguientes campos
customer_num (entero y pk), ordersqty (entero), maxdate (date), uniqueProducts
(entero)
Crear un procedimiento ‘actualizaEstadisticas’ que reciba dos parámetros
customer_numDES y customer_numHAS y que en base a los datos de la tabla
customer cuyo customer_num estén en en rango pasado por parámetro, inserte (si
no existe) o modifique el registro de la tabla CustomerStatistics con la siguiente
información:
Ordersqty contedrá la cantidad de órdenes para cada cliente.
Maxdate contedrá la fecha máxima de la última órde puesta por cada cliente.
uniqueProducts contendrá la cantidad única de tipos de productos adquiridos
por cada cliente.
*/

CREATE TABLE CustomerStatistics (
	customer_num INT PRIMARY KEY,
	ordersqty INT,
	maxdate DATE,
	uniqueProducts INT
);

CREATE PROCEDURE actualizarEstadisticas
	@customer_numDES INT,
	@customer_numHAS  INT
AS
BEGIN
	DECLARE cliente CURSOR FOR
		SELECT c.customer_num, COUNT(o.order_num) cant_ordenes, MAX(order_date) fecha_ultima_compra
		FROM customer c 
		INNER JOIN orders o ON (c.customer_num = o.customer_num)
		INNER JOIN items i ON  (o.order_num = i.order_num)
		WHERE c.customer_num BETWEEN @customer_numDES AND @customer_numHAS
		GROUP BY c.customer_num;

	DECLARE @customer_num SMALLINT, @cant_ordenes INT, @fecha_ultima_compra DATETIME, @tipos_unicos INT;
	
	OPEN cliente;
	FETCH NEXT FROM cliente INTO @customer_num, @cant_ordenes, @fecha_ultima_compra;

	WHILE (@@FETCH_STATUS = 0)
		
		BEGIN
			SELECT @tipos_unicos = count(distinct stock_num)
			FROM items I JOIN orders o ON (o.order_num = i.order_num)
			WHERE o.customer_num = @customer_num;

			IF EXISTS (SELECT 1 FROM CustomerStatistics WHERE customer_num = @customer_num )
			BEGIN
			UPDATE CustomerStatistics
			SET ordersqty = @cant_ordenes, maxdate = @fecha_ultima_compra, uniqueProducts = @tipos_unicos
			WHERE customer_num = @customer_num
			END
			
			ELSE
			BEGIN
			INSERT INTO CustomerStatistics (customer_num, ordersqty, maxdate, uniqueProducts) VALUES (@customer_num, @cant_ordenes, @fecha_ultima_compra, @tipos_unicos)
			END
			
			FETCH NEXT FROM cliente INTO @customer_num, @cant_ordenes, @fecha_ultima_compra;
		
		END

	CLOSE cliente;
	DEALLOCATE cliente;
END;

EXEC actualizarEstadisticas @customer_numDES = 101, @customer_numHAS = 104;