use super::rocket;
use rocket::testing::MockRequest;
use rocket::http::Method::*;

#[test]
fn db_test() {
    let rocket = rocket();
    let mut req = MockRequest::new(Get, "/db");
    let mut response = req.dispatch_with(&rocket);

    let body_str = response.body().and_then(|body| body.into_string());
    assert_eq!(body_str, Some("This Guy".to_string()));
}
