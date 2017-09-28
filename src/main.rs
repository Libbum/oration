//! Oration: a Rocket/Elm self hosted commenting system for static sites.
//!
//! Inspired by ![Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
//! However, the codebase is unmaintained and ![security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.
//! Oration aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.


#![cfg_attr(feature="clippy", feature(plugin))]
#![cfg_attr(feature="clippy", plugin(clippy))]
#![cfg_attr(feature="clippy", warn(missing_docs_in_private_items))]
#![cfg_attr(feature="clippy", warn(single_match_else))]

#![feature(plugin, custom_derive, use_extern_macros)]
#![plugin(rocket_codegen)]

// `error_chain!` can recurse deeply
#![recursion_limit = "1024"]

extern crate chrono;
extern crate dotenv;
#[macro_use]
extern crate error_chain;
extern crate rand;
extern crate rocket;
//extern crate serde_json;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_codegen;
extern crate r2d2_diesel;
extern crate r2d2;
extern crate yansi;
extern crate argon2rs;
extern crate reqwest;
extern crate serde_yaml;
#[macro_use(log)]
extern crate log;

/// Loads configuration data from disk.
mod config;
/// Handles the database connection pool.
mod db;
/// SQL <----> Rust inerop using Diesel.
mod models;
/// Verbose schema for the comment database.
mod schema;
/// Serves up static files through Rocket.
mod static_files;
/// Handles the error chain of the program.
mod errors;
/// Tests for the Rocket side of the app.
#[cfg(test)]
mod tests;

use std::io;
use std::net::SocketAddr;
use std::io::Cursor;
use rocket::http::Status;
use rocket::{State, Response};
use rocket::request::Form;
use rocket::response::NamedFile;
use models::preferences::Preference;
use models::comments::Comment;
use models::threads;
use std::process;
use yansi::Paint;
use config::Config;

/// Serve up the index file, which ultimately launches the Elm app.
#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("public/index.html")
}

//NOTE: we can use FormInput<'c>, url: &'c RawStr, for unvalidated data if/when we need it.
#[derive(Debug, FromForm)]
/// Incoming data from the web based form for a new comment.
struct FormInput {
    /// Comment from textarea.
    comment: String,
    /// Optional name.
    name: String,
    /// Optional email.
    email: String,
    /// Optional website.
    url: String,
    /// Title of post.
    title: String,
    /// Path of post.
    path: String,
}

/// Process comment input from form.
#[post("/", data = "<comment>")]
fn new_comment<'a>(
    conn: db::Conn,
    comment: Result<Form<FormInput>, Option<String>>,
    config: State<Config>,
    remote_addr: SocketAddr,
) -> Response<'a> {
    let mut response = Response::new();
    match comment {
        Ok(f) => {
            //If the comment form data is valid, proceed to comment insertion
            let form = f.into_inner();
            //Get thread id from the db, create if needed
            match threads::gen_or_get_id(&conn, &config.host, &form.title, &form.path) {
                Ok(tid) => {
                    if let Err(err) = Comment::new(
                        &conn,
                        tid,
                        &form.comment,
                        &form.name,
                        &form.email,
                        &form.url,
                        &remote_addr.ip().to_string(),
                    )
                    {
                        //Something went wrong, return a 500
                        log::warn!("{}", &err);
                        for e in err.iter().skip(1) {
                            log::warn!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
                        }
                        response.set_status(Status::InternalServerError);
                    } else {
                        //All good, 200
                        response.set_status(Status::Ok);
                        response.set_sized_body(Cursor::new("Comment recieved."));
                    }
                }
                Err(err) => {
                    //We didn't get the thread id
                    match err {
                        errors::Error(errors::ErrorKind::PathCheckFailed, _) => {
                            //The requsted path doesn't exist on the server
                            //Most likely an attempt at injecting junk into the db through the post method
                            response.set_status(Status::Forbidden)
                        }
                        _ => response.set_status(Status::InternalServerError),
                    }
                }
            }
        }
        Err(Some(f)) => {
            //The form request was malformed, 400
            response.set_status(Status::BadRequest);
            response.set_sized_body(Cursor::new(format!("Invalid form input: {}", f)));
        }
        Err(None) => {
            //Not UTF-8 encoded
            response.set_status(Status::BadRequest);
            response.set_sized_body(Cursor::new("Form input was invalid UTF8."));
        }
    }
    response
}

/// Gets a hash from a clients IP.
#[get("/hash")]
fn get_hash(config: State<Config>, remote_addr: SocketAddr) -> String {
    let ip_addr = remote_addr.ip().to_string();

    //This is not a password, so use the faster 2d variant
    let hash = argon2rs::argon2d_simple(&ip_addr, &config.salt);
    hash.iter().map(|b| format!("{:02x}", b)).collect()
}

/// Test function that returns the session hash from the database.
#[get("/session")]
fn get_session(conn: db::Conn) -> String {
    match Preference::get_session(&conn) {
        Ok(s) => s,
        Err(err) => {
            log::warn!("{}", err);
            for e in err.iter().skip(1) {
                log::warn!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
            }
            err.to_string()
        }
    }
}

#[derive(FromForm)]
/// Used in conjuction with `/count?`.
struct Post {
    /// Gets the url for the request.
    url: Option<String>,
}

/// Returns the comment count for a given post from the database.
#[get("/count?<post>")]
fn get_comment_count(conn: db::Conn, post: Post) -> String {
    //TODO: The logic here is not 100%, need to consider / vs /index.* and response to nulls etc
    let path = match post.url {
        Some(l) => l,
        None => "/".to_string(),
    };
    match Comment::count(&conn, &path) {
        Ok(s) => s.to_string(),
        Err(err) => {
            log::warn!("{}", err);
            for e in err.iter().skip(1) {
                log::warn!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
            }
            err.to_string()
        }
    }
}

/// Ignite Rocket, connect to the database and start serving data.
/// Exposes a connection to the database so we can set the session on startup.
fn rocket() -> (rocket::Rocket, db::Conn, String) {
    //Load configuration data from disk
    let config = match Config::load() {
        Ok(c) => c,
        Err(ref err) => {
            println!("Error loading configuration: {}", err);
            for e in err.iter().skip(1) {
                println!("caused by: {}", e);
            }
            process::exit(1);
        }
    };
    let host = config.host.clone();
    let pool = db::init_pool();
    let conn = db::Conn(pool.get().expect("database connection for initialisation"));
    let rocket = rocket::ignite().manage(pool).manage(config).mount(
        "/",
        routes![
            index,
            static_files::files,
            new_comment,
            get_hash,
            get_session,
            get_comment_count,
        ],
    );

    (rocket, conn, host)
}

/// Application entry point.
fn main() {
    //Initialise webserver routes and database connection pool
    let (rocket, conn, host) = rocket();

    //Set the session info in the database
    log::info!("💿  {}", Paint::purple("Saving session hash to database"));
    match Preference::set_session(&conn) {
        Ok(set) => {
            if !set {
                //TODO: This may need to be a crit as well. Unsure.
                log::warn!("Failed to set session hash");
            }
        }
        Err(err) => {
            log::error!("{}", err);
            for e in err.iter().skip(1) {
                log::error!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
            }
            process::exit(1);
        }
    };

    log::info!(
        "📢  {} {}",
        Paint::blue("Oration will serve comments to"),
        host
    );


    //Start the web service
    rocket.launch();
}
