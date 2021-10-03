;;#! /gnu/store/q8brh7j5mwy0hbrly6hjb1m3wwndxqc8-guile-3.0.5/bin/guile \
;;-e main -s
;;!#

;; comma delimitted authors, first last names
;; expecting Title Of Book by Fname M. Lname, Fname2 Lname2 (z-lib.org).epub
;; expecting Swing By Me byy Fname M. Lname, Fname2 Lname2 (z-lib.org).epub


(add-to-load-path "/home/mbc/projects/bookmunger")
(load "/home/mbc/projects/bookmunger/curses.scm")

 ;;(add-to-load-path "/home/admin/projects")

(use-modules 
	     (srfi srfi-19)   ;; date time
	     (srfi srfi-1)  ;;list searching; delete-duplicates in list 
	     (srfi srfi-9)  ;;records
	     (ice-9 rdelim)
	     (ice-9 i18n)   ;; internationalization
	     (ice-9 popen)
	     (ice-9 regex) ;;list-matches
	     (ice-9 receive)
	     (ice-9 format)
	     (ice-9 string-fun)  ;;string-replace-substring
	     (ice-9 pretty-print)
	     (ice-9 textual-ports)
	     (ice-9 ftw) ;; file tree walk
	     (ice-9 readline)
	     (bookmunger utilities)
	     (bookmunger logging)   ;; logging is in guile-lib
             (logging logger)
             (logging rotating-log)
             (logging port-log)
	     (sxml simple)
	     (dbi dbi)
	     
	     )

(define book-count 0)

(define lib-dir "/home/mbc/temp/lib/") ;; home of library XML
(define lib-backup-dir "/home/mbc/temp/lib/backups/") ;;
(define on-deck-dir "/home/mbc/temp/lib/on-deck/")  ;; out of z-lib ready to have z-lib removed
(define dest-dir "/home/mbc/temp/lib/finalmod/") ;; final destination directory probably ~/syncd/library/files
(define lib-file-name "a-lib.reflib")


