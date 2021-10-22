CREATE TABLE book(
         id INTEGER PRIMARY KEY ASC,
	 title TEXT UNIQUE NOT NULL,
	 file_name TEXT UNIQUE NOT NULL
	 );
	 
CREATE TABLE author(
         id INTEGER PRIMARY KEY ASC,
         author_name TEXT unique NOT NULL
	 );
	 
CREATE TABLE tag(
         id INTEGER PRIMARY KEY ASC,
	 tag_name TEXT unique NOT NULL
	 );

CREATE TABLE suffix(
         id INTEGER PRIMARY KEY ASC,
	 suffix_name TEXT unique NOT NULL
	 );

CREATE TABLE book_author(
book_id INTEGER,
author_id INTEGER,
FOREIGN KEY(book_id) REFERENCES book(id),
FOREIGN KEY(author_id) REFERENCES author(id)
);

CREATE TABLE book_tag(
book_id INTEGER,
tag_id INTEGER,
FOREIGN KEY(book_id) REFERENCES book(id),
FOREIGN KEY(tag_id) REFERENCES tag(id)
);


INSERT INTO tag (tag_name) VALUES ('fiction');
INSERT INTO tag (tag_name) VALUES ('nonfiction');
INSERT INTO tag (tag_name) VALUES ('technical');
INSERT INTO tag (tag_name) VALUES ('r');
INSERT INTO tag (tag_name) VALUES ('statistics');
INSERT INTO tag (tag_name) VALUES ('Bayes');
INSERT INTO tag (tag_name) VALUES ('popgen');
INSERT INTO tag (tag_name) VALUES ('gametheory');
INSERT INTO tag (tag_name) VALUES ('bitcoin');
INSERT INTO tag (tag_name) VALUES ('genetics');
INSERT INTO tag (tag_name) VALUES ('work');
INSERT INTO tag (tag_name) VALUES ('admixture');
INSERT INTO tag (tag_name) VALUES ('DOE');
INSERT INTO tag (tag_name) VALUES ('manuals');
INSERT INTO tag (tag_name) VALUES ('programming');
INSERT INTO tag (tag_name) VALUES ('math');
INSERT INTO tag (tag_name) VALUES ('smalltalk');
INSERT INTO tag (tag_name) VALUES ('history');
INSERT INTO tag (tag_name) VALUES ('philosophy');
INSERT INTO tag (tag_name) VALUES ('guile/guix');
INSERT INTO tag (tag_name) VALUES ('agriculture');

INSERT INTO suffix (suffix_name) VALUES ('(z-lib.org)');


