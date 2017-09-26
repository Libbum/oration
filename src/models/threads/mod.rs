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

/// Returns a thread ID given creation details about it.
/// If the thread exists, an ID is returned directly, otherwise an entry
/// is created for it first
pub fn gen_or_get_id(conn: &SqliteConnection, host: &str, title: &str, path: &str) -> Result<i32> {
    match get_id(conn, path) {
        //TODO: Maybe the id is the same, but the title has been updated.
        Ok(id) => Ok(id), //Found an id, return it
        Err(err) => {
            match err {
                Error(ErrorKind::NoThread(_), _) => {
                    //We didn't find an id, but there was no error from the db.
                    //Create one.
                    //TODO: Pehaps we need to verify what's coming from the frontend is true.
                    //does host+path exist on host?
                    let opt_title = if title.is_empty() { None } else { Some(title) };

                    let tid = create(conn, path, opt_title)?;
                    Ok(tid)
                }
                _ => Err(err),
            }
        }
    }
}

/// Saves a new thread for URI into the database. Returns the id of the new record.
fn create<'t>(
    conn: &SqliteConnection,
    new_url: &'t str,
    new_title: Option<&'t str>,
) -> Result<i32> {
    use schema::threads::dsl::{threads, id};

    let new_thread = NewThread {
        uri: new_url,
        title: new_title,
    };

    let result = diesel::insert(&new_thread)
        .into(threads)
        .execute(conn)
        .is_ok();

    if result {
        let thread_info = threads.order(id.desc()).first::<Thread>(conn).chain_err(
            || {
                ErrorKind::DBRead
            },
        )?;
        Ok(thread_info.id)
    } else {
        Err(ErrorKind::DBInsert.into())
    }
}

/// Returns the id and title of a thread from the database for a given URI.
fn get(conn: &SqliteConnection, find_uri: &str) -> Result<String> {
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
fn get_id(conn: &SqliteConnection, find_uri: &str) -> Result<i32> {
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
fn contains(conn: &SqliteConnection, find_uri: &str) -> Result<bool> {
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
