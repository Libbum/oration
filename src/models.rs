use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;

use self::schema::*;
use self::schema::comments::dsl::{comments as all_comments};

mod schema {
    infer_schema!("env:DATABASE_URL");
}

#[table_name = "preferences"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
pub struct Preference {
    pub key: Option<String>,
    pub value: Option<String>
}

#[table_name = "threads"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
pub struct Thread {
    pub id: Option<i32>,
    pub uri: Option<String>,
    pub title: Option<String>
}

#[table_name = "comments"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
pub struct Comment {
    pub id: i32,
    pub tid: Option<i32>, // reference
    pub parent: Option<i32>,
    pub created: f32, //A date type perhaps
    pub modified: Option<f32>,
    pub mode: i32,
    pub remote_addr: Option<String>,
    pub text: String,
    pub author: Option<String>,
    pub email: Option<String>,
    pub website: Option<String>,
    pub likes: Option<i32>, // DEFAULT 0,
    pub dislikes: Option<i32>, // DEFAULT 0,
    pub voters: String //BLOB
}

#[derive(FromForm)]
pub struct Post {
    //Needs to be filled in
    pub comment: String,
}

impl Comment {
//    pub fn all(conn: &SqliteConnection) -> Vec<Comment> {
//        all_comments.order(comments::id.desc()).load::<Comment>(conn).unwrap()
//    }

    //pub fn insert(post: Post, conn: &SqliteConnection) -> bool {
    //    let c = Comment { id: None, text: Some(post.comment) }; //TODO: Finish
    //    diesel::insert(&c).into(comments::table).execute(conn).is_ok()
    //}

    pub fn delete_with_id(id: i32, conn: &SqliteConnection) -> bool {
        diesel::delete(all_comments.find(id)).execute(conn).is_ok()
    }
}
