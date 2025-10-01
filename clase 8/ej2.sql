/*
Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma
realice en su lugar un update del campo estado de ‘A’ a ‘I’ (inactivo).
*/

CREATE TRIGGER products_historia_precios_delete
ON products_historia_precios
INSTEAD OF DELETE
AS
BEGIN 
	UPDATE products_historia_precios
	SET estado = 'I' 
	WHERE Stock_historia_Id IN (SELECT Stock_historia_Id FROM deleted)
END

DELETE products_historia_precios 
WHERE Stock_historia_Id = 1 