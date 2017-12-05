use diesel;
use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;
use diesel::types::{Integer, Text};
use diesel::expression::dsl::sql;
use chrono::{DateTime, NaiveDateTime, Utc};
use crypto::digest::Digest;
use crypto::sha2::Sha224;
use itertools::join;
use petgraph::graphmap::DiGraphMap;

use schema::comments;
use data::FormInput;
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
        form: &FormInput,
        ip_addr: &'c str,
        nesting_limit: u32,
    ) -> Result<InsertedComment> {
        let time = Utc::now().naive_utc();

        let ip = if ip_addr.is_empty() {
            None //TODO: I wonder if this is ever true?
        } else {
            Some(ip_addr)
        };

        let parent_id = nesting_check(conn, &form.parent, nesting_limit)?;
        let hash = gen_hash(&form.name, &form.email, &form.url, Some(ip_addr));

        let c = NewComment {
            tid: tid,
            parent: parent_id,
            created: time,
            modified: None,
            mode: 0,
            remote_addr: ip,
            text: &form.comment,
            author: form.name.clone(),
            email: form.email.clone(),
            website: form.url.clone(),
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
            //Return a NestedComment formated result of this entry to the front end
            let comment_id = comments::table
                .select(comments::id)
                .order(comments::id.desc())
                .first::<i32>(conn)
                .chain_err(|| ErrorKind::DBRead)?;
            let comment = PrintedComment::get(conn, comment_id)?;
            Ok(InsertedComment::new(&comment))
        } else {
            Err(ErrorKind::DBInsert.into())
        }
    }
}

/// Checks if this comment is nested too deep based on the configuration file value.
/// If so, don't allow this to happen and just post as a reply to the previous parent.
fn nesting_check(
    conn: &SqliteConnection,
    parent: &Option<i32>,
    nesting_limit: u32,
) -> Result<Option<i32>> {
    match *parent {
        Some(pid) => {
            //NOTE: UNION ALL and WITH RECURSIVE are currently not supported by diesel
            //https://github.com/diesel-rs/diesel/issues/33
            //https://github.com/diesel-rs/diesel/issues/356
            //So this is implemented in native SQL for the moment
            let query = sql::<Integer>(
                "WITH RECURSIVE node_ancestors(node_id, parent_id) AS (
                    SELECT id, id FROM comments WHERE id = ?
                UNION ALL
                    SELECT na.node_id, comments.parent
                    FROM node_ancestors AS na, comments
                    WHERE comments.id = na.parent_id AND comments.parent IS NOT NULL
                )
                SELECT COUNT(parent_id) AS depth FROM node_ancestors GROUP BY node_id;",
            );
            let parent_depth: Vec<i32> = query
                .bind::<Text, _>(pid.to_string())
                .load(conn)
                .chain_err(|| ErrorKind::DBRead)?;

            if parent_depth.is_empty() || parent_depth[0] <= nesting_limit as i32 {
                //We're fine to nest
                Ok(Some(pid as i32))
            } else {
                //We've hit the limit, reply to the current parent's parent only.
                let parents_parent: Option<i32> = comments::table
                    .select(comments::parent)
                    .filter(comments::id.eq(pid))
                    .first(conn)
                    .chain_err(|| ErrorKind::DBRead)?;
                Ok(parents_parent)
            }
        }
        None => Ok(None), //We don't need to worry about this check for new comments
    }
}

