#!/data/data/com.termux/files/usr/bin/bash
v=0.5
#2.0 should support git like pass does
h="$HOME/proj"
c="$(basename "$0")"
mkdir -p "$h"

function gp {
	if [[ $# -lt 1 || "$1" == "" ]]
	then
		echo "Please enter project name:"
		read p
	else p="$1"
	fi
	pp="$h/$p"
	if ! [ -d "$pp" ]
	then
		echo "Project $p doesn't exist. Create it? (y/n)"
		read -n1 q
		if [[ "$q" =~ [Yy] ]]
		then
			mkdir -p "$pp" || exit 2
		else exit 1
		fi
	fi
}

if [[ $# -eq 0 || "$1" =~ ^(-h|h|--help|help)$ ]]
then
	echo "Usage: $c help # for this screen"
	echo "$c new <proj>"
	echo "$c ls [proj]"
	echo "$c mv <proj> <newproj>"
	echo "$c file <proj> <path> [name] # mv file into project space"
	echo "$c edit <proj> <name>"
	echo "$c url <proj> <url>"
	echo "$c version"
elif [[ "$1" == "version" ]]
then
	echo "proj (as $c) version $v working in $h"
elif [[ "$1" == "ls" ]]
then
	ls "$h/$2"
elif [[ "$1" == "tree" ]]
then
	tree "$h/$2"
elif [[ "$1" == "browse" ]]
then ~/bin/termux-url-opener "file://$(realpath "$h/$2")"
elif [[ "$1" == "new" ]]
then
	if [ -d "$h/$2" ]
	then echo "Project $2 already exists"
	else mkdir -p "$h/$2" && echo "Project folder $2 created" || exit 2
	fi
elif [[ "$1" == "mv" ]]
then
	if [ -d "$h/$3" ]
	then echo "Project $3 already exists."
	else
		gp "$2"
		mv "$pp" "$h/$3" && echo "$p renamed to $3"
	fi
elif [[ "$1" == "file" ]]
then
	if [ -f "$3" ]
	then
		gp "$2"
		n=${4:-"$(basename "$3")"}
		if [ -f "$h/$n" ]
		then echo "$n already exists in project $p"
		else mv "$3" "$h/$n" && echo "moved $3 to $n in project $p"
		fi
	else echo "$3 not found"
	fi
elif [[ "$1" == "edit" ]]
then
	gp "$2"
	~/bin/termux-file-editor "$pp"
elif [[ "$1" == "url" ]]
then
	gp "$2"
	if ! [ -f "$pp/bookmarks.html" ]
	then echo "<html><head><title>$p bookmarks</title></head><body><h1><a href=\".\">$p</a> bookmarks</h2><ul>" > "$pp/bookmarks.html"
	fi
	echo Title for $3 for project $p
	read t
	echo "<li><a href=\"$3\">${t:-"$3"}</e></li>" >> "$pp/bookmarks.html"
elif [[ "$1" == "bookmarks" ]]
then
	gp "$2"
	~/bin/termux-url-opener "file://$(realpath "$pp/bookmarks.html")"
else echo "unknown command: $1 (try '$c help')"
fi
