#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to print status
print_status() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for container to be ready
wait_for_container() {
    local container_name=$1
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $container_name container to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec "$container_name" echo "ready" >/dev/null 2>&1; then
            print_success "$container_name container is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting 2 seconds..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "Container $container_name failed to become ready after $max_attempts attempts"
    return 1
}

# Function to wait for database to be ready
wait_for_mysql() {
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for MySQL to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec msqlchamo_mysql mysql -u root -prootpassword -e "SELECT 1;" >/dev/null 2>&1; then
            print_success "MySQL is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting 2 seconds..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "MySQL failed to become ready after $max_attempts attempts"
    return 1
}

wait_for_postgresql() {
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for PostgreSQL to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec msqlchamo_postgresql psql -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "PostgreSQL is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting 2 seconds..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "PostgreSQL failed to become ready after $max_attempts attempts"
    return 1
}

# Main execution
main() {
    print_section "Chameleon Demo - Complete Setup"
    echo "This script will set up the entire replication environment from scratch."
    echo "It includes:"
    echo "- Starting Docker containers"
    echo "- Setting up ACME Corporation database"
    echo "- Configuring replication users and databases"
    echo "- Testing all connections"
    echo "- Setting up pg_chameleon replication"
    
    # Check prerequisites
    print_section "Checking Prerequisites"
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if docker compose plugin is available
    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose plugin is not available. Please ensure Docker Compose is installed as a plugin."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
    
    # Source virtual environment if it exists
    print_section "Setting up Environment"
    if [ -f ".venv/bin/activate" ]; then
        print_status "Sourcing virtual environment..."
        source .venv/bin/activate
        print_success "Virtual environment activated!"
    else
        print_status "No .venv found, using system Python"
    fi
    
    # Stop any existing containers
    print_section "Stopping Existing Containers"
    print_status "Stopping any existing containers..."
    docker compose down -v 2>/dev/null || true
    
    # Force remove any lingering containers with our names
    print_status "Cleaning up any lingering containers..."
    docker rm -f msqlchamo_mysql msqlchamo_postgresql 2>/dev/null || true
    print_success "Existing containers stopped and cleaned up."
    
    # Start containers
    print_section "Starting Docker Containers"
    print_status "Starting MySQL and PostgreSQL containers..."
    if docker compose up -d; then
        print_success "Containers started successfully!"
    else
        print_error "Failed to start containers!"
        exit 1
    fi
    
    # Wait for containers to be ready
    print_section "Waiting for Containers to be Ready"
    if ! wait_for_mysql; then
        print_error "MySQL container failed to become ready!"
        exit 1
    fi
    
    if ! wait_for_postgresql; then
        print_error "PostgreSQL container failed to become ready!"
        exit 1
    fi
    
    # Setup ACME database
    print_section "Setting up ACME Corporation Database"
    if ./scripts/setup_acme_db.sh; then
        print_success "ACME database setup completed!"
    else
        print_error "ACME database setup failed!"
        exit 1
    fi
    
    # Setup replication configuration
    print_section "Setting up Replication Configuration"
    if ./scripts/setup_replication.sh; then
        print_success "Replication configuration completed!"
    else
        print_error "Replication configuration failed!"
        exit 1
    fi
    
    # Test database connections
    print_section "Testing Database Connections"
    if ./scripts/test_databases.sh; then
        print_success "Database connection tests completed!"
    else
        print_error "Database connection tests failed!"
        exit 1
    fi
    
    # Setup pg_chameleon
    print_section "Setting up pg_chameleon Replication"
    
    # Check if pg_chameleon is installed
    if ! command_exists pg_chameleon; then
        print_status "pg_chameleon not found. Installing..."
        if pip install pg_chameleon; then
            print_success "pg_chameleon installed successfully!"
            # Refresh PATH to find the newly installed command
            export PATH="$HOME/.local/bin:$PATH"
            if [ -f ".venv/bin/activate" ]; then
                source .venv/bin/activate
            fi
        else
            print_error "Failed to install pg_chameleon!"
            print_status "Please install manually: pip install pg_chameleon"
        fi
    else
        print_success "pg_chameleon is already installed!"
    fi
    
    # Create pg_chameleon configuration directory
    print_status "Setting up pg_chameleon configuration..."
    mkdir -p ~/.pg_chameleon/configuration
    
    # Copy configuration file
    if [ -f "scripts/pg_chameleon_config.yaml" ]; then
        cp scripts/pg_chameleon_config.yaml ~/.pg_chameleon/configuration/config.yaml
        print_success "Configuration file copied!"
    else
        print_error "pg_chameleon configuration file not found!"
        exit 1
    fi
    
    # Initialize pg_chameleon
    print_status "Initializing pg_chameleon..."
    if python -m pg_chameleon create_replica_schema; then
        print_success "pg_chameleon replica schema created!"
    else
        print_error "Failed to create replica schema!"
        exit 1
    fi
    
    # Add source
    print_status "Adding MySQL source..."
    if python -m pg_chameleon add_source --config default; then
        print_success "MySQL source added!"
    else
        print_error "Failed to add MySQL source!"
        exit 1
    fi
    
    # Initialize replica
    print_status "Initializing replica..."
    if python -m pg_chameleon init_replica --config default --source mysql; then
        print_success "Replica initialized!"
    else
        print_error "Failed to initialize replica!"
        exit 1
    fi
    
    # Start replication
    print_status "Starting replication..."
    if python -m pg_chameleon start_replica --config default; then
        print_success "Replication started!"
    else
        print_error "Failed to start replication!"
        exit 1
    fi
    
    # Final verification
    print_section "Final Verification"
    print_status "Checking replication status..."
    if python -m pg_chameleon show_status --config default; then
        print_success "Replication status retrieved!"
    else
        print_error "Failed to get replication status!"
    fi
    
    # Test replica database
    print_status "Testing replica database..."
    if docker exec msqlchamo_postgresql psql -U repl_user -d acme_corp_replica -c "\dt" 2>/dev/null; then
        print_success "Replica database is accessible!"
    else
        print_error "Replica database is not accessible!"
    fi
    
    print_section "Setup Complete!"
    print_success "🎉 Chameleon replication environment is now fully configured!"
    echo ""
    echo "What's been set up:"
    echo "- MySQL container with ACME Corporation database"
    echo "- PostgreSQL container with replica database"
    echo "- Replication users and permissions"
    echo "- pg_chameleon replication system"
    echo "- Active replication from MySQL to PostgreSQL"
    echo ""
    echo "Useful commands:"
    echo "- Check replication status: pg_chameleon show_status --config default"
    echo "- Stop replication: pg_chameleon stop_replica --config default"
    echo "- Start replication: pg_chameleon start_replica --config default"
    echo "- View replica data: docker exec msqlchamo_postgresql psql -U repl_user -d acme_corp_replica -c 'SELECT * FROM categories;'"
    echo ""
    echo "The replication is now running and will automatically sync changes from MySQL to PostgreSQL!"
}

# Run main function
main "$@"
