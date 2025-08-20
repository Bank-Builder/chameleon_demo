# CD

A Python project with MySQL and PostgreSQL database setup using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- No local database clients required (uses Docker exec)

## Quick Start

1. **Start the databases:**
   ```bash
   docker-compose up -d
   ```

2. **Setup ACME Corporation database (optional):**
   ```bash
   ./scripts/setup_acme_db.sh
   ```

3. **Test database connections:**
   ```bash
   ./scripts/test_databases.sh
   ```

4. **Setup replication (optional):**
   ```bash
   ./scripts/setup_replication.sh
   ```

5. **Stop the databases:**
   ```bash
   docker-compose down
   ```

## Chameleon Setup Steps

After running `./scripts/setup_replication.sh`, follow these steps to complete the replication setup:

1. **Install chameleon:**
   ```bash
   pip install pg_chameleon
   ```

2. **Create configuration directory:**
   ```bash
   mkdir -p ~/.pg_chameleon/configuration
   ```

3. **Copy the configuration template:**
   ```bash
   cp scripts/pg_chameleon_config.yaml ~/.pg_chameleon/configuration/default.yml
   ```

4. **Initialize replication:**
   ```bash
   chameleon create_replica_schema
   chameleon add_source --config default
   chameleon init_replica --config default --source mysql
   chameleon start_replica --config default
   ```

## Database Configuration

### MySQL
- **Port:** 3306
- **Root Password:** rootpassword
- **Database:** testdb
- **User:** testuser
- **Password:** testpass

### PostgreSQL
- **Port:** 5432
- **Database:** testdb
- **User:** testuser
- **Password:** testpass

## Testing Database Connections

The `scripts/test_databases.sh` script will:
- Test connections to both databases using Docker exec
- List system tables if connections are successful
- Test ACME Corporation database if it exists
- Provide colored output for easy reading
- Fall back to alternative users if the primary connection fails
- No local database clients required

## ACME Corporation Database

The project includes a sample ACME Corporation database with:
- **5 tables**: categories, customers, products, orders, order_items
- **Sample data**: Realistic e-commerce data for testing
- **Proper relationships**: Foreign keys and constraints
- **Performance indexes**: Optimized for queries
- **Useful view**: order_summary for quick insights

To setup the ACME database:
```bash
./scripts/setup_acme_db.sh
```

## Project Structure

```
msqlchamo/
├── .gitignore           # Python gitignore file
├── docker-compose.yaml  # Database services configuration
├── scripts/             # Utility scripts
│   ├── test_databases.sh        # Database connection test script
│   ├── setup_acme_db.sh         # ACME database setup script
│   ├── acme_db.sql              # ACME database schema and sample data
│   ├── setup_replication.sh     # Database replication setup script
│   ├── pg_chameleon_config.yaml # chameleon configuration template
│   └── mysql.cnf                # MariaDB configuration for replication
└── README.md            # This file
```

## Development

This project is set up for Python development with:
- Virtual environment support (`.venv/`)
- Comprehensive `.gitignore` for Python projects
- Docker-based database development environment

## Chameleon Replication Setup

pg_chameleon is a MySQL/MariaDB to PostgreSQL replication tool that allows you to replicate data from MariaDB to PostgreSQL in real-time.

### Prerequisites

- Python 3.7+ with pip
- Access to both MariaDB and PostgreSQL databases
- Network connectivity between databases

### Installation

```bash
# Install chameleon
pip install pg_chameleon

# Or install from source
git clone https://github.com/the4masters/pg_chameleon.git
cd pg_chameleon
pip install -e .
```

