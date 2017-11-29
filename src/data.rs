
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
        self.name.to_owned().unwrap_or_else(
            || "anonymous".to_string(),
        )
    }

    /// Yields the senders email address with a default if is empty.
    pub fn sender_email(&self) -> String {
        self.email.to_owned().unwrap_or_else(
            || "noreply@dev.null".to_string(),
        )
    }
}
