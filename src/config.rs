use serde_yaml;

use std::fs::File;
use errors::*;

// The main struct which all input data from `oration.yaml` is pushed into.
#[derive(Serialize, Deserialize, Debug)]
pub struct Config {
    /// Top level location of the blog we are serving.
    pub host: String,
    /// A salt for slightly more anonymous `anonymous` user identification.
    pub salt: String,
}

impl Config {
    /// Reads and parses data from the `oration.yaml` file and command line arguments.
    pub fn load() -> Result<Config> {
        let reader = File::open("oration.yaml").chain_err(
            || ErrorKind::ConfigLoad,
        )?;
        // Decode configuration file.
        let decoded_config: Config = serde_yaml::from_reader(reader).chain_err(
            || ErrorKind::Deserialize,
        )?;
        Config::parse(&decoded_config).chain_err(
            || ErrorKind::ConfigParse,
        )?;

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
