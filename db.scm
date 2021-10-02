

(use-modules (dbi dbi))

;; Log into the database.
(define db-obj (dbi-open "sqlite3" "/home/mbc/projects/bookmunger/db/book.db"))

(dbi-query db-obj "insert into book ( 'name') values( 'ola')")
(dbi-query db-obj "select * from book")
(write (dbi-get_row db-obj))

(define (add-tag t)

  )

(display db-obj) (newline)
