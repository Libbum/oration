#![feature(plugin)]
#![plugin(rocket_codegen)]

extern crate rocket;
extern crate rusqlite;

#[cfg(test)]
mod tests;

use rocket::State;
use rocket::response::NamedFile;
use rusqlite::{Connection, Error};
use std::io;
use std::path::{Path, PathBuf};
use std::sync::Mutex;


type DbConn = Mutex<Connection>;

fn init_database(conn: &Connection) {
    conn.execute("CREATE TABLE entries (
                  id              INTEGER PRIMARY KEY,
                  name            TEXT NOT NULL
                  )", &[])
        .expect("create entries table");

    conn.execute("INSERT INTO entries (id, name) VALUES ($1, $2)",
            &[&0, &"This Guy"])
        .expect("insert single entry into entries table");
}

#[get("/db")]
fn db_test(db_conn: State<DbConn>) -> Result<String, Error>  {
    db_conn.lock()
        .expect("db connection lock")
        .query_row("SELECT name FROM entries WHERE id = 0",
                   &[], |row| { row.get(0) })
}

#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("public/index.html")
}

#[get("/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("public/").join(file)).ok()
}

fn rocket() -> rocket::Rocket {
    // Open a new in-memory SQLite database.
    let conn = Connection::open_in_memory().expect("in memory db");

    // Initialize the `entries` table in the in-memory database.
    init_database(&conn);

    rocket::ignite().manage(Mutex::new(conn)).mount("/", routes![index, files, db_test])
}

fn main() {
    rocket().launch();
}
