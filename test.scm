
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


(map string-trim-both '(" jdhfs " "  skjdfk " " skjdf "  ))
(= (length (list-matches " byy " "jshfd by sjkdf bjhsjdhfj")) 0)

  (doclist
    "\n\t\t"
    (doc "\n\t\t\t"
         (relative_filename
           "files/1-s2.0-00221759"


(cddr (scandir "/home/mbc/projects/bookmunger/tests"))
