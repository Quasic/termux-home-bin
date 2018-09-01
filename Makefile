default:
	# to install, run make handlers or make duckduckgo or make all

handlers:
	sh install.sh
	
duckduckgo:
	cp duckduckgo "$PREFIX/bin/duckduckgo"
	chmod +x "$PREFIX/bin/duckduckgo"

all: handlers duckduckgo
