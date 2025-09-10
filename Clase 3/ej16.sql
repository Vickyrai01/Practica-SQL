-- Obtener un listado con el código de fabricante, nro de producto, la cantidad vendida (quantity), y el total
-- vendido (quantity x unit_price), para los fabricantes cuyo código tiene una “R” como segunda letra. Ordenar
-- el listado por código de fabricante y nro de producto.

SELECT manu_code, stock_num, SUM(quantity) Cantidad, SUM(quantity * unit_price) totalVendido 
FROM items 
WHERE manu_code LIKE '_R%' 
GROUP BY manu_code, stock_num 
ORDER BY 1,2;