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

(define (make-doc filename key tags title authors  )
   `(doc "\n\t\t\t" (relative_filename ,(string-append "files/" filename)) "\n\t\t\t" (key ,key) "\n\t\t\t" (notes) "\n\t\t\t" ,@tags "\n\t\t\t" (bib_type "book") "\n\t\t\t" (bib_doi) "\n\t\t\t" (bib_title ,title) "\n\t\t\t" (bib_authors ,authors) "\n\t\t\t" (bib_journal) "\n\t\t\t" (bib_volume) "\n\t\t\t" (bib_number) "\n\t\t\t" (bib_pages) "\n\t\t\t" (bib_year) "\n\t\t")
  )
