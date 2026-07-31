#!/data/data/com.termux/files/usr/bin/sh
if [ $# -eq 0 ]
then
	printf 'Enter duckduckgo search:\n'
	read -r S
else
	S="$*"
fi
exec /data/data/com.termux/files/home/bin/termux-url-opener "https://duckduckgo.com/?q=$(printf %s "$S"| sed 's/%/%25/g; s/+/%2B/g; s/ /+/g; s/&/%26/g')"
