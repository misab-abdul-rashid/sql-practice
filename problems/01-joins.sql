-- 01-joins.sql
-- Schema (example tables):
-- customers(customer_id, name, city)
-- orders(order_id, customer_id, order_date, total_amount)
-- products(product_id, name, category)
-- order_items(order_item_id, order_id, product_id, qty, price)

-- 1) INNER JOIN: list orders with customer name and total amount
SELECT o.order_id,
       c.customer_id,
       c.name AS customer_name,
       o.order_date,
       o.total_amount
FROM orders o
INNER JOIN customers c
  ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC
LIMIT 50;

-- 2) LEFT JOIN: show all customers and their last order amount (if any)
SELECT c.customer_id,
       c.name,
       o.order_id,
       o.order_date,
       o.total_amount
FROM customers c
LEFT JOIN (
    SELECT order_id, customer_id, order_date, total_amount
    FROM orders
) o
  ON c.customer_id = o.customer_id
ORDER BY c.customer_id;

-- 3) JOIN across three tables: order items with product name and customer
SELECT oi.order_item_id,
       o.order_id,
       c.name AS customer_name,
       p.name AS product_name,
       oi.qty,
       oi.price,
       (oi.qty * oi.price) AS line_total
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY line_total DESC
LIMIT 100;

-- 4) INNER JOIN with aggregation: total spend per customer
SELECT c.customer_id,
       c.name,
       SUM(o.total_amount) AS total_spend,
       COUNT(o.order_id) AS orders_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.total_amount) > 1000
ORDER BY total_spend DESC;

-- 5) Self-join example: customers who live in same city (pairing)
SELECT a.customer_id AS cust_a,
       a.name AS name_a,
       b.customer_id AS cust_b,
       b.name AS name_b,
       a.city
FROM customers a
JOIN customers b
  ON a.city = b.city
 AND a.customer_id < b.customer_id
ORDER BY a.city;
