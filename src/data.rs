use rocket::http::Status;
use rocket::request::{self, FromRequest, Request};
use rocket::Outcome;

//NOTE: we can use FormInput<'c>, url: &'c RawStr, for unvalidated data if/when we need it.
#[derive(Debug, FromForm)]
/// Incoming data from the web based form for a new comment.
pub struct FormInput {
    /// Comment from textarea.
    pub comment: String,
    /// Parent comment if any.
    pub parent: Option<i32>,
    /// Optional name.
    pub name: Option<String>,
    /// Optional email.
    pub email: Option<String>,
    /// Optional website.
    pub url: Option<String>,
    /// Title of post.
    pub title: String,
    /// Path of post.
    pub path: String,
}

impl FormInput {
    /// Yields the senders name with a default if is empty.
    pub fn sender_name(&self) -> String {
        self.name
            .to_owned()
            .unwrap_or_else(|| "anonymous".to_string())
    }

    /// Yields the senders email address with a default if is empty.
    pub fn sender_email(&self) -> String {
        self.email
            .to_owned()
            .unwrap_or_else(|| "noreply@dev.null".to_string())
    }
}

#[derive(Debug, FromForm)]
/// Incoming data from the web based form for an edited comment.
pub struct FormEdit {
    /// Comment from textarea.
    pub comment: String,
    /// Optional name.
    pub name: Option<String>,
    /// Optional email.
    pub email: Option<String>,
    /// Optional website.
    pub url: Option<String>,
}

/// Hash of the user which wants to edit/delete a comment
#[derive(PartialEq)]
pub struct AuthHash(String);

impl<'a, 'r> FromRequest<'a, 'r> for AuthHash {
    type Error = ();

    fn from_request(request: &'a Request<'r>) -> request::Outcome<AuthHash, ()> {
        let keys: Vec<_> = request.headers().get("x-auth-hash").collect();
        if keys.len() != 1 {
            return Outcome::Failure((Status::BadRequest, ()));
        }

        let key = keys[0];
        return Outcome::Success(AuthHash(key.to_string()));
    }
}

impl AuthHash {
    pub fn matches(&self, compare: &str) -> bool {
        let &AuthHash(ref hash) = self;
        if hash == compare {
            true
        } else {
            false
        }
    }
}
