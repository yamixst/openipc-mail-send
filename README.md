# OpenIPC Mail Send

Email notification system for OpenIPC cameras with SMTP support and web interface integration.

## Overview

This package provides email notification capabilities for OpenIPC IP cameras, allowing you to send snapshots and alerts via email. It includes:

- **mail-send** - Lightweight CLI tool to send emails with attachments via SMTP
- **mail** - Shell wrapper script for OpenIPC integration
- **ext-mail.cgi** - Web interface for configuration and remote triggering

## Features

- Send emails with text body and/or file attachments
- SMTP authentication with STARTTLS support
- Automatic SMTP host detection from email domain
- Multiple file attachments support
- Automatic MIME type detection
- Snapshot attachments in JPEG or HEIF format
- Scheduled email notifications via crontab
- Web interface for easy configuration
- Webhook support for remote triggering
- Template placeholders for dynamic content

## Installation

### Quick Install

Download and install the latest release:

```sh
VERSION=0.1
curl -sL https://github.com/yamixst/openipc-mail-send/releases/download/v${VERSION}/openipc-mail-send-${VERSION}.tar.gz | \
  gunzip | tar x -C /tmp && \
  /tmp/openipc-mail-send-${VERSION}/install.sh && \
  rm -rf /tmp/openipc-mail-send-${VERSION}
```

### Manual Installation

1. Download the release package
2. Extract to a temporary directory
3. Run `install.sh`

The installer will:
- Copy `mail-send` and `mail` to `/usr/bin/`
- Install configuration file to `/etc/webui/mail.conf`
- Add CGI script to `/var/www/cgi-bin/`
- Add Mail menu to the web interface

## Configuration

Edit `/etc/webui/mail.conf` to configure your mail settings:

```sh
# Enable/disable mail notifications
mail_enabled="true"

# Sender mail address (required)
mail_from="camera@example.com"

# Recipient mail address (required)
mail_to="alerts@example.com"

# SMTP authentication password (required)
# For Gmail, use App Password: https://support.google.com/accounts/answer/185833
mail_password="your_smtp_password"

# Mail subject (optional)
# Placeholders: %hostname, %datetime, %soctemp
mail_subject="Alert from %hostname at %datetime"

# Mail body text (optional)
# Placeholders: %hostname, %datetime, %soctemp
mail_body="Camera %hostname captured a snapshot at %datetime. Temperature: %soctemp C"

# SMTP authentication username (optional, defaults to mail_from)
#mail_user="smtp_username"

# SMTP server host (optional, auto-detected from mail domain)
#mail_smtp_host="smtp.gmail.com"

# SMTP server port (optional, default: 587)
#mail_smtp_port="587"

# Send snapshot as HEIF instead of JPEG (optional, requires h265 codec)
#mail_heif="false"
```

### Template Placeholders

The following placeholders can be used in `mail_subject` and `mail_body`:

| Placeholder | Description |
|-------------|-------------|
| `%hostname` | Camera hostname |
| `%datetime` | Current date and time |
| `%soctemp` | SoC temperature |

## Usage

### Command Line

Send a snapshot manually:

```sh
/usr/bin/mail
```

### Web Interface

Access the Mail configuration page at:
```
http://CAMERA_IP/cgi-bin/ext-mail.cgi
```

### Webhook

Trigger email sending remotely via HTTP:

```
http://root:password@CAMERA_IP/cgi-bin/ext-mail.cgi?send=image
```

Returns `true` on success, `false` on failure.

### Scheduled Sending

Enable crontab in the web interface to send snapshots at regular intervals.

## mail-send CLI

The `mail-send` utility can be used standalone:

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

Send a simple email:

```sh
mail-send \
  -f user@gmail.com \
  -t recipient@example.com \
  -s "Hello" \
  -b "This is the message body" \
  -p "your-app-password"
```

Send an email with attachment:

```sh
mail-send \
  -f user@gmail.com \
  -t recipient@example.com \
  -s "Photo from camera" \
  -a /tmp/snapshot.jpg \
  -p "your-app-password"
```

Send with multiple attachments:

```sh
mail-send \
  -f user@gmail.com \
  -t recipient@example.com \
  -s "Multiple files" \
  -b "See attached files" \
  -a /tmp/file1.jpg \
  -a /tmp/file2.pdf \
  -p "your-app-password"
```

## SMTP Configuration

### Automatic Host Detection

If `--smtp-host` is not specified, the SMTP host is automatically derived from the sender's email domain:

- `user@gmail.com` → `smtp.gmail.com`
- `user@outlook.com` → `smtp.outlook.com`
- `user@mail.ru` → `smtp.mail.ru`

### Gmail Setup

For Gmail, you need to use an App Password:

1. Enable 2-Factor Authentication on your Google Account
2. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
3. Create a new App Password for "Mail"
4. Use the generated 16-character password

### Other Providers

| Provider | SMTP Host | Port |
|----------|-----------|------|
| Gmail | smtp.gmail.com | 587 |
| Outlook/Hotmail | smtp.office365.com | 587 |
| Yahoo | smtp.mail.yahoo.com | 587 |
| Mail.ru | smtp.mail.ru | 587 |
| Yandex | smtp.yandex.ru | 587 |

## Project Structure

```
openipc-mail-send/
├── mail-send              # Shell script implementation
├── mail-send-rs/          # Rust implementation (optional)
│   ├── src/
│   ├── Cargo.toml
│   └── docker-build.sh
├── openipc/
│   ├── mail               # OpenIPC wrapper script
│   ├── mail.conf.example  # Configuration template
│   ├── ext-mail.cgi       # Web interface CGI
│   └── add-mail-menu.sh   # Menu installation script
├── build-package.sh       # Package build script
└── README.md
```

## Building from Source

### Build Package

```sh
VERSION=0.1 ./build-package.sh
```

Creates `openipc-mail-send-0.1.tar.gz` package.

### Build Rust Binary (Optional)

The project includes a Rust implementation for better performance:

```sh
cd mail-send-rs
./docker-build.sh
```

## Supported MIME Types

The tool automatically detects MIME types for common file extensions:

- **Images:** JPEG, PNG, GIF, WebP, HEIF/HEIC
- **Documents:** PDF, TXT, HTML
- **Video:** MP4, AVI, MKV
- **Audio:** MP3, WAV
- **Archives:** ZIP, TAR, GZIP

## Requirements

- OpenIPC firmware with web interface
- `curl` with SSL support
- `base64` or `openssl` for encoding attachments

## License

Part of the [OpenIPC](https://openipc.org) project.
