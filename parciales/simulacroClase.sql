/*
Por cada estado (state) seleccionar los dos clientes que mayores montos compraron. Se
deberá mostrar el código del estado, nro de cliente, nombre y apellido del cliente y monto total
comprado.
Mostrar la información ordenada por provincia y por monto comprado en forma descendente.
Notas: No se puede usar Store procedures, ni funciones de usuarios, ni tablas temporales.
*/


SELECT c.state, c.customer_num, c.fname, c.lname, SUM(i.quantity * i.unit_price) monto_total
FROM customer c
	INNER JOIN orders o ON (o.customer_num = c.customer_num)
	INNER JOIN items i ON (i.order_num = o.order_num)
WHERE c.customer_num IN (
    SELECT TOP 2 c1.customer_num
    FROM customer c1
        INNER JOIN orders o1 ON (o1.customer_num = c1.customer_num)
        INNER JOIN items i1 ON (i1.order_num = o1.order_num)
        WHERE c1.state = c.state
        GROUP BY c1.customer_num, c1.state
        ORDER BY SUM(i1.quantity * i1.unit_price) DESC
)
GROUP BY c.state, c.customer_num, c.fname, c.lname
ORDER BY c.state,  SUM(i.quantity * i.unit_price) DESC

/*
4. Store Procedure
Crear un procedimiento BorrarProd que en base a una tabla ProductosDeprecados que
contiene filas con Productos a borrar realice el borrado lógico de los mismos de la tabla
Products asignando el valor ‘D’ al estatus del mismo. El procedimiento deberá guardar en
una tabla de auditoria AuditProd (stock_num, manu_code, Mensaje) el producto y un mensaje
que podrá ser: ‘Deprecado’, ‘Deprecado con ventas’ o cualquier mensaje de error que se
produjera. Crear las tablas ProductosDeprecados y AuditProd.
Deberá manejar una transacción por registro. Ante un error deshacer lo realizado y seguir
procesando los demás registros. Asimismo, deberá manejar excepciones ante cualquier error
que ocurra.
*/

SELECT * FROM products

CREATE TABLE ProductosDeprecado (
    stock_num SMALLINT,
    manu_code SMALLINT,
    unit_price DECIMAL,
    unit_code SMALLINT
)

CREATE TABLE AuditProd(
    stock_num SMALLINT, 
    manu_code SMALLINT, 
    mensaje VARCHAR(100)
)
GO 

CREATE PROCEDURE BorrarProd
AS
BEGIN 
    
    DECLARE product_cursor CURSOR FOR
        SELECT stock_num, manu_code FROM ProductosDeprecado

    DECLARE @stock_num SMALLINT, @manu_code SMALLINT;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @stock_num, @manu_code

    WHILE (@@FETCH_STATUS = 0)
    BEGIN

        BEGIN TRY

            BEGIN TRAN

                UPDATE products SET status = 'D'
                WHERE manu_code = @manu_code AND stock_num = @stock_num
                
                IF((SELECT COUNT(*) FROM items WHERE manu_code = @manu_code AND stock_num = @stock_num) > 0)
                BEGIN
                    INSERT INTO AuditProd (stock_num, manu_code, mensaje) VALUES (@stock_num, @manu_code, 'Deprecado con ventas')
                END
                ELSE
                BEGIN
                    INSERT INTO AuditProd (stock_num, manu_code, mensaje) VALUES (@stock_num, @manu_code, 'Deprecado')
                END

            COMMIT TRAN
            FETCH NEXT FROM product_cursor INTO @stock_num, @manu_code
        END TRY

        BEGIN CATCH

            ROLLBACK TRANSACTION

            INSERT INTO AuditProd (stock_num, manu_code, mensaje)
                VALUES (@stock_num, @manu_code, ERROR_MESSAGE());
            
            FETCH NEXT FROM product_cursor INTO @stock_num, @manu_code

        END CATCH
    
    CLOSE product_cursor;
    DEALLOCATE product_cursor;

    END
END
GO

/*
Crear un trigger que ante un cambio de precios en un producto inserte un nuevo registro con
el precio anterior (no el nuevo) en la tabla PRECIOS_HIST.
La estructura de la tabla PRECIOS_HIST es (stock_num, manu_code, fechaDesde,
fechaHasta, precio_unit). La fecha desde del nuevo registro será la fecha hasta del último
cambio de precios de ese producto y su fecha hasta será la fecha del dia. SI no tuviese un
registro de precio anterior ingrese como fecha desde ‘2000-01-01’.
Nota: Las actualizaciones de precios pueden ser masivas.
*/

CREATE TABLE precios_hist(
    stock_num SMALLINT,
    manu_code SMALLINT,
    fecha_desde DATETIME,
    fecha_hasta DATETIME,
    precio_unit DECIMAL
)

SELECT * FROM products
GO
CREATE TRIGGER product_tr ON products
AFTER UPDATE
AS
BEGIN
    
    DECLARE product_cursor CURSOR FOR SELECT stock_num, manu_code, unit_price FROM deleted;
    DECLARE @stock_num SMALLINT, @manu_code SMALLINT, @unit_price DECIMAL;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @stock_num, @manu_code, @unit_price;

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        
        IF EXISTS (SELECT 1 FROM PRECIOS_HIST WHERE stock_num = @stock_num AND  manu_code = @manu_code)
        BEGIN
            DECLARE @fecha DATETIME;
            SELECT @fecha = MAX(fecha_hasta) FROM PRECIOS_HIST WHERE stock_num = @stock_num AND  manu_code = @manu_code;

            INSERT INTO PRECIOS_HIST (stock_num, manu_code, fecha_desde, fecha_hasta, precio_unit)
            VALUES (@stock_num, @manu_code, @fecha, GETDATE(), @unit_price) 

        END
        
        ELSE
        BEGIN
            INSERT INTO PRECIOS_HIST (stock_num, manu_code, fecha_desde, fecha_hasta, precio_unit)
            VALUES (@stock_num, @manu_code, '2000-01-01', GETDATE(), @unit_price)
        END
    
    END
    CLOSE product_cursor;
    DEALLOCATE product_cursor;
END
GO