/// Generates a Sha224 hash of author details.
/// If none are set, then the possiblity of using a clients' IP address is available.
pub fn gen_hash(
    author: &Option<String>,
    email: &Option<String>,
    url: &Option<String>,
    ip_addr: Option<&str>,
) -> String {
    // Generate users sha224 hash
    let mut hasher = Sha224::new();
    //TODO: This section is pretty nasty at the moment.
    //There has to be a better way to organise this.
    let is_data = {
        //Check if any of the optional values have data in them
        let user = [&author, &email, &url];
        user.into_iter().any(|&v| v.is_some())
    };
    if is_data {
        //Generate a set of data to hash
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
        //Join with 'b' since it gives the author a nice identicon
        hasher.input_str(&join(data.iter(), "b"));
    } else if let Some(ip) = ip_addr {
        //If we have no data but an ip, hash the ip, otherwise return an empty string
        hasher.input_str(ip);
    } else {
        return String::default();
    }
    hasher.result_str()
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
    /// Commentors email address if given.
    email: Option<String>,
    /// Commentors website if given.
    url: Option<String>,
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
            .select((comments::id, comments::parent, comments::text, comments::author, comments::email, comments::website, comments::hash, comments::created))
            .inner_join(threads::table)
            .filter(threads::uri.eq(path).and(comments::mode.eq(0))) //TODO: This is default, but we need to set a flag to 'enable' comments at some stage
            .load(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        Ok(comments)
    }

    /// Returns a comment based on its' unique ID.
    pub fn get(conn: &SqliteConnection, id: i32) -> Result<PrintedComment> {
        let comment: PrintedComment = comments::table
            .select((
                comments::id,
                comments::parent,
                comments::text,
                comments::author,
                comments::email,
                comments::website,
                comments::hash,
                comments::created,
            ))
            .filter(comments::id.eq(id))
            .first(conn)
            .chain_err(|| ErrorKind::DBRead)?;
        Ok(comment)
    }
}

#[derive(Serialize, Debug)]
/// Subset of the comment which was just inserted. This data is needed to populate the frontend
/// without calling for a complete refresh.
pub struct InsertedComment {
    /// Primary key.
    id: i32,
    /// Parent comment.
    parent: Option<i32>,
    /// Commentors details.
    author: Option<String>,
}

impl InsertedComment {
    /// Creates a new nested comment from a PrintedComment and a set of precalculated NestedComment children.
    fn new(comment: &PrintedComment) -> InsertedComment {
        let author = get_author(&comment.author, &comment.email, &comment.url);
        InsertedComment {
            id: comment.id,
            parent: comment.parent,
            author: author,
        }
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
    created: DateTime<Utc>,
    /// Comment children.
    children: Vec<NestedComment>,
}

impl NestedComment {
    /// Creates a new nested comment from a PrintedComment and a set of precalculated NestedComment children.
    fn new(comment: &PrintedComment, children: Vec<NestedComment>) -> NestedComment {
        let date_time = DateTime::<Utc>::from_utc(comment.created, Utc);
        let author = get_author(&comment.author, &comment.email, &comment.url);
        NestedComment {
            id: comment.id,
            text: comment.text.to_owned(),
            author: author,
            hash: comment.hash.to_owned(),
            created: date_time,
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
fn build_tree(graph: &DiGraphMap<i32, ()>, id: i32, comments: &[PrintedComment]) -> NestedComment {
    let children: Vec<NestedComment> = graph
        .neighbors(id)
        .map(|child_id| build_tree(graph, child_id, comments))
        .collect();

    //We can just unwrap here since the id value is always populated from a map over contents.
    let idx: usize = comments.iter().position(|c| c.id == id).unwrap();

    if !children.is_empty() {
        NestedComment::new(&comments[idx], children)
    } else {
        NestedComment::new(&comments[idx], Vec::new())
    }
}

/// Generates a value for author depending on the completeness of the author profile.
fn get_author(
    author: &Option<String>,
    email: &Option<String>,
    url: &Option<String>,
) -> Option<String> {
    if author.is_some() {
        author.to_owned()
    } else if email.is_some() {
        //We want to parse the email address to keep it somewhat confidential.
        let real_email = email.to_owned().unwrap();
        let at_index = real_email.find('@').unwrap_or_else(|| real_email.len());
        let (user, domain) = real_email.split_at(at_index);
        let first_dot = domain.find('.').unwrap_or_else(|| domain.len());
        let (_, trailing) = domain.split_at(first_dot);

        let mut email_obf = String::new();
        email_obf.push_str(user);
        email_obf.push_str("@****");
        email_obf.push_str(trailing);
        Some(email_obf)
    } else {
        //This can be something or nothing, since we don't need te parse it it doesn't matter
        url.to_owned()
    }
}
