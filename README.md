# Book Munger

You are busy. You read WSJ, NYT, follow on Twitter, Gettr, Givvr, Gottr. Your friends are making suggestions on GoodReads, Scribd, Libib. How to keep up? Book Munger can't help you with the reading, but can help you collect, organize, and keep ebooks at your fingertips so that when free time becomes available, you will have access to the books everyone is reading.

Book Munger also works on the assumption that you don't trust Amazon, Mendely, Zotero with your property nor your privacy.  You want control of your books - no DRM, no expiration, no spying, and always available.  The source code of Book Munger is available for inspection to assure you that your privacy is protected.

From this point on I will refer to Book Munger using the unfortunate initials "BM". BM is a terminal application designed to be fast and unobtrusive. It is easily installed onto your favorite Linux distribution using the Guix Package Manager. Wait - you aren't using Linux yet!! - don't hang up!!!  Because BM doesn't require any windowing software, you can spin up your favorite distribution in the cloud, install, and voila! book management with the distrubution managed by your cloud provider. 

## Book Munger Workflow

A typical workflow with BM would look like the following:

 * You are reading something, a website, the news, a tweet.  A book is mentioned that sounds appealing to you. You know you have no time to read it now, but you would like to grab it and put it in your library.
 
 * You download the book, maybe from Gutenberg, maybe ManyBooks, wherever, and place it in the BM "on-deck" directory. That's it. You move on, keep reading or next activity.  Nothing more need be done until you decide to batch process all the books in your on-deck directory.  BM is meant to be non-obtrusive. Don't interupt your workflow or thought process to add a book to your library - do it later.
 
 * Time comes to process your on-deck directory. Maybe once a week, once a month.  Depends on you. You launch BM, it finds books in your on-deck directory. BM will cycle through each book, extracting title, authors from the filename, prompt you for tags, and load the book into the database. As books are processed, they are rename and deposited into a destination "library" directory.
 
 * At any time you can query the library by title, author, or tag (keyword). Books that match your query criteria can be opened, or copied to a "readme" directory. The purpose of the readme directory is to hold the books that are to be read soon.
 
 * A session with BM begins by automatically making a backup copy of the database, should things go awry. The database is SQLite, so you may access and manipulate your data should you be so inclined. The application is written in Guile, the GNU extension language (<b>G</b>nu <b>U</b>biquitous <b>I</b>ntelligent <b>L</b>anguage for <b>E</b>xtensions), so you can even enhance with your own code without much difficulty.
 
 ## Book File Name Requirements
 
 As mentioned above, title and author(s) are extracted from the ebook file name, so this name needs to be informative and fit certain patterns.  BM does not provide forms for modifying title or authors.  This is achieved by modifying (renaming) the file directly. Natural intelligence (mine) has been used to design algorithms that can extract author names from a variety of formats.  The decision tree is outlined below. The general pattern for file names is:
 
 * [title] by [author(s)] [suffix] . [extension]  e.g. Dune by Frank Herbert (ManyBooks).epub
 
 extension: e.g. .epub, .pdf, .mobi.  The extension is saved and applied to the final book name
 
 suffix: removed and discarded. Some providers attach a suffix to the book name as a form of advertising e.g. Dune by Frank Herbert (ManyBooks).epub.  In all cases the suffix is removed and discarded. The new title of the book in the database would be Dune and the file would be Dune.epub
 
 by: the word by must be in the file name and is used to separate title and authors. Everything to the left of the rightmost "by" is considered the title, and everything to the right is the author(s). The algorithm for sorting authors is described below.
 
 title: Everything to the left of the rightmost "by" is considered the title.
 
 Note that some books are delivered with a filename like 28376as.pdf.  This file would need to be renamed to something like "Title of the Book by Fname1 Lname1 and Fname2 Lname2.pdf
 
 ## Author Handling
 
 BM will handle multiple types of author designations:
 
 * by Fname Lname
 * by Fname1 Lname1 and Fname2 Lname2
 * by Fname1 Lname1, Fname2 Lname2, .... , FnameN LnameN
 * by Lname, Fname
 * by Lname1, Fname1 and Lname2, Fname2
 
 Note that title and authors must always be separated by " by "
 Note that if last name is first, names must be separated by and, two names at most.  Commas can not separate last names first e.g. not Lname1, Fname1, Lname2, Fname2,... etc.
 
 When renaming a file, choose one of the patterns above.
 
 
 
 
 
 
 
 
