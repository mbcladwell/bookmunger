;; (define-module (bookmunger utilities)
;;   #:export (find-occurences-in-string
;; 	    any-not-false?
;; 	    display-logo
;; 	    display-main-menu
;; 	    ))


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

;
 (define (display-logo)
   ;;https://patorjk.com/software/taag/#p=display&f=Big&t=Book%20Munger
   (begin
     (system "printf \"\\033c\"")
     (display "  ____              _      __  __\n")
     (display " |  _ \\            | |    |  \\/  |\n")
     (display " | |_) | ___   ___ | | __ | \\  / |_   _ _ __   __ _  ___ _ __\n")
     (display " |  _ < / _ \\ / _ \\| |/ / | |\\/| | | | | '_ \\ / _  |/ _ \\ '__|\n")
     (display " | |_) | (_) | (_) |   <  | |  | | |_| | | | | (_| |  __/ |\n")
     (display " |____/ \\___/ \\___/|_|\\_\\ |_|  |_|\\__,_|_| |_|\\__, |\\___|_|\n")
     (display "                                               __/ |\n")
     (display "                                              |___/    \n")
     (display (string-append "Library: " top-dir "\n"))
     (display "Ctrl-z to exit\n\n")))

(define (display-main-menu)
  (begin
    (display-logo)
    (display "1 Query Library\n")
    (display "2 Process on-deck files\n")
    (display "3 Add a tag\n\n")
  
  ))
