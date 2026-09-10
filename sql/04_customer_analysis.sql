USE ecommerce_analytics;

-- Per-customer lifetime value (delivered orders only)
SELECT
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS total_spent,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- Top 10 customers by spend
SELECT
    c.customer_id,
    c.name,
    c.state,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.name, c.state
ORDER BY total_spent DESC
LIMIT 10;

-- Repeat vs one-time customers
SELECT
    CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*) AS num_customers
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
) t
GROUP BY customer_type;

-- Customer value segmentation (High / Medium / Low) via NTILE
SELECT
    customer_id,
    total_spent,
    CASE
        WHEN spend_quartile = 4 THEN 'High Value'
        WHEN spend_quartile IN (2,3) THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment
FROM (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS total_spent,
        NTILE(4) OVER (ORDER BY SUM(oi.quantity * oi.unit_price * (1 - o.discount))) AS spend_quartile
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id
) ranked
ORDER BY total_spent DESC;

-- Running (cumulative) revenue per customer over time  [SUM() OVER]
SELECT
    o.customer_id,
    o.order_date,
    ROUND(oi.quantity * oi.unit_price * (1 - o.discount), 2) AS order_line_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)) OVER (
        PARTITION BY o.customer_id ORDER BY o.order_date
    ), 2) AS running_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
ORDER BY o.customer_id, o.order_date;

-- Rank customers within their state by total spend  [RANK() / DENSE_RANK()]
SELECT
    customer_id,
    state,
    total_spent,
    RANK() OVER (PARTITION BY state ORDER BY total_spent DESC) AS rank_in_state,
    DENSE_RANK() OVER (PARTITION BY state ORDER BY total_spent DESC) AS dense_rank_in_state
FROM (
    SELECT c.customer_id, c.state, SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.state
) t;

-- Days since previous order per customer  [LAG()]
SELECT
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
    DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_since_last_order
FROM orders
WHERE status = 'Delivered';

-- Month-over-month revenue growth  [LAG() + window]
SELECT
    month,
    revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY month
) t
ORDER BY month;

-- Average order value by customer, using a CTE
WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS order_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id, o.order_id
)
SELECT
    customer_id,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM customer_orders
GROUP BY customer_id
ORDER BY avg_order_value DESC;

-- Customer retention: % of customers who ordered in month N who also
--     ordered in month N+1 (simplified cohort-style retention check)
WITH monthly_customers AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE status = 'Delivered'
)
SELECT
    cur.activity_month AS month,
    COUNT(DISTINCT cur.customer_id) AS active_customers,
    COUNT(DISTINCT nxt.customer_id) AS retained_next_month,
    ROUND(100.0 * COUNT(DISTINCT nxt.customer_id) / COUNT(DISTINCT cur.customer_id), 2) AS retention_rate_pct
FROM monthly_customers cur
LEFT JOIN monthly_customers nxt
    ON cur.customer_id = nxt.customer_id
    AND nxt.activity_month = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(cur.activity_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
GROUP BY cur.activity_month
ORDER BY cur.activity_month;