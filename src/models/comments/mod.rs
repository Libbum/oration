use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;
use chrono::{NaiveDateTime, Utc};
use crypto::digest::Digest;
use crypto::sha2::Sha224;
use itertools::join;

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
    /// Commentors idenifier hash.
    hash: String,
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
    remote_addr: Option<&'c str>,
    /// Actual comment.
    text: &'c str,
    /// Commentors author if given.
    author: Option<String>,
    /// Commentors email address if given.
    email: Option<String>,
    /// Commentors website if given.
    website: Option<String>,
    /// Sha224 hash to identify commentor.
    hash: String,
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
        author: Option<String>,
        email: Option<String>,
        url: Option<String>,
        ip_addr: &'c str,
    ) -> Result<()> {
        let time = Utc::now().naive_utc();

        let ip = if ip_addr.is_empty() {
            None //TODO: I wonder if this is ever true?
        } else {
            Some(ip_addr)
        };

        // Generate users sha224 hash
        let mut hasher = Sha224::new();
        //TODO: This section is pretty nasty at the moment.
        //There has to be a better way to organise this.
        let is_data = {
            let user = [&author, &email, &url];
            if user.into_iter().any(|&v| v.is_some()) {
                true
            } else {
                false
            }
        };
        if is_data {
            let mut data: Vec<String> = Vec::new();
            if let Some(val) = author.clone() {
                data.push(val)
            };
            if let Some(val) = email.clone() {
                data.push(val)
            };
            if let Some(val) = url.clone() {
                data.push(val)
            };
            hasher.input_str(&join(data.iter(), "b"));
        } else {
            hasher.input_str(&ip_addr);
        }
        let hash = hasher.result_str();

        let c = NewComment {
            tid: tid,
            parent: None,
            created: time,
            modified: None,
            mode: 0,
            remote_addr: ip,
            text: data,
            author: author,
            email: email,
            website: url,
            hash: hash,
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


#[derive(Serialize, Queryable, Debug)]
/// Subset of the comments table which is to be sent to the frontend.
/// Very cut down for the moment (i.e. proof of concept).
pub struct PrintedComment {
    /// Actual comment.
    text: String,
    /// Commentors author if given.
    author: Option<String>,
    /// Commentors indentifier.
    hash: String,
}

impl PrintedComment {
    /// Returna a list of all comments for a give post denoted via the `path` variable.
    pub fn list(conn: &SqliteConnection, path: &str) -> Result<Vec<PrintedComment>> {
        use schema::threads;

        let comments: Vec<PrintedComment> = comments::table
            .select((comments::text, comments::author, comments::hash))
            .inner_join(threads::table)
            .filter(threads::uri.eq(path).and(comments::mode.eq(0))) //TODO: This is default, but we need to set a flag to 'enable' comments at some stage
            .load(conn)
            .chain_err(|| ErrorKind::DBRead)?;

        Ok(comments)
    }
}
