-- Mostrar el Código del fabricante, nombre del fabricante, tiempo de entrega y monto
-- Total de productos vendidos, ordenado por nombre de fabricante. En caso que el
-- fabricante no tenga ventas, mostrar el total en NULO.

SELECT m.manu_code, manu_name, lead_time, SUM(i.quantity * i.unit_price) montoTotal  
FROM manufact m LEFT JOIN items i ON (m.manu_code = i.manu_code)
GROUP BY m.manu_code, manu_name, lead_time
ORDER BY m.manu_name