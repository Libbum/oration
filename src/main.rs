#![feature(plugin)]
#![plugin(rocket_codegen)]

extern crate rocket;
#[macro_use] extern crate diesel;
#[macro_use] extern crate diesel_codegen;
extern crate r2d2_diesel;
extern crate r2d2;

mod db;
mod static_files;
#[cfg(test)] mod tests;

use std::io;
use rocket::response::NamedFile;

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
