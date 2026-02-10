# Multi-stage Dockerfile for building mail-send
# Supports building for multiple architectures

FROM rust:1.87-bookworm AS builder

# Install cross-compilation tools for musl
RUN apt-get update && apt-get install -y \
    musl-tools \
    && rm -rf /var/lib/apt/lists/*

# Install musl cross-compiler for ARM
RUN wget -qO- https://musl.cc/arm-linux-musleabihf-cross.tgz | tar xz -C /opt

ENV PATH="/opt/arm-linux-musleabihf-cross/bin:$PATH"

# Add Rust targets
RUN rustup target add x86_64-unknown-linux-gnu \
    && rustup target add armv7-unknown-linux-musleabihf

WORKDIR /app

# Copy the project files
COPY Cargo.toml Cargo.lock ./
COPY src ./src

# Create cargo config for ARM cross-compilation
RUN mkdir -p .cargo && \
    echo '[target.armv7-unknown-linux-musleabihf]' > .cargo/config.toml && \
    echo 'linker = "arm-linux-musleabihf-gcc"' >> .cargo/config.toml

# Build for x86_64
RUN cargo build --release --target x86_64-unknown-linux-gnu

# Build for armv7 musl
RUN cargo build --release --target armv7-unknown-linux-musleabihf

# Create output directory and copy binaries
RUN mkdir -p /output && \
    cp target/x86_64-unknown-linux-gnu/release/mail-send /output/mail-send-x86_64-linux && \
    cp target/armv7-unknown-linux-musleabihf/release/mail-send /output/mail-send-armv7l-linux
