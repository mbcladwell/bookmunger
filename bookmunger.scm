#! /gnu/store/6l9rix46ydxyldf74dvpgr60rf5ily0c-guile-3.0.7/bin/guile \
-e main -s
!#

;; comma delimitted authors, first last names
;; expecting Title Of Book by Fname M. Lname, Fname2 Lname2 (z-lib.org).epub
;; expecting Swing By Me byy Fname M. Lname, Fname2 Lname2 (z-lib.org).epub


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
;; forms
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (print-tag-title win starty startx width str color)
  (let ((length (string-length str)))

    (attr-on! win color)
    (addstr win str
            #:y (- starty 1)
            #:x (+ startx 3))

    (addstr win
	    (get-all-tags-as-string)
            #:y (+ starty 1)
            #:x  3)


	    

    (attr-off! win color)
    (refresh stdscr)))

(define stdscr (initscr))
(define field (list
               (new-field 1 30 6 1 0 0))) ;;new-field takes height, width startx, starty, the number of off-screen rows, and number of additional working buffers.
              ;; (new-field 1 10 8 1 0 0)))
(define my-form (new-form field)) ;;Creates a new form given a list that contains fields.
(define xy (scale-form my-form)) ;; scale-form returns the a list of two elements: minimum size required for the subwindow of form
(define rows (car xy))
(define cols (cadr xy))

(define my-form-win (newwin 20  ;;newwin height width starty startx
                            120
                            4
                            4))

(define (create-tagwin)
  ((lambda (stdscr)			; Make a lambda proc that
     (box stdscr (acs-vline) (acs-hline))	; Makes a box,
     (refresh stdscr)			; Draws the window
     stdscr)				; Returns the window to the caller

   (newwin 20 120 0 0))) ; Create a window and apply it
                                        ; to the lambda function



(define (display-tag-options)
(let loop ((ch (getch my-form-win)))
  (if (not (eqv? ch (key-f 1)))
      (cond
       ((eqv? ch KEY_DOWN)
        (begin
          ;; Go to the end of the next field
          (form-driver my-form REQ_NEXT_FIELD)
          (form-driver my-form REQ_END_LINE)
          (loop (getch my-form-win))))
       ((eqv? ch KEY_UP)
        (begin
          ;; Go to the end of the previous field
          (form-driver my-form REQ_PREV_FIELD)
          (form-driver my-form REQ_END_LINE)
          (loop (getch my-form-win))))
       (else
        (begin
          ;; Print any normal character
          (form-driver my-form ch)
          (loop (getch my-form-win)))))))

  )


(define (init-form)
(start-color!)
(cbreak!)
(noecho!)
(keypad! stdscr #t)
(init-pair! 1 COLOR_YELLOW COLOR_BLUE)
(set-field-back! (first field) A_UNDERLINE)
(field-opts-off! (first field) O_AUTOSKIP)
;;(box stdscr 0 0)

;;(set-field-back! (second field) A_UNDERLINE)
;;(field-opts-off! (second field) O_AUTOSKIP)
(keypad! my-form-win #t)

(create-tagwin)
(refresh stdscr)
;; Set main window and subwindow
;;(set-form-win! my-form my-form-win)
;;(set-form-sub! my-form (derwin my-form-win rows cols 2 2))

;; Print a border around the main window and print a title

;;(print-tag-title my-form-win 1 0 (+ cols 14) "Available tags" (color-pair 1)) ;;print-tag-title win starty startx width str color

;;(post-form my-form)
;;(refresh my-form-win)

(addstr stdscr "Use UP, DOWN arrow keys to switch between fields"
        #:y (- (lines) 2) #:x 0)
(refresh stdscr)
  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define (main args)
  (let* ((start-time (current-time time-monotonic))
	 (dummy2 (log-msg 'CRITICAL (string-append "Starting up at: "  (number->string (time-second start-time)))))
	 (all-files (cddr (scandir on-deck-dir)))
	 (dummy (begin (init-form)
		       (display-tag-options)
		       (unpost-form my-form)
		       (endwin)
		       ))
	
 	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 (dummy3 (log-msg 'INFO (string-append "Elapsed time: " (number->string   elapsed-time) " minutes.")))
	 (dummy4 (log-msg 'INFO (string-append "Book count: " (number->string  book-count) )))
	 (dummy5 (shutdown-logging))
	 )
#t)    
  ;;(pretty-print results))    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
   ;; #f
    )
