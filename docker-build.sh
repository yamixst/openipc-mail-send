#!/bin/bash
set -e

echo "=== Email-Send Docker Build Script ==="
echo ""

# Ensure we're in the project directory
cd "$(dirname "$0")"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Create output directory
OUTPUT_DIR="./target/release-builds"
mkdir -p "$OUTPUT_DIR"

echo "Building Docker image..."
echo ""

# Build the Docker image
docker build -t email-send-builder .

echo ""
echo "Extracting binaries from Docker image..."
echo ""

# Create a temporary container and copy binaries out
CONTAINER_ID=$(docker create email-send-builder)
docker cp "$CONTAINER_ID:/output/email-send-x86_64-linux" "$OUTPUT_DIR/email-send-x86_64-linux"
docker cp "$CONTAINER_ID:/output/email-send-armv7l-linux" "$OUTPUT_DIR/email-send-armv7l-linux"
docker rm "$CONTAINER_ID" > /dev/null

# Make binaries executable
chmod +x "$OUTPUT_DIR/email-send-x86_64-linux"
chmod +x "$OUTPUT_DIR/email-send-armv7l-linux"

echo ""
echo "=== Build Complete ==="
echo ""
echo "Binaries are located in: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"

echo ""
echo "To run the x86_64 binary directly:"
echo "  $OUTPUT_DIR/email-send-x86_64-linux --help"
echo ""
echo "To run via Docker:"
echo "  docker run --rm email-send-builder --help"
