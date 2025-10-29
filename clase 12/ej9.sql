SELECT c.customer_num, fname, lname, state, COUNT(DISTINCT o.order_num) cant_ordenes, SUM(i.quantity * i.unit_price) total_gastado
FROM customer c
	INNER JOIN orders o ON (c.customer_num = o.customer_num)
	INNER JOIN items i ON (o.order_num = i.order_num)
WHERE YEAR(order_date) = 2015 AND state <> 'FL'
GROUP BY c.customer_num, fname, lname,  state
HAVING SUM(i.quantity * i.unit_price) > 
	(
	SELECT SUM(i1.quantity * i1.unit_price)/ COUNT(DISTINCT c1.customer_num)
	 FROM customer c1
		INNER JOIN orders o1 ON (o1.customer_num = c1.customer_num)
		INNER JOIN items i1 ON (o1.order_num = i1.order_num)
	  WHERE c1.state <> 'FL')

ORDER BY SUM(i.quantity * i.unit_price) DESC