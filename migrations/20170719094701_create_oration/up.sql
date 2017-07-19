CREATE TABLE preferences (
    key VARCHAR PRIMARY KEY,
    value VARCHAR
);

CREATE TABLE threads (
    id INTEGER PRIMARY KEY,
    uri VARCHAR(256) UNIQUE,
    title VARCHAR(256)
);

CREATE TABLE comments (
    id INTEGER PRIMARY KEY,
    tid REFERENCES threads(id),
    parent INTEGER,
    created FLOAT NOT NULL,
    modified FLOAT,
    mode INTEGER,
    remote_addr VARCHAR,
    text VARCHAR,
    author VARCHAR,
    email VARCHAR,
    website VARCHAR,
    likes INTEGER DEFAULT 0,
    dislikes INTEGER DEFAULT 0,
    voters VARCHAR NOT NULL
);

CREATE TRIGGER remove_stale_threads AFTER DELETE ON comments BEGIN
    DELETE FROM threads WHERE id NOT IN (SELECT tid FROM comments);
END;
