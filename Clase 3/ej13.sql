-- Mostrar fecha de embarque (ship_date) y cantidad total de libras (ship_weight) por día, de aquellos 
-- días cuyo peso de los embarques superen las 30 libras. Ordenar el resultado por el total de libras en orden 
-- descendente. 

SELECT ship_date, SUM(ship_weight) pesoTotal
FROM orders 
GROUP BY ship_date 
HAVING SUM(ship_weight) > 30