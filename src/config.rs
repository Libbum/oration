use serde_yaml;

use std::fs::File;
use models::comments::gen_hash;
use errors::*;

/// The main struct which all input data from `oration.yaml` is pushed into.
#[derive(Serialize, Deserialize, Debug)]
pub struct Config {
    /// Top level location of the blog we are serving.
    pub host: String,
    /// Name of the blog we are serving.
    pub blog_name: String,
    /// A salt for slightly more anonymous `anonymous` user identification.
    pub salt: String,
    /// Blog Author to highlight as an authority in comments.
    pub author: Author,
    /// Limit of thread nesting in comments.
    pub nesting_limit: u32,
    /// Time limit that restricts user editing of their own comments.
    pub edit_timeout: f32,
    /// Email notification system and connection details.
    pub notifications: Notifications,
    /// Telegram notification endpoint details.
    pub telegram: Telegram,
}

impl Config {
    /// Reads and parses data from the `oration.yaml` file and command line arguments.
    pub fn load() -> Result<Config> {
        let reader = File::open("oration.yaml").chain_err(
            || ErrorKind::ConfigLoad,
        )?;
        // Decode configuration file.
        let mut decoded_config: Config = serde_yaml::from_reader(reader).chain_err(
            || ErrorKind::Deserialize,
        )?;
        Config::parse(&decoded_config).chain_err(
            || ErrorKind::ConfigParse,
        )?;

        decoded_config.author.gen_hash();

        Ok(decoded_config)
    }

    /// Additional checks to the configuration file that cannot be done implicitly
    /// by the type checker.
    fn parse(&self) -> Result<()> {
        let handle = self.host.get(0..4);
        if handle != Some("http") {
            return Err(ErrorKind::NoHTTPHandle.into());
        }

        if self.notifications.new_comment {
            // Empty values are parsed as ~, so we want to check for those
            if self.notifications.smtp_server.into_iter().any(|x| {
                x.is_empty() || x == "~"
            })
            {
                return Err(ErrorKind::EmptySMTP.into());
            }
            if self.notifications.recipient.email.is_empty() ||
                self.notifications.recipient.email == "~"
            {
                return Err(ErrorKind::EmptyRecipientEmail.into());
            }
        }
        Ok(())
    }
}

/// Details of the blog author.
#[derive(Serialize, Deserialize, Debug)]
pub struct Author {
    /// Blog author's name.
    name: Option<String>,
    /// Blog author's email address.
    email: Option<String>,
    /// Blog author's website.
    url: Option<String>,
    #[serde(skip)]
    /// A Sha224 hash of the blog author's details (automitically generated).
    pub hash: String,
}

impl Author {
    /// Generates a Sha224 hash for the blog author if details are set.
    fn gen_hash(&mut self) {
        self.hash = gen_hash(&self.name, &self.email, &self.url, None);
    }
}

/// Details of the email notification system.
#[derive(Serialize, Deserialize, Debug)]
pub struct Notifications {
    /// Toggle if an email is to be sent when a new comment is posted.
    pub new_comment: bool,
    /// SMTP connection details.
    pub smtp_server: SMTPServer,
    /// Who to send the notification to.
    pub recipient: Recipient,
}


/// Details of the SMTP server which the notification system should connect to.
#[derive(Serialize, Deserialize, Debug)]
pub struct SMTPServer {
    /// SMTP host url. (No need for a protocol header).
    pub host: String,
    /// Username for authentication.
    pub user_name: String,
    /// Password for authentication.
    pub password: String,
}

impl<'a> IntoIterator for &'a SMTPServer {
    type Item = &'a str;
    type IntoIter = SMTPServerIterator<'a>;

    fn into_iter(self) -> Self::IntoIter {
        SMTPServerIterator {
            server: self,
            index: 0,
        }
    }
}

/// Iterator helper for `SMTPServer`
pub struct SMTPServerIterator<'a> {
    /// The SMTPServer struct.
    server: &'a SMTPServer,
    /// A helper index.
    index: usize,
}

impl<'a> Iterator for SMTPServerIterator<'a> {
    type Item = &'a str;
    fn next(&mut self) -> Option<&'a str> {
        let result = match self.index {
            0 => &self.server.host,
            1 => &self.server.user_name,
            2 => &self.server.password,
            _ => return None,
        };
        self.index += 1;
        Some(result)
    }
}

/// Details of a person to email the notifications to.
#[derive(Serialize, Deserialize, Debug)]
pub struct Recipient {
    /// Recipient's email address.
    pub email: String,
    /// Recipient's name.
    pub name: String,
}

/// Details of the telegram notification system.
#[derive(Serialize, Deserialize, Debug)]
pub struct Telegram {
    /// If true, the notification system will be active.
    pub push_notifications: bool,
    /// API token for your telegram bot.
    pub bot_id: String,
    /// The ID of your personal chat with the bot.
    pub chat_id: String,
}
