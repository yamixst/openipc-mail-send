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

This requires Docker and will use [cross](https://github.com/cross-rs/cross) for cross-compilation.

Binaries will be placed in `./target/release-builds/`:
- `email-send-x86_64-linux`
- `email-send-armv7l-linux`

## Usage

```bash
email-send -u AUTH_USER -p AUTH_PASS -f FROM_EMAIL -t TO_EMAIL -a ATTACHED_FILE_PATH
```

### Required Arguments

| Argument | Description |
|----------|-------------|
| `-p`, `--password` | SMTP authentication password |
| `-f`, `--from` | Sender email address |
| `-t`, `--to` | Recipient email address |
| `-a`, `--attach` | Path to the file to attach |

### Optional Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `-u`, `--user` | SMTP authentication username | Same as FROM_EMAIL |
| `-s`, `--subject` | Email subject | "Email with attachment" |
| `-b`, `--body` | Email body text | "Please see the attached file." |
| `--smtp-host` | SMTP server hostname | Auto-detected from email domain |
| `--smtp-port` | SMTP server port | 587 |

### Examples

Send an email with default auth user (same as from email):

```bash
email-send -p "mypassword" -f "sender@gmail.com" -t "recipient@example.com" -a "./document.pdf"
```

Send with custom subject and body:

```bash
email-send -p "mypassword" -f "sender@gmail.com" -t "recipient@example.com" \
  -a "./report.xlsx" -s "Monthly Report" -b "Please find the monthly report attached."
```

Use a custom SMTP server:

```bash
email-send -u "smtp_user" -p "smtp_pass" -f "sender@company.com" -t "client@example.com" \
  -a "./invoice.pdf" --smtp-host "mail.company.com" --smtp-port 465
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