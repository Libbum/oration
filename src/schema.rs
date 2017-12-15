table! {
    comments (id) {
        id -> Integer,
        tid -> Integer,
        parent -> Nullable<Integer>,
        created -> Timestamp,
        modified -> Nullable<Timestamp>,
        mode -> Integer,
        remote_addr -> Nullable<Text>,
        text -> Text,
        author -> Nullable<Text>,
        email -> Nullable<Text>,
        website -> Nullable<Text>,
        hash -> Text,
        likes -> Nullable<Integer>,
        dislikes -> Nullable<Integer>,
        voters -> Nullable<Binary>,
    }
}

table! {
    preferences (key) {
        key -> Text,
        value -> Text,
    }
}

table! {
    threads (id) {
        id -> Integer,
        uri -> Text,
        title -> Nullable<Text>,
    }
}

joinable!(comments -> threads (tid));
allow_tables_to_appear_in_same_query!(comments, threads);
