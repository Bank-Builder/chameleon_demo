#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing database connections..."
echo "================================"

# Test MySQL connection using docker exec
echo -e "\n${YELLOW}Testing MySQL connection...${NC}"
if docker exec msqlchamo_mysql mysql -u testuser -ptestpass testdb -e "SHOW TABLES;" 2>/dev/null; then
    echo -e "${GREEN}MySQL connection successful!${NC}"
    echo -e "${YELLOW}Listing MySQL system tables:${NC}"
    docker exec msqlchamo_mysql mysql -u testuser -ptestpass testdb -e "SHOW TABLES;"
else
    echo -e "${RED}MySQL connection failed!${NC}"
    echo "Trying with root user..."
    if docker exec msqlchamo_mysql mysql -u root -prootpassword -e "SHOW DATABASES;" 2>/dev/null; then
        echo -e "${GREEN}MySQL root connection successful!${NC}"
        echo -e "${YELLOW}Listing MySQL system tables:${NC}"
        docker exec msqlchamo_mysql mysql -u root -prootpassword -e "SHOW TABLES FROM information_schema;"
    else
        echo -e "${RED}MySQL root connection also failed!${NC}"
    fi
fi

# Test ACME database if it exists
echo -e "\n${YELLOW}Testing ACME Corporation database...${NC}"
if docker exec msqlchamo_mysql mysql -u root -prootpassword -e "USE acme_corp; SHOW TABLES;" 2>/dev/null; then
    echo -e "${GREEN}ACME database found!${NC}"
    echo -e "${YELLOW}ACME database tables:${NC}"
    docker exec msqlchamo_mysql mysql -u root -prootpassword acme_corp -e "SHOW TABLES;"
    
    echo -e "\n${YELLOW}ACME database sample data summary:${NC}"
    docker exec msqlchamo_mysql mysql -u root -prootpassword acme_corp -e "
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
else
    echo -e "${YELLOW}ACME database not found. Run ./scripts/setup_acme_db.sh to create it.${NC}"
fi

# Test PostgreSQL connection using docker exec
echo -e "\n${YELLOW}Testing PostgreSQL connection...${NC}"
if docker exec msqlchamo_postgresql psql -U testuser -d testdb -c "\dt" 2>/dev/null; then
    echo -e "${GREEN}PostgreSQL connection successful!${NC}"
    echo -e "${YELLOW}Listing PostgreSQL system tables:${NC}"
    docker exec msqlchamo_postgresql psql -U testuser -d testdb -c "\dt"
else
    echo -e "${RED}PostgreSQL connection failed!${NC}"
    echo "Trying with postgres user..."
    if docker exec msqlchamo_postgresql psql -U postgres -d postgres -c "\dt" 2>/dev/null; then
        echo -e "${GREEN}PostgreSQL postgres user connection successful!${NC}"
        echo -e "${YELLOW}Listing PostgreSQL system tables:${NC}"
        docker exec msqlchamo_postgresql psql -U postgres -d postgres -c "\dt"
    else
        echo -e "${RED}PostgreSQL postgres user connection also failed!${NC}"
    fi
fi

echo -e "\n${YELLOW}Database connection test completed.${NC}"
echo "================================"
