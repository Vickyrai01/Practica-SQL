/*
1. Dada la tabla Products de la base de datos stores7 se requiere crear una tabla
Products_historia_precios y crear un trigger que registre los cambios de precios que se hayan
producido en la tabla Products.
Tabla Products_historia_precios
	 Stock_historia_Id Identity (PK)
	 Stock_num
	 Manu_code
	 fechaHora (grabar fecha y hora del evento)
	 usuario (grabar usuario que realiza el cambio de precios)
	 unit_price_old
	 unit_price_new
	 estado char default ‘A’ check (estado IN (‘A’,’I’)

*/

CREATE TABLE products_historia_precios (
	Stock_historia_Id INT IDENTITY (1,1),
	Stock_num SMALLINT,
	manu_code VARCHAR(4), 
	fechaHora DATETIME,
	usuario VARCHAR(50),
	unit_price_old INT,
	unit_price_new INT,
	estado CHAR DEFAULT 'A'
);

DROP TABLE products_historia_precios

CREATE TRIGGER products_historia_precios_auditoria
ON products
AFTER UPDATE
AS
BEGIN
	INSERT INTO products_historia_precios
	SELECT d.stock_num, d.manu_code, getdate(), SYSTEM_USER, d.unit_price, i.unit_price, 'A'
	FROM deleted d INNER JOIN inserted i ON (d.manu_code = i.manu_code) AND (d.stock_num = i.stock_num)
END

SELECT * FROM products

DROP TRIGGER products_historia_precios_auditoria

UPDATE products
SET unit_price = 440
WHERE manu_code = 'HRO' AND stock_num = 1 


SELECT * FROM products_historia_precios 
