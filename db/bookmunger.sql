CREATE TABLE book(
         book_id INTEGER PRIMARY KEY ASC,
	 title TEXT UNIQUE NOT NULL,
	 file_name TEXT UNIQUE NOT NULL
	 );
	 
CREATE TABLE author(
         auth_id INTEGER PRIMARY KEY ASC,
         auth_name TEXT unique NOT NULL
	 );
	 
CREATE TABLE tag(
         tag_id INTEGER PRIMARY KEY ASC,
	 tag_name TEXT unique NOT NULL
	 );


CREATE TABLE book_author(
book_id INTEGER,
author_id INTEGER,
FOREIGN KEY(book_id) REFERENCES book(book_id),
FOREIGN KEY(author_id) REFERENCES author(auth_id)
);

CREATE TABLE book_tag(
book_id INTEGER,
tag_id INTEGER,
FOREIGN KEY(book_id) REFERENCES book(book_id),
FOREIGN KEY(tag_id) REFERENCES tag(tag_id)
);

