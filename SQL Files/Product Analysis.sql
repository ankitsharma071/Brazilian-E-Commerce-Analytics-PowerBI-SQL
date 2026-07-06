-- Product Analysis
SELECT
    CASE
        WHEN p.product_category_name IS NULL THEN 'Unknown Category'
        ELSE COALESCE(ct.product_category_name_english, p.product_category_name)
    END AS product_category_name,

    COUNT(DISTINCT oi.product_id) AS unique_products,

    ROUND(SUM(oi.price),2) AS revenue,

    ROUND(AVG(oi.price),2) AS avg_price,

    ROUND(AVG(oi.freight_value),2) AS avg_freight,

    ROUND((SUM(oi.freight_value) / SUM(oi.price)),4) AS freight_pct,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id),2) AS avg_order_value,

    ROUND(
        (
            COUNT(DISTINCT CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN o.order_id
            END)
            /
            COUNT(DISTINCT o.order_id)
        ),
    4) AS late_delivery_pct,

    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
    2) AS avg_delivery_days

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products p
    ON p.product_id = oi.product_id

LEFT JOIN category_translation ct
    ON ct.product_category_name = p.product_category_name

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY
    CASE
        WHEN p.product_category_name IS NULL THEN 'Unknown Category'
        ELSE COALESCE(ct.product_category_name_english, p.product_category_name)
    END;
    
-- Lifetime Revenue Of Customers 
SELECT customer_unique_id, COUNT(DISTINCT order_id) as no_of_orders, SUM(PRICE) as Lifetime_revenue FROM
(SELECT c.customer_unique_id , o.order_id , oi.price
FROM orders o 
JOIN customers c
ON c.customer_id = o.customer_id 
JOIN order_items oi 
ON oi.order_id = o.order_id)a
GROUP BY customer_unique_id
order by lifetime_revenue desc
LIMIT 10

-- Product Category with their Avg Rating
SELECT
    p.product_category_name,
    ROUND(AVG(r.review_score),2) AS avg_review_score,
    COUNT(*) AS review_count
FROM order_reviews r
JOIN order_items oi
ON r.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING COUNT(*) >= 100
ORDER BY avg_review_score;