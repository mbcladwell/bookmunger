
(define (make-doc filename key  tags title authors  )
   (string-append "(doc\n\t\t\t(relative_filename \"files/" filename "\")\n\t\t\t (key ,key) \n\t\t\t (notes) \n\t\t\t" tags " (bib_type \"book\") \n\t\t\t (bib_doi) \n\t\t\t (bib_title" title ") \n\t\t\t (bib_authors " authors ")\n\t\t\t (bib_journal) \n\t\t\t (bib_volume) \n\t\t\t (bib_number) \n\t\t\t(bib_pages)\n\t\t\t (bib_year)) \n\t\t")
  )



(define b (make-doc "myfile" "mykey" (make-tags "11 2 5 6") "A Title" "P.B Woodhouse, Joe Schmoe"))
(define c   (cons doclist b))

(pretty-print b)

(define (make-lib-file mod-doclist)
  (cons taglist (append '(doclist) mod-doclist)))


(pretty-print (make-lib-file c))

(let*((out (open-file "/home/mbc/temp/lib/doc-out.txt" "w"))
      (dummy (write (sxml->xml c) out)))
      (flush-all-ports)
  )

(car c)
;; (pretty-print  (caddr a))
;; (pretty-print doclist)


()


(define db-obj (dbi-open "sqlite3" (string-append lib-dir lib-file-name)))


(let* ((str "Beyond")
       (a (string-append "SELECT book.id, book.title FROM book WHERE  book.title LIKE '%" str  "%' UNION  SELECT DISTINCT book.id, book.title FROM book, author, tag, book_author, book_tag WHERE book_author.author_id=author.id AND book_author.book_id=book.id AND book_tag.tag_id=tag.id AND book_tag.book_id=book.id AND author.author_name LIKE '%" str  "%' UNION SELECT DISTINCT book.id, book.title FROM book, author, tag, book_author, book_tag WHERE book_author.author_id=author.id AND book_author.book_id=book.id AND book_tag.tag_id=tag.id AND book_tag.book_id=book.id AND tag.tag_name LIKE '%" str  "%'" ))
	(dbi-query db-obj a)
        (lst '())
	(ret (dbi-get_row db-obj))
	  ;; (dummy (while (not (equal? ret #f))
	  ;; 	   (begin		      
	  ;; 	     (set! lst (cons (assoc-ref ret "id") lst))
	  ;; 	     (set! ret (dbi-get_row db-obj)))))
	  )
  ret)
   ;; lst)

(format "  ____              _      __  __")
(format)
