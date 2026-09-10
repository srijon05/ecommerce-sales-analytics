
CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id  INT PRIMARY KEY,
    name         VARCHAR(100),
    gender       VARCHAR(20),
    age          INT,
    city         VARCHAR(100),
    state        VARCHAR(100),
    signup_date  DATE
);

-- ------------------------------------------------------------
-- PRODUCTS
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id    INT PRIMARY KEY,
    product_name  VARCHAR(150),
    category      VARCHAR(50),
    brand         VARCHAR(50),
    cost_price    DECIMAL(10,2),
    selling_price DECIMAL(10,2)
);

-- ------------------------------------------------------------
-- ORDERS  (1 customer -> N orders)
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id       INT PRIMARY KEY,
    customer_id    INT,
    order_date     DATE,
    payment_method VARCHAR(30),
    discount       DECIMAL(4,2),
    status         VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ------------------------------------------------------------
-- ORDER_ITEMS  (1 order -> N line items, N line items -> 1 product)
-- ------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INT,
    product_id    INT,
    quantity      INT,
    unit_price    DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
