/*
Escribir una sentencia SELECT que devuelva el número de orden, fecha de orden y el nombre del
día de la semana de la orden de todas las órdenes que no han sido pagadas.
Si el cliente pertenece al estado de California el día de la semana debe devolverse en inglés, caso
contrario en español. Cree una función para resolver este tema.
Nota: SET @DIA = datepart(weekday,@fecha)
Devuelve en la variable @DIA el nro. de día de la semana , comenzando con 1 Domingo hasta 7
Sábado.
*/

SELECT order_num, order_date, dbo.fecha_orden(order_date, CASE c.state
													WHEN 'CA' THEN 'ingles'
													ELSE 'espaniol'
													END) fecha
FROM orders o
	INNER JOIN customer c ON (o.customer_num = c.customer_num)
WHERE paid_date IS NULL


CREATE FUNCTION fecha_orden(@fecha DATETIME, @idioma VARCHAR(10))
	RETURNS VARCHAR (20)
	AS
	BEGIN

		DECLARE @dia INT
		DECLARE @return VARCHAR(20)
		
		SET @dia = datepart(weekday,@fecha)
		
		IF @idioma = 'espaniol'
		BEGIN
			SET @return =
				CASE WHEN @dia = 1 THEN 'Domingo'
					 WHEN @dia = 2 THEN 'Lunes'
				     WHEN @dia = 3 THEN 'Martes'
					 WHEN @dia = 4 THEN 'Miercoles'
					 WHEN @dia = 5 THEN 'Jueves'
					 WHEN @dia = 6 THEN 'Viernes'
					 WHEN @dia = 7 THEN 'Sabado'
				END
		END
		ELSE
		BEGIN
			SET @return =
				CASE WHEN @dia = 1 THEN 'Sunday'
					 WHEN @dia = 2 THEN 'Monday'
				     WHEN @dia = 3 THEN 'Tuesday'
					 WHEN @dia = 4 THEN 'Wednesday'
					 WHEN @dia = 5 THEN 'Thursday'
					 WHEN @dia = 6 THEN 'Friday'
					 WHEN @dia = 7 THEN 'Saturday'
				END	
		END
		RETURN @return
	END