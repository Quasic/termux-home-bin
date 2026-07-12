#!/data/data/com.termux/files/usr/bin/sh
pkg install dialog
mkdir -p ~/bin
if [ -e ~/bin/termux-url-opener ]
then mv ~/bin/termux-url-opener ~/bin/termux-url-opener~ && echo backed up ~/bin/termux-url-opener to ~/bin/termux-url-opener~
fi
cp termux-url-opener ~/bin
if cd ~/bin
then
chmod +x termux-url-opener && echo "termux-url-opener installed at $(realpath termux-url-opener)"
ln -sfb termux-url-opener termux-file-editor && echo termux-file-editor installed as symlink with -b option
else echo Could not cd to ~/bin
fi