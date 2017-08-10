use std::path::{Path, PathBuf};
use rocket::response::NamedFile;

#[get("/<file..>")]
/// Call serves any requested static file from public.
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("public/").join(file)).ok()
}
