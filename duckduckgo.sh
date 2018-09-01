#!/data/data/com.termux/files/usr/bin/sh
if [ $# -eq 0 ]
then
	echo Enter duckduckgo search:
	read S
else
	S=
fi
/data/data/com.termux/files/home/bin/termux-url-opener https://duckduckgo.com/?q=$(echo "${S:-$*}"|sed 's/ /+/g')
