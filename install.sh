#!/data/data/com.termux/files/usr/bin/sh
pkg install dialog
mkdir -p ~/bin
if [ -e ~/bin/termux-url-opener ]
then mv ~/bin/termux-url-opener ~/bin/termux-url-opener~ && echo backed up ~/bin/termux-url-opener to ~/bin/termux-url-opener~
fi
if [ -e ~/bin/dialog-wrapper.sh ]
then mv ~/bin/dialog-wrapper.sh ~/bin/dialog-wrapper.sh~ && echo backed up ~/bin/dialog-wrapper.sh to ~/bin/dialog-wrapper.sh~
fi
cp termux-url-opener ~/bin
cp dialog-wrapper.sh ~/bin
if cd ~/bin
then
chmod +x termux-url-opener dialog-wrapper.sh && echo "termux-url-opener and dialog-wrapper.sh installed at $(realpath termux-url-opener)"
ln -sfb termux-url-opener termux-file-editor && echo termux-file-editor installed as symlink with -b option
else echo Could not cd to ~/bin
fi
