#!/bin/bash
# vim: ts=2 sts=2 sw=2 et

#==============================================================================
# Prerequisites Installer for x86 Kernel Development Labs
#==============================================================================
# Detects Linux distribution and installs required packages for kernel
# development using NASM, QEMU, GDB, and cross-compiler toolchain.
#
# Supported distributions:
#   - Ubuntu 20.04+ (and derivatives)
#   - Fedora 35+
#   - AlmaLinux 8+ (and RHEL-compatible)
#==============================================================================

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#==============================================================================
# Helper Functions
#==============================================================================

print_header() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

#==============================================================================
# Distribution Detection
#==============================================================================

detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="$ID"
    DISTRO_VERSION="$VERSION_ID"
    DISTRO_NAME="$NAME"
  else
    print_error "Cannot detect distribution. /etc/os-release not found."
    exit 1
  fi

  # Normalize distribution ID
  case "$DISTRO_ID" in
    ubuntu|debian|linuxmint|pop)
      DISTRO_FAMILY="debian"
      ;;
    fedora)
      DISTRO_FAMILY="fedora"
      ;;
    almalinux|rocky|rhel|centos)
      DISTRO_FAMILY="rhel"
      ;;
    *)
      print_error "Unsupported distribution: $DISTRO_NAME ($DISTRO_ID)"
      print_info "Supported: Ubuntu, Fedora, AlmaLinux"
      exit 1
      ;;
  esac

  print_success "Detected: $DISTRO_NAME $DISTRO_VERSION"
  print_info "Distribution family: $DISTRO_FAMILY"
}

#==============================================================================
# Package Installation
#==============================================================================

install_debian_packages() {
  print_header "Installing packages for Debian/Ubuntu"

  print_info "Updating package lists..."
  sudo apt update

  print_info "Installing core development tools..."
  sudo apt install -y \
    nasm \
    qemu-system-x86 \
    gdb \
    make \
    gcc \
    g++ \
    build-essential

  print_info "Installing cross-compiler build dependencies..."
  sudo apt install -y \
    bison \
    flex \
    libgmp3-dev \
    libmpc-dev \
    libmpfr-dev \
    texinfo \
    libisl-dev

  print_success "All packages installed successfully"
}

install_fedora_packages() {
  print_header "Installing packages for Fedora"

  print_info "Installing core development tools..."
  sudo dnf install -y \
    nasm \
    qemu-system-x86 \
    gdb \
    make \
    gcc \
    gcc-c++

  print_info "Installing cross-compiler build dependencies..."
  sudo dnf install -y \
    bison \
    flex \
    gmp-devel \
    mpfr-devel \
    libmpc-devel \
    texinfo \
    isl-devel

  print_success "All packages installed successfully"
}

install_rhel_packages() {
  print_header "Installing packages for AlmaLinux/RHEL"

  print_info "Installing core development tools..."
  sudo dnf install -y \
    nasm \
    qemu-system-x86 \
    gdb \
    make \
    gcc \
    gcc-c++

  print_info "Installing cross-compiler build dependencies..."

  # Try to install isl-devel, but don't fail if it's not available
  if sudo dnf install -y bison flex gmp-devel mpfr-devel libmpc-devel texinfo; then
    print_success "Core dependencies installed"
  else
    print_error "Failed to install some packages"
    exit 1
  fi

  # ISL is optional and may not be in base repos
  if sudo dnf install -y isl-devel 2>/dev/null; then
    print_success "ISL development library installed"
  else
    print_warning "isl-devel not available (optional, you may need to enable PowerTools/CRB repo)"
    print_info "To enable: sudo dnf config-manager --set-enabled powertools"
  fi

  print_success "All available packages installed successfully"
}

install_packages() {
  case "$DISTRO_FAMILY" in
    debian)
      install_debian_packages
      ;;
    fedora)
      install_fedora_packages
      ;;
    rhel)
      install_rhel_packages
      ;;
    *)
      print_error "Unknown distribution family: $DISTRO_FAMILY"
      exit 1
      ;;
  esac
}

#==============================================================================
# Verification
#==============================================================================

verify_tool() {
  local tool_name="$1"
  local command="$2"
  local expected_pattern="$3"

  if command -v "$command" &> /dev/null; then
    local version=$($command --version 2>&1 | head -n1)
    if [[ "$version" =~ $expected_pattern ]] || [[ -z "$expected_pattern" ]]; then
      print_success "$tool_name: $version"
      return 0
    else
      print_warning "$tool_name: Found but version unexpected: $version"
      return 1
    fi
  else
    print_error "$tool_name: NOT FOUND ($command)"
    return 1
  fi
}

verify_qemu_i386() {
  if command -v qemu-system-i386 &> /dev/null; then
    local version=$(qemu-system-i386 --version 2>&1 | head -n1)
    print_success "QEMU i386 emulator: $version"
    return 0
  else
    print_error "qemu-system-i386: NOT FOUND"
    print_info "Try installing the full qemu-system package"
    return 1
  fi
}

verify_installation() {
  print_header "Verifying Installation"

  local all_good=true

  verify_tool "NASM" "nasm" "version" || all_good=false
  verify_qemu_i386 || all_good=false
  verify_tool "GDB" "gdb" "GNU gdb" || all_good=false
  verify_tool "Make" "make" "GNU Make" || all_good=false
  verify_tool "GCC" "gcc" "gcc" || all_good=false
  verify_tool "G++" "g++" "g++" || all_good=false

  echo ""
  if [ "$all_good" = true ]; then
    print_success "All tools verified successfully!"
    return 0
  else
    print_warning "Some tools may not be properly installed"
    print_info "Review the errors above and install missing packages manually"
    return 1
  fi
}

#==============================================================================
# Main Script
#==============================================================================

main() {
  print_header "x86 Kernel Development - Prerequisites Installer"
  echo ""

  # Check if running as root
  if [ "$EUID" -eq 0 ]; then
    print_error "Do not run this script as root!"
    print_info "The script will use sudo when necessary"
    exit 1
  fi

  # Detect distribution
  detect_distro
  echo ""

  # Confirm before proceeding
  print_info "This will install development tools using your package manager"
  read -p "Continue? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled"
    exit 0
  fi

  echo ""

  # Install packages
  install_packages
  echo ""

  # Verify installation
  verify_installation
  local verify_status=$?
  echo ""

  # Final message
  if [ $verify_status -eq 0 ]; then
    print_header "Setup Complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. cd ../01-Bootloader"
    echo "  2. make"
    echo "  3. ./run_it.sh"
    echo ""
    print_info "Note: You will build the i686-elf-gcc cross-compiler in Lab 08"
  else
    print_header "Setup Complete with Warnings"
    echo ""
    print_warning "Some tools may need manual installation"
    print_info "See README.md for manual installation instructions"
  fi
}

# Run main function
main
