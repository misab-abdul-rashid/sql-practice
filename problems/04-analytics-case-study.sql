-- 04-analytics-case-study.sql
-- Mini case study: "Repeat customers and driver of revenue" 
-- Objective: Find repeat purchase rate, top 10 products driving repeat orders, and churn signal.

-- 1) Create customer order summary (orders_count, first_order_date, last_order_date, total_spend)
WITH cust_summary AS (
  SELECT customer_id,
         COUNT(order_id) AS orders_count,
         MIN(order_date) AS first_order_date,
         MAX(order_date) AS last_order_date,
         SUM(total_amount) AS total_spend
  FROM orders
  GROUP BY customer_id
)

SELECT *
FROM cust_summary
ORDER BY orders_count DESC
LIMIT 50;

-- 2) Repeat customer rate: percentage of customers with >1 orders
WITH cust_orders AS (
  SELECT customer_id, COUNT(order_id) AS orders_count
  FROM orders
  GROUP BY customer_id
)
SELECT
  SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS repeat_customer_rate,
  SUM(CASE WHEN orders_count = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS one_time_rate
FROM cust_orders;

-- 3) Top products in repeat orders (products that appear more in repeat customers' orders)
WITH repeat_customers AS (
  SELECT customer_id
  FROM orders
  GROUP BY customer_id
  HAVING COUNT(order_id) > 1
),
repeat_order_items AS (
  SELECT oi.*
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.customer_id IN (SELECT customer_id FROM repeat_customers)
)
SELECT p.product_id,
       p.name,
       p.category,
       SUM(repeat_order_items.qty * repeat_order_items.price) AS revenue_from_repeat
FROM repeat_order_items
JOIN products p ON repeat_order_items.product_id = p.product_id
GROUP BY p.product_id, p.name, p.category
ORDER BY revenue_from_repeat DESC
LIMIT 10;

-- 4) Churn signal example: customers with no orders in last 90 days but ordered in prior 90 days
WITH last_dates AS (
  SELECT customer_id,
         MAX(order_date) AS last_order_date
  FROM orders
  GROUP BY customer_id
),
churn_candidates AS (
  SELECT customer_id
  FROM last_dates
  WHERE last_order_date < DATE('now', '-90 days')
)
SELECT COUNT(*) AS churn_candidates_count
FROM churn_candidates;

-- 5) Actionable insight (combine revenue + recency to prioritize re-engagement)
WITH recency AS (
  SELECT customer_id, JULIANDAY('now') - JULIANDAY(MAX(order_date)) AS days_since_last_order
  FROM orders
  GROUP BY customer_id
),
r_value AS (
  SELECT r.customer_id, r.days_since_last_order, SUM(o.total_amount) AS lifetime_value
  FROM recency r
  JOIN orders o ON r.customer_id = o.customer_id
  GROUP BY r.customer_id, r.days_since_last_order
)
SELECT customer_id, lifetime_value, days_since_last_order
FROM r_value
WHERE days_since_last_order BETWEEN 60 AND 120
ORDER BY lifetime_value DESC
LIMIT 50;
