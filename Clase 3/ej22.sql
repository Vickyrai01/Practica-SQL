-- Se desea obtener el promedio de lead_time por cada estado, donde los Fabricantes tengan una ‘e’ en
-- manu_name y el lead_time sea entre 5 y 20.

SELECT state, AVG(lead_time) 
FROM manufact 
WHERE manu_name LIKE '%e%' AND lead_time BETWEEN 5 AND 20 
GROUP BY state