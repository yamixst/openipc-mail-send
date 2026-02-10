use clap::Parser;
use lettre::{
    message::{header::ContentType, Attachment, MultiPart, SinglePart},
    transport::smtp::authentication::Credentials,
    AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(name = "email-send")]
#[command(about = "Send emails with attachments via SMTP")]
struct Args {
    /// Sender email address
    #[arg(short = 'f', long = "from")]
    from_email: String,

    /// Recipient email address
    #[arg(short = 't', long = "to")]
    to_email: String,

    /// Email subject
    #[arg(short = 's', long = "subject")]
    subject: String,

    /// Email body text
    #[arg(short = 'b', long = "body")]
    body: Option<String>,

    /// Path to the file to attach
    #[arg(short = 'a', long = "attach")]
    attached_file: Option<PathBuf>,

    /// SMTP authentication username (defaults to FROM_EMAIL if not specified)
    #[arg(short = 'u', long = "user")]
    auth_user: Option<String>,

    /// SMTP authentication password
    #[arg(short = 'p', long = "password")]
    auth_pass: String,

    /// SMTP server host
    #[arg(long = "smtp-host")]
    smtp_host: Option<String>,

    /// SMTP server port
    #[arg(long = "smtp-port", default_value = "587")]
    smtp_port: u16,
}

fn extract_smtp_host(email: &str) -> Result<String, String> {
    let domain = email
        .split('@')
        .nth(1)
        .ok_or_else(|| format!("Invalid email address: {}", email))?;

    Ok(format!("smtp.{}", domain))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // Validate that at least one of body or attach is provided
    if args.body.is_none() && args.attached_file.is_none() {
        return Err("At least one of --body or --attach must be specified".into());
    }

    // Use from_email as auth_user if not specified
    let auth_user = args.auth_user.unwrap_or_else(|| args.from_email.clone());

    // Determine SMTP host
    let smtp_host = match args.smtp_host {
        Some(host) => host,
        None => extract_smtp_host(&args.from_email)?,
    };

    // Build the email message
    let email_builder = Message::builder()
        .from(args.from_email.parse()?)
        .to(args.to_email.parse()?)
        .subject(&args.subject);

    let email = match (&args.body, &args.attached_file) {
        (Some(body), Some(attached_file)) => {
            // Both body and attachment
            if !attached_file.exists() {
                return Err(format!("File not found: {:?}", attached_file).into());
            }

            let file_content = std::fs::read(attached_file)?;
            let file_name = attached_file
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("attachment");

            let fallback_content_type = ContentType::parse("application/octet-stream").unwrap();
            let content_type = mime_guess::from_path(attached_file)
                .first()
                .map(|mime| {
                    ContentType::parse(mime.as_ref()).unwrap_or_else(|_| fallback_content_type.clone())
                })
                .unwrap_or(fallback_content_type);

            let attachment = Attachment::new(file_name.to_string()).body(file_content, content_type);

            email_builder.multipart(
                MultiPart::mixed()
                    .singlepart(SinglePart::plain(body.clone()))
                    .singlepart(attachment),
            )?
        }
        (Some(body), None) => {
            // Only body, no attachment
            email_builder.body(body.clone())?
        }
        (None, Some(attached_file)) => {
            // Only attachment, no body
            if !attached_file.exists() {
                return Err(format!("File not found: {:?}", attached_file).into());
            }

            let file_content = std::fs::read(attached_file)?;
            let file_name = attached_file
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("attachment");

            let fallback_content_type = ContentType::parse("application/octet-stream").unwrap();
            let content_type = mime_guess::from_path(attached_file)
                .first()
                .map(|mime| {
                    ContentType::parse(mime.as_ref()).unwrap_or_else(|_| fallback_content_type.clone())
                })
                .unwrap_or(fallback_content_type);

            let attachment = Attachment::new(file_name.to_string()).body(file_content, content_type);

            email_builder.multipart(MultiPart::mixed().singlepart(attachment))?
        }
        (None, None) => {
            // This case is already handled by the validation above
            unreachable!()
        }
    };

    // Create SMTP credentials
    let creds = Credentials::new(auth_user, args.auth_pass);

    // Build SMTP transport
    let mailer: AsyncSmtpTransport<Tokio1Executor> =
        AsyncSmtpTransport::<Tokio1Executor>::starttls_relay(&smtp_host)?
            .port(args.smtp_port)
            .credentials(creds)
            .build();

    // Send the email
    match mailer.send(email).await {
        Ok(_) => {
            println!("Email sent successfully to {}", args.to_email);
            Ok(())
        }
        Err(e) => Err(format!("Failed to send email: {}", e).into()),
    }
}
