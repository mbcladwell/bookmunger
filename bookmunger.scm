;;#! /gnu/store/q8brh7j5mwy0hbrly6hjb1m3wwndxqc8-guile-3.0.5/bin/guile \
;;-e main -s
;;!#

 (add-to-load-path "/home/mbc/projects/bookmunger")

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
	     )

(define book-count 0)

(define lib-dir "/home/mbc/temp/lib/") ;; home of library XML
(define lib-backup-dir "/home/mbc/temp/lib/backups/") ;;
(define on-deck-dir "/home/mbc/temp/lib/")  ;; out of z-lib ready to have z-lib removed
(define no-zlib-dir "/home/temp/mbc/lib/nozlib/")  ;; no z-lib, ready for title author extraction; regular books here
(define dest-dir "/home/temp/lib/mbc/finalmod/") ;; final destination directory probably ~/syncd/library/files
(define lib-file-name "a-lib.reflib")


(define tags '((0 . "fiction")	(1 . "nonfiction")(2 . "technical")(3 . R)(4 . "statistics")(5 . "Bayes")(6 . "popgen")(7 . "gametheory")(9 . "bitcoin")(10 . "genetics")(11 . "work")(12 . "admixture")(13 . "DOE")(14 . "manuals")(15 . "programming")(16 . "math")(17 . "smalltalk")(18 . "history")(19 . "philosophy")))


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


;;(remove-zlib "Gazelle by Ducornet Rikki (z-lib.org).epub")

(define (rm-zlib-from-filename fname)
  (let* ((pref on-deck-dir)
	 (old (string-append pref fname))
	 (new-pre (remove-zlib fname))
	 (new (string-append pref new-pre)))
 ;;   (pretty-print new-pre)))
  (rename-file old new )))

;;(rm-zlib-from-filename "The First Man by Camus, Albert (z-lib.org).epub")

(define (recurse-rm-zlib-from-filename lst)
  (if (null? (cdr lst))
      (rm-zlib-from-filename (car lst))
      (begin
	(rm-zlib-from-filename (car lst))
	(recurse-rm-zlib-from-filename (cdr lst)))))

  
;; (recurse-rm-zlib-from-filename  (cddr (scandir "/home/mbc/Downloads/lib")))


(define (get-title-author-filename str)
  ;; return a list '(title author new-file-name)
  ;; if "by" is in the title, I will not extract author
  (let* ((len (length (string->list str)))
	 (dot (string-rindex str #\.)) ;;reverse search
	 (pref (substring str 0  dot ))
	 (len-pref (length (string->list pref)))
	 (suf (substring str dot len)) ;; includes .
	 (a (list-matches " by " pref))
	 ;;test if a is length 1
	 (start (match:start (car a)))
	 (end (match:end (car a)))
	 (title (substring pref 0 start))
	 (author (substring pref end len-pref))
	 (new-file-name (string-append title suf)) )
  `(,title ,author ,new-file-name) ))

;;(get-title-author-filename "some book the name by Peter LaPan (zlib.org).epub")



(define myfile (open-file (string-append lib-dir lib-file-name) "r"))

(define a (xml->sxml myfile))

;; ((*PI* xml "version=\"1.0\" encoding=\"UTF-8\"")
;; (library...
;;  (manage_target...)
;;  (library_folder...)
;;  (taglist...
;;     (tag)
;;     (tag))
;;  (doclist...
;;     (doc)
;;     (doc)))))

;;get each element of the xml
;; I want to add to the doclist



(define pi (cadr a));; (*PI* xml "version=\"1.0\" encoding=\"UTF-8\"")
;;(pretty-print (cadr a))
(define manage-target (cadr (cdaddr a)));; (library "\n\t" (manage_target (@ (utf8 "false") (braces...
;;(pretty-print (cadr (cdaddr a)))
(define library-folder (cdddr a));;
;;(pretty-print (cadddr (cdaddr a)))
(define taglist (caddr (cddddr (caddr a))));;
;;(pretty-print (caddr (cddddr (caddr a))))
(define doclist (cdar (cddddr (cddddr (caddr a)))))
;;(pretty-print (cdar (cddddr (cddddr (caddr a)))))
;;(pretty-print (car (cddddr (cddddr (caddr a)))))

;;print library
;;(pretty-print  (caddr a))
  

;;(pretty-print (make-lib-file doclist))

(define (recurse-make-tag lst new-lst)
  (if (null? (cdr lst))
      (begin
	 (set! new-lst (cons (string-append "(tagged \"" (car lst) "\")\n\t\t\t") new-lst))
	 (apply string-append new-lst))
      (begin
	(set! new-lst (cons (string-append "(tagged \"" (car lst) "\")\n\t\t\t") new-lst))
	(recurse-make-tag (cdr lst) new-lst))))

(define (make-tags args)
  ;;args is a string of integers i.e. "4 5 6 7 8"
  (let*((a (string-split args #\space))
	(b (recurse-make-tag a '())))
    b))

;; (make-tags "4 5 6 7")

(define (make-lib-backup)
 ;;lib-dir "/home/mbc/temp/lib/" ;; home of library XML
 ;;lib-backup-dir "/home/mbc/temp/lib/backups/" ;;
 ;;lib-file-name "a-lib.reflib"
  (let*((pref (date->string  (current-date) "~Y~m~d~I~M"))
	(backup-file-name (string-append lib-backup-dir pref "-" lib-file-name ))
	(working-file-name (string-append lib-dir lib-file-name))
	(command (string-append "cp " working-file-name " " backup-file-name)))
    (system command)))




(define (make-doc filename key tags title authors  )
   `(doc "\n\t\t\t" (relative_filename ,(string-append "files/" filename)) "\n\t\t\t" (key ,key) "\n\t\t\t" (notes) "\n\t\t\t" ,@tags "\n\t\t\t" (bib_type "book") "\n\t\t\t" (bib_doi) "\n\t\t\t" (bib_title ,title) "\n\t\t\t" (bib_authors ,authors) "\n\t\t\t" (bib_journal) "\n\t\t\t" (bib_volume) "\n\t\t\t" (bib_number) "\n\t\t\t" (bib_pages) "\n\t\t\t" (bib_year) "\n\t\t")
  )


(define (main args)
  ;; args: mod - remove ' (zlib.org) from filename
  ;;       stash - put into xml file
  (let* ((start-time (current-time time-monotonic))
	 (dummy2 (log-msg 'CRITICAL (string-append "Starting up at: "  (number->string (time-second start-time)))))
	;; (a (get-summaries (cadr args) (caddr args)))
	;; (dummy (map retrieve-article a))  ;;this does all the work; comment out last line for testing
	 (stop-time (current-time time-monotonic))
	 (elapsed-time (ceiling (/ (time-second (time-difference stop-time start-time)) 60)))
	 (dummy3 (log-msg 'INFO (string-append "Elapsed time: " (number->string   elapsed-time) " minutes.")))
	 (dummy4 (log-msg 'INFO (string-append "Book count: " (number->string  book-count) )))
	 (dummy5 (shutdown-logging))
	 )
;;   (pretty-print b)))    
   ;; (pretty-print (string-append "Elapsed time: " (number->string  elapsed-time) " minutes." ))
    #f
    ))
