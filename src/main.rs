//! Oration: a Rocket/Elm self hosted commenting system for static sites.
//!
//! Inspired by ![Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
//! However, the codebase is unmaintained and ![security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.
//! Oration aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.


#![cfg_attr(feature="clippy", feature(plugin))]
#![cfg_attr(feature="clippy", plugin(clippy))]
#![cfg_attr(feature="clippy", warn(missing_docs_in_private_items))]
#![cfg_attr(feature="clippy", warn(single_match_else))]

#![feature(plugin, custom_derive)]
#![plugin(rocket_codegen)]

extern crate dotenv;
extern crate rand;
extern crate rocket;
extern crate serde_json;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_codegen;
extern crate r2d2_diesel;
extern crate r2d2;

/// Handles the database connection pool.
mod db;
/// SQL <--> Rust inerop using Diesel.
mod models;
/// Verbose schema for the comment database.
mod schema;
/// Serves up static files through Rocket.
mod static_files;
/// Tests for the Rocket side of the app.
#[cfg(test)]
mod tests;

use std::io;
use rocket::response::NamedFile;
use models::preferences::Preference;

/// Serve up the index file, which ultimately launches the Elm app.
#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("public/index.html")
}

/// Test function that will ultimately initialise the session hash.
/// Currently this sets a new session every call but this obviously isn't
/// what we want once we get up and running.
#[get("/session")]
fn get_session(conn: db::Conn) -> String {
    let session = match Preference::get_session(&conn) {
        Ok(s) => s,
        Err(err) => {
            println!("Error: Failed to load session hash from database: {}", err);
            err.to_string()
        }
    };
    session
}

/// Ignite Rocket, connect to the database and start serving data.
/// Exposes a connection to the database so we can set the session on startup.
fn rocket() -> (rocket::Rocket, db::Conn) {
    let pool = db::init_pool();
    let conn = db::Conn(pool.get().expect("database connection for initialisation"));
    let rocket = rocket::ignite().manage(pool).mount(
        "/",
        routes![
            index,
            static_files::files,
            get_session,
        ],
    );

    (rocket, conn)
}

/// Application entry point.
fn main() {
    let (rocket, conn) = rocket();

    //Set the session info in the database
    match Preference::set_session(&conn) {
        Ok(b) => {
            if b == false {
                //TODO: Turn theses printlns into proper errors and logs.
                println!("Warning: Failed to set session hash");
            }
        }
        Err(err) => println!("Error: Failed to generate session hash: {}", err),
    };

    //Start the web service
    rocket.launch();
}
