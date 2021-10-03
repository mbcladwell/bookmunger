#!guile
!#
(use-modules (srfi srfi-1)
             (ncurses curses)
             (ncurses form))



  (let* ((stdscr (initscr))
	 (a (addstr stdscr "Hello World!!!"))
	 (b (refresh stdscr))
	 (c (getch stdscr)))
  (endwin))
