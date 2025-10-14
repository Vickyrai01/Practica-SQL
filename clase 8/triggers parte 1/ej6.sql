/*
Crear tres triggers (Insert, Update y Delete) sobre la tabla Products para replicar todas las
operaciones en la tabla Products _replica, la misma deberá tener la misma estructura de la tabla
Products.
*/

CREATE TABLE products_replica(
		stock_num SMALLINT PRIMARY KEY,
		manu_code CHAR(3),
		unit_price DECIMAL(6,2),
		unit_code SMALLINT,
		status CHAR(1)
)
CREATE TRIGGER insert_products ON products
AFTER INSERT AS
BEGIN
	INSERT INTO Products_replica (stock_num, manu_code, unit_price, unit_code)
	SELECT stock_num, manu_code, unit_price, unit_code FROM inserted
END


CREATE TRIGGER delete_products ON products
AFTER DELETE AS
BEGIN
	DELETE pr FROM products_replica pr 
	INNER JOIN deleted d ON (d.stock_num = pr.stock_num AND d.manu_code = pr.manu_code)
	
END

CREATE TRIGGER update_products ON products
AFTER INSERT AS
BEGIN
	UPDATE sr SET sr.unit_price = i.unit_price, sr.unit_code = i.unit_code
	FROM Products_replica sr
	JOIN inserted i ON (sr.stock_num = i.stock_num AND sr.manu_code = i.manu_code)
END