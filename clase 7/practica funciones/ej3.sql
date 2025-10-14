
/*
Escribir un Select que devuelva para cada producto de la tabla Products que exista en la tabla
Catalog todos sus fabricantes separados entre sí por el caracter pipe (|). Utilizar una función para
resolver parte de la consulta. Ejemplo de la salida
			Stock_num			Fabricantes
			   5				NRG | SMT | ANZ


*/

SELECT stock_num, dbo.fabricantes(stock_num) FROM products


DROP FUNCTION fabricantes;

CREATE FUNCTION fabricantes(@stock_num SMALLINT)
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @fabricantes VARCHAR(100), @manu_code CHAR(3);

	DECLARE products_cursor CURSOR FOR 
		SELECT manu_code FROM products WHERE stock_num = @stock_num;

	OPEN products_cursor;
	FETCH NEXT FROM products_cursor INTO @manu_code;
	SET @fabricantes = @manu_code

	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		SET @fabricantes = @fabricantes +' | ' + @manu_code
		FETCH NEXT FROM products_cursor INTO @manu_code;
	END
	
	CLOSE products_cursor
	DEALLOCATE products_cursor
	
	RETURN @fabricantes
END