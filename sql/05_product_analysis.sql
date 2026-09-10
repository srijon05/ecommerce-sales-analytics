USE ecommerce_analytics;

-- Units sold and revenue per product
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC;

-- Best-selling product per category  [ROW_NUMBER()]
SELECT category, product_name, revenue
FROM (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.unit_price * (1 - o.discount)) DESC) AS rn
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category, p.product_name
) ranked
WHERE rn = 1;

-- Product profitability (profit per unit and total profit)
SELECT
    p.product_name,
    p.category,
    ROUND(p.selling_price - p.cost_price, 2) AS profit_per_unit,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity) * (p.selling_price - p.cost_price), 2) AS total_profit
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category, p.selling_price, p.cost_price
ORDER BY total_profit DESC
LIMIT 20;

-- Slow-moving products (bottom 10 by units sold, at least 1 sale)
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold ASC
LIMIT 10;

-- Category share of total revenue (%)
SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total_revenue
FROM (
    SELECT p.category, SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category
) t
ORDER BY revenue DESC;

-- Brand performance
SELECT
    p.brand,
    COUNT(DISTINCT p.product_id) AS num_products,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount)), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.brand
ORDER BY revenue DESC;

-- Products priced below cost (data-quality / margin risk flag)
SELECT product_id, product_name, cost_price, selling_price
FROM products
WHERE selling_price < cost_price;
