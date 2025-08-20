# MSQLChamo

A Python project with MySQL and PostgreSQL database setup using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- MySQL client (optional, for testing)
- PostgreSQL client (optional, for testing)

## Quick Start

1. **Start the databases:**
   ```bash
   docker-compose up -d
   ```

2. **Test database connections:**
   ```bash
   ./scripts/test_databases.sh
   ```

3. **Stop the databases:**
   ```bash
   docker-compose down
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
- Test connections to both databases
- List system tables if connections are successful
- Provide colored output for easy reading
- Fall back to alternative users if the primary connection fails

## Project Structure

```
msqlchamo/
├── .gitignore           # Python gitignore file
├── docker-compose.yaml  # Database services configuration
├── scripts/             # Utility scripts
│   └── test_databases.sh # Database connection test script
└── README.md            # This file
```

## Development

This project is set up for Python development with:
- Virtual environment support (`.venv/`)
- Comprehensive `.gitignore` for Python projects
- Docker-based database development environment
