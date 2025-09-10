-- Emitir un reporte con la cantidad de unidades vendidas y el importe total por mes de productos,
-- ordenado por importe total en forma descendente.
-- Formato: Año/Mes Cantidad Monto_Total

SELECT FORMAT(o.order_date, 'yyyy/MM') AñoMes, SUM(i.quantity) Cantidad, SUM(i.unit_price * i.quantity) Monto_Total
FROM orders o INNER JOIN items i ON (o.order_num = i.order_num)
GROUP BY FORMAT(o.order_date, 'yyyy/MM')
ORDER BY Monto_Total DESC;