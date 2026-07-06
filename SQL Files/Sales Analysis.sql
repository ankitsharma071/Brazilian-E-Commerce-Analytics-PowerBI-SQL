-- MOM Growth Percent
SELECT *,
round(100.0 * ((revenue - previous_month_revenue)/previous_month_revenue),2) as mom_growth_pct from 
(SELECT *, LAG(REVENUE) OVER(ORDER BY year, month_no) as previous_month_revenue from 
(SELECT
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) as month_no,
    MONTHNAME(order_purchase_timestamp) AS month_name,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT o.order_id) as total_orders,
    (SUM(oi.price)/COUNT(DISTINCT o.order_id)) AS AOV
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_purchase_timestamp >= '2017-01-01'
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp),
    MONTHNAME(order_purchase_timestamp)
ORDER BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp))a)b

-- Effect on Rating If ON Time Delivery vs Late Delivery
SELECT delivery_status, AVG(review_Score) as avg_score FROM
(SELECT r.review_score,
CASE WHEN order_estimated_delivery_date < order_delivered_customer_date 
		  THEN 'LATE'
	 ELSE 'ON-TIME' END AS delivery_status
FROM ORDERS O 
JOIN order_reviews r
ON o.order_id = r.order_id
WHERE o.order_status = 'delivered')a
GROUP BY delivery_status