-- Escriba una transacción que incluya las siguientes acciones:
--	BEGIN TRANSACTION
--		•Insertar un nuevo cliente llamado “Fred Flintstone” en la tabla de clientes (customer).
--		• Seleccionar todos los clientes llamados Fred de la tabla de clientes (customer).
--	ROLLBACK TRANSACTION
-- Luego volver a ejecutar la consulta
--		• Seleccionar todos los clientes llamados Fred de la tabla de clientes (customer).
--		• Completado el ejercicio descripto arriba. Observar que los resultados del segundo SELECT difieren con respecto al primero.

BEGIN TRANSACTION 

INSERT INTO customer (fname, lname, customer_num) VALUES ('Fred', 'Flintstone', 2003)
SELECT * FROM customer WHERE fname = 'Fred'

ROLLBACK