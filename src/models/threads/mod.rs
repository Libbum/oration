use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use schema::threads;
use errors::*;

#[derive(Serialize, Queryable, Debug)]
/// Queryable reference to the threads table.
pub struct Thread {
    /// Primary key
    pub id: i32,
    /// URI to the thread
    pub uri: String,
    /// Thread title
    pub title: Option<String>,
}

#[derive(Insertable, Debug)]
#[table_name = "threads"]
/// Insertable reference to the threads table.
struct NewThread<'t> {
    /// URI to the thread.
    uri: &'t str,
    /// Thread title.
    title: Option<&'t str>,
}

impl Thread {
    /// Returns the id and title of a thread from the database for a given URI.
    pub fn get_thread(conn: &SqliteConnection, find_uri: &str) -> Result<String> {
        use schema::threads::dsl::*;

        let thread_info = threads
            .filter(uri.eq(find_uri.to_string()))
            .load::<Thread>(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        if thread_info.len() == 1 {
            Ok(format!("{:?}", thread_info[0]))
        } else {
            Err(ErrorKind::NoThread(find_uri.to_string()).into())
        }
    }

    /// Returns the id of a thread from the database for a given URI.
    pub fn get_thread_id(conn: &SqliteConnection, find_uri: &str) -> Result<i32> {
        use schema::threads::dsl::*;

        let thread_info = threads
            .filter(uri.eq(find_uri.to_string()))
            .load::<Thread>(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        if thread_info.len() == 1 {
            Ok(thread_info[0].id)
        } else {
            Err(ErrorKind::NoThread(find_uri.to_string()).into())
        }
    }

    /// Returns true if the requested URI is in the database.
    pub fn contains_thread(conn: &SqliteConnection, find_uri: &str) -> Result<bool> {
        use schema::threads::dsl::*;

        let thread_info = threads
            .filter(uri.eq(find_uri))
            .load::<Thread>(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        if thread_info.len() == 1 {
            Ok(true)
        } else {
            Ok(false)
        }
    }

    /// Saves a new thread for URI into the database.
    pub fn create_thread<'t>(
        conn: &SqliteConnection,
        new_url: &'t str,
        new_title: Option<&'t str>,
    ) -> Result<bool> {

        let new_thread = NewThread {
            uri: new_url,
            title: new_title,
        };

        let result = diesel::insert(&new_thread)
            .into(threads::table)
            .execute(conn)
            .is_ok();
        Ok(result)
    }
}