(define tags '((0 . "fiction")	(1 . "nonfiction")(2 . "technical")(3 . R)(4 . "statistics")(5 . "Bayes")(6 . "popgen")(7 . "gametheory")(9 . "bitcoin")(10 . "genetics")(11 . "work")(12 . "admixture")(13 . "DOE")(14 . "manuals")(15 . "programming")(16 . "math")(17 . "smalltalk")(18 . "history")(19 . "philosophy")(20 . "guile/guix")))


(define (remove-zlib str)
  (let* ((dot (string-rindex str #\.)) ;;reverse search
	 (name (substring str 0  dot ))
	 (len (length (string->list name)))
	 (a (substring name (- len 12) len))
	 (is-it-zlib? (string= " (z-lib.org)" a)))
    (if is-it-zlib?
	(let* ((len2 (length (string->list str)))
	       (ext (substring str dot len2))  ;;inlcudes the .
	       (new-name (substring name 0 (- len 12))))
	  (string-append new-name ext))
	str)))


(define (recurse-get-auth-ids auths ids)
  (if (null? (cdr auths))
      (let* ((a (dbi-query db-obj (string-append "select auth_id from author where auth_name LIKE '" (car auths) "'")))
	     (b (dbi-get_row db-obj))
	     (c (if b (assoc-ref b "auth_id")
		    (begin
		      (dbi-query db-obj (string-append "insert into author ('auth_name') values('"  (car auths) "')"))
		      (dbi-query db-obj (string-append "select auth_id from author where auth_name LIKE '" (car auths) "'"))
		      (assoc-ref (dbi-get_row db-obj) "auth_id"))))
	     (dummy (set! ids (cons c ids))))
	ids)
       (let* ((a (dbi-query db-obj (string-append "select auth_id from author where auth_name LIKE '" (car auths) "'")))
	     (b (dbi-get_row db-obj))
	     (c (if b (assoc-ref b "auth_id")
		    (begin
		      (dbi-query db-obj (string-append "insert into author ('auth_name') values('"  (car auths) "')"))
		      (dbi-query db-obj (string-append "select auth_id from author where auth_name LIKE '" (car auths) "'"))
		      (assoc-ref (dbi-get_row db-obj) "auth_id"))))
	     (dummy (set! ids (cons c ids))))
	(recurse-get-auth-ids (cdr auths) ids))))





(define (get-author-ids arg)
  ;;for a string of , delimitted authors get the ids
  ;;beware of last, first authors - must be edited
  ;;add to database if needed
  (let*((trimmed (string-trim-both arg))
	(auth-lst (string-split trimmed #\,))
	(trimmed-auth-lst (map string-trim-both auth-lst))
	)
    (recurse-get-auth-ids trimmed-auth-lst '())))


(define (get-title-author-ids-filename str)
  ;; return a list '(title author-ids new-file-name)
  ;; if "by" is in the title, I will not extract author
  (let* ((len (length (string->list str)))
	 (dot (string-rindex str #\.)) ;;reverse search
	 (pref (substring str 0  dot ))
	 (len-pref (length (string->list pref)))
	 (suf (substring str dot len)) ;; includes .
	 (a (list-matches " by " pref))
	 (b (list-matches " byy " pref))
	 ;;test if a is length 1; if >1 by is in the title, use byy
	 (c (if (= (length a) 1) a b))
	 (start (match:start (car c)))
	 (end (match:end (car c)))
	 (title (substring pref 0 start))
	 (authors (substring pref end len-pref))
	 (auth-ids (get-author-ids authors))
	 (new-file-name (string-append title suf)) )
  `(,title ,auth-ids ,new-file-name) ))

;;(get-title-author-filename "some book the name by Peter LaPan (zlib.org).epub")


(define (add-auths-to-book book-id auth-ids)
  ;;book-id is integer
  ;;auth-ids is list of integers
  (if (null? (cdr auth-ids))
      (dbi-query db-obj (string-append "insert into book_author ('book_id','author_id') values(" (number->string book-id) "," (number->string (car auth-ids))  ")"))
      (begin
	(dbi-query db-obj (string-append "insert into book_author ('book_id','author_id') values(" (number->string book-id) "," (number->string (car auth-ids))  ")"))
	(add-auths-to-book book-id (cdr auth-ids)))))


(define (add-tags-to-book book-id tag-ids)
  ;;book-id is integer
  ;;auth-ids is list of integers
  (if (null? (cdr tag-ids))
      (dbi-query db-obj (string-append "insert into book_tag ('book_id','tag_id') values(" (number->string book-id) "," (number->string (car tag-ids))  ")"))
      (begin
	(dbi-query db-obj (string-append "insert into book_tag ('book_id','tag_id') values(" (number->string book-id) "," (number->string (car tag-ids))  ")"))
	(add-tags-to-book book-id (cdr tag-ids)))))
  

(define (add-book-to-db title auth-ids tag-ids filename)
  ;;authors and tags must already be in db for assigment with ids
  (let* ((a (dbi-query db-obj (string-append "insert into book ('title','file_name') values('" title "','" filename "')")))
	 (b (dbi-query db-obj (string-append "select book_id from book where title LIKE '"title "'")))
	 (book-id (assoc-ref (dbi-get_row db-obj) "book_id"))
	 (c (add-auths-to-book book-id auth-ids))
	 (d (add-tags-to-book book-id tag-ids))
	 )
  book-id  ))


(define (make-lib-backup)
 ;;lib-dir "/home/mbc/temp/lib/" ;; home of library XML
 ;;lib-backup-dir "/home/mbc/temp/lib/backups/" ;;
 ;;lib-file-name "a-lib.reflib"
  (let*((pref (date->string  (current-date) "~Y~m~d~I~M"))
	(backup-file-name (string-append lib-backup-dir pref "-" lib-file-name ))
	(working-file-name (string-append lib-dir lib-file-name))
	(command (string-append "cp " working-file-name " " backup-file-name)))
    (system command)))


(define (get-all-books-as-string lst out)
  (if (null? (cdr lst))
      (begin
	(set! out (string-append (car lst) "\n" out))
	out)
      (begin
	(set! out (string-append (car lst) "\n" out))
	(get-all-books-as-string (cdr lst) out))))




(define (get-all-tags-as-string)
  (let* ( (a   (dbi-query db-obj "SELECT * FROM tag")  )
	  (b "")
	  (counter 0)
	  (ret (dbi-get_row db-obj))
	  (dummy (while (not (equal? ret #f))
		   (begin
		     (set! counter (+ counter 1))
		     (set! b (string-append b  (number->string (assoc-ref ret "tag_id")) ":" (assoc-ref ret "tag_name") "  " (if (= 0 (euclidean-remainder counter 8)) "\n" "" )))
		     (set! ret (dbi-get_row db-obj))))))
	  b ))



(define (process-file f)
  (let* ((a (remove-zlib f))
	 (b (get-title-author-ids-filename a))
	 (title (car b))
	 (auth-ids (cadr b))
	 (filename (caddr b))
	 (old-fname (string-append on-deck-dir f))
	 (new-fname (string-append dest-dir filename))
	 (c (add-book-to-db (car b) (cadr b) '(3 4) (caddr b)))
	 (d (rename-file old-fname new-fname ))
	 (e (set! book-count (+ book-count 1)))
	 )
    
#t  ))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; database
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define db-obj (dbi-open "sqlite3" "/home/mbc/projects/bookmunger/db/book.db"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define (main args)
  (let* ((start-time (current-time time-monotonic))
	 (dummy2 (log-msg 'CRITICAL (string-append "Starting up at: "  (number->string (time-second start-time)))))
	 (all-files (cddr (scandir on-deck-dir)))
	 
	 ;; (results (get-all-books-as-string  all-files ""))
	 ;; (results (get-all-tags-as-string))
	 (results (prompt-list))
 	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 (dummy3 (log-msg 'INFO (string-append "Elapsed time: " (number->string   elapsed-time) " minutes.")))
	 (dummy4 (log-msg 'INFO (string-append "Book count: " (number->string  book-count) )))
	 (dummy5 (shutdown-logging))
	 )
  (pretty-print results))    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    )
