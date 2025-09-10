-- Se tiene la tabla units, de la cual se quiere saber la cantidad de unidades que hay por cada tipo (unit) que no
-- tengan en nulo el descr_unit, y además se deben mostrar solamente los que cumplan que la cantidad
-- mostrada se superior a 5. Al resultado final se le debe sumar 1

SELECT unit, COUNT(*) + 1 
FROM units 
WHERE unit_descr IS NOT NULL 
GROUP BY unit HAVING COUNT(*) > 5