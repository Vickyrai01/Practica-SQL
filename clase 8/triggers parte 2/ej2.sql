/*
2. Triggers Dada la siguiente vista
CREATE VIEW ProdPorFabricante AS
SELECT m.manu_code, m.manu_name, COUNT(*)
FROM manufact m INNER JOIN products p
ON (m.manu_code = p.manu_code)
GROUP BY manu_code, manu_name;

Crear un trigger que permita ante un insert en la vista ProdPorFabricante insertar una fila
en la tabla manufact.
Observaciones: el atributo leadtime deberá insertarse con un valor default 10
El trigger deberá contemplar inserts de varias filas, por ej. ante un INSERT / SELECT.

*/

CREATE VIEW ProdPorFabricante AS
	SELECT m.manu_code, m.manu_name, COUNT(*) cant_productos
	FROM manufact m 
		INNER JOIN products p ON (m.manu_code = p.manu_code)
	GROUP BY m.manu_code, manu_name;


CREATE TRIGGER triggerC8T2E2
ON ProdPorFabricante
INSTEAD OF INSERT AS
BEGIN

	INSERT INTO manufact (manu_code, manu_name, lead_time)
		SELECT manu_code,manu_name,10 FROM inserted;

END