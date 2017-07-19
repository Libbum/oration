#![feature(plugin, custom_derive)]
#![plugin(rocket_codegen)]

extern crate rocket;
extern crate serde_json;
#[macro_use] extern crate serde_derive;
#[macro_use] extern crate diesel;
#[macro_use] extern crate diesel_codegen;
extern crate r2d2_diesel;
extern crate r2d2;

mod db;
mod models;
mod static_files;
#[cfg(test)] mod tests;

use std::io;
use rocket::response::NamedFile;

use models::{Preference};

#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("public/index.html")
}

fn rocket() -> rocket::Rocket {
    rocket::ignite().manage(db::init_pool()).mount("/", routes![index, static_files::files])
}

fn main() {
    rocket().launch();
}
