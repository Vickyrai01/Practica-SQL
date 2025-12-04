/*
3. Query.
Realizar una consulta que muestre para cada par (cliente, fabricante) los clientes que hayan comprado todos los productos fabricados 
por ese fabricante. Mostrar la información ordenada por número de cliente y código del fabricante.
*/

SELECT c.customer_num, c.fname + ' ' + c.lname 'Nombre y apellido', i.manu_code, SUM(i.quantity * i.unit_price) 'Monto total'
FROM customer c 
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i ON (o.order_num = i.order_num)
GROUP BY c.customer_num, c.fname, c.lname, i.manu_code
HAVING COUNT(DISTINCT i.stock_num) = (SELECT COUNT(p.stock_num) FROM products p  WHERE p.manu_code = i.manu_code)
ORDER BY c.customer_num, i.manu_code

/*
5. Trigger
Desarrolle un trigger que registre en la tabla Logs Fabricante las operaciones de borrado 
y modificaciones que se realicen sobre la tabla MANUFACT.
La tabla tendrá la siguiente estructura: Manu_code Char(3) not null, Fecha Hora Datetime not null, valores Old varchar(40) not null, 
valores New varchar(40) null, operación char(1).
Por cada operación guardar el fabricante, el instante en que se produzco la operación, 
los valores concatenados que contenían las columnas del fabricante borrado o modificado en la columna valores Old, 
los valores concatenados de todas las columnas después de la modificación en la columna vaioresNew y los valores 'B' o 'M' 
en la operación según corresponda.
Importante: Los valores a tener en cuenta para la registración son los de las columnas: manu_name, lead_time y state. 
No se modifica el manu_code.
Las operaciones pueden ser masivas.
*/

CREATE TABLE logsFabricante(
	manu_code CHAR(3) NOT NULL,
	fechaHora DATETIME NOT NULL,
	valoresOLD VARCHAR(40) NOT NULL,
	valoresNEW VARCHAR(40),
	operacion CHAR(1)
)
GO

CREATE TRIGGER logsFabricantes ON manufact 
AFTER UPDATE, DELETE AS
BEGIN
	DECLARE @operacion CHAR(1) = 'B';
	IF EXISTS (SELECT 1 FROM inserted)
	BEGIN
		SET @operacion = 'M'

		INSERT INTO logsFabricante 
			SELECT d.manu_code, GETDATE(), d.manu_name + ' ' + CAST(d.lead_time AS VARCHAR(15)) + i.state, i.manu_name + ' ' + CAST(i.lead_time AS VARCHAR(15)) + i.state, @operacion
			FROM deleted d
				INNER JOIN inserted i ON (d.manu_code = i.manu_code)
	END
	ELSE
	BEGIN
	INSERT INTO logsFabricante 
		SELECT d.manu_code, GETDATE(), d.manu_name + ' ' + CAST(d.lead_time AS VARCHAR(15)) + d.state, NULL, @operacion
		FROM deleted d
	END
END

/*
4.Procedure
Crear un procedimiento historicoVtasPr que reciba como parámetro una fecha y que en base a las órdenes emitidas hasta esa fecha realice 
lo siguiente.
	a. En una tabla Nivel Fabricantes registre si dicho fabricante ha vendido o no, alguno de sus productos. 
	Deberá guardar la cantidad de tipos de productos fabricados por él y la cantidad de tipos de productos vendidos 
	hasta la fecha pasada como parámetro. Ej. El fabricante produce 10 productos pero vendió solo 3 tipos de productos.
	
	b. En caso que el fabricante haya vendido productos, guardar en una tabla NivelProductos la cantidad total de unidades vendidas 
	de cada producto del fabricante según las órdenes emitidas hasta esa fecha.

	En la tabla NivelProductos existe una columna nivel que se deberá asigna el valor ALTO para aquellos productos que hayan sido 
	vendido en 10 o más unidades, mientras que los productos que se hayan vendido menos de 10 unidades o no hayan tenido ventas se 
	les deberá asignar el valor BAJO.
	
	Si la fecha pasada como parámetro ya ha sido procesada mostrar el mensaje "Periodo ya procesado" y no realizar ninguna operación.
	En caso que se produzca un error mostrarlo y deshacer todo lo procesado.

	Estructura de tablas
	
	NivelFABRICANTES: FechaHta DATE not null, manu_Cod char(3) not null, cantFabricados int, cantVendidos int
	NivelPRODUCTOS: FechaHta DATE not null, stock_num int not null, manu_Cod char(3) not null, cantidad int not null, nivel varchar(4).

*/

CREATE TABLE NivelFABRICANTES(
	FechaHta DATE NOT NULL,
	manu_code CHAR(3) NOT NULL,
	cantFabricados INT,
	cantVendidos INT
)

CREATE TABLE NivelProductos(
	FechaHta DATE NOT NULL,
	stock_num INT NOT NULL,
	manu_code CHAR(3) NOT NULL,
	cantidad INT NOT NULL,
	nivel VARCHAR(4)
)
GO

CREATE PROCEDURE historicoVtasPr @fechaHist DATE AS
BEGIN
	IF EXISTS (SELECT 1 FROM NivelFABRICANTES WHERE FechaHta = @fechaHist )
		THROW 50099, 'Periodo ya procesado', 1;

	DECLARE fabCursor CURSOR FOR
		SELECT i.manu_code, 
			   (SELECT COUNT(p.stock_num) FROM products p WHERE p.manu_code = i.manu_code GROUP BY p.manu_code) , 
			   COUNT(DISTINCT i.stock_num)
		FROM orders o
			INNER JOIN items i ON (i.order_num = o.order_num)
		WHERE order_date <= @fechaHist
		GROUP BY i.manu_code

	DECLARE @manu_code CHAR(3), @CantProductos INT, @CantVendidos INT;
	
	OPEN fabCursor;
	FETCH NEXT FROM fabCursor INTO @manu_code, @CantProductos, @CantVendidos;

	BEGIN TRAN
	BEGIN TRY 

		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			INSERT INTO NivelFABRICANTES VALUES (@fechaHist, @manu_code, @CantProductos, @CantVendidos)
			
			IF (@CantVendidos > 0)
			BEGIN
				INSERT INTO NivelProductos
					SELECT @fechaHist, i.stock_num, i.manu_code, SUM(quantity),
					CASE WHEN SUM(quantity) >= 10 THEN 'ALTO' ELSE 'BAJO' END
					FROM items i
						INNER JOIN orders o ON (i.order_num = o.order_num)
					WHERE i.manu_code = @manu_code AND order_date <= @fechaHist
					GROUP BY i.stock_num, i.manu_code
						
			END

			FETCH NEXT FROM fabCursor INTO @manu_code, @CantProductos, @CantVendidos;

		END
		COMMIT TRAN

	END TRY
	BEGIN CATCH

		ROLLBACK TRAN
		
		DECLARE @error VARCHAR(100) = 'Ocurrio un error procesando los datos: ' + ERROR_MESSAGE();
		raiserror(@error, 16, 1)
		
	END CATCH
	CLOSE fabCursor;
	DEALLOCATE fabCursor;
END
