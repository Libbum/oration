use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use rand::{OsRng, Rng};
use std::io;
use schema::preferences;

#[table_name = "preferences"]
#[derive(Serialize, Queryable, Identifiable, Debug, Clone)]
#[primary_key(key)]
/// Queryable, Insertable reference to the preferences table.
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
    pub fn set_session(conn: &SqliteConnection) -> bool {
        use schema::preferences::dsl::*; //TODO: It'd be nice if we didn't have to double up here.

        let hash = session_hash();
        let session = preferences.filter(key.eq("session-key"));
        diesel::update(session)
            .set(value.eq(hash.unwrap())) //TODO: Proper error handling on this.
            .execute(&*conn)
            .is_ok()
    }

    /// Returns the current session value from the database.
    pub fn get_session(conn: &SqliteConnection) -> String {
        use schema::preferences::dsl::*;

        let session = preferences
            .filter(key.eq("session-key")) //TODO: Maybe put .limit(1) here
            .load::<Preference>(&*conn)
            .expect("Error loading session hash");
        session[0].value.to_string() //TODO: We should error check here too - should not expect 1 result be defualt.
    }
}

/// Generates a random hash used as a session ID.
fn session_hash() -> Result<String, io::Error> {
    Ok(OsRng::new()?.gen_ascii_chars().take(24).collect())
}
