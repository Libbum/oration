//! Oration: a Rocket/Elm self hosted commenting system for static sites.
//!
//! Inspired by ![Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
//! However, the codebase is unmaintained and ![security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.
//! Oration aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.

#![cfg_attr(
    feature = "cargo-clippy",
    warn(missing_docs_in_private_items)
)]
#![cfg_attr(feature = "cargo-clippy", warn(single_match_else))]
#![feature(plugin, custom_derive, use_extern_macros)]
#![plugin(rocket_codegen)]
// `error_chain!` can recurse deeply
#![recursion_limit = "1024"]

extern crate bincode;
extern crate chrono;
#[macro_use]
extern crate diesel;
extern crate dotenv;
#[macro_use]
extern crate error_chain;
extern crate petgraph;
extern crate r2d2;
extern crate r2d2_diesel;
extern crate rand;
extern crate rocket;
extern crate rocket_contrib;
#[macro_use]
extern crate serde_derive;
extern crate yansi;
//extern crate argon2rs;
extern crate bloomfilter;
extern crate crypto;
extern crate itertools;
#[macro_use]
extern crate lazy_static;
extern crate lettre;
extern crate lettre_email;
#[macro_use(log)]
extern crate log;
extern crate openssl_probe;
extern crate regex;
extern crate reqwest;
extern crate serde_yaml;

/// Loads configuration data from disk.
mod config;
/// Houses Data Structures that are needed in multiple modules.
mod data;
/// Handles the database connection pool.
mod db;
/// Handles the error chain of the program.
mod errors;
/// SQL <----> Rust inerop using Diesel.
mod models;
/// Sends notifications to admin.
mod notify;
/// Verbose schema for the comment database.
mod schema;
/// Serves up static files through Rocket.
mod static_files;
/// Tests for the Rocket side of the app.
#[cfg(test)]
mod tests;

use config::Config;
use crypto::digest::Digest;
use crypto::sha2::Sha224;
use data::{AuthHash, FormEdit, FormInput};
use errors::Error;
use models::comments::{self, Comment, CommentEdits, InsertedComment, NestedComment};
use models::preferences::Preference;
use models::threads;
use rocket::http::Status;
use rocket::request::Form;
use rocket::response::{status, Failure, NamedFile};
use rocket::State;
use rocket_contrib::Json;
use std::io;
use std::net::SocketAddr;
use std::process;
use yansi::Paint;

/// Serve up the index file. This is only useful for development. Should not be used in a release.
//TODO: Serve this some other way, we don't want oration doing this work.
#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("public/index.html")
}

/// Process comment input from form.
#[post("/oration", data = "<comment>")]
fn new_comment(
    conn: db::Conn,
    comment: Result<Form<FormInput>, Option<String>>,
    config: State<Config>,
    remote_addr: SocketAddr,
) -> Result<Json<InsertedComment>, Failure> {
    match comment {
        Ok(f) => {
            //If the comment form data is valid, proceed to comment insertion
            let form = f.into_inner();
            let ip_addr = remote_addr.ip().to_string();
            //Get thread id from the db, create if needed
            match threads::gen_or_get_id(&conn, &config.host, &form.title, &form.path) {
                Ok(tid) => {
                    match Comment::insert(&conn, tid, &form, &ip_addr, config.nesting_limit) {
                        Err(err) => {
                            //Something went wrong, return a 500
                            print_errors(&err);
                            Err(Failure(Status::InternalServerError))
                        }
                        Ok(comment) => {
                            //All good, return the comment
                            //Send notification to admin
                            if config.notifications.new_comment {
                                match notify::send_notification(
                                    &form,
                                    &config.notifications,
                                    &config.host,
                                    &config.blog_name,
                                    &ip_addr,
                                ) {
                                    Ok(_) => log::info!(
                                        "📧  {}",
                                        Paint::blue("New comment email notification sent.")
                                    ),
                                    Err(err) => {
                                        print_errors(&err);
                                    }
                                }
                            }
                            if config.telegram.push_notifications {
                                match notify::push_telegram(
                                    &form,
                                    &config.telegram,
                                    &config.host,
                                    &ip_addr,
                                ) {
                                    Ok(_) => log::info!(
                                        "📧  {}",
                                        Paint::blue(
                                            "New comment push notification sent to Telegram."
                                        )
                                    ),
                                    Err(err) => {
                                        print_errors(&err);
                                    }
                                }
                            }
                            Ok(Json(comment))
                        }
                    }
                }
                Err(err) => {
                    //We didn't get the thread id
                    print_errors(&err);
                    match err {
                        errors::Error(errors::ErrorKind::PathCheckFailed, _) => {
                            //The requsted path doesn't exist on the server
                            //Most likely an attempt at injecting junk into the db through the post method
                            Err(Failure(Status::Forbidden))
                        }
                        _ => Err(Failure(Status::InternalServerError)),
                    }
                }
            }
        }
        Err(_) => {
            //The form request was malformed, 400
            Err(Failure(Status::BadRequest))
        }
    }
}

