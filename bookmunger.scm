#! /gnu/store/6l9rix46ydxyldf74dvpgr60rf5ily0c-guile-3.0.7/bin/guile \
-e main -s
!#

;; comma delimitted authors, first last names
;; expecting Title Of Book by Fname M. Lname, Fname2 Lname2 (z-lib.org).epub


(add-to-load-path "/home/mbc/projects/bookmunger")
;;(load "/home/mbc/projects/bookmunger/curses.scm")

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
	   ;;  (ice-9 readline)
	     (bookmunger utilities)
	     (bookmunger logging)   ;; logging is in guile-lib
             (logging logger)
             (logging rotating-log)
             (logging port-log)
	     (sxml simple)
	     (dbi dbi)
	     (ncurses curses)
	     (ncurses panel)
             (ncurses form)
	     )

(define book-count 0)

(define lib-dir "/home/mbc/temp/lib/") ;; home of library XML
(define lib-backup-dir "/home/mbc/temp/lib/backups/") ;;
(define on-deck-dir "/home/mbc/temp/lib/on-deck/")  ;; out of z-lib ready to have z-lib removed
(define dest-dir "/home/mbc/temp/lib/finalmod/") ;; final destination directory probably ~/syncd/library/files
(define lib-file-name "a-lib.reflib")


;; (define tags '((0 . "fiction")	(1 . "nonfiction")(2 . "technical")(3 . R)(4 . "statistics")(5 . "Bayes")(6 . "popgen")(7 . "gametheory")(9 . "bitcoin")(10 . "genetics")(11 . "work")(12 . "admixture")(13 . "DOE")(14 . "manuals")(15 . "programming")(16 . "math")(17 . "smalltalk")(18 . "history")(19 . "philosophy")(20 . "guile/guix")))


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
  ;; last "by" is the delimiter of title author
  (let* ((len (length (string->list str)))
	 (dot (string-rindex str #\.)) ;;reverse search
	 (pref (substring str 0  dot ))
	 (len-pref (length (string->list pref)))
	 (suf (substring str dot len)) ;; includes .
	 (a (last (list-matches " by " pref)))
	 (start (match:start (car a)))
	 (end (match:end (car a)))
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
		     (set! b (string-append b  (number->string (assoc-ref ret "tag_id")) ":" (assoc-ref ret "tag_name") "  "))
		     (if (= 0 (euclidean-remainder counter 8))
			 (begin
			   (set! c (cons b c))
			   (set! b "")) #t)		 
		     (set! ret (dbi-get_row db-obj))))))
	  (reverse (cons "" (cons b c)) )))  ;;add the last few, then add "" because the while won't process the last element i.e. not recursion



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
;; ncurses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(define (create-tag-win width starty startx)
  (let* ((tag-list (get-all-tags-as-list))
	 (height (+ (length tag-list) 2))
	 (win  (newwin height width starty startx))			; Make a lambda proc that
	 (dummy  (box win (acs-vline) (acs-hline)))					; Makes a box,
	 (dummy (addstr win "Tag options:" #:y 0  #:x 4))
	 (y-loc 1)
	 (dummy (while (not (null? (cdr tag-list)))
		  (begin
		    (addstr win (car tag-list) #:y y-loc  #:x 3)
		    (set! y-loc (+ y-loc 1))
		    (set! tag-list (cdr tag-list))))))
    (begin
      (refresh win)  ; Draws the window
      win)))         ; Returns the window to the caller




(define (create-form-win stdscr height width starty startx)
  (let* ((my-fields (list (new-field 1 20 (+ starty 5) 10 0 0)))
	 (dummy (set-field-back!  (car my-fields) A_UNDERLINE))
	 (my-form (new-form my-fields))
	 (dummy  (begin
		   (post-form my-form )
    		   ;;(dummy (set-form-sub! my-form (derwin my-win 30 120 0 0)))
		   (addstr stdscr "Title: " #:y (+ starty 1)  #:x 7)
		   (addstr stdscr "Author(s): " #:y (+ starty 3)  #:x 3)
		   (addstr stdscr "Tag(s): " #:y (+ starty 5)  #:x 6)
		   (addstr stdscr "q to quit " #:y (+ starty 9)  #:x 6)
		   (addstr stdscr "Up/down arrow to navigate fields" #:y (+ starty 10)  #:x 6)
		   (refresh stdscr))))
    #t))       


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;field related 



(define (init-form)
  (let* ((tag-list (get-all-tags-as-list))
	 (height (+ (length tag-list) 2)) ;;how tall is the tags window?

	 (stdscr (initscr))
	 (dummy (begin
		  (start-color!)
		  (cbreak!)
		  (echo!)
		  (keypad! stdscr #t)
		  (create-form-win stdscr 10 100 (+ height 1) 0)
		  (create-tag-win 120 0 0)
		 ;; (refresh stdscr)
		  ))

	)        
  (getch stdscr)			; Wait for user input 
  ))                             ; End curses mode
 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define (main args)
  (let* ((start-time (current-time time-monotonic))
	 (dummy2 (log-msg 'CRITICAL (string-append "Starting up at: "  (number->string (time-second start-time)))))
	 (all-files (cddr (scandir on-deck-dir)))
	 (dummy (begin (init-form)
		    ;;  (display-tag-options)
		      ;;(unpost-form my-form)
		       (endwin)
		       ))
	
 	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 (dummy3 (log-msg 'INFO (string-append "Elapsed time: " (number->string   elapsed-time) " minutes.")))
	 (dummy4 (log-msg 'INFO (string-append "Book count: " (number->string  book-count) )))
	 (dummy5 (shutdown-logging))
	 )
#t)    
;;  (pretty-print (get-all-tags-as-list)))    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    )
