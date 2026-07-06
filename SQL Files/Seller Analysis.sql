-- Seller Analysis 1
SELECT s.seller_id  , s.seller_state, sum(oi.price) as revenue,
COUNT(DISTINCT o.order_id) as total_orders,
COUNT(DISTINCT c.customer_unique_id) as unique_customers,
ROUND(sum(oi.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value,
ROUND(AVG(orev.review_score),2) as AVG_rating
FROM sellers s
JOIN order_items oi 
ON s.seller_id = oi.seller_id
JOIN orders o
on o.order_id = oi.order_id 
JOIN customers c
ON c.customer_id = o.customer_id 
JOIN order_reviews orev
ON orev.order_id = o.order_id
GROUP BY s.seller_id , s.seller_state 

-- Seller Analysis 2
SELECT
    s.seller_id,

    ROUND(
        (
            COUNT(DISTINCT CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN o.order_id
            END)
            /
            NULLIF(COUNT(DISTINCT o.order_id),0)
        ),
    2) AS late_del_pct,

    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
    2) AS avg_del_time_days,

    COUNT(DISTINCT p.product_category_name) AS distinct_cat_sold,

    COUNT(DISTINCT oi.product_id) AS products_sold

FROM sellers s

LEFT JOIN order_items oi
    ON s.seller_id = oi.seller_id

LEFT JOIN orders o
    ON oi.order_id = o.order_id

LEFT JOIN products p
    ON oi.product_id = p.product_id

GROUP BY s.seller_id;


-- Seller Analysis 3
WITH seller_orders AS
(
SELECT DISTINCT
    seller_id,
    order_id
FROM order_items
)
SELECT
    s.seller_id,
    ROUND(AVG(orev.review_score),2) AS avg_rating
FROM seller_orders so
JOIN sellers s
ON s.seller_id = so.seller_id
JOIN order_reviews orev
ON orev.order_id = so.order_id
GROUP BY s.seller_id

-- Sellers with highest Late Delivery Percent
SELECT s.seller_id,
COUNT(DISTINCT o.order_id) AS total_orders , 
ROUND((100.0 * (COUNT(DISTINCT CASE WHEN 
	order_delivered_customer_date > order_estimated_delivery_date THEN o.order_id END) /
COUNT(DISTINCT o.order_id))),2)
    as late_pct
FROM products p
JOIN order_items oi
on p.product_id = oi.product_id
JOIN orders o
ON o.order_id = oi.order_id
JOIN sellers s 
ON s.seller_id = oi.seller_id
WHERE order_status = 'delivered'
GROUP BY s.seller_id
HAVING COUNT(DISTINCT o.order_id) >= 300
ORDER BY late_pct DESC

-- Top 3 Sellers in Each Customer State 
SELECT * FROM 
(SELECT * , dense_rank() OVER(partition by customer_state order by revenue desc) as rnk FROM 
(SELECT c.customer_state, oi.seller_id , SUM(oi.price) as revenue
FROM
customers c
JOIN orders o 
ON c.customer_id = o.customer_id 
JOIN order_items oi
ON oi.order_id = o.order_id 
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, c.customer_state )a)b
WHERE rnk <=3

-- Cumulative Revenue By Sellers
SELECT *, row_number() OVER(order by cumulative_pct asc) AS RNK FROM
(SELECT *, ROUND(100.0 * (cumulative_revenue/(SUM(revenue) OVER())),2) as cumulative_pct 
FROM  
(SELECT *,
SUM(revenue) 
OVER(ORDER BY REVENUE DESC rows between unbounded preceding and current row) as cumulative_revenue 
FROM 
(SELECT seller_id, SUM(price) as revenue
FROM order_items oi 
GROUP BY seller_id
ORDER BY revenue desc)a)b)C
