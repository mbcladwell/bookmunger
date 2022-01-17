#!/usr/bin/gawk -f
BEGIN {
	FS=":";
}
{
    gsub(/^[ \t]+|[ \t]+$/,"",$1);
    gsub(/^[ \t]+|[ \t]+$/,"",$2);
    
    if ( $1 == "Title" || $1 == "Author(s)") {
		print  "\"" $2 "\"";
    } 
}
