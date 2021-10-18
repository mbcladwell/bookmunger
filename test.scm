
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


(cddr (scandir "/home/mbc/test/lib/on-deck"))

(define a "f1 l1 and f2 l2")
(string-contains-ci "f1 l1 and f2 l2" " and ")
(substring a 0 5)
(substring a (+ 5 5) (string-length a))

(define b "last, first")
(string-split b #\,)





  (let* ((str "Smith, Joe M. and Blow, Bill")
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
     auth-lst)

