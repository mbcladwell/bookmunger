#! /gnu/store/6l9rix46ydxyldf74dvpgr60rf5ily0c-guile-3.0.7/bin/guile \
-L /gnu/store/hiiljpxr855z0w1ail01phv7vwq40s38-guile-dbi-2.1.6/share/guile/site/2.2 -e main -s
!#

;; comma delimitted authors, first last names
;; expecting Title Of Book by Fname M. Lname, Fname2 Lname2 (z-lib.org).epub


(add-to-load-path "/home/mbc/projects/bookmunger")
(add-to-load-path "/gnu/store/va6l1ivclww22fi38w5h99pb4ndn99hg-guile-readline-3.0.2/share/guile/site/3.0")

(use-modules 
	     (srfi srfi-19)   ;; date time
	     (srfi srfi-1)  ;;list searching; delete-duplicates in list 
	     (ice-9 rdelim)
	     (ice-9 popen)
	     (ice-9 regex) ;;list-matches
	     (ice-9 receive)
	     (ice-9 format)
	     (ice-9 string-fun)  ;;string-replace-substring
	     (ice-9 pretty-print)
	     (ice-9 textual-ports)
	     (ice-9 ftw) ;; file tree walk
	     (ice-9 readline) ;;must sudo apt-get install libreadline-dev
	     (ice-9 pretty-print)
	     (bookmunger utilities)
	     (dbi dbi)	   
	     )

(define book-count 0)

;; for testing
(define lib-dir "/home/mbc/projects/bookmunger/db/") ;; home of db
(define lib-backup-dir "/home/mbc/temp/lib/backups/") ;;
(define on-deck-dir "/home/mbc/temp/lib/on-deck/")  ;; out of z-lib ready to have z-lib removed
(define dest-dir "/home/mbc/temp/lib/dest/") ;; final destination directory probably ~/syncd/library/files
(define readme-dir "/home/mbc/temp/lib/readme/")

;; (define lib-dir "/home/mbc/syncd/library/db/") ;; home of db
;; (define lib-backup-dir "/home/mbc/syncd/library/backup/") ;;
;; (define on-deck-dir "/home/mbc/syncd/library/readme/")  ;; out of z-lib ready to have z-lib removed
;; (define dest-dir "/home/mbc/syncd/library/files2/") ;; final destination directory probably ~/syncd/library/files
;; (define readme-dir "/home/mbc/Documents/readme/")


