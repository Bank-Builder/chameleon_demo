-- ACME Corporation Database Schema
-- MariaDB/MySQL compatible

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS acme_corp;
USE acme_corp;

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS categories;

-- Create categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create customers table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT,
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    stock_quantity INT DEFAULT 0,
    sku VARCHAR(50) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- Create orders table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    shipping_address TEXT,
    shipping_city VARCHAR(50),
    shipping_state VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_country VARCHAR(50) DEFAULT 'USA',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
);

-- Create order_items table
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

-- Insert sample data into categories
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports & Outdoors', 'Sports equipment and outdoor gear'),
('Books & Media', 'Books, movies, and music');

-- Insert sample data into customers
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, postal_code) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', '10001'),
('Jane', 'Doe', 'jane.doe@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90210'),
('Bob', 'Johnson', 'bob.johnson@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601'),
('Alice', 'Williams', 'alice.williams@email.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001'),
('Charlie', 'Brown', 'charlie.brown@email.com', '555-0105', '654 Maple Dr', 'Phoenix', 'AZ', '85001');

-- Insert sample data into products
INSERT INTO products (product_name, description, category_id, price, cost, stock_quantity, sku) VALUES
('Laptop Pro X1', 'High-performance laptop with 16GB RAM', 1, 1299.99, 800.00, 25, 'LAPTOP-X1-001'),
('Smartphone Galaxy S25', 'Latest smartphone with 128GB storage', 1, 899.99, 600.00, 50, 'PHONE-GS25-001'),
('Cotton T-Shirt', 'Comfortable cotton t-shirt in various colors', 2, 19.99, 8.00, 100, 'TSHIRT-COT-001'),
('Denim Jeans', 'Classic blue denim jeans', 2, 49.99, 20.00, 75, 'JEANS-DEN-001'),
('Garden Hose', '50ft heavy-duty garden hose', 3, 29.99, 15.00, 30, 'HOSE-GDN-001'),
('Basketball', 'Official size basketball for indoor/outdoor use', 4, 24.99, 12.00, 40, 'BALL-BASK-001'),
('Python Programming Book', 'Complete guide to Python programming', 5, 39.99, 15.00, 60, 'BOOK-PYTH-001'),
('Wireless Headphones', 'Noise-cancelling wireless headphones', 1, 199.99, 120.00, 35, 'HEAD-WIRE-001');

-- Insert sample data into orders
INSERT INTO orders (customer_id, status, total_amount, shipping_address, shipping_city, shipping_state, shipping_postal_code) VALUES
(1, 'delivered', 1349.98, '123 Main St', 'New York', 'NY', '10001'),
(2, 'shipped', 69.98, '456 Oak Ave', 'Los Angeles', 'CA', '90210'),
(3, 'processing', 149.97, '789 Pine Rd', 'Chicago', 'IL', '60601'),
(4, 'pending', 199.99, '321 Elm St', 'Houston', 'TX', '77001'),
(5, 'delivered', 39.99, '654 Maple Dr', 'Phoenix', 'AZ', '85001');

-- Insert sample data into order_items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
(1, 1, 1, 1299.99, 1299.99),
(1, 8, 1, 49.99, 49.99),
(2, 3, 2, 19.99, 39.98),
(2, 4, 1, 29.99, 29.99),
(3, 4, 1, 49.99, 49.99),
(3, 6, 2, 24.99, 49.98),
(3, 7, 1, 39.99, 39.99),
(4, 8, 1, 199.99, 199.99),
(5, 7, 1, 39.99, 39.99);

-- Create indexes for better performance
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Create a view for order summary
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    o.order_date,
    o.status,
    o.total_amount,
    COUNT(oi.order_item_id) AS item_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, c.first_name, c.last_name, c.email, o.order_date, o.status, o.total_amount;

-- Display sample data
SELECT 'Categories' AS table_name, COUNT(*) AS record_count FROM categories
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items;
