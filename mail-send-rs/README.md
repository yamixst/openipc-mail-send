# mail-send-rs

A lightweight CLI tool written in Rust to send emails with attachments via SMTP. Designed for embedded systems and IoT devices, particularly OpenIPC cameras.

## Features

- Send emails with text body and/or file attachments
- SMTP authentication with STARTTLS support
- Automatic SMTP host detection from email domain
- Multiple file attachments support
- Automatic MIME type detection
- Cross-compilation support for x86_64 and ARMv7 (musl)
- Optimized binary size with LTO and stripping

## Installation

### From Source

```bash
cd mail-send-rs
cargo build --release
```

The binary will be located at `target/release/mail-send`.

### Cross-Compilation

#### Using Docker (Recommended)

Build for both x86_64 and ARMv7 architectures:

```bash
./docker-build.sh
```

Binaries will be available in `target/release-builds/`:
- `mail-send-x86_64-linux`
- `mail-send-armv7l-linux`

#### Manual Cross-Compilation

```bash
./build.sh
```

Requires ARM musl cross-compiler (`arm-linux-musleabihf-gcc`) for ARMv7 builds.
Download from https://musl.cc/ if not installed.

## Usage

```
mail-send [OPTIONS]
```

### Required Options

| Option | Description |
|--------|-------------|
| `-f, --from <FROM>` | Sender email address |
| `-t, --to <TO>` | Recipient email address |
| `-s, --subject <SUBJECT>` | Email subject |
| `-p, --password <PASSWORD>` | SMTP authentication password |

### Optional Options

| Option | Description |
|--------|-------------|
| `-b, --body <BODY>` | Email body text |
| `-a, --attach <FILE>` | Path to file to attach (can be repeated) |
| `-u, --user <USER>` | SMTP auth username (defaults to FROM) |
| `--smtp-host <HOST>` | SMTP server host (auto-detected from domain) |
| `--smtp-port <PORT>` | SMTP server port (default: 587) |
| `-h, --help` | Show help message |

**Note:** At least one of `--body` or `--attach` must be specified.

### Examples

Send a simple text email:

```bash
mail-send \
  -f user@gmail.com \
  -t recipient@example.com \
  -s "Hello" \
  -b "This is the message body" \
  -p "your-app-password"
```

Send an email with an attachment:

```bash
mail-send \
  -f user@gmail.com \
  -t recipient@example.com \
  -s "Photo from camera" \
  -a /tmp/snapshot.jpg \
  -p "your-app-password"
```

Send an email with multiple attachments:

```bash
mail-send \
  -f user@gmail.com \
  -t recipient@example.com \
  -s "Multiple files" \
  -b "See attached files" \
  -a /tmp/file1.jpg \
  -a /tmp/file2.pdf \
  -p "your-app-password"
```

Using a custom SMTP server:

```bash
mail-send \
  -f user@example.com \
  -t recipient@example.com \
  -s "Custom SMTP" \
  -b "Message" \
  --smtp-host mail.example.com \
  --smtp-port 465 \
  -p "password"
```

## SMTP Configuration

### Automatic Host Detection

If `--smtp-host` is not specified, the tool automatically derives the SMTP host from the sender's email domain:

- `user@gmail.com` → `smtp.gmail.com`
- `user@outlook.com` → `smtp.outlook.com`
- `user@example.com` → `smtp.example.com`

### Gmail Setup

For Gmail, you need to use an App Password:

1. Enable 2-Factor Authentication on your Google Account
2. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
3. Create a new App Password for "Mail"
4. Use the generated 16-character password with `-p`

## Dependencies

- [lettre](https://crates.io/crates/lettre) - Email library for Rust
- [tokio](https://crates.io/crates/tokio) - Async runtime
- [clap](https://crates.io/crates/clap) - Command line argument parser
- [mime_guess](https://crates.io/crates/mime_guess) - MIME type detection

## Supported MIME Types

The tool automatically detects MIME types for common file extensions:

- **Images:** JPEG, PNG, GIF, WebP, HEIF/HEIC
- **Documents:** PDF, TXT, HTML
- **Video:** MP4, AVI, MKV
- **Audio:** MP3, WAV
- **Archives:** ZIP, TAR, GZIP

Unknown file types default to `application/octet-stream`.

## Build Optimization

The release build is optimized for minimal binary size:

- `opt-level = "z"` - Optimize for size
- `lto = true` - Link-Time Optimization
- `strip = true` - Strip debug symbols

## License

Part of the OpenIPC project.