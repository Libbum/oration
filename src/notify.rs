use lettre::smtp::authentication::{Credentials, Mechanism};
use lettre::{EmailTransport, SmtpTransport};
use lettre_email::EmailBuilder;
use reqwest;
use std::collections::HashMap;

use errors::*;
use config::{Notifications, Telegram};
use data::FormInput;
use regex::Regex;

/// Parses a URL, returning just the domain portion. The regex is overkill for this at the moment,
/// but I think it may be usefull in the future to have this ability.
fn get_domain(host: &str) -> &str {
    lazy_static! {
        // Matches 4 groups: protocol, domain, port, path.
        static ref URLPARSE: Regex = Regex::new(r"(?i)(https?)://([^\s/?#_:]+\.?)+:?(\d+)?(/[^\s]*)?$").unwrap();
    }
    let caps = URLPARSE.captures(host).unwrap();

    caps.get(2).map_or("noreply", |m| m.as_str())
}

/// Sends an email to a recipient listed in the configuration file when a new comment is posted, so
/// long as the notification system is enabled (this check is elsewhere).
pub fn send_notification(
    form: &FormInput,
    notify: &Notifications,
    host: &str,
    blog_name: &str,
    ip_addr: &str,
) -> Result<()> {

    let post_url = format!("{}{}", host.trim_right_matches('/'), form.path);
    let oration_addr = format!("oration@{}", get_domain(host));
    let recipient_name = if notify.recipient.name == "~" {
        "Oration Admin".to_string()
    } else {
        notify.recipient.name.to_owned()
    };

    let email = EmailBuilder::new()
        .to((notify.recipient.email.to_owned(), recipient_name))
        .from((oration_addr, "Oration Watchdog"))
        .reply_to((form.sender_email(), form.sender_name()))
        .subject(format!("A new comment has been posted on {}", blog_name))
        .text(format!(
"A comment has been posted by {} on a post titled: {}.

The comment reads:
{}

You may reply on your blog post ({}), or if the user has left an email address, responding to this message will deliver them an email.

Debug information:
{:?}

Commenter's IP: {}",
                form.sender_name(), form.title, form.comment, post_url, form, ip_addr))
        .build()
        .chain_err(|| ErrorKind::BuildEmail)?;

    // Connect to a remote server on a custom port
    let mut mailer = SmtpTransport::simple_builder(notify.smtp_server.host.to_owned())
        .chain_err(|| ErrorKind::BuildSmtpTransport)?
        // Add credentials for authentication
        .credentials(Credentials::new(notify.smtp_server.user_name.to_owned(), notify.smtp_server.password.to_owned()))
        // Enable SMTPUTF8 if the server supports it
        .smtp_utf8(true)
        // Configure expected authentication mechanism
        .authentication_mechanism(Mechanism::Plain)
        .build();


    mailer.send(&email).chain_err(|| ErrorKind::SendEmail)?;

    Ok(())
}

/// Sends a push notification to a bot which will forward you a message containing the recent comment.
pub fn push_telegram(
    form: &FormInput,
    telegram: &Telegram,
    host: &str,
    ip_addr: &str,
) -> Result<()> {

    let post_url = format!("{}{}", host.trim_right_matches('/'), form.path);
    let message = format!(
"A comment has been posted by *{}* on a post titled:
_{}_.

The comment reads:
{}

You may reply on your blog post [here]({}). In the future, this bot may also provide a means of responding.

Debug information:
`{:?}`

Commenter's IP: {}",
        form.sender_name(), form.title, form.comment, post_url, form, ip_addr);
    println!("{}", message);
    let preview = String::from("1");
    let md = String::from("Markdown");
    let mut params = HashMap::new();
    params.insert("chat_id", &telegram.chat_id);
    params.insert("parse_mode", &md);
    params.insert("disable_web_page_preview", &preview);
    params.insert("text", &message);

    let res = reqwest::Client::new()
            .post(&format!("https://api.telegram.org/bot{}/sendMessage", telegram.bot_id))
            .form(&params)
            .send()
    .chain_err(|| {
        ErrorKind::Request
    })?;

    if res.status() == reqwest::StatusCode::Ok {
        Ok(())
    } else {
        Err(ErrorKind::TelegramNotify.into())
    }
}
