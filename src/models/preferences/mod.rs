use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use rand::{OsRng, Rng};
use std::io;
use schema::preferences;

#[table_name = "preferences"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
/// Queryable, Insertable reference to the preferences table.
pub struct Preference {
    /// Key
    pub key: Option<String>,
    /// Value
    pub value: Option<String>,
}

impl Preference {
    /// Inserts a sesssion key into the database only if the key does not exist.
    pub fn set_session(conn: &SqliteConnection) -> bool {

        let hash = session_hash();
        let session = Preference {
            key: Some("session-key".to_string()),
            value: Some(hash.unwrap()),
        };
        println!("Starting session {:?}", session);
        diesel::insert(&session)
            .into(preferences::table)
            .execute(&*conn)
            .is_ok()
    }
}

/// Generates a random hash used as a session ID.
fn session_hash() -> Result<String, io::Error> {
    Ok(OsRng::new()?.gen_ascii_chars().take(24).collect())
}

