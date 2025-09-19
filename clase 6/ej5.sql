-- Obtener por cada fabricante, el listado de todos los productos de stock con precio
-- unitario (unit_price) mayor que el precio unitario promedio de dicho fabricante.
-- Los campos de salida serán: manu_code, manu_name, stock_num, description,
-- unit_price.


SELECT m.manu_code, m.manu_name, p.stock_num, pt.description, p.unit_price FROM manufact m 
    INNER JOIN products p ON (m.manu_code = p.manu_code)
    INNER JOIN product_types pt ON (p.stock_num = pt.stock_num)
WHERE unit_price > (
                    SELECT AVG(p2.unit_price)
                    FROM manufact m2
                        INNER JOIN products p2 ON (m2.manu_code = p2.manu_code)
                    WHERE m2.manu_code = m.manu_code
                    )