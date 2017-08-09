use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use rand::{OsRng, Rng};
use std::io;
use schema::preferences;

#[table_name = "preferences"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
pub struct Preference {
    pub key: Option<String>,
    pub value: Option<String>,
}

impl Preference {
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

fn session_hash() -> Result<String, io::Error> {
    Ok(OsRng::new()?.gen_ascii_chars().take(24).collect())
}

