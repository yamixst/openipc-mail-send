use clap::Parser;
use lettre::{
    message::{header::ContentType, Attachment, MultiPart, SinglePart},
    transport::smtp::authentication::Credentials,
    AsyncSmtpTransport, AsyncTransport, Message, Tokio1Executor,
};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(name = "mail-send")]
#[command(about = "Send mails with attachments via SMTP")]
struct Args {
    /// Sender mail address
    #[arg(short = 'f', long = "from")]
    from: String,

    /// Recipient mail address
    #[arg(short = 't', long = "to")]
    to: String,

    /// Mail subject
    #[arg(short = 's', long = "subject")]
    subject: String,

    /// Mail body text
    #[arg(short = 'b', long = "body")]
    body: Option<String>,

    /// Path to the file to attach (can be specified multiple times)
    #[arg(short = 'a', long = "attach")]
    attached_files: Vec<PathBuf>,

    /// SMTP authentication username (defaults to FROM if not specified)
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

fn extract_smtp_host(mail: &str) -> Result<String, String> {
    let domain = mail
        .split('@')
        .nth(1)
        .ok_or_else(|| format!("Invalid mail address: {}", mail))?;

    Ok(format!("smtp.{}", domain))
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // Validate that at least one of body or attach is provided
    if args.body.is_none() && args.attached_files.is_empty() {
        return Err("At least one of --body or --attach must be specified".into());
    }

    // Use from as auth_user if not specified
    let auth_user = args.auth_user.unwrap_or_else(|| args.from.clone());

    // Determine SMTP host
    let smtp_host = match args.smtp_host {
        Some(host) => host,
        None => extract_smtp_host(&args.from)?,
    };

    // Build the mail message
    let mail_builder = Message::builder()
        .from(args.from.parse()?)
        .to(args.to.parse()?)
        .subject(&args.subject);

    // Build attachments
    let mut attachments = Vec::new();
    for attached_file in &args.attached_files {
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
        attachments.push(attachment);
    }

    let mail = match (&args.body, attachments.is_empty()) {
        (Some(body), false) => {
            // Both body and attachments
            let mut multipart = MultiPart::mixed().singlepart(SinglePart::plain(body.clone()));
            for attachment in attachments {
                multipart = multipart.singlepart(attachment);
            }
            mail_builder.multipart(multipart)?
        }
        (Some(body), true) => {
            // Only body, no attachments
            mail_builder.body(body.clone())?
        }
        (None, false) => {
            // Only attachments, no body - start with empty body to convert builder to MultiPart
            let mut multipart = MultiPart::mixed().singlepart(SinglePart::plain(String::new()));
            for attachment in attachments {
                multipart = multipart.singlepart(attachment);
            }
            mail_builder.multipart(multipart)?
        }
        (None, true) => {
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

    // Send the mail
    match mailer.send(mail).await {
        Ok(_) => {
            println!("Mail sent successfully to {}", args.to);
            Ok(())
        }
        Err(e) => Err(format!("Failed to send mail: {}", e).into()),
    }
}
