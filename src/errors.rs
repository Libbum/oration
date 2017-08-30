error_chain!{
    errors {
        CreateLog(path: String) {
                description("Cannot write log file")
                display("Unable to write log file `{}`", path)
        }
        SessionHash {
                description("Cannot generate session hash")
                display("Unable to generate a session hash")
        }
        NoSession {
                description("Cannot read session info")
                display("Unable to read session information from database")
        }
        DBRead {
                description("Cannot parse db response")
                display("Unable to parse response from database query")
        }
        Rand {
                description("Cannot generate random number")
                display("Unable to call /dev/urandom")
        }
    }
}
