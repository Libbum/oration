CREATE TABLE preferences (
    key VARCHAR PRIMARY KEY NOT NULL,
    value VARCHAR NOT NULL
);

CREATE TABLE threads (
    id INTEGER PRIMARY KEY NOT NULL,
    uri VARCHAR(256) UNIQUE NOT NULL,
    title VARCHAR(256)
);

CREATE TABLE comments (
    id INTEGER PRIMARY KEY NOT NULL,
    tid REFERENCES threads(id),
    parent INTEGER,
    created DATETIME NOT NULL,
    modified DATETIME,
    mode INTEGER NOT NULL,
    remote_addr VARCHAR,
    text VARCHAR NOT NULL,
    author VARCHAR,
    email VARCHAR,
    website VARCHAR,
    hash VARCHAR NOT NULL,
    likes INTEGER DEFAULT 0,
    dislikes INTEGER DEFAULT 0,
    voters VARCHAR NOT NULL
);

CREATE TRIGGER remove_stale_threads AFTER DELETE ON comments BEGIN
    DELETE FROM threads WHERE id NOT IN (SELECT tid FROM comments);
END;

INSERT INTO preferences (key, value) VALUES ('session-key', '0000');
