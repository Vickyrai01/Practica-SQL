-- Consultar la tabla temporal del punto anterior y obtener la cantidad de clientes con igual cantidad de
-- compras. Ordenar el listado por cantidad de compras en orden descendente

SELECT cantidadOrdenes, COUNT(*) cantCliConIgualesCompras 
FROM #OrdenesTemp 
GROUP BY cantidadOrdenes 
ORDER BY cantidadOrdenes DESC;