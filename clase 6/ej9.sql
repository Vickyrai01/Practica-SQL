-- Reescribir la siguiente consulta utilizando el operador UNION:
-- SELECT * FROM products
-- WHERE manu_code = 'HRO' OR stock_num = 1

SELECT * FROM products WHERE manu_code = 'HRO'
UNION
SELECT * FROM products WHERE stock_num = 1