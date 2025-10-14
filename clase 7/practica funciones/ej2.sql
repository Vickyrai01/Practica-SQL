SELECT o.customer_num, dbo.fx_datosporMes(1, o.customer_num) anio1, dbo.fx_datosporMes(2, o.customer_num) anio2 FROM orders o 
WHERE EXISTS (SELECT 1
			  FROM orders o2
			  WHERE o2.customer_num = o.customer_num AND 
					month(o.order_date) > month(o2.order_date))


CREATE FUNCTION fx_datosporMes(@ORDEN SMALLINT, @CLIENTE INT)
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @MES VARCHAR(4)
    DECLARE @CARGA VARCHAR(50)
    DECLARE @RETORNO VARCHAR(100)

    IF @ORDEN = 1
    BEGIN
        SELECT TOP 1
            @MES   = MONTH(ship_date),
            @CARGA = MAX(ship_charge)
        FROM orders
        WHERE customer_num = @CLIENTE
        GROUP BY MONTH(ship_date)
        ORDER BY 2 DESC;

        SET @RETORNO = @MES + ' - Total: ' + @CARGA;
    END
    ELSE
    BEGIN
        SELECT TOP 1
            @MES   = order_date,
            @CARGA = COALESCE(ship_charge,0)
        FROM
        (
            SELECT TOP 2
                   MONTH(ship_date)      AS order_date,
                   MAX(ship_charge)       AS ship_charge
            FROM orders
            WHERE customer_num = @CLIENTE
            GROUP BY MONTH(ship_date)
            ORDER BY 2 DESC              
        ) AS SQL1
        ORDER BY 2 ASC;                   

        SET @RETORNO = @MES + ' - Total: ' + @CARGA;
    END

    RETURN @RETORNO;
END