**Note:** See the [Chameleon Setup Steps](#chameleon-setup-steps) section below for complete setup instructions.

### MariaDB Replication Configuration

1. **Binary Logging is automatically enabled via configuration file:**
   ```bash
   # The docker-compose.yaml mounts a custom mysql.cnf file
   # that enables binary logging with proper settings
   
   # If you need to restart MariaDB to apply new config:
   docker-compose restart mysql
   ```

2. **Verify Binary Logging Configuration:**
   ```sql
   -- Connect to MariaDB as root
   docker exec -it cd_mysql mysql -u root -prootpassword
   
   -- Check current binary log status
   SHOW VARIABLES LIKE 'log_bin';
   SHOW VARIABLES LIKE 'binlog_format';
   SHOW VARIABLES LIKE 'server_id';
   ```

2. **Create Replication User:**
   ```sql
   -- Create dedicated replication user
   CREATE USER 'repl_user'@'%' IDENTIFIED BY 'repl_password';
   GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
   GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'repl_user'@'%';
   FLUSH PRIVILEGES;
   ```

3. **Verify Binary Log Configuration:**
   ```sql
   -- Check binary log files
   SHOW BINARY LOGS;
   
   -- Check current log position
   SHOW MASTER STATUS;
   ```

### PostgreSQL Replication Configuration

1. **Enable Logical Replication:**
   ```sql
   -- Connect to PostgreSQL
   docker exec -it msqlchamo_postgresql psql -U postgres
   
   -- Check if logical replication is enabled
   SHOW wal_level;
   
   -- If not 'logical', you'll need to restart PostgreSQL with:
   -- wal_level = logical in postgresql.conf
   ```

2. **Create Replication User:**
   ```sql
   -- Create dedicated user for replication
   CREATE USER repl_user WITH PASSWORD 'repl_password';
   GRANT REPLICATION ON ALL TABLES IN SCHEMA public TO repl_user;
   GRANT USAGE ON SCHEMA public TO repl_user;
   ```

### Chameleon Configuration

1. **Create Configuration Directory:**
   ```bash
   mkdir -p ~/.pg_chameleon/configuration
   ```

2. **Create Configuration File:**
   ```yaml
   # ~/.pg_chameleon/configuration/default.yml
   global:
     pid_dir: '~/.pg_chameleon/pid/'
     log_dir: '~/.pg_chameleon/logs/'
     log_level: info
     log_file: '~/.pg_chameleon/logs/chameleon.log'
     log_rotation_age: 1d
     log_rotation_size: 10M
   
   # MariaDB source configuration
   mysql:
     host: 'localhost'
     port: 3306
     user: 'repl_user'
     password: 'repl_password'
     charset: 'utf8'
     connect_timeout: 10
     read_timeout: 30
     write_timeout: 30
   
   # PostgreSQL destination configuration
   postgresql:
     host: 'localhost'
     port: 5432
     user: 'repl_user'
     password: 'repl_password'
     database: 'acme_corp_replica'
     schema: 'public'
     charset: 'utf8'
     connect_timeout: 10
     read_timeout: 30
     write_timeout: 30
   
   # Replication settings
   replication:
     type: 'row'
     tables:
       - 'acme_corp.categories'
       - 'acme_corp.customers'
       - 'acme_corp.products'
       - 'acme_corp.orders'
       - 'acme_corp.order_items'
     exclude_tables: []
     exclude_columns: []
     batch_size: 1000
     batch_timeout: 10
     max_retries: 3
     retry_delay: 5
   
   # Schema mapping (if needed)
   schema_mapping:
     acme_corp: public
   
   # Data type mapping (if needed)
   type_mapping:
     int: integer
     bigint: bigint
     varchar: varchar
     text: text
     decimal: numeric
     timestamp: timestamp
     datetime: timestamp
     enum: varchar
     boolean: boolean
   ```

3. **Initialize Replication:**
   ```bash
   # Create replica schema in PostgreSQL
   chameleon create_replica_schema
   
   # Add source (MariaDB)
   chameleon add_source --config default
   
   # Initialize tables (one-time copy)
   chameleon init_replica --config default --source mysql
   
   # Start replication
   chameleon start_replica --config default
   ```

4. **Monitor Replication:**
   ```bash
   # Check replication status
   chameleon show_status --config default
   
   # Check replication lag
   chameleon show_lag --config default
   
   # Stop replication
   chameleon stop_replica --config default
   ```

### Docker-Specific Configuration

For this project's Docker setup, update the configuration:

```yaml
mysql:
  host: 'cd_mysql'  # Docker service name
  port: 3306
  user: 'repl_user'
  password: 'repl_password'

postgresql:
  host: 'cd_postgresql'  # Docker service name
  port: 5432
  user: 'repl_user'
  password: 'repl_password'
  database: 'acme_corp_replica'
```

### Troubleshooting

1. **Binary Log Issues:**
   - Ensure MariaDB has binary logging enabled
   - Check server_id is unique
   - Verify binlog_format is 'ROW'

2. **Permission Issues:**
   - Ensure replication user has proper privileges
   - Check network connectivity between databases

3. **Data Type Issues:**
   - Review type_mapping configuration
   - Handle ENUM types (convert to VARCHAR)
   - Check for unsupported MariaDB features

4. **Performance Issues:**
   - Adjust batch_size and batch_timeout
   - Monitor replication lag
   - Consider table partitioning for large tables

### Useful Commands

```bash
# Check replication status
   chameleon show_status --config default

# View logs
   tail -f ~/.pg_chameleon/logs/chameleon.log

# Reset replication
chameleon drop_replica_schema --config default
chameleon create_replica_schema --config default
chameleon init_replica --config default --source mysql

# Emergency stop
chameleon stop_replica --config default
```
