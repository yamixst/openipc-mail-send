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

# Create output directory
OUTPUT_DIR="./target/release-builds"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "=== Building for x86_64-unknown-linux-gnu ==="
echo ""

# Add target if not present
rustup target add x86_64-unknown-linux-gnu 2>/dev/null || true

# Build for x86_64 Linux
cargo build --release --target x86_64-unknown-linux-gnu

# Copy binary to output directory
cp target/x86_64-unknown-linux-gnu/release/email-send "$OUTPUT_DIR/email-send-x86_64-linux"
echo "Built: $OUTPUT_DIR/email-send-x86_64-linux"

echo ""
echo "=== Building for armv7-unknown-linux-musleabihf (armv7l) ==="
echo ""

# Add target if not present
rustup target add armv7-unknown-linux-musleabihf 2>/dev/null || true

# Check if ARM musl cross-compiler is available
if ! command -v arm-linux-musleabihf-gcc &> /dev/null; then
    echo "Warning: ARM musl cross-compiler (arm-linux-musleabihf-gcc) not found."
    echo "Download from https://musl.cc/ and add to PATH"
    echo "Skipping ARM build..."
else
    # Create cargo config for cross-compilation if not exists
    mkdir -p .cargo
    if ! grep -q "armv7-unknown-linux-musleabihf" .cargo/config.toml 2>/dev/null; then
        echo '[target.armv7-unknown-linux-musleabihf]' >> .cargo/config.toml
        echo 'linker = "arm-linux-musleabihf-gcc"' >> .cargo/config.toml
    fi

    # Build for armv7l Linux (musl)
    cargo build --release --target armv7-unknown-linux-musleabihf

    # Copy binary to output directory
    cp target/armv7-unknown-linux-musleabihf/release/email-send "$OUTPUT_DIR/email-send-armv7l-linux"
    echo "Built: $OUTPUT_DIR/email-send-armv7l-linux"
fi

echo ""
echo "=== Build Complete ==="
echo ""
echo "Binaries are located in: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
