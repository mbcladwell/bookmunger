#! /bin/bash

rm ./db/book.db
sqlite3 ./db/book.db < ./db/bookmunger.sql
rm /home/mbc/temp/lib/on-deck/*.*
rm /home/mbc/temp/lib/dest/*.*

cp /home/mbc/temp/lib/backups/*.epub /home/mbc/temp/lib/on-deck/
cp /home/mbc/temp/lib/backups/*.pdf /home/mbc/temp/lib/on-deck/
