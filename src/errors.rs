error_chain!{
    errors {
        SessionHash {
                description("Cannot generate session hash")
                display("Unable to generate a session hash")
        }
        NoSession {
                description("Cannot read session info")
                display("Unable to read session information from database")
        }
        NoThread(uri: String) {
                description("Cannot read thread info")
                display("Unable to read thread information for {} from database", uri)
        }
        DBRead {
                description("Cannot parse db response")
                display("Unable to parse response from database query")
        }
        DBInsert {
                description("Cannot insert data in db")
                display("Database query to insert data failed")
        }
        Rand {
                description("Cannot generate random number")
                display("Unable to call /dev/urandom")
        }
        ConfigLoad {
                description("Config file not found")
                display("Unable to read configuration file oration.yaml")
        }
        ConfigParse {
            description("Error parsing config")
            display("an error occurred trying to parse the configuratation file")
        }
        Deserialize {
                description("Cannot deserialize data")
                display("Unable to deserialize data to required struct")
        }
        NoHTTPHandle {
                description("No HTTP handle")
                display("The configuration parameter 'host' requires either a http:// or https:// prefix")
        }
    }
}
