-- Usando el operador NOT EXISTS listar la información de órdenes de compra que NO
-- incluyan ningún producto que contenga en su descripción el string ‘ baseball gloves’.
-- Ordenar el resultado por compañía del cliente ascendente y número de orden
-- descendente.
-- El formato de salida deberá ser:
-- Número de Cliente       Compañía       Número de Orden       Fecha de la Orden
-- (customer_num)          (company)        (order_num)          (order_date)

SELECT c.customer_num, c.company, o.order_num, o.order_date 
FROM orders o
    INNER JOIN customer      c  ON (c.customer_num =o.customer_num)
    INNER JOIN items         i  ON (o.order_num = i.order_num)
    INNER JOIN product_types pt ON (pt.stock_num = i.stock_num)
WHERE NOT EXISTS (
          SELECT 1 
          FROM items i2
              INNER JOIN product_types pt2 ON (pt2.stock_num = i2.stock_num)
          WHERE i2.order_num = o.order_num AND description LIKE '%baseball gloves%'
          )
ORDER BY c.company ASC, o.order_num DESC