/// Information sent to the client upon initialisation.
#[derive(Serialize)]
struct Initialise {
    /// The clients' ip address, hashed via Sha224.
    user_ip: String,
    /// The Sha224 hash of the blog author to distinguish the authority on this blog.
    blog_author: String,
    /// Time frame in which users can edit thier own comments.
    edit_timeout: f32,
}

/// Gets a Sha224 hash from a clients IP along with the blog's author hash.
#[get("/oration/init")]
fn initialise(remote_addr: SocketAddr, config: State<Config>) -> Json<Initialise> {
    let ip_addr = remote_addr.ip().to_string();
    // create a Sha224 object
    let mut hasher = Sha224::new();
    // write input message
    hasher.input_str(&ip_addr);

    let to_send = Initialise {
        user_ip: hasher.result_str(),
        blog_author: config.author.hash.to_owned(),
        edit_timeout: config.edit_timeout,
    };

    Json(to_send)
}

#[derive(FromForm, Copy, Clone)]
/// Used in conjuction with `/delete?` and `/edit?`.
struct CommentId {
    /// The id of the requested comment.
    id: i32,
}

/// Requests comment deletion from a user, may or may not actually delete the comment
/// based on a number of possibilities: authentication issues, over time, etc.
/// Secondarily, the method of deletion may differ. If the comment has children it
/// is not deleted entirely, but flagged so that the rest of the conversation is not
/// automatically pruned.
#[delete("/oration/delete?<identifier>")]
fn delete_comment(
    conn: db::Conn,
    config: State<Config>,
    identifier: CommentId,
    hash: AuthHash,
) -> Result<String, Failure> {
    if let Err(err) = comments::update_authorised(&conn, &hash, identifier.id, config.edit_timeout)
    {
        print_errors(&err);
        return Err(Failure(Status::Unauthorized));
    };
    match Comment::delete(&conn, identifier.id) {
        Ok(_) => Ok(identifier.id.to_string()),
        Err(err) => {
            print_errors(&err);
            Err(Failure(Status::NotFound))
        }
    }
}

/// Requests an update to a comment from a user, which may or may not occur
/// based on a number of possibilities: authentication issues, over time, etc.
#[post("/oration/edit?<identifier>", data = "<edits>")]
fn edit_comment(
    conn: db::Conn,
    config: State<Config>,
    identifier: CommentId,
    hash: AuthHash,
    edits: Result<Form<FormEdit>, Option<String>>,
    remote_addr: SocketAddr,
) -> Result<Json<CommentEdits>, Failure> {
    if let Err(err) = comments::update_authorised(&conn, &hash, identifier.id, config.edit_timeout)
    {
        print_errors(&err);
        return Err(Failure(Status::Unauthorized));
    };
    match edits {
        Ok(f) => {
            //If the comment form data is valid, proceed to updating the comment
            let form = f.into_inner();
            let ip_addr = remote_addr.ip().to_string();
            match Comment::update(&conn, identifier.id, &form, &ip_addr) {
                Ok(edits) => Ok(Json(edits)),
                Err(err) => {
                    print_errors(&err);
                    Err(Failure(Status::NotFound))
                }
            }
        }
        Err(_) => {
            //The form request was malformed or not UTF8 encoded: 400
            Err(Failure(Status::BadRequest))
        }
    }
}

