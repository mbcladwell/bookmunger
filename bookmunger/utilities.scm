(define-module (bookmunger utilities)
  #:export (find-occurences-in-string
	    any-not-false?
	    to-regular-char
	    ))


(use-modules  (ice-9 regex) ;;list-matches
	      )

(define (find-occurences-in-string query the-string)
  (let*((starts (map match:start (list-matches query the-string  )))
	(start-offset (map (lambda (x) (+ x 4)) starts))
	(end-offset-pre (map (lambda (x) (- x 1)) starts))
	(end-offset (append (cdr end-offset-pre) (list (string-length the-string))))
	(final '())
	(final  (map (lambda (x y) (append final (cons x y) )) start-offset end-offset))
	)
    final))

(define (any-not-false? x)
        (if (null? x) #f
	    (if (equal? (car x) #f) (any-not-false? (cdr x)) #t)))

;; to use to-regular-char:
;; (normal-chars (string->char-set "-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' "))
;; (normal-chars-only? (string-every  normal-chars author-name))
;; (define name "Marjanović Ž")
;; (pretty-print (string-map to-regular-char  name))

(define (to-regular-char x)
  (let* (
	 (A (string->char-set "ÀÁÂÃÄÅÆĀĂĄ"))
	 (a (string->char-set "àáâãäåæāă"))
	 (C (string->char-set "ÇĆĈĊČĆĈĊČ"))
	 (c (string->char-set "çćĉċčćĉċč"))
	 (D (string->char-set "ÐĎĐ"))
	 (d (string->char-set "ď"))
	 (E (string->char-set "ĒĔĖĘĚ"))
	 (e (string->char-set "èéêëēĕėęě"))
	 (G (string->char-set "ĜĞĠĢ"))
	 (g (string->char-set "ĝğġģ"))
	 (H (string->char-set "Ĥ"))
	 (h (string->char-set "ĥĦħ"))
	 (I (string->char-set "ĨĪĬĮİ"))
	 (i (string->char-set "ìíîïĩīĭįı"))
	 (J (string->char-set "Ĵ"))
	 (j (string->char-set "ĵ"))
	 (K (string->char-set "Ķ"))
	 (k (string->char-set "ķĸ"))
	 (L (string->char-set "ĹĻĽĿŁ"))
	 (l (string->char-set "ĺļľŀł"))
	 (N (string->char-set "ÑŃŅŇŊ"))
	 (n (string->char-set "ñńņňŉŋ"))
	 (O (string->char-set "ÒÓÔÕÖ×ØŌōŎŐ"))
	 (o (string->char-set "òóôõö÷øōŏő"))
	 (R (string->char-set "ŔŖŘ"))
	 (r (string->char-set "ŕŗ"))
	 (S (string->char-set "ŚŜŞŠ"))
	 (s (string->char-set "śŝşš"))
	 (T (string->char-set "ŢŤŦ"))
	 (t (string->char-set "ţťŧ"))
	 (U (string->char-set "ÙÚÛÜŨŪŬŮŰŲ"))
	 (u (string->char-set "ùúûüũūŭůűų"))
	 (W (string->char-set "Ŵ"))
	 (w (string->char-set "ŵ"))
	 (Y (string->char-set "ÝŶŸ"))
	 (y (string->char-set "ýŷ"))
	 (Z (string->char-set "ŹŻŽ"))
	 (z (string->char-set "źżž"))
	 )
    (cond
     [ (char-set-contains? A x) #\A]
     [ (char-set-contains? a x) #\a]
     [ (char-set-contains? C x) #\C]
     [ (char-set-contains? c x) #\c]
     [ (char-set-contains? D x) #\D]
     [ (char-set-contains? d x) #\d]
     [ (char-set-contains? E x) #\E]
     [ (char-set-contains? e x) #\e]
     [ (char-set-contains? G x) #\G]
     [ (char-set-contains? g x) #\g]
     [ (char-set-contains? H x) #\H]
     [ (char-set-contains? h x) #\h]
     [ (char-set-contains? I x) #\I]
     [ (char-set-contains? i x) #\i]
     [ (char-set-contains? J x) #\J]
     [ (char-set-contains? j x) #\j]
     [ (char-set-contains? K x) #\K]
     [ (char-set-contains? k x) #\k]
     [ (char-set-contains? L x) #\L]
     [ (char-set-contains? l x) #\l]
     [ (char-set-contains? N x) #\N]
     [ (char-set-contains? n x) #\n]
     [ (char-set-contains? O x) #\O]
     [ (char-set-contains? o x) #\o]
     [ (char-set-contains? R x) #\R]
     [ (char-set-contains? r x) #\r]
     [ (char-set-contains? S x) #\S]
     [ (char-set-contains? s x) #\s]
     [ (char-set-contains? T x) #\T]
     [ (char-set-contains? t x) #\t]
     [ (char-set-contains? U x) #\U]
     [ (char-set-contains? u x) #\u]
     [ (char-set-contains? W x) #\W]
     [ (char-set-contains? w x) #\w]
     [ (char-set-contains? Y x) #\Y]
     [ (char-set-contains? y x) #\y]
     [ (char-set-contains? Z x) #\Z]
     [ (char-set-contains? z x) #\z]
     [ else  x])
  ))
