-- Se desea obtener la cantidad de clientes por cada state y city, donde los clientes contengan el string
-- ‘ts’ en el nombre de compañía, el código postal este entre 93000 y 94100 y la ciudad no sea 'Mountain View'. Se
-- desea el listado ordenado por ciudad

SELECT state, city, COUNT(*) Clientes 
FROM customer 
WHERE company LIKE '%ts%' AND zipcode BETWEEN 93000 AND 94100 AND city != 'Mountain View'
GROUP BY state, city 
ORDER BY city
