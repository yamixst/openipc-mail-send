# Mail-Send

A simple CLI tool written in Rust to send mails with attachments via SMTP.

## Features

- Send mails with file attachments
- Automatic SMTP server detection from mail domain
- MIME type detection for attachments
- Cross-platform support (x86_64 and armv7l Linux)

## Installation

### From Source

```bash
# Clone the repository
cd mail-send

# Build in release mode
cargo build --release

# The binary will be at ./target/release/mail-send
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
docker run --rm -v "$(pwd):/data" mail-send-builder \
  -f "sender@gmail.com" -t "recipient@example.com" -s "Subject" \
  -a "/data/document.pdf" -p "mypassword"
```

Binaries will be placed in `./target/release-builds/`:
- `mail-send-x86_64-linux`
- `mail-send-armv7l-linux` (statically linked with musl)

## Usage

```bash
mail-send -f FROM -t TO -s SUBJECT -b BODY -a ATTACHED_FILE_PATH -p AUTH_PASS
```

### Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `-f`, `--from` | Sender mail address | - |
| `-t`, `--to` | Recipient mail address | - |
| `-s`, `--subject` | Mail subject | - |
| `-b`, `--body` | Mail body text | - |
| `-a`, `--attach` | Path to file to attach (can be specified multiple times) | - |
| `-u`, `--user` | SMTP authentication username | Same as Sender |
| `-p`, `--password` | SMTP authentication password | - |
| `--smtp-host` | SMTP server hostname | Auto-detected from mail domain |
| `--smtp-port` | SMTP server port | 587 |

### Examples

Send a mail with default auth user (same as from):

```bash
mail-send -f "sender@gmail.com" -t "recipient@example.com" -s "Mail with attachment" -a "./document.pdf" -p "mypassword"
```

Send with custom subject and body:

```bash
mail-send -f "sender@gmail.com" -t "recipient@example.com" -s "Monthly Report" \
  -b "Please find the monthly report attached." -a "./report.xlsx" -p "mypassword"
```

Send multiple attachments:

```bash
mail-send -f "sender@gmail.com" -t "recipient@example.com" -s "Documents" \
  -b "Please find the attached documents." \
  -a "./report.pdf" -a "./data.xlsx" -a "./summary.docx" -p "mypassword"
```

Use a custom SMTP server:

```bash
mail-send -f "sender@company.com" -t "client@example.com" -s "Invoice" \
  -a "./invoice.pdf" -u "smtp_user" -p "smtp_pass" --smtp-host "mail.company.com" --smtp-port 465
```

## SMTP Server Auto-Detection

If `--smtp-host` is not specified, the tool will attempt to determine the SMTP server from the sender's mail domain:

- `user@gmail.com` → `smtp.gmail.com`
- `user@outlook.com` → `smtp.outlook.com`
- `user@company.com` → `smtp.company.com`

## Security Notes

- Never hardcode passwords in scripts
- Consider using environment variables for credentials:
  ```bash
  mail-send -p "$SMTP_PASSWORD" -f "..." -t "..." -a "..."
  ```
- For Gmail, you may need to use an [App Password](https://support.google.com/accounts/answer/185833)

## Dependencies

- [lettre](https://crates.io/crates/lettre) - Mail sending library
- [clap](https://crates.io/crates/clap) - Command-line argument parsing
- [tokio](https://crates.io/crates/tokio) - Async runtime
- [mime_guess](https://crates.io/crates/mime_guess) - MIME type detection

## License

MIT