use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use reqwest;
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
                    verify_post(host, path)?;

                    //We didn't find an id, but there was no error from the db.
                    //Create one.
                    let opt_title = if title.is_empty() { None } else { Some(title) };

                    let tid = create(conn, path, opt_title)?;
                    Ok(tid)
                }
                _ => Err(err),
            }
        }
    }
}

/// Checks that the path posted actually exists on the host.
/// Should minimise the injection attack surface.
fn verify_post(host: &str, path: &str) -> Result<()> {
    // We use reqwest to handle the request for now, but may drop down to hyper later on.
    let res = reqwest::get(&format!("{}{}", host, path)).chain_err(|| {
        ErrorKind::Request
    })?;

    if res.status() == reqwest::StatusCode::Ok {
        Ok(())
    } else {
        Err(ErrorKind::PathCheckFailed.into())
    }
}

/// Saves a new thread for URI into the database. Returns the id of the new record.
fn create<'t>(
    conn: &SqliteConnection,
    new_url: &'t str,
    new_title: Option<&'t str>,
) -> Result<i32> {
    use schema::threads;

    let new_thread = NewThread {
        uri: new_url,
        title: new_title,
    };

    let result = diesel::insert_into(threads::table)
        .values(&new_thread)
        .execute(conn)
        .is_ok();

    if result {
        let thread_id = threads::table
            .select(threads::id)
            .order(threads::id.desc())
            .first::<i32>(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        Ok(thread_id)
    } else {
        Err(ErrorKind::DBInsert.into())
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
