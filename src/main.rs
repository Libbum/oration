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

mod db;
mod models;
mod schema;
mod static_files;
#[cfg(test)] mod tests;

use std::io;
use rocket::response::{NamedFile, Redirect};
use models::preferences::Preference;

#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("public/index.html")
}

#[get("/session")]
fn run_session(conn: db::Conn) -> Redirect {
    Preference::set_session(&conn);
    Redirect::to("/")
}

fn rocket() -> rocket::Rocket {
    rocket::ignite().manage(db::init_pool()).mount("/", routes![index, static_files::files, run_session])
}

fn main() {
    rocket().launch();
}
