#!/bin/bash
x=0
fail(){
printf %s\\n "$1 failed test: $2"
((x++))
}
# check Makefile
if command -v make
then
	make -n all>/dev/null||fail Makefile 'make -n all'
	make -n proj>/dev/null||fail Makefile 'make -n proj'  # deprecated, due to name conflict, but still testing
else printf 'SKIPPED TESTS: no make\n'
fi
# check shell scripts
for s in ./*.sh termux-url-opener
do bash -n "$s"||fail "$s" 'bash -n'
done
if command -v shellcheck
then shellcheck ./*.sh termux-url-opener||fail '*.sh termux-url-opener' shellcheck
else printf 'SKIPPED TESTS: no shellcheck\n'
fi
# check prj.sh
bash prj.sh version||fail prj.sh version
# Results
if [ "$x" = 0 ]
then printf Passed!\\n
else
	printf '%i failures\n' "$x"
	exit 1
fi
