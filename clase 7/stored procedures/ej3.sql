CREATE TABLE listaPrecioMayor(
	stock_num SMALLINT PRIMARY KEY,
	manu_code CHAR(3),
	unit_price DECIMAL(6,2),
	unit_code SMALLINT,
)

CREATE TABLE listaPrecioMenor(
	stock_num SMALLINT PRIMARY KEY,
	manu_code CHAR(3),
	unit_price DECIMAL(6,2),
	unit_code SMALLINT,
)

CREATE PROCEDURE actualizaPrecios
	@manu_codeDES CHAR(3),
	@manu_codeHAS CHAR(3),
	@porcActualizacion DECIMAL(6,2)
AS
BEGIN
	DECLARE stock_cursor CURSOR FOR
		SELECT stock_num, manu_code, unit_price, unit_code 
		FROM products
		WHERE manu_code BETWEEN @manu_codeDES AND @manu_codeHAS
		ORDER BY manu_code, stock_num

	DECLARE @stock_num SMALLINT, @manu_code CHAR(3), @unit_price DECIMAL(6,2), @unit_code SMALLINT, @manu_codeAux CHAR(3);

	OPEN stock_cursor;

	FETCH NEXT FROM stock_cursor INTO @stock_num, @manu_code, @unit_price, @unit_code;
	
	SET @manu_codeAux = @manu_code

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			IF (SELECT SUM(quantity) 
				FROM items i WHERE manu_code = @manu_code AND stock_num=@stock_num) >= 500
            BEGIN
				INSERT INTO listaPrecioMayor (stock_num, manu_code, unit_price, unit_code)
                 VALUES (@stock_num, @manu_code,
					     @unit_price * (1 + @porcActualizacion * 0.80), @unit_code);
            END
            ELSE
            BEGIN
                INSERT INTO listaPrecioMenor (stock_num, manu_code, unit_price, unit_code)
                VALUES (@stock_num, @manu_code,
                            @unit_price * (1 + @porcActualizacion), @unit_code);
            END

			
			UPDATE products
			SET status = 'A' 
			WHERE stock_num = @stock_num

		IF @manu_code != @manu_codeAux
		BEGIN
		COMMIT TRAN

		SET @manu_codeAux = @manu_code
		END
		END TRY
		BEGIN CATCH
		
			CLOSE stock_cursor
			DEALLOCATE stock_cursor
			ROLLBACK TRANSACTION

			DECLARE @errorDescripcion VARCHAR(100)
			SELECT @errorDescripcion = 'Error en Productos '+ CAST(@stock_num AS
			CHAR(5)) ;
			THROW 50000, @errorDescripcion, 1 
		
		END CATCH

		FETCH NEXT FROM stock_cursor INTO @stock_num, @manu_code, @unit_price, @unit_code;

	END

	CLOSE stock_cursor
	DEALLOCATE stock_cursor
END
