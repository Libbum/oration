use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use errors::*;

#[derive(Serialize, Queryable, Debug)]
/// Queryable reference to the comments table.
pub struct Comment {
    /// Primary key.
    id: i32,
    /// Reference to Thread.
    tid: Option<i32>, //TODO: Diesel parsed this as a bool. Write up a new issue.
    /// Parent comment.
    parent: Option<i32>,
    /// Timestamp of creation.
    created: f32,
    /// Date modified it that's happened.
    modified: Option<f32>,
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

impl Comment {
    pub fn count(conn: &SqliteConnection, thread: Option<i32>) -> Result<usize> {
        use schema::comments::dsl::*;

        let comment_count = comments
            .filter(tid.eq(thread))
            .count()
            .execute(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        Ok(comment_count)
    }
////    pub fn all(conn: &SqliteConnection) -> Vec<Comment> {
////        all_comments.order(comments::id.desc()).load::<Comment>(conn).unwrap()
////    }
//
//    //pub fn insert(post: Post, conn: &SqliteConnection) -> bool {
//    //    let c = Comment { id: None, text: Some(post.comment) }; //TODO: Finish
//    //    diesel::insert(&c).into(comments::table).execute(conn).is_ok()
//    //}
//
//  //  pub fn delete_with_id(id: i32, conn: &SqliteConnection) -> bool {
//  //      diesel::delete(all_comments.find(id)).execute(conn).is_ok()
//   // }
}
