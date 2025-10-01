/*
Validar que sólo se puedan hacer inserts en la tabla Products en un horario entre las 8:00 AM y
8:00 PM. En caso contrario enviar un error por pantalla.
*/

CREATE TRIGGER horarioTR
ON products
AFTER INSERT
AS
BEGIN
    IF(DATEPART(hour, GETDATE()) NOT BETWEEN 8 AND 20)
        THROW 50000, 'No se puede insertar a esta hora', 1
END