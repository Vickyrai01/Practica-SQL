-- Obtener un listado de la cantidad de productos únicos comprados a cada fabricante, en donde el total
-- comprado a cada fabricante sea mayor a 1500. El listado deberá estar ordenado por cantidad de productos
-- comprados de mayor a menor.

SELECT manu_code fabricante, COUNT(DISTINCT stock_num) productosTotales  
FROM items 
GROUP BY manu_code 
HAVING COUNT(quantity * unit_price) > 1500 
ORDER BY productosTotales DESC;