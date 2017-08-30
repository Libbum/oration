use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use rand::{OsRng, Rng};
use std::io;
use schema::preferences;

#[table_name = "preferences"]
#[derive(Queryable, Identifiable)]
#[primary_key(key)]
/// Queryable, Identifiable reference to the preferences table.
pub struct Preference {
    /// Key
    pub key: String,
    /// Value
    pub value: String,
}

impl Preference {
    /// Updates the sesssion key into the database only if the key does not exist.
    /// A default value is set in the migration schema and no other functions operate
    /// on this entry, so that should cover all bases.
    pub fn set_session(conn: &SqliteConnection) -> Result<bool, io::Error> {
        use schema::preferences::dsl::*; //TODO: It'd be nice if we didn't have to double up here.

        let hash = session_hash()?;
        let session = preferences.filter(key.eq("session-key"));
        let result = diesel::update(session)
            .set(value.eq(hash))
            .execute(&*conn)
            .is_ok();
        Ok(result)
    }

    /// Returns the current session value from the database.
    pub fn get_session(conn: &SqliteConnection) -> Result<String, diesel::result::Error> {
        use schema::preferences::dsl::*;

        let session = preferences
            .filter(key.eq("session-key"))
            .limit(1) //This should always be the case, but just to be certain
            .load::<Preference>(&*conn)?;
        if session.len() == 1 {
            Ok(session[0].value.to_string())
        } else {
            Err(diesel::result::Error::NotFound)
        }
    }
}

/// Generates a random hash used as a session ID.
fn session_hash() -> Result<String, io::Error> {
    Ok(OsRng::new()?.gen_ascii_chars().take(24).collect())
}
