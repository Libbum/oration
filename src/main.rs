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
#[macro_use] extern crate serde_derive;
#[macro_use] extern crate diesel;
#[macro_use] extern crate diesel_codegen;
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
#[cfg(test)] mod tests;

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
fn run_session(conn: db::Conn) -> String {
    Preference::set_session(&conn);
    Preference::get_session(&conn)
}

/// Ignite Rocket, connect to the database and start serving data.
fn rocket() -> rocket::Rocket {
    rocket::ignite().manage(db::init_pool()).mount("/", routes![index, static_files::files, run_session])
}

/// Application entry point.
fn main() {
    rocket().launch();
}
