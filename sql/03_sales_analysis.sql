USE ecommerce_analytics;

SELECT COUNT(*) AS total_customers FROM customers;
SELECT COUNT(*) AS total_orders FROM orders;
SELECT COUNT(*) AS total_products FROM products;
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered';

SELECT
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered';

SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Orders by payment method
SELECT payment_method, COUNT(*) AS order_count
FROM orders
GROUP BY payment_method
ORDER BY order_count DESC;

-- Revenue by month
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY month
ORDER BY month;

-- Revenue by category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;

-- Revenue by state
SELECT
    c.state,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.state
ORDER BY revenue DESC;

-- Top 10 products by revenue
SELECT
    p.product_name,
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue,
    SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- Cancellation / return rate
SELECT
    ROUND(100.0 * SUM(CASE WHEN status IN ('Cancelled','Returned') THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancel_return_rate_pct
FROM orders;

-- Average order value by payment method
SELECT
    o.payment_method,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY o.payment_method
ORDER BY avg_order_value DESC;

-- Revenue and profit by category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS net_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)) - SUM(oi.quantity * p.cost_price), 2) AS profit
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
ORDER BY profit DESC;

-- Discount impact: avg discount vs avg profit margin, by category
SELECT
    p.category,
    ROUND(AVG(o.discount) * 100, 2) AS avg_discount_pct,
    ROUND(
        100.0 * (SUM(oi.quantity * oi.unit_price * (1 - o.discount)) - SUM(oi.quantity * p.cost_price))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 0),
    2) AS profit_margin_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
ORDER BY avg_discount_pct DESC;