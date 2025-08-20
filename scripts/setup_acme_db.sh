#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Setting up ACME Corporation database..."
echo "======================================"

# Check if MariaDB container is running
if ! docker ps | grep -q cd_mysql; then
    echo -e "${RED}MariaDB container is not running. Please start it first with:${NC}"
    echo "docker-compose up -d"
    exit 1
fi

echo -e "\n${YELLOW}Running ACME database setup script...${NC}"

# Run the SQL script in the MariaDB container
if docker exec -i cd_mysql mysql -u root -prootpassword < scripts/acme_db.sql; then
    echo -e "${GREEN}ACME database setup completed successfully!${NC}"
    
    echo -e "\n${YELLOW}Verifying database setup...${NC}"
    
    # Test the new database and show table counts
    docker exec cd_mysql mysql -u root -prootpassword acme_corp -e "
    SELECT 'Categories' AS table_name, COUNT(*) AS record_count FROM categories
    UNION ALL
    SELECT 'Customers', COUNT(*) FROM customers
    UNION ALL
    SELECT 'Products', COUNT(*) FROM products
    UNION ALL
    SELECT 'Orders', COUNT(*) FROM orders
    UNION ALL
    SELECT 'Order Items', COUNT(*) FROM order_items;
    "
    
    echo -e "\n${GREEN}ACME Corporation database is ready!${NC}"
    echo "Database: acme_corp"
    echo "Tables: categories, customers, products, orders, order_items"
    echo "Sample data has been loaded."
    
else
    echo -e "${RED}Failed to setup ACME database.${NC}"
    exit 1
fi
