use serde_yaml;

use std::fs::File;
use models::comments::gen_hash;
use errors::*;

/// The main struct which all input data from `oration.yaml` is pushed into.
#[derive(Serialize, Deserialize, Debug)]
pub struct Config {
    /// Top level location of the blog we are serving.
    pub host: String,
    /// A salt for slightly more anonymous `anonymous` user identification.
    pub salt: String,
    /// Blog Author to highlight as an authority in comments.
    pub author: Author,
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
