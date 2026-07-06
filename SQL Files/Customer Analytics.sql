-- Customer State Wise Analysis
SELECT c.customer_state as State, 
SUM(oi.price) as Revenue, 
COUNT(DISTINCT o.order_id) as Orders,
COUNT(DISTINCT customer_unique_id) as Customers,
ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,o.order_purchase_timestamp)),2) as avg_delivery_days,
ROUND(100.0 * COUNT(
DISTINCT CASE
WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
THEN o.order_id
END
)
/
COUNT(DISTINCT o.order_id),2) as late_delivery_pct
FROM customers c 
JOIN orders o 
ON c.customer_id = o.customer_id
JOIN order_items oi 
ON oi.order_id = o.order_id 
WHERE order_delivered_customer_date IS NOT NULL
AND order_status='delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC