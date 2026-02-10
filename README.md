# Email-Send

A simple CLI tool written in Rust to send emails with attachments via SMTP.

## Features

- Send emails with file attachments
- Automatic SMTP server detection from email domain
- MIME type detection for attachments
- Cross-platform support (x86_64 and armv7l Linux)

## Installation

### From Source

```bash
# Clone the repository
cd email-sender

# Build in release mode
cargo build --release

# The binary will be at ./target/release/email-send
```

### Cross-Compilation

To build for both x86_64 and armv7l Linux:

```bash
./build.sh
```

This requires ARM cross-compiler (`arm-linux-gnueabihf-gcc`) to be installed.

### Docker Build

To build using Docker (no local toolchain required):

```bash
./docker-build.sh
```

This will build binaries for both x86_64 and armv7l Linux inside a Docker container.

You can also run the tool directly via Docker:

```bash
docker run --rm -v "$(pwd):/data" email-send-builder \
  -f "sender@gmail.com" -t "recipient@example.com" -s "Subject" \
  -a "/data/document.pdf" -p "mypassword"
```

Binaries will be placed in `./target/release-builds/`:
- `email-send-x86_64-linux`
- `email-send-armv7l-linux` (statically linked with musl)

## Usage

```bash
email-send -f FROM_EMAIL -t TO_EMAIL -s SUBJECT -b BODY -a ATTACHED_FILE_PATH -p AUTH_PASS
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `-f`, `--from` | Sender email address | - |
| `-t`, `--to` | Recipient email address | - |
| `-s`, `--subject` | Email subject | - |
| `-b`, `--body` | Email body text | - |
| `-a`, `--attach` | Path to file to attach (can be specified multiple times) | - |
| `-u`, `--user` | SMTP authentication username | Same as Sender |
| `-p`, `--password` | SMTP authentication password | - |
| `--smtp-host` | SMTP server hostname | Auto-detected from email domain |
| `--smtp-port` | SMTP server port | 587 |

### Examples

Send an email with default auth user (same as from email):

```bash
email-send -f "sender@gmail.com" -t "recipient@example.com" -s "Email with attachment" -a "./document.pdf" -p "mypassword"
```

Send with custom subject and body:

```bash
email-send -f "sender@gmail.com" -t "recipient@example.com" -s "Monthly Report" \
  -b "Please find the monthly report attached." -a "./report.xlsx" -p "mypassword"
```

Send multiple attachments:

```bash
email-send -f "sender@gmail.com" -t "recipient@example.com" -s "Documents" \
  -b "Please find the attached documents." \
  -a "./report.pdf" -a "./data.xlsx" -a "./summary.docx" -p "mypassword"
```

Use a custom SMTP server:

```bash
email-send -f "sender@company.com" -t "client@example.com" -s "Invoice" \
  -a "./invoice.pdf" -u "smtp_user" -p "smtp_pass" --smtp-host "mail.company.com" --smtp-port 465
```

## SMTP Server Auto-Detection

If `--smtp-host` is not specified, the tool will attempt to determine the SMTP server from the sender's email domain:

- `user@gmail.com` → `smtp.gmail.com`
- `user@outlook.com` → `smtp.outlook.com`
- `user@company.com` → `smtp.company.com`

## Security Notes

- Never hardcode passwords in scripts
- Consider using environment variables for credentials:
  ```bash
  email-send -p "$SMTP_PASSWORD" -f "..." -t "..." -a "..."
  ```
- For Gmail, you may need to use an [App Password](https://support.google.com/accounts/answer/185833)

## Dependencies

- [lettre](https://crates.io/crates/lettre) - Email sending library
- [clap](https://crates.io/crates/clap) - Command-line argument parsing
- [tokio](https://crates.io/crates/tokio) - Async runtime
- [mime_guess](https://crates.io/crates/mime_guess) - MIME type detection

## License

MIT
