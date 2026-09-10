USE ecommerce_analytics;

-- RFM base metrics per customer
--     Recency  = days since last order (relative to most recent order date in the dataset)
--     Frequency = number of distinct delivered orders, Monetary = total net revenue
WITH rfm_base AS (
    SELECT
        o.customer_id,
        DATEDIFF((SELECT MAX(order_date) FROM orders WHERE status = 'Delivered'), MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
)
SELECT * FROM rfm_base ORDER BY monetary DESC;

-- RFM scoring (1-5 per dimension via NTILE) + segment labels
-- This is the query to point to when an interviewer asks about RFM.
WITH rfm_base AS (
    SELECT
        o.customer_id,
        DATEDIFF((SELECT MAX(order_date) FROM orders WHERE status = 'Delivered'), MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        -- lower recency_days is better -> invert the score direction
        (6 - NTILE(5) OVER (ORDER BY recency_days)) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN f_score >= 4 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM rfm_scored
ORDER BY rfm_total DESC;


-- Customer lifetime value percentile ranking  [PERCENT_RANK()]
SELECT
    customer_id,
    total_spent,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_spent), 4) AS percentile_rank
FROM (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
) t
ORDER BY total_spent DESC;

-- Pareto check: what % of customers generate 80% of revenue?
WITH customer_revenue AS (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS total_spent
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
),
ranked AS (
    SELECT
        customer_id,
        total_spent,
        SUM(total_spent) OVER (ORDER BY total_spent DESC) AS running_total,
        SUM(total_spent) OVER () AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rn,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
)
SELECT MIN(rn) AS customers_needed_for_80pct_revenue, MIN(total_customers) AS total_customers,
       ROUND(100.0 * MIN(rn) / MIN(total_customers), 2) AS pct_of_customer_base
FROM ranked
WHERE running_total >= 0.8 * grand_total;

-- Year-over-year revenue growth
WITH yearly AS (
    SELECT YEAR(o.order_date) AS yr, SUM(oi.quantity * oi.unit_price * (1 - o.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY YEAR(o.order_date)
)
SELECT
    yr,
    revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY yr)) / LAG(revenue) OVER (ORDER BY yr), 2) AS yoy_growth_pct
FROM yearly
ORDER BY yr;

-- Customers who bought from more than 3 different categories (cross-category buyers)
SELECT
    o.customer_id,
    COUNT(DISTINCT p.category) AS distinct_categories
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY o.customer_id
HAVING COUNT(DISTINCT p.category) > 3
ORDER BY distinct_categories DESC;

-- First purchase category per customer (useful for acquisition analysis)
SELECT customer_id, first_category
FROM (
    SELECT
        o.customer_id,
        p.category AS first_category,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS rn
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
) t
WHERE rn = 1;