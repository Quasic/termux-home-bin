default:
	# to install, run make handlers or make duckduckgo or make all

check:
	bash test.sh

handlers:
	sh install.sh
	
duckduckgo:
	cp duckduckgo.sh "${PREFIX}/bin/duckduckgo"
	chmod +x "${PREFIX}/bin/duckduckgo"

prj:
	cp prj.sh "${PREFIX}/bin/prj"
	chmod +x "${PREFIX}/bin/prj"

proj:
	cp prj.sh "${PREFIX}/bin/proj"
	chmod +x "${PREFIX}/bin/proj"

all: check handlers duckduckgo prj
