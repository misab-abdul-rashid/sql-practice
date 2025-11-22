-- 03-ctes.sql
-- Common Table Expression (CTE) examples and recursive CTE example

-- 1) Simple CTE: top 10 customers by spend, then join to get details
WITH top_customers AS (
  SELECT customer_id, SUM(total_amount) AS total_spend
  FROM orders
  GROUP BY customer_id
  ORDER BY total_spend DESC
  LIMIT 10
)
SELECT tc.customer_id,
       tc.total_spend,
       c.name,
       c.city
FROM top_customers tc
JOIN customers c ON tc.customer_id = c.customer_id;

-- 2) Multi-CTE pipeline: filter, aggregate, then rank
WITH recent_orders AS (
  SELECT *
  FROM orders
  WHERE order_date >= DATE('2024-01-01')
),
customer_spend AS (
  SELECT customer_id, SUM(total_amount) AS spend_2024
  FROM recent_orders
  GROUP BY customer_id
)
SELECT cs.customer_id,
       c.name,
       cs.spend_2024,
       RANK() OVER (ORDER BY cs.spend_2024 DESC) AS rank_2024
FROM customer_spend cs
JOIN customers c ON cs.customer_id = c.customer_id
ORDER BY rank_2024;

-- 3) Recursive CTE: build a calendar table (useful in many analyses)
WITH RECURSIVE calendar AS (
  SELECT DATE('2024-01-01') AS day
  UNION ALL
  SELECT DATE(day, '+1 day')
  FROM calendar
  WHERE day < DATE('2024-12-31')
)
SELECT day FROM calendar;

-- 4) CTE for incremental aggregation: compute month-over-month growth by category
WITH monthly_rev AS (
  SELECT strftime('%Y-%m', o.order_date) AS year_month,
         p.category,
         SUM(oi.qty * oi.price) AS revenue
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY year_month, p.category
),
ranked AS (
  SELECT year_month, category, revenue,
         LAG(revenue) OVER (PARTITION BY category ORDER BY year_month) AS prev_rev
  FROM monthly_rev
)
SELECT year_month,
       category,
       revenue,
       prev_rev,
       CASE
         WHEN prev_rev IS NULL THEN NULL
         ELSE (revenue - prev_rev) * 1.0 / prev_rev
       END AS mom_growth
FROM ranked
ORDER BY category, year_month;
