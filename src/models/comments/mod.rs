//
//use schema::comments;
////use schema::comments::dsl::{comments as all_comments};
//
//#[table_name = "comments"]
//#[derive(Serialize, Queryable, Debug, Clone)]
//pub struct Comment {
//    pub id: i32,
//    pub tid: Option<i32>, // reference
//    pub parent: Option<i32>,
//    pub created: f32, //A date type perhaps
//    pub modified: Option<f32>,
//    pub mode: i32,
//    pub remote_addr: Option<String>,
//    pub text: String,
//    pub author: Option<String>,
//    pub email: Option<String>,
//    pub website: Option<String>,
//    pub likes: Option<i32>, // DEFAULT 0,
//    pub dislikes: Option<i32>, // DEFAULT 0,
//    pub voters: String //BLOB
//}
//
//impl Comment {
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
//}
