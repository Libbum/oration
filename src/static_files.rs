use rocket::response::NamedFile;
use std::path::{Path, PathBuf};

#[get("/<file..>")]
/// Call serves any requested static file from public.
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("public/").join(file)).ok()
}
