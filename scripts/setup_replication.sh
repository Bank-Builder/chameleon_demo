#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Setting up pg_chameleon replication..."
echo "====================================="

# Check if containers are running
if ! docker ps | grep -q msqlchamo_mysql; then
    echo -e "${RED}MariaDB container is not running. Please start it first with:${NC}"
    echo "docker-compose up -d"
    exit 1
fi

if ! docker ps | grep -q msqlchamo_postgresql; then
    echo -e "${RED}PostgreSQL container is not running. Please start it first with:${NC}"
    echo "docker-compose up -d"
    exit 1
fi

echo -e "\n${YELLOW}Configuring MariaDB for replication...${NC}"

# Configure MariaDB binary logging
echo "Setting up MariaDB binary logging..."
docker exec msqlchamo_mysql mysql -u root -prootpassword -e "
SET GLOBAL log_bin = ON;
SET GLOBAL binlog_format = 'ROW';
SET GLOBAL server_id = 1;
SET GLOBAL log_bin_trust_function_creators = ON;
"

# Create replication user in MariaDB
echo "Creating replication user in MariaDB..."
docker exec msqlchamo_mysql mysql -u root -prootpassword -e "
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'repl_user'@'%';
GRANT SELECT ON acme_corp.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;
"

# Verify MariaDB configuration
echo -e "\n${YELLOW}Verifying MariaDB replication configuration...${NC}"
docker exec msqlchamo_mysql mysql -u root -prootpassword -e "
SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'server_id';
SHOW MASTER STATUS;
"

echo -e "\n${YELLOW}Configuring PostgreSQL for replication...${NC}"

# Create replication user in PostgreSQL
echo "Creating replication user in PostgreSQL..."
docker exec msqlchamo_postgresql psql -U postgres -c "
CREATE USER repl_user WITH PASSWORD 'repl_password';
GRANT REPLICATION ON ALL TABLES IN SCHEMA public TO repl_user;
GRANT USAGE ON SCHEMA public TO repl_user;
GRANT CREATE ON SCHEMA public TO repl_user;
"

# Create replica database
echo "Creating replica database..."
docker exec msqlchamo_postgresql psql -U postgres -c "
CREATE DATABASE acme_corp_replica;
GRANT ALL PRIVILEGES ON DATABASE acme_corp_replica TO repl_user;
"

# Grant additional privileges
docker exec msqlchamo_postgresql psql -U postgres -d acme_corp_replica -c "
GRANT ALL ON SCHEMA public TO repl_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO repl_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO repl_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO repl_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO repl_user;
"

echo -e "\n${GREEN}Database replication configuration completed!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Install pg_chameleon: pip install pg_chameleon"
echo "2. Create config directory: mkdir -p ~/.pg_chameleon/configuration"
echo "3. Copy scripts/pg_chameleon_config.yaml to ~/.pg_chameleon/configuration/config.yaml"
echo "4. Initialize replication: pg_chameleon create_replica_schema"
echo "5. Add source: pg_chameleon add_source --config default"
echo "6. Initialize replica: pg_chameleon init_replica --config default --source mysql"
echo "7. Start replication: pg_chameleon start_replica --config default"
echo -e "\n${YELLOW}Configuration files:${NC}"
echo "- MariaDB replication user: repl_user / repl_password"
echo "- PostgreSQL replication user: repl_user / repl_password"
echo "- Replica database: acme_corp_replica"
echo -e "\n${YELLOW}Test replication user connections:${NC}"
echo "MariaDB: docker exec msqlchamo_mysql mysql -u repl_user -prepl_password -e 'SHOW DATABASES;'"
echo "PostgreSQL: docker exec msqlchamo_postgresql psql -U repl_user -d acme_corp_replica -c '\dt'"
