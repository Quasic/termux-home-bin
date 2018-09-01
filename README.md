# termux-handlers
termux-url-opener and termux-file-editor menus using dialog
as well as a utility for duckduckgo searching

To install:
clone this repo and run make for options or manually run sh install.sh for just the menu system without installing make

It will install the dialog package if needed, and will backup any existing handlers in ~/bin (though I recommend renaming the backups if you really want to save them, because they aren't saved on a reinstall.) Note that files in usr/bin are NOT backed up.
