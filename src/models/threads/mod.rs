use schema::*;

#[table_name = "threads"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
/// Queryable, Insertable reference to the threads table.
pub struct Thread {
    /// Primary key
    pub id: Option<i32>,
    /// URI to the thread
    pub uri: Option<String>,
    /// Thread title
    pub title: Option<String>
}

