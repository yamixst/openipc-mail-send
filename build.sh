#!/bin/bash
set -e

echo "=== Email-Send Cross-Compilation Build Script ==="
echo ""

# Ensure we're in the project directory
cd "$(dirname "$0")"

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust/Cargo is not installed. Please install it from https://rustup.rs/"
    exit 1
fi

# Install cross if not already installed
if ! command -v cross &> /dev/null; then
    echo "Installing 'cross' for cross-compilation..."
    cargo install cross --git https://github.com/cross-rs/cross
fi

# Create output directory
OUTPUT_DIR="./target/release-builds"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "=== Building for x86_64-unknown-linux-gnu ==="
echo ""

# Add target if not present
rustup target add x86_64-unknown-linux-gnu 2>/dev/null || true

# Build for x86_64 Linux
cross build --release --target x86_64-unknown-linux-gnu

# Copy binary to output directory
cp target/x86_64-unknown-linux-gnu/release/email-send "$OUTPUT_DIR/email-send-x86_64-linux"
echo "Built: $OUTPUT_DIR/email-send-x86_64-linux"

echo ""
echo "=== Building for armv7-unknown-linux-gnueabihf (armv7l) ==="
echo ""

# Add target if not present
rustup target add armv7-unknown-linux-gnueabihf 2>/dev/null || true

# Build for armv7l Linux
cross build --release --target armv7-unknown-linux-gnueabihf

# Copy binary to output directory
cp target/armv7-unknown-linux-gnueabihf/release/email-send "$OUTPUT_DIR/email-send-armv7l-linux"
echo "Built: $OUTPUT_DIR/email-send-armv7l-linux"

echo ""
echo "=== Build Complete ==="
echo ""
echo "Binaries are located in: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