(define doc-viewer "ebook-viewer") ;;from Calibre
(define lib-file-name "book.db")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; database
(define db-obj (dbi-open "sqlite3" (string-append lib-dir lib-file-name)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (init-db)
  (system (string-append "sqlite3 " lib-dir lib-file-name " </home/mbc/projects/bookmunger/db/bookmunger.sql" )))



(define (move-file old new)
  (let* ((old-fname (string-append on-deck-dir old))
	 (new-fname (string-append dest-dir new))
	 (command (string-append "mv '" old-fname "' '" new-fname"'")))
   (system command )))



(define (recurse-get-auth-ids auths ids)
  ;;recurse for get-auth-ids
  ;;first check if author already in db, create if not
  (if (null? (cdr auths))
      (let* ((a (dbi-query db-obj (string-append "select id from author where author_name LIKE '" (car auths) "'")))
	     (b (dbi-get_row db-obj))
	     (c (if b (assoc-ref b "id")
		    (begin
		      (dbi-query db-obj (string-append "insert into author ('author_name') values('"  (car auths) "')"))
		      (dbi-query db-obj (string-append "select id from author where author_name LIKE '" (car auths) "'"))
		      (assoc-ref (dbi-get_row db-obj) "id"))))
	     (dummy (set! ids (cons c ids))))
	ids)
       (let* ((a (dbi-query db-obj (string-append "select id from author where author_name LIKE '" (car auths) "'")))
	     (b (dbi-get_row db-obj))
	     (c (if b (assoc-ref b "id")
		    (begin
		      (dbi-query db-obj (string-append "insert into author ('author_name') values('"  (car auths) "')"))
		      (dbi-query db-obj (string-append "select id from author where author_name LIKE '" (car auths) "'"))
		      (assoc-ref (dbi-get_row db-obj) "id"))))
	     (dummy (set! ids (cons c ids))))
	(recurse-get-auth-ids (cdr auths) ids))))


;; (recurse-get-auth-ids '("Howard Rheingold" "Joe Blow") '())


(define (get-author-ids arg)
  ;;for a string of , delimitted authors get the ids
  ;;all authors must be First M. Last before getting here
  ;;add to database if needed
  (let*((trimmed (string-trim-both arg))
	(auth-lst (string-split trimmed #\,))
	(trimmed-auth-lst (map string-trim-both auth-lst))
	)
   ;; trimmed-auth-lst))
    (recurse-get-auth-ids trimmed-auth-lst '())))


;;(get-author-ids "Howard Rheingold, Joe Blow")

(define (get-authors-as-string lst str)
  ;; input is the processed list from get-authors-as-list
  ;; str should be ""
  ;;output is a single string for display or input into get-author-ids
  ;;use the list of authors for adding to database
  (if (null? (cdr lst))
      (begin
	(set! str (string-append str (car lst) ))
	str)       
       (begin
	 (set! str (string-append str (car lst) ", " ))
	 (get-authors-as-string (cdr lst) str))))


;;will handle the following author spellings
;; first last
;; first last and first last 
;; first last, first last, ... , first last
;; first m. last, ...
;; last, first
;; last, first and last, first
;;  

(define (get-authors-as-list str)
  ;;input is a string that may have multiple authors
  ;;output is a list with each element as first (m) last
  (let* (
	(str (string-trim-both str))
	(len-str (string-length str))
	;;if has and then split and check if has comma and reverse
	(and-start (string-contains-ci str " and "))
	(auth-lst (if and-start
		      (let* (
			     (str (string-trim-both str))
			     (len-str (string-length str))
			     (auth1 (substring str 0 and-start))
			     (auth2 (substring str (+ and-start 5) len-str))
			     ;;if auth1 has a comma it is last, first - reverse
			     (has-comma? (> (length (string-split auth1 #\,)) 1)))
			(if has-comma?
			    (let* ((auth1-split (string-split auth1 #\,))
			     	   (auth1-lname (car auth1-split))
			      	   (auth1-fname (string-trim-both (cadr auth1-split)))
			      	   (auth2-split (string-split auth2 #\,))
			      	   (auth2-lname (car auth2-split))
			      	   (auth2-fname (string-trim-both (cadr auth2-split)))
			      	   (auth1rev (string-append auth1-fname " " auth1-lname))
			      	   (auth2rev (string-append auth2-fname " " auth2-lname)))
			      (list auth1rev auth2rev))
			    (list auth1 auth2)))			     
		      ;; no and
		      (let*(
			     (auth-str (string-split str #\,))
			     (auth-str (map string-trim-both auth-str))
			     (has-space? (> (length (string-split (car auth-str) #\space)) 1)))
			;;if it has a space than it is first last, otherwise last, first
			;;if last first must flip			    
			(if has-space? auth-str (list (string-append (cadr auth-str) " " (car auth-str))))))))	
     auth-lst))

;;(get-authors-as-list "Smith, Joe M. and Blow, Bill")


(define (get-title-authors-filename str)
  ;; return a list '(title '(authors) new-file-name)
  ;; last "by" is the delimiter of title author
  (let* ((len (length (string->list str)))
	 (dot (string-rindex str #\.)) ;;reverse search
	 (pref (substring str 0  dot ))
	 (len-pref (length (string->list pref)))	 
	 (ext (substring str dot len)) ;; includes .
	 (a (substring pref (- len-pref 12) len-pref))
	 (is-it-zlib? (string= " (z-lib.org)" a))
	 (pref (if is-it-zlib? (substring pref 0 (- len-pref 12)) pref))	 
	 (b (last (list-matches " by " pref)))
	 (start (match:start  b))
	 (end (match:end  b))
	 (len-pref (length (string->list pref)));;it might have changed
	 (title (substring pref 0 start))
	 (authors (substring pref end len-pref))
	  (auth-lst (get-authors-as-list authors)) ;;gets a list '("Fname1 Lname1" "Fname2 Lname2")
	  (new-file-name (string-append title ext))
	 )
 ;;pref))
    
  `(,title ,auth-lst ,new-file-name) ))

;;(get-title-authors-filename "A Biologists Guide to Mathematical Modeling in Ecology and Evolution by Sarah P. Otto, Troy Day.epub")



(define (add-auths-to-book book-id auth-ids)
  ;;book-id is integer
  ;;auth-ids is list of integers
  (if (null? (cdr auth-ids))
      (dbi-query db-obj (string-append "insert into book_author ('book_id','author_id') values(" (number->string book-id) "," (number->string (car auth-ids))  ")"))
      (begin
	(dbi-query db-obj (string-append "insert into book_author ('book_id','author_id') values(" (number->string book-id) "," (number->string  (car auth-ids))  ")"))
	(add-auths-to-book book-id (cdr auth-ids)))))


(define (add-tags-to-book book-id tag-ids)
  ;;book-id is integer
  ;;tag-ids is list of integers as strings
  (if (null? (cdr tag-ids))
      (dbi-query db-obj (string-append "insert into book_tag ('book_id','tag_id') values(" (number->string book-id) ",'"  (car tag-ids)  "')"))
      (begin
	(dbi-query db-obj (string-append "insert into book_tag ('book_id','tag_id') values(" (number->string book-id) ",'"  (car tag-ids)  "')"))
	(add-tags-to-book book-id (cdr tag-ids)))))
  

(define (add-book-to-db title auth-ids tag-ids filename)
  ;;authors and tags must already be in db for assigment with ids
  (let* ((a (dbi-query db-obj (string-append "insert into book ('title','file_name') values('" title "','" filename "')")))
	 (b (dbi-query db-obj (string-append "select id from book where title LIKE '" title "'")))
	 (book-id (assoc-ref (dbi-get_row db-obj) "id"))
	 (c (add-auths-to-book book-id  auth-ids))
	 (d (add-tags-to-book book-id (string-split (car tag-ids) #\space)))
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




(define (get-all-tags-as-list)
  ;;input to create-tagwin
  (let* ( (a   (dbi-query db-obj "SELECT * FROM tag")  )
	  (b "")
	  (c '(""))
	  (counter 0)
	  (ret (dbi-get_row db-obj))
	  (dummy (while (not (equal? ret #f))
		   (begin
		     (set! counter (+ counter 1))
		     (set! b (string-append b  (number->string (assoc-ref ret "id")) ":" (assoc-ref ret "tag_name") "  "))
		     (if (= 0 (euclidean-remainder counter 8))
			 (begin
			   (set! c (cons b c))
			   (set! b "")) #t)		 
		     (set! ret (dbi-get_row db-obj))))))
	  (reverse (cons "" (cons b c)) )))  ;;add the last few, then add "" because the while won't process the last element i.e. not recursion

(define (get-all-tags-as-string)
  (let* ((sep "==========================================================================================\n")
	 (lst (cdr (get-all-tags-as-list)))
	 (out sep)
	 (dummy (while (not (string= (car lst) "") )		  
		  (begin
		    (set! out (string-append out "\n" (car lst)))
		    (set! lst (cdr lst))
		    ))))
    (string-append "\n\n" out "\n\n" sep "\n")))
	      

(define (process-file f)
  (let* ((old-fname f)
	 (out (get-all-tags-as-string))
	 (lst (get-title-authors-filename old-fname))  ;;authos is  a list '("Fname1 Lname1" "Fname2 Lname2")      
	 (out (string-append out "Original File: " old-fname "\n"))
	 (title (car lst))
	 (auth-lst (cadr lst))
	 (auth-str (get-authors-as-string auth-lst "") )
	 
	 (new-fname (caddr lst))
	 (out (string-append out "Title: " title  "\n"))
	 (out (string-append out "Author(s): " auth-str  "\n"))
	 (out (string-append out "New Filename: " new-fname  "\n\n"))
	 (dummy (display out))
	 (tag-ids (list  (readline "Tag(s): ")))
	 (auth-ids (get-author-ids auth-str))
	 (c (add-book-to-db title auth-ids tag-ids new-fname))
	 (d (move-file old-fname new-fname))
	 (e (set! book-count (+ book-count 1))))
    #t))

(define (process-all-files lst)   
    (if (null? (cdr lst))
	(process-file (car lst))
	(begin
	  (process-file (car lst))
	  (process-all-files (cdr lst)))))
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; queries



(define (query-all-fields str)
  ;;returns a list of id as integer
  (let* ( (a   (dbi-query db-obj (string-append "SELECT book.id, book.title FROM book WHERE  book.title LIKE '%" str  "%' UNION
                                                 SELECT DISTINCT book.id, book.title FROM book, author, tag, book_author, book_tag WHERE book_author.author_id=author.id AND book_author.book_id=book.id AND book_tag.tag_id=tag.id AND book_tag.book_id=book.id AND author.author_name LIKE '%" str  "%' UNION
SELECT DISTINCT book.id, book.title FROM book, author, tag, book_author, book_tag WHERE book_author.author_id=author.id AND book_author.book_id=book.id AND book_tag.tag_id=tag.id AND book_tag.book_id=book.id AND tag.tag_name LIKE '%" str  "%'" )))
	  (lst '())
	  (ret (dbi-get_row db-obj))
	  (dummy (while (not (equal? ret #f))
		   (begin		      
		     (set! lst (cons (assoc-ref ret "id") lst))
		     (set! ret (dbi-get_row db-obj))))))
    lst))

;;(query-all-fields "capital")

(define (display-results lst)
  ;;list is a list of book IDs
  ;;book.id is what will have to be typed to view/move a book
  (if (null? (cdr lst))
      (let* ((dummy (dbi-query db-obj (string-append "SELECT book.id, book.title FROM book WHERE  book.id = '" (number->string (car lst)) "'")))
	     (ret (dbi-get_row db-obj))			 
	     (dummy (display (string-append (number->string (assoc-ref ret "id")) " | " (assoc-ref ret "title")  "\n\n")))
	     )
	#t)
      (let* ((dummy (dbi-query db-obj (string-append "SELECT book.id, book.title FROM book WHERE  book.id = '" (number->string (car lst)) "'")))
	     (ret (dbi-get_row db-obj))			 
	     (dummy (display (string-append (number->string (assoc-ref ret "id")) " | " (assoc-ref ret "title")  "\n")))
	     )
	(display-results (cdr lst)))
      
	))

(define (copy-book-to-readme book-id)
  ;;book-id is integer
  (let*((dummy (dbi-query db-obj (string-append "SELECT book.file_name FROM book WHERE  book.id = '" (number->string book-id) "'")))
	(ret (dbi-get_row db-obj))
	(file-name (assoc-ref ret "file_name"))
	(lib-file-name (string-append dest-dir file-name ))	
	(readme-file-name (string-append readme-dir file-name ))
	(command (string-append "cp '" lib-file-name "' '" readme-file-name "'")))
    (system command)))

(define (view-book book-id)
  ;;viewing the book in the library (dest-dir)
  (let*((dummy (dbi-query db-obj (string-append "SELECT book.file_name FROM book WHERE  book.id = '" (number->string book-id) "'")))
	(ret (dbi-get_row db-obj))
	(file-name (assoc-ref ret "file_name"))
	(lib-file-name (string-append dest-dir file-name ))	
	(command (string-append doc-viewer " '" lib-file-name "'")))
    (system command)))


;; (define (display-logo)
;;   ;;https://patorjk.com/software/taag/#p=display&f=Big&t=Book%20Munger
;;   (begin
;;     (display "  ____              _      __  __")
;;     (display " |  _ \            | |    |  \/  |                            ")
;;     (display " | |_) | ___   ___ | | __ | \  / |_   _ _ __   __ _  ___ _ __ ")
;;     (display " |  _ < / _ \ / _ \| |/ / | |\/| | | | | '_ \ / _` |/ _ \ '__|")
;;     (display " | |_) | (_) | (_) |   <  | |  | | |_| | | | | (_| |  __/ |   ")
;;     (display " |____/ \___/ \___/|_|\_\ |_|  |_|\__,_|_| |_|\__, |\___|_|   ")
;;     (display "                                               __/ |          ")
;;     (display "                                              |___/           \n\n")))

(define (main args)
  (let* ((dummy (activate-readline))
	 ;;(dummy (display-logo))
	 (dummy (display "help     me"))
	 (all-files (cddr (scandir on-deck-dir)))
	 (files-on-deck? (if (= (length all-files) 0) #f #t ))
	 (dummy (if files-on-deck? (begin
				     (make-lib-backup)
				     (process-all-files all-files)
				     (display (string-append "\nProcessed " (number->string book-count) " books.\n\n")))))	 
	 (dummy (display (string-append (get-all-tags-as-string) "\nCtrl-z to exit\n\n")))
	 (find-me (readline "Query: "))
	 (lst (query-all-fields find-me)))
    (if (= (length lst) 0)
	(display "Match not found!\n\n")
	(let* ((dummy (display-results lst))			     			     		     
	       (what-do  (readline "(o)pen or (r)etrieve (id): "))
	       (a (string-split what-do #\space))
	       (action (car a))
	       (id (string->number (cadr a)))
	       (b (if (string= action "o")  (view-book id)))
	       (c (if (string= action "r") (copy-book-to-readme id))))
	  #t))))







