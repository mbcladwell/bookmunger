#! /gnu/store/6l9rix46ydxyldf74dvpgr60rf5ily0c-guile-3.0.7/bin/guile \
-L /gnu/store/hiiljpxr855z0w1ail01phv7vwq40s38-guile-dbi-2.1.6/share/guile/site/2.2 -s
!#

;; comma delimitted authors, first last names
;; expecting Title Of Book by Fname M. Lname, Fname2 Lname2 (z-lib.org).epub


(add-to-load-path "/home/mbc/projects/bookmunger")
(add-to-load-path "/gnu/store/va6l1ivclww22fi38w5h99pb4ndn99hg-guile-readline-3.0.2/share/guile/site/3.0")
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
	     (ice-9 readline) ;;must sudo apt-get install libreadline-dev
	     (ice-9 pretty-print)
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
(define dest-dir "/home/mbc/temp/lib/dest/") ;; final destination directory probably ~/syncd/library/files
(define lib-file-name "a-lib.reflib")


;; (define tags '((0 . "fiction")	(1 . "nonfiction")(2 . "technical")(3 . R)(4 . "statistics")(5 . "Bayes")(6 . "popgen")(7 . "gametheory")(9 . "bitcoin")(10 . "genetics")(11 . "work")(12 . "admixture")(13 . "DOE")(14 . "manuals")(15 . "programming")(16 . "math")(17 . "smalltalk")(18 . "history")(19 . "philosophy")(20 . "guile/guix")))

(define (move-file old new)
  (let* ((old-fname (string-append on-deck-dir old))
	 (new-fname (string-append dest-dir new))
	 (command (string-append "mv '" old-fname "' '" new-fname"'")))
   (system command )))


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



;; (define (remove-zlib str)
;;   (let* ((dot (string-rindex str #\.)) ;;reverse search
;; 	 (name (substring str 0  dot ))
;; 	 (len (length (string->list name)))
	 
;; 	 (a (substring name (- len 12) len))
;; 	 (is-it-zlib? (string= " (z-lib.org)" a)))
;;     (if is-it-zlib?
;; 	(let* ((len2 (length (string->list str)))
;; 	       (ext (substring str dot len2))  ;;inlcudes the .
;; 	       (new-name (substring name 0 (- len 12))))
;; 	  (string-append new-name ext))
;; 	str)))


(define (get-authors-as-string lst str)
  ;; input is the processed list from get-authors-as-list
  ;; str should be ""
  (if (null? (cdr lst))
      (begin
	(set! str (string-append (car lst)))
	str)       
       (begin
	 (set! str (string-append (car lst) ", "))
	 (get-authors-as-string (cdr lst)))))


(define (get-authors-as-list str)
  ;;input is a string that may have multiple authors
   (let*((trimmed (string-trim-both str))
	(auth-lst (string-split trimmed #\,))
	(auth-lst (map string-trim-both auth-lst))
	(has-space? (> (length (string-split (car auth-lst) #\space)) 1))
	;;if it has a space than it is first last, otherwise last, first
	;;if last first must flip; assume only one author
	(auth-lst (if has-space? auth-lst (list (string-append (cadr auth-lst) " " (car auth-lst)))))
	)
;;    (recurse-get-auth-ids trimmed-auth-lst '()))
auth-lst

  ))

;; (apply string-append (get-authors-as-list "Smith Harold, Joe Blow, Me Too"))


;; (define (get-title-authors-filename str)
;;   ;; return a list '(title author-ids new-file-name)
;;   ;; last "by" is the delimiter of title author
;;   (let* ((len (length (string->list str)))
;; 	 (dot (string-rindex str #\.)) ;;reverse search
;; 	 (pref (substring str 0  dot ))
;; 	 (len-pref (length (string->list pref)))	 
;; 	 (ext (substring str dot len)) ;; includes .
;; 	 (a (substring pref (- len-pref 12) len-pref))
;; 	 (is-it-zlib? (string= " (z-lib.org)" a))
;; 	 (pref (if is-it-zlib? (substring pref 0 (- len-pref 12)) str))	 
;; 	 (b (last (list-matches " by " pref)))
;; 	 (start (match:start  b))
;; 	 (end (match:end  b))
;; 	 (len-pref (length (string->list pref)));;it might have changed
;; 	 (title (substring pref 0 start))
;; 	 (authors (substring pref end len-pref))
;; 	  (auth-lst (get-authors-as-list authors))
;; 	  (new-file-name (string-append title ext))
;; 	 )
;; ;; (pretty-print  new-file-name)))
    
;;   `(,title ,auth-lst ,new-file-name) ))





(define (get-title-authors-filename str)
  ;; return a list '(title author-ids new-file-name)
  ;; last "by" is the delimiter of title author
  (let* ((len (length (string->list str)))
	 (dot (string-rindex str #\.)) ;;reverse search
	 (pref (substring str 0  dot ))
	 (len-pref (length (string->list pref)))	 
	 (ext (substring str dot len)) ;; includes .
	 (a (substring pref (- len-pref 12) len-pref))
	 (is-it-zlib? (string= " (z-lib.org)" a))
	 (pref (if is-it-zlib? (substring pref 0 (- len-pref 12)) str))	 
	 (b (last (list-matches " by " pref)))
	 (start (match:start  b))
	 (end (match:end  b))
	 (len-pref (length (string->list pref)));;it might have changed
	 (title (substring pref 0 start))
	 (authors (substring pref end len-pref))
	  (auth-lst (get-authors-as-list authors))
	  (new-file-name (string-append title ext))
	 )
;; (pretty-print  auth-lst)))
    
  `(,title ,auth-lst ,new-file-name) ))

;;(get-title-authors-filename "The Genetic Lottery by Kathryn Paige Harden (z-lib.org).epub")


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
  ;;tag-ids is list of integers as strings
  (if (null? (cdr tag-ids))
      (dbi-query db-obj (string-append "insert into book_tag ('book_id','tag_id') values(" (number->string book-id) ",'"  (car tag-ids)  "')"))
      (begin
	(dbi-query db-obj (string-append "insert into book_tag ('book_id','tag_id') values(" (number->string book-id) ",'"  (car tag-ids)  "')"))
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

(define (get-all-tags-as-string)
  (let* ((sep "====================================================================================\n")
	 (lst (cdr (get-all-tags-as-list)))
	 (out sep)
	 (dummy (while (not (string= (car lst) "") )		  
		  (begin
		    (set! out (string-append out "\n" (car lst)))
		    (set! lst (cdr lst))
		    ))))
    (string-append "\n\n" out "\n\n" sep "\n")))
	      


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; database
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define db-obj (dbi-open "sqlite3" "/home/mbc/projects/bookmunger/db/book.db"))




(define all-files (cddr (scandir on-deck-dir)))
	 
(activate-readline)
;;(display (get-all-tags-as-string)) ;;starts and ends with ""

(let* ((old-fname (car all-files))
       (out (get-all-tags-as-string))
       (lst (get-title-authors-filename old-fname))       
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
;;  (pretty-print auth-lst))
  #t  )



