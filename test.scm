


(define b (make-doc "myfile" "mykey" (make-tags "11 2 5 6") "A Title" "P.B Woodhouse, Joe Schmoe"))
(define c (cons doclist b))

(define (make-lib-file mod-doclist)
  (cons `(,@(doclist "\n\t\t")) mod-doclist))

(make-lib-file c)

(define out (open-file "/home/mbc/temp/lib/doc-out.txt" "w"))

()




(begin (format out "~a" b )
(force-output out))

(nss:sha256 b)
