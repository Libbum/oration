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
        Unauthorized {
                description("Cannot identify user")
                display("Unable to complete request without correct authorization")
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
        EmptySMTP {
                description("Invalid SMTP configuration")
                display("Email notifications have been enabled, but one or more of the SMTP server configuration options are empty.")
        }
        EmptyRecipientEmail {
                description("Invalid Recipient configuration")
                display("Email notifications have been enabled, but no email address has been given to send notifications to.")
        }
        Request {
                description("HTTP request failed")
                display("Could not generate HTTP request")
        }
        PathCheckFailed {
                description("Requested path does not exist")
                display("Could not find path on blog server")
        }
        BuildEmail {
                description("Failed to build email")
                display("Could not construct notification email")
        }
        SendEmail {
                description("Failed to send email")
                display("Could not send notification email")
        }
        BuildSmtpTransport {
                description("Failed SMTP handshake")
                display("Could not attach to SMTP server")
        }
    }
}
