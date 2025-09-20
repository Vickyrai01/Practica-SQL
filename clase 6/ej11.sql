-- Desarrollar una consulta que devuelva los dos tipos de productos más vendidos y los dos
-- menos vendidos en función de las unidades totales vendidas.

SELECT stock_num, cantidad
FROM (
    SELECT TOP 2 stock_num, SUM(quantity) AS cantidad
    FROM items
    GROUP BY stock_num
    ORDER BY SUM(quantity) DESC
) AS mas_vendidos

UNION

SELECT stock_num, cantidad
FROM (
    SELECT TOP 2 stock_num, SUM(quantity) AS cantidad
    FROM items
    GROUP BY stock_num
    ORDER BY SUM(quantity) ASC
) AS menos_vendidos

ORDER BY cantidad DESC