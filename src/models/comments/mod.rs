use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;
use chrono::{NaiveDateTime, Utc};
use crypto::digest::Digest;
use crypto::sha2::Sha224;
use itertools::join;
use petgraph::graphmap::DiGraphMap;

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
    pub fn insert<'c>(
        conn: &SqliteConnection,
        tid: i32,
        parent: Option<i32>,
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
            user.into_iter().any(|&v| v.is_some())
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
            hasher.input_str(ip_addr);
        }
        let hash = hasher.result_str();

        let c = NewComment {
            tid: tid,
            parent: parent,
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
struct PrintedComment {
    /// Primary key.
    id: i32,
    /// Parent comment.
    parent: Option<i32>,
    /// Actual comment.
    text: String,
    /// Commentors author if given.
    author: Option<String>,
    /// Commentors indentifier.
    hash: String,
    /// Timestamp of creation.
    created: NaiveDateTime,
}

impl PrintedComment {
    /// Returns a list of all comments for a given post denoted via the `path` variable.
    fn list(conn: &SqliteConnection, path: &str) -> Result<Vec<PrintedComment>> {
        use schema::threads;

        let comments: Vec<PrintedComment> = comments::table
            .select((comments::id, comments::parent, comments::text, comments::author, comments::hash, comments::created))
            .inner_join(threads::table)
            .filter(threads::uri.eq(path).and(comments::mode.eq(0))) //TODO: This is default, but we need to set a flag to 'enable' comments at some stage
            .load(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        Ok(comments)
    }
}

#[derive(Serialize, Debug)]
/// Subset of the comments table which is to be nested and sent to the frontend.
pub struct NestedComment {
    /// Primary key.
    id: i32,
    /// Actual comment.
    text: String,
    /// Commentors author if given.
    author: Option<String>,
    /// Commentors indentifier.
    hash: String,
    /// Timestamp of creation.
    created: NaiveDateTime,
    /// Comment children.
    children: Option<Vec<NestedComment>>,
}

impl NestedComment {
    /// Creates a new nested comment from a PrintedComment and a set of precalculated NestedComment children.
    fn new(comment: &PrintedComment, children: Option<Vec<NestedComment>>) -> NestedComment {
        NestedComment {
            id: comment.id,
            text: comment.text.to_owned(),
            author: comment.author.to_owned(),
            hash: comment.hash.to_owned(),
            created: comment.created,
            children: children,
        }
    }

    /// Returns a list of all comments, nested, for a given post denoted via the `path` variable.
    pub fn list(conn: &SqliteConnection, path: &str) -> Result<Vec<NestedComment>> {
        // Pull data from DB
        let comments = PrintedComment::list(conn, path)?;

        let mut graph = DiGraphMap::new();
        let mut top_level_ids = Vec::new();

        for comment in &comments {
            //For each comment, build a graph of parents and children
            graph.add_node(comment.id);

            //Generate edges if a relationship is found, stash as a root if not
            if let Some(parent_id) = comment.parent {
                    graph.add_node(parent_id);
                    graph.add_edge(parent_id, comment.id, ());
                } else {
                    top_level_ids.push(comment.id);
                }
        }

        //Run over all root comments, recursively filling their children as we go
        let tree: Vec<_> = top_level_ids
            .into_iter()
            .map(|id| build_tree(&graph, id, &comments))
            .collect();

        Ok(tree)
    }
}

/// Construct a nested comment tree from the flat indexed data obtained from the database.
fn build_tree(
    graph: &DiGraphMap<i32, ()>,
    id: i32,
    comments: &[PrintedComment],
) -> NestedComment {
    let children: Vec<NestedComment> = graph
        .neighbors(id)
        .map(|child_id| build_tree(graph, child_id, comments))
        .collect();

    //We can just unwrap here since the id value is always populated from a map over contents.
    let idx: usize = comments.iter().position(|c| c.id == id).unwrap();

    if !children.is_empty() {
        NestedComment::new(&comments[idx], Some(children))
    } else {
        NestedComment::new(&comments[idx], None)
    }
}
