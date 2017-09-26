use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;
use chrono::{NaiveDateTime, Utc};

use schema::comments;
use errors::*;

#[derive(Queryable, Debug)]
/// Queryable reference to the comments table.
pub struct Comment {
    /// Primary key.
    id: i32,
    /// Reference to Thread.
    tid: i32, //TODO: Diesel parsed this as a bool. Write up a new issue.
    /// Parent comment.
    parent: Option<i32>,
    /// Timestamp of creation.
    created: NaiveDateTime,
    /// Date modified it that's happened.
    modified: Option<NaiveDateTime>,
    /// If the comment is live or under review.
    mode: i32,
    /// Remote IP.
    remote_addr: Option<String>,
    /// Actual comment.
    text: String,
    /// Commentors author if given.
    author: Option<String>,
    /// Commentors email address if given.
    email: Option<String>,
    /// Commentors website if given.
    website: Option<String>,
    /// Number of likes a comment has recieved.
    likes: Option<i32>,
    /// Number of dislikes a comment has recieved.
    dislikes: Option<i32>,
    /// Who are the voters on this comment.
    voters: String,
}

#[derive(Insertable, Debug)]
#[table_name = "comments"]
/// Insertable reference to the comments table.
struct NewComment<'c> {
    /// Reference to Thread.
    tid: i32,
    /// Parent comment.
    parent: Option<i32>,
    /// Timestamp of creation.
    created: NaiveDateTime,
    /// Date modified it that's happened.
    modified: Option<NaiveDateTime>,
    /// If the comment is live or under review.
    mode: i32,
    /// Remote IP.
    remote_addr: Option<String>,
    /// Actual comment.
    text: &'c str,
    /// Commentors author if given.
    author: Option<&'c str>,
    /// Commentors email address if given.
    email: Option<&'c str>,
    /// Commentors website if given.
    website: Option<&'c str>,
    /// Number of likes a comment has recieved.
    likes: Option<i32>,
    /// Number of dislikes a comment has recieved.
    dislikes: Option<i32>,
    /// Who are the voters on this comment.
    voters: String,
}

impl Comment {
    /// Returns the number of comments for a given post denoted via the `path` variable.
    pub fn count(conn: &SqliteConnection, path: &str) -> Result<i64> {
        use schema::threads;

        let comment_count = comments::table
            .inner_join(threads::table)
            .filter(threads::uri.eq(path))
            .count()
            .first(conn)
            .chain_err(|| ErrorKind::DBRead)?;

        Ok(comment_count)
    }

    /// Stores a new comment into the database.
    pub fn new<'c>(
        conn: &SqliteConnection,
        tid: i32,
        data: &'c str,
        author: &'c str,
        email: &'c str,
        url: &'c str,
    ) -> Result<()> {
        let time = Utc::now().naive_utc();
        let auth = if author.is_empty() {
            None
        } else {
            Some(author)
        };
        let addr = if email.is_empty() { None } else { Some(email) };
        let web = if url.is_empty() { None } else { Some(url) };

        let c = NewComment {
            tid: tid,
            parent: None,
            created: time,
            modified: None,
            mode: 0,
            remote_addr: None,
            text: data,
            author: auth,
            email: addr,
            website: web,
            likes: None,
            dislikes: None,
            voters: "1".to_string(),
        };

        let result = diesel::insert(&c)
            .into(comments::table)
            .execute(conn)
            .is_ok();
        if result {
            Ok(())
        } else {
            Err(ErrorKind::DBInsert.into())
        }
    }
}
