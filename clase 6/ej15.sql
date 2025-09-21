-- Se ha decidido crear un nuevo fabricante AZZ, quién proveerá parte de los mismos
-- productos que provee el fabricante ANZ, los productos serán los que contengan el string
-- ‘tennis’ en su descripción.
-- • Agregar las nuevas filas en la tabla manufact y la tabla products.
-- • El código del nuevo fabricante será “AZZ”, el nombre de la compañía “AZZIO SA”
-- y el tiempo de envío será de 5 días (lead_time).
-- • La información del nuevo fabricante “AZZ” de la tabla Products será la misma
-- que la del fabricante “ANZ” pero sólo para los productos que contengan 'tennis'
-- en su descripción.
-- • Tener en cuenta las restricciones de integridad referencial existentes, manejar
-- todo dentro de una misma transacción.

BEGIN TRANSACTION

SELECT p.stock_num, 'AZZ' manu_code, p.unit_price, p.unit_code
INTO #fabProducTenis
FROM products p
	INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
WHERE description LIKE '%tennis%' AND manu_code = 'ANZ'

INSERT INTO manufact (manu_code, manu_name, lead_time) VALUES ('AZZ', 'AZZIO SA', 5)

INSERT INTO products (stock_num, manu_code, unit_price, unit_code)
SELECT stock_num, manu_code, unit_price, unit_code
FROM #fabProducTenis;

SELECT * FROM products
SELECT * FROM manufact

COMMIT 

ROLLBACK