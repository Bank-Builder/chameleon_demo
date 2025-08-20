#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing database connections..."
echo "================================"

# Test MySQL connection
echo -e "\n${YELLOW}Testing MySQL connection...${NC}"
if command -v mysql &> /dev/null; then
    if mysql -h localhost -P 3306 -u testuser -ptestpass testdb -e "SHOW TABLES;" 2>/dev/null; then
        echo -e "${GREEN}MySQL connection successful!${NC}"
        echo -e "${YELLOW}Listing MySQL system tables:${NC}"
        mysql -h localhost -P 3306 -u testuser -ptestpass testdb -e "SHOW TABLES;" 2>/dev/null
    else
        echo -e "${RED}MySQL connection failed!${NC}"
        echo "Trying with root user..."
        if mysql -h localhost -P 3306 -u root -prootpassword -e "SHOW DATABASES;" 2>/dev/null; then
            echo -e "${GREEN}MySQL root connection successful!${NC}"
            echo -e "${YELLOW}Listing MySQL system tables:${NC}"
            mysql -h localhost -P 3306 -u root -prootpassword -e "SHOW TABLES FROM information_schema;" 2>/dev/null
        else
            echo -e "${RED}MySQL root connection also failed!${NC}"
        fi
    fi
else
    echo -e "${RED}MySQL client not installed. Please install mysql-client.${NC}"
fi

# Test PostgreSQL connection
echo -e "\n${YELLOW}Testing PostgreSQL connection...${NC}"
if command -v psql &> /dev/null; then
    export PGPASSWORD=testpass
    if psql -h localhost -p 5432 -U testuser -d testdb -c "\dt" 2>/dev/null; then
        echo -e "${GREEN}PostgreSQL connection successful!${NC}"
        echo -e "${YELLOW}Listing PostgreSQL system tables:${NC}"
        psql -h localhost -p 5432 -U testuser -d testdb -c "\dt" 2>/dev/null
    else
        echo -e "${RED}PostgreSQL connection failed!${NC}"
        echo "Trying with postgres user..."
        export PGPASSWORD=testpass
        if psql -h localhost -p 5432 -U postgres -d postgres -c "\dt" 2>/dev/null; then
            echo -e "${GREEN}PostgreSQL postgres user connection successful!${NC}"
            echo -e "${YELLOW}Listing PostgreSQL system tables:${NC}"
            psql -h localhost -p 5432 -U postgres -d postgres -c "\dt" 2>/dev/null
        else
            echo -e "${RED}PostgreSQL postgres user connection also failed!${NC}"
        fi
    fi
else
    echo -e "${RED}PostgreSQL client not installed. Please install postgresql-client.${NC}"
fi

echo -e "\n${YELLOW}Database connection test completed.${NC}"
echo "================================"
