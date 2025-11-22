-- 02-window-functions.sql
-- Window functions examples using orders and customers

-- 1) Rank customers by total spend (descending)
SELECT customer_id,
       total_spend,
       RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM (
    SELECT customer_id, SUM(total_amount) AS total_spend
    FROM orders
    GROUP BY customer_id
) t;

-- 2) Rolling 3-month sum of orders per customer (assuming order_date is DATE)
SELECT order_date,
       customer_id,
       total_amount,
       SUM(total_amount) OVER (
         PARTITION BY customer_id
         ORDER BY order_date
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS rolling_3_orders_sum
FROM orders
ORDER BY customer_id, order_date;

-- 3) Percentile / relative contribution per product category
SELECT product_id,
       category,
       revenue,
       revenue * 1.0 / SUM(revenue) OVER (PARTITION BY category) AS pct_of_category
FROM (
    SELECT p.product_id, p.category, SUM(oi.qty * oi.price) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.category
) s
ORDER BY category, revenue DESC;

-- 4) LAG / LEAD example: month over month change in sales per product
-- (Assumes a monthly_agg table or aggregated data)
WITH monthly_sales AS (
  SELECT DATE_TRUNC('month', order_date) AS month,
         oi.product_id,
         SUM(oi.qty * oi.price) AS revenue
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  GROUP BY 1, oi.product_id
)
SELECT month,
       product_id,
       revenue,
       LAG(revenue) OVER (PARTITION BY product_id ORDER BY month) AS prev_month_revenue,
       revenue - LAG(revenue) OVER (PARTITION BY product_id ORDER BY month) AS revenue_diff
FROM monthly_sales
ORDER BY product_id, month;
