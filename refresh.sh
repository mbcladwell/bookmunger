#! /bin/bash

rm /home/mbc/temp/lib/db/book.db
sqlite3 /home/mbc/temp/lib/db/book.db < ./db/bookmunger.sql
rm /home/mbc/temp/lib/on-deck/*.*
rm /home/mbc/temp/lib/files/*.*
rm /home/mbc/temp/lib/readme/*.*

cp /home/mbc/temp/lib/backups/*.epub /home/mbc/temp/lib/on-deck/
cp /home/mbc/temp/lib/backups/*.pdf /home/mbc/temp/lib/on-deck/
