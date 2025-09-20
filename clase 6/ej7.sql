-- Obtener el número, nombre y apellido de los clientes que NO hayan comprado productos
-- del fabricante ‘HSK’.

SELECT fname, lname, c.customer_num 
FROM customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
        INNER JOIN items i ON (o.order_num = i.order_num)
        WHERE c.customer_num = o.customer_num
            AND manu_code = 'HSK'
)