/// Likes a comment so long as the current user has not done so already.
#[post("/oration/like?<identifier>")]
fn like_comment(
    conn: db::Conn,
    identifier: CommentId,
    remote_addr: SocketAddr,
) -> Result<String, status::Custom<String>> {
    let ip_addr = remote_addr.ip().to_string();
    match Comment::vote(&conn, identifier.id, &ip_addr, true) {
        Ok(_) => Ok(identifier.id.to_string()),
        Err(err) => {
            print_errors(&err);
            //TODO: A custom status with a Failure that doesn't require &'static strings
            Err(status::Custom(Status::Forbidden, identifier.id.to_string()))
        }
    }
}

/// Dislikes a comment so long as the current user has not done so already.
#[post("/oration/dislike?<identifier>")]
fn dislike_comment(
    conn: db::Conn,
    identifier: CommentId,
    remote_addr: SocketAddr,
) -> Result<String, status::Custom<String>> {
    let ip_addr = remote_addr.ip().to_string();
    match Comment::vote(&conn, identifier.id, &ip_addr, false) {
        Ok(_) => Ok(identifier.id.to_string()),
        Err(err) => {
            print_errors(&err);
            Err(status::Custom(Status::Forbidden, identifier.id.to_string()))
        }
    }
}

/// Test function that returns the session hash from the database.
#[get("/oration/session")]
fn get_session(conn: db::Conn) -> String {
    match Preference::get_session(&conn) {
        Ok(s) => s,
        Err(err) => {
            print_errors(&err);
            err.to_string()
        }
    }
}

#[derive(FromForm)]
/// Used in conjuction with `/count?` and `/comments?`.
struct Post {
    /// Gets the url for the request.
    url: String,
}

#[derive(Serialize)]
/// Comments to frontend
struct PostComments {
    /// A nested set of comments.
    comments: Vec<NestedComment>,
}

/// Return a json block of comment data for the requested url.
#[get("/oration/comments?<post>")]
fn get_comments(conn: db::Conn, post: Post) -> Option<Json<PostComments>> {
    //TODO: The logic here may not 100%, need to consider / vs /index.* for example.
    match NestedComment::list(&conn, &post.url) {
        Ok(comments) => {
            //We now have a vector of comments
            let to_send = PostComments { comments };
            Some(Json(to_send))
        }
        Err(err) => {
            print_errors(&err);
            None
        }
    }
}

/// Returns the comment count for a given post from the database.
#[get("/oration/count?<post>")]
fn get_comment_count(conn: db::Conn, post: Post) -> String {
    //TODO: The logic here may not 100%, need to consider / vs /index.* for example.
    match Comment::count(&conn, &post.url) {
        Ok(s) => s.to_string(),
        Err(err) => {
            print_errors(&err);
            err.to_string()
        }
    }
}

/// Prints the current error chain to the log file / stdio.
fn print_errors(err: &Error) {
    log::warn!("{}", err);
    for e in err.iter().skip(1) {
        log::warn!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
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
            process::exit(1)
        }
    };
    let host = config.host.clone();
    let pool = db::init_pool();
    let conn = match pool.get() {
        Ok(p) => db::Conn(p),
        Err(err) => {
            println!("Could not connect to database: {}", err);
            process::exit(1)
        }
    };
    let rocket = rocket::ignite().manage(pool).manage(config).mount(
        "/",
        routes![
            index, //TODO: index and static_files should not be managed by oration
            static_files::files,
            new_comment,
            delete_comment,
            edit_comment,
            like_comment,
            dislike_comment,
            initialise,
            get_session,
            get_comment_count,
            get_comments,
        ],
    );

    (rocket, conn, host)
}

/// Application entry point.
fn main() {
    openssl_probe::init_ssl_cert_env_vars();

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
            print_errors(&err);
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
