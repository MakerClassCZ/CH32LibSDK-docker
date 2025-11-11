#!/bin/bash
# ============================================================================
# Build CH32LibSDK Docker Images (Local Build Only)
# ============================================================================
#
# Usage:
#   ./build-all.sh                # Build all containers
#   ./build-all.sh base           # Build only base container
#   ./build-all.sh gcc            # Build base + GCC container
#   ./build-all.sh clang          # Build base + Clang+libgcc container
#   ./build-all.sh compiler-rt    # Build base + compiler-rt container
#   ./build-all.sh nobase         # Build only toolchain containers (skip base)
#
# Prerequisites:
#   - wch-toolchain.tar.gz must exist in current directory
#   - cmake-toolchains/ directory with toolchain files
#   - memmap-lld.ld linker script
#

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

IMAGE_NAME="ch32libsdk"  # Local images only (no registry)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if wch-toolchain.tar.gz exists
    if [ ! -f "wch-toolchain.tar.gz" ]; then
        log_error "wch-toolchain.tar.gz not found in current directory!"
        log_error "Please create it first (see README)"
        exit 1
    fi

    # Check if memmap-lld.ld exists
    if [ ! -f "memmap-lld.ld" ]; then
        log_error "memmap-lld.ld not found in current directory!"
        exit 1
    fi

    # Check if cmake-toolchains exists
    if [ ! -d "cmake-toolchains" ]; then
        log_error "cmake-toolchains directory not found!"
        exit 1
    fi

    log_success "All prerequisites met"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check prerequisites
check_prerequisites

# Get build metadata
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if git rev-parse --git-dir > /dev/null 2>&1; then
    VCS_REF=$(git rev-parse --short HEAD)
    log_info "Git commit: $VCS_REF"
else
    VCS_REF="unknown"
    log_warning "Not a git repository, VCS_REF will be 'unknown'"
fi

VERSION="local"

echo ""
log_info "CH32LibSDK and ch32v003fun will be automatically downloaded from GitHub during build"
echo ""

# ============================================================================
# Build Functions
# ============================================================================

build_base() {
    log_info "Building base image..."
    docker build -f Dockerfile.base \
      -t $IMAGE_NAME:base \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "Base image built"
}

build_gcc() {
    # Check if base image exists
    if ! docker image inspect $IMAGE_NAME:base >/dev/null 2>&1; then
        log_warning "Base image not found, building base first..."
        build_base
        echo ""
    fi

    log_info "Building gcc-wch image..."
    docker build -f Dockerfile.gcc-wch \
      -t $IMAGE_NAME:gcc-wch \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "GCC WCH image built"
}

build_clang() {
    # Check if base image exists
    if ! docker image inspect $IMAGE_NAME:base >/dev/null 2>&1; then
        log_warning "Base image not found, building base first..."
        build_base
        echo ""
    fi

    log_info "Building clang-libgcc image (recommended)..."
    docker build -f Dockerfile.clang-libgcc \
      -t $IMAGE_NAME:clang-libgcc \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "Clang+libgcc image built"
}

build_compiler_rt() {
    # Check if base image exists
    if ! docker image inspect $IMAGE_NAME:base >/dev/null 2>&1; then
        log_warning "Base image not found, building base first..."
        build_base
        echo ""
    fi

    log_info "Building clang-compiler-rt image (this takes ~15-20 minutes)..."
    docker build -f Dockerfile.clang-compiler-rt \
      -t $IMAGE_NAME:clang-compiler-rt \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "Clang+compiler-rt image built"
}

build_gcc_nobase() {
    log_info "Building gcc-wch image (assuming base exists)..."
    docker build -f Dockerfile.gcc-wch \
      -t $IMAGE_NAME:gcc-wch \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "GCC WCH image built"
}

build_clang_nobase() {
    log_info "Building clang-libgcc image (assuming base exists)..."
    docker build -f Dockerfile.clang-libgcc \
      -t $IMAGE_NAME:clang-libgcc \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "Clang+libgcc image built"
}

build_compiler_rt_nobase() {
    log_info "Building clang-compiler-rt image (assuming base exists, ~15-20 minutes)..."
    docker build -f Dockerfile.clang-compiler-rt \
      -t $IMAGE_NAME:clang-compiler-rt \
      --build-arg VERSION=$VERSION \
      --build-arg BUILD_DATE=$BUILD_DATE \
      --build-arg VCS_REF=$VCS_REF \
      .
    log_success "Clang+compiler-rt image built"
}

# ============================================================================
# Main Build Logic
# ============================================================================

case "${1:-all}" in
    base)
        build_base
        ;;
    gcc)
        build_gcc
        ;;
    clang|clang-libgcc)
        build_clang
        ;;
    compiler-rt|clang-compiler-rt)
        build_compiler_rt
        ;;
    nobase)
        echo "============================================================================"
        echo "  Building Toolchain Images Only (skipping base)"
        echo "============================================================================"
        echo "  Version:      $VERSION"
        echo "  Build Date:   $BUILD_DATE"
        echo "  VCS Ref:      $VCS_REF"
        echo "============================================================================"
        echo ""

        # Check if base image exists
        if ! docker image inspect $IMAGE_NAME:base >/dev/null 2>&1; then
            log_error "Base image not found!"
            log_error "Please build base image first: ./build-all.sh base"
            exit 1
        fi

        log_info "Base image found, building toolchain images..."
        echo ""

        build_gcc_nobase
        echo ""
        build_clang_nobase
        echo ""
        build_compiler_rt_nobase

        log_success "All toolchain images built successfully!"
        echo ""

        # Show image sizes
        log_info "Image sizes:"
        docker images | grep -E "$IMAGE_NAME|REPOSITORY" | grep -v ghcr.io
        echo ""
        ;;
    all|"")
        echo "============================================================================"
        echo "  Building CH32LibSDK Docker Images"
        echo "============================================================================"
        echo "  Version:      $VERSION"
        echo "  Build Date:   $BUILD_DATE"
        echo "  VCS Ref:      $VCS_REF"
        echo "============================================================================"
        echo ""

        log_info "Starting Docker builds..."
        echo ""

        build_base
        echo ""
        build_gcc
        echo ""
        build_clang
        echo ""
        build_compiler_rt

        log_success "All images built successfully!"
        echo ""

        # Show image sizes
        log_info "Image sizes:"
        docker images | grep -E "$IMAGE_NAME|REPOSITORY" | grep -v ghcr.io
        echo ""
        ;;
    *)
        log_error "Unknown option: $1"
        echo ""
        echo "Usage: $0 [base|gcc|clang|compiler-rt|nobase|all]"
        echo ""
        echo "Options:"
        echo "  base         - Build only base container (common foundation)"
        echo "  gcc          - Build base + GCC WCH container"
        echo "  clang        - Build base + Clang + libgcc container (recommended)"
        echo "  compiler-rt  - Build base + compiler-rt container (pure LLVM)"
        echo "  nobase       - Build only toolchain containers (requires base to exist)"
        echo "  all          - Build all containers (default)"
        echo ""
        echo "Multi-stage structure:"
        echo "  base → gcc-wch"
        echo "  base → clang-libgcc"
        echo "  base → clang-compiler-rt"
        echo ""
        echo "Use 'nobase' for faster rebuilds when base hasn't changed."
        exit 1
        ;;
esac

echo ""
log_success "Done!"
