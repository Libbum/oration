use schema::*;

#[table_name = "threads"]
#[derive(Serialize, Queryable, Insertable, Debug, Clone)]
pub struct Thread {
    pub id: Option<i32>,
    pub uri: Option<String>,
    pub title: Option<String>
}

