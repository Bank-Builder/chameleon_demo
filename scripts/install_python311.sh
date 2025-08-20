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

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "This script should not be run as root (sudo)."
        print_status "Please run it as a regular user. The script will prompt for sudo when needed."
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Could not detect operating system."
        exit 1
    fi
    
    print_status "Detected OS: $OS $VER"
    
    # Check if it's Ubuntu or Debian
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        print_success "OS is supported (Ubuntu/Debian based)"
    else
        print_error "This script is designed for Ubuntu/Debian based systems."
        print_error "Detected: $OS"
        exit 1
    fi
}

# Function to install system dependencies
install_system_deps() {
    print_section "Installing System Dependencies"
    
    print_status "Installing build dependencies for Python compilation..."
    if sudo apt update && sudo apt install -y \
        make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev git; then
        print_success "System dependencies installed successfully!"
    else
        print_error "Failed to install system dependencies!"
        exit 1
    fi
}

# Function to install pyenv
install_pyenv() {
    print_section "Installing pyenv"
    
    # Check if pyenv is already installed
    if command_exists pyenv; then
        print_status "pyenv is already installed!"
        pyenv --version
        return 0
    fi
    
    print_status "Installing pyenv..."
    
    # Install pyenv using the official installer
    if curl https://pyenv.run | bash; then
        print_success "pyenv installed successfully!"
    else
        print_error "Failed to install pyenv!"
        exit 1
    fi
    
    # Add pyenv to shell profile
    print_status "Configuring shell environment..."
    
    # Detect shell and add to appropriate profile
    if [ -n "$ZSH_VERSION" ]; then
        PROFILE_FILE="$HOME/.zshrc"
    else
        PROFILE_FILE="$HOME/.bashrc"
    fi
    
    # Add pyenv configuration if not already present
    if ! grep -q "pyenv init" "$PROFILE_FILE"; then
        echo '' >> "$PROFILE_FILE"
        echo '# pyenv configuration' >> "$PROFILE_FILE"
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$PROFILE_FILE"
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$PROFILE_FILE"
        echo 'eval "$(pyenv init -)"' >> "$PROFILE_FILE"
        print_success "pyenv configuration added to $PROFILE_FILE"
    else
        print_status "pyenv configuration already present in $PROFILE_FILE"
    fi
    
    # Source the profile to make pyenv available in current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    print_success "pyenv is now available in current session!"
}

# Function to install Python 3.11 using pyenv
install_python311_pyenv() {
    print_section "Installing Python 3.11 using pyenv"
    
    # Ensure pyenv is available
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    # Check if Python 3.11 is already installed
    if pyenv versions | grep -q "3.11"; then
        print_status "Python 3.11 is already installed via pyenv!"
        pyenv versions
        return 0
    fi
    
    print_status "Installing Python 3.11.9 (latest stable 3.11.x)..."
    if pyenv install 3.11.9; then
        print_success "Python 3.11.9 installed successfully!"
    else
        print_error "Failed to install Python 3.11.9!"
        exit 1
    fi
    
    # Set local Python version for this project
    print_status "Setting Python 3.11.9 as local version for this project..."
    if pyenv local 3.11.9; then
        print_success "Python 3.11.9 set as local version!"
    else
        print_error "Failed to set local Python version!"
        exit 1
    fi
    
    # Verify installation
    if python --version | grep -q "3.11"; then
        print_success "Python 3.11 installation verified!"
        python --version
    else
        print_error "Python 3.11 installation failed!"
        exit 1
    fi
}

# Function to create virtual environment
create_venv() {
    print_section "Creating Virtual Environment"
    
    if [ -d ".venv" ]; then
        print_status "Removing existing virtual environment..."
        rm -rf .venv
        print_success "Existing virtual environment removed."
    fi
    
    print_status "Creating new virtual environment with Python 3.11..."
    if python -m venv .venv; then
        print_success "Virtual environment created successfully!"
    else
        print_error "Failed to create virtual environment!"
        exit 1
    fi
    
    print_status "Activating virtual environment..."
    source .venv/bin/activate
    
    print_status "Verifying Python version in virtual environment..."
    if python --version | grep -q "3.11"; then
        print_success "Virtual environment is using Python 3.11!"
        python --version
    else
        print_error "Virtual environment is not using Python 3.11!"
        exit 1
    fi
}

# Function to install dependencies
install_dependencies() {
    print_section "Installing Dependencies"
    
    print_status "Upgrading pip..."
    if pip install --upgrade pip; then
        print_success "pip upgraded successfully!"
    else
        print_error "Failed to upgrade pip!"
        exit 1
    fi
    
    print_status "Installing pg_chameleon..."
    if pip install pg_chameleon; then
        print_success "pg_chameleon installed successfully!"
    else
        print_error "Failed to install pg_chameleon!"
        exit 1
    fi
    
    print_status "Installing additional dependencies..."
    if pip install PyMySQL psycopg2-binary PyYAML; then
        print_success "Additional dependencies installed successfully!"
    else
        print_error "Failed to install additional dependencies!"
        exit 1
    fi
}

# Function to test installation
test_installation() {
    print_section "Testing Installation"
    
    print_status "Testing Python 3.11..."
    if python --version | grep -q "3.11"; then
        print_success "Python 3.11 is working!"
    else
        print_error "Python 3.11 test failed!"
        exit 1
    fi
    
    print_status "Testing virtual environment..."
    source .venv/bin/activate
    if python --version | grep -q "3.11"; then
        print_success "Virtual environment is working!"
    else
        print_error "Virtual environment test failed!"
        exit 1
    fi
    
    print_status "Testing pg_chameleon import..."
    if python -c "import pg_chameleon; print('pg_chameleon imported successfully!')"; then
        print_success "pg_chameleon is working!"
    else
        print_error "pg_chameleon test failed!"
        exit 1
    fi
}

# Function to show next steps
show_next_steps() {
    print_section "Installation Complete!"
    print_success "🎉 Python 3.11 and virtual environment are ready!"
    echo ""
    echo "What's been installed:"
    echo "- pyenv (Python version manager)"
    echo "- Python 3.11.9 (via pyenv)"
    echo "- Python 3.11 virtual environment (.venv/)"
    echo "- pg_chameleon and dependencies"
    echo ""
    echo "Important notes:"
    echo "- Python 3.11 is set as local version for this project"
    echo "- Your system Python 3.13 remains unchanged"
    echo "- pyenv configuration added to your shell profile"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.bashrc"
    echo "2. Activate the virtual environment:"
    echo "   source .venv/bin/activate"
    echo ""
    echo "3. Run the quick start script:"
    echo "   ./scripts/quick_start.sh"
    echo ""
    echo "4. Or manually test pg_chameleon:"
    echo "   source .venv/bin/activate"
    echo "   python -c \"import pg_chameleon; print('Success!')\""
    echo ""
    echo "The virtual environment is now compatible with pg_chameleon!"
}

# Main execution
main() {
    print_section "Python 3.11 Installation Script (pyenv method)"
    echo "This script will install Python 3.11 using pyenv, which works on"
    echo "all Ubuntu versions including 25.04 (Plucky)."
    
    # Check if not running as root
    check_root
    
    # Detect OS
    detect_os
    
    # Install system dependencies
    install_system_deps
    
    # Install pyenv
    install_pyenv
    
    # Install Python 3.11 using pyenv
    install_python311_pyenv
    
    # Create virtual environment
    create_venv
    
    # Install dependencies
    install_dependencies
    
    # Test installation
    test_installation
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
