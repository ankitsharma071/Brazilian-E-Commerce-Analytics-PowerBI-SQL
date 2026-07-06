-- RFM Segmentation
WITH Recency as (
SELECT *, DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders) ,last_order_date) as RECENCY FROM
(SELECT customer_unique_id , order_purchase_timestamp as last_order_date FROM 
(SELECT *, 
DENSE_RANK() OVER(partition by customer_unique_id order by order_purchase_timestamp desc ) as rnk from 
(SELECT c.customer_unique_id , o.order_purchase_timestamp
FROM orders o
JOIN customers c
ON c.customer_id = o.customer_id )a)b
where RNK =1)c
ORDER BY RECENCY asc),

FREQUENCY AS (
SELECT c.customer_unique_id , COUNT(DISTINCT order_id) as Frequency 
FROM 
orders o  JOIN customers c
ON o.customer_id= c.customer_id
GROUP BY c.customer_unique_id), 

SPEND AS (
SELECT customer_unique_id , SUM(price) as Spend
FROM 
orders o
JOIN customers c
ON o.customer_id = c.customer_id 
join order_items oi 
ON oi.order_id = o.order_id
GROUP BY customer_unique_id)

(SELECT *, 
CASE
WHEN R >= 4 AND F >= 4 AND S >= 4
THEN 'Champion'
WHEN R >= 3 AND F >= 4
THEN 'Loyal Customer'
WHEN R >= 4 AND F <= 2
THEN 'New Customer'
WHEN R <= 2 AND (F >= 4 OR S >= 4)
THEN 'At Risk'
ELSE 'Regular Customer' END AS Customer_Segment
FROM 
(SELECT *, CONCAT(R,F,S) as RFS_Score FROM 
(SELECT * , NTILE(5) over(order by recency desc) as R, 
NTILE(5) OVER(order by frequency asc) as F,
NTILE(5) OVER(order by spend asc) as S from 
(SELECT r.customer_unique_id , r.Recency , f.Frequency, S.Spend
FROM 
recency r
JOIN frequency f
ON r.customer_unique_id = f.customer_unique_id 
JOIN spend s
on s.customer_unique_id = f.customer_unique_id
ORDER BY recency ASC)
a)b)c)

