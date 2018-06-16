use super::rocket;
use diesel::prelude::*;
use rocket::http::Status;
use rocket::local::Client;
use schema::preferences::dsl::*;

#[test]
/// Tests connection to the database through the pool managed by rocket.
fn db_connection() {
    let conn = rocket().1;

    let expected_keys = vec!["session-key"];
    let actual_keys: Vec<String> = preferences.select(key).load(&*conn).unwrap();

    assert_eq!(expected_keys, actual_keys);
}

#[test]
/// Compares the session hash in the database to the one returned by /session
fn session_hash() {
    let (rocket, conn, _) = rocket();
    let client = Client::new(rocket).expect("valid rocket instance");
    let mut response = client.get("/oration/session").dispatch();

    let session_key: Vec<String> = preferences
        .filter(key.eq("session-key"))
        .select(value)
        .load(&*conn)
        .unwrap();

    assert_eq!(response.status(), Status::Ok);
    assert_eq!(response.body_string().unwrap(), session_key[0]);
}
