-- 13. Crear una Vista llamada Productos_HRO en base a la consulta
-- SELECT * FROM products
-- WHERE manu_code = “HRO”

-- La vista deberá restringir la posibilidad de insertar datos que no cumplan con su criterio de
-- selección.
-- a. Realizar un INSERT de un Producto con manu_code=’ANZ’ y stock_num=303. Qué sucede? <- Son re graciosos
-- b. Realizar un INSERT con manu_code=’HRO’ y stock_num=303. Qué sucede?
-- c. Validar los datos insertados a través de la vista.

CREATE VIEW Productos_HRO AS
SELECT * FROM products
WHERE manu_code = 'HRO'


INSERT INTO Productos_HRO (manu_code, stock_num) VALUES ('ANZ', 303)

INSERT INTO Productos_HRO (manu_code, stock_num) VALUES ('HRO', 303)