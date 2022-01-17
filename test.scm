
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


(use-modules 
	     (srfi srfi-19)   ;; date time
	     (srfi srfi-1)  ;;list searching   	     
	     (ice-9 rdelim)
	     (ice-9 unicode) ;;character sets
	     (ice-9 popen)
	     (ice-9 textual-ports) ;;read file into variable
	     (ice-9 regex) ;;list-matches
	     (ice-9 pretty-print)
	     )


(define isbn "9781529035674")

(define (get-title-auths-w-isbn isbn)
  (let* (
	 (a (number->string (time-second (current-time time-monotonic))))
	 (temp-file (string-append "/tmp/metadata" a ".txt"))
	 (b  (system (string-append "/usr/bin/fetch-ebook-metadata -o -i " isbn " > " temp-file)))
	 (contents (call-with-input-file temp-file get-string-all))
	 (title-start (match:end (string-match "<dc:title>" contents)))
	 (title-end (match:start (string-match "</dc:title>" contents)))
	 (title (substring contents title-start title-end) )
	 (aut-start (match:end (string-match "<dc:creator[a-zA-Z0-9:=\" -]+>" contents)))
	 (aut-end (match:start (string-match "</dc:creator>" contents)))
	 (author (substring contents aut-start aut-end)))
     (list title  author)))

(get-title-auths-w-isbn "9781529035674")


(system  "/usr/bin/fetch-ebook-metadata -o -i 9781529035674 > /home/mbc/gogo2.txt" )

 (use-modules (sxml simple))
(define myfile  "/tmp/metadata1642337939.txt")

(define contents (call-with-input-file myfile get-string-all))

(match:end (string-match "<dc:creator[a-zA-Z0-9=-:;\" ]+>" contents))

(match:end (string-match "</dc:creator>" contents))


(match:end (string-match "<dc:creator[a-zA-Z0-9:=\" -]+>" contents))

(match:end (string-match "<dc:creator[a-zA-Z0-9:=\" -]+>" "<dc:creator opf:file-as=\"Unknown\" opf:role=\"aut\">Edward Snowden</dc:creator>"))
