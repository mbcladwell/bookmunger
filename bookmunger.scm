;;#! /gnu/store/q8brh7j5mwy0hbrly6hjb1m3wwndxqc8-guile-3.0.5/bin/guile \
;;-e main -s
;;!#

 (add-to-load-path "/home/mbc/projects")

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
	     (ice-9 string-fun)  ;;string-replace-substring
	     (ice-9 pretty-print)
	     (bookmunger utilities)
	     (bookmunger logging)   ;; logging is in guile-lib
             (logging logger)
             (logging rotating-log)
             (logging port-log)
	     )

(define book-count 0)

(define (remove-zlib str)
   (let*
	(string-index str /#.))


(define (main args)
  ;; args: mod - remove ' (zlib.org) from filename
  ;;       stash - put into xml file
  (let* ((start-time (current-time time-monotonic))
	 (dummy2 (log-msg 'CRITICAL (string-append "Starting up at: "  (number->string (time-second start-time)))))
	 (a (get-summaries (cadr args) (caddr args)))
	 (dummy (map retrieve-article a))  ;;this does all the work; comment out last line for testing
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
