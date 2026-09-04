# termux-home-bin

Small collection of Termux handler scripts and lightweight utilities:
- Menu wrappers for `termux-url-opener` and `termux-file-editor` using `dialog`, `termux-dialog` widget, or bash `select`.
- A tiny directory-based project organizer (prj).
- A command-line DuckDuckGo search helper.

## Features
- Interactive menu for handling shared URLs and files in Termux.
- **Dual dialog support**: Automatically uses `termux-dialog` (if available) or falls back to `dialog` or `select`.
- Customizeable via config file or environment variable.
- Lightweight "prj" directory-based organizer (inspired by `pass`) for storing project notes/bookmarks.
- `duckduckgo` command for quick searches from the shell.
- Installer that backs up existing handlers.

## Requirements
- Termux (Android)
- A POSIX shell (sh / bash) — scripts are standard shell scripts.
- `dialog` and/or `termux-dialog` are recommended, but bash `select` is a fallback

## Quick install
Clone the repo and run the installer:

1. Clone:
   ```
   git clone https://github.com/Quasic/termux-home-bin.git
   cd termux-home-bin
   ```

2. Install
   - Recommended (offers options): run `make` from this directory (select targets as needed).
   - Minimal installer (menu system only): run `sh install.sh`

Notes:
- The installer will back up any existing handlers in `~/bin`. I recommend moving or renaming those backups if you want to archive them permanently — the installer's backups are only a simple fallback.

- For `termux-dialog` support, install it with `pkg install termux-api`after installing the Termux:API app. The script will auto-detect and prefer it by default if available.

- You can also run `pkg install dialog` to upgrade it to the newest version, though it does come with modern Termux.

## Usage examples

- DuckDuckGo search:
  ```
  duckduckgo 'termux dialog tips'
  ```
  This opens a menu to choose what to do with the duckduckgo query url.
  Unquoted Example:
  ```
  duckduckgo termux dialog tips
  ```
  Just be careful of some symbols that will have special meaning to the shell.

- Handler menus:
  After installation, the repository installs handler scripts (for `termux-url-opener` and `termux-file-editor`) into `~/bin` by default. When an app passes a URL or file to Termux, these handlers will display a menu of options for what to do with it.

- prj (project organizer):
  ```
  prj help
  prj git init
  prj new group/this
  prj ls
  ```
  It's a directory-based organizer (similar in spirit to `pass`) intended to consolidate bookmarks, notes, and small files in ~/prj/ per project.

## Dialog Backend Selection

By default, the menu system will:
1. Check if `termux-dialog` is installed and use it if available
2. Fall back to `dialog` if `termux-dialog` is not found
3. Fall back to bash select if dialog is not found.

You can override this behavior by setting the `TERMUX_URL_OPENER_CONFIG` environment variable or creating `.termux-url-opener.conf` in the same directory (usually `~/bin`):

```
# Create config file
~ $ bin/termux-url-opener dump config > bin/.termux-url-opener.conf

# Change termux-dialog widget
nano bin/.termux-url-opener.conf
# in the [display] section, at the top of the file, edit the line
termux-dialog-widget=...
# a blank or unknown widget will disable it

# Disable dialog: in the config file, remove
dialog
# or replace with one of these:
#dialog
dialog=
# I do this on my Android 7 device, where modern dialog acts strange

# To use dialog, but have termux-dialog as a backup for some reason,
# just swap the order of those lines in the file, so dialog comes first

# I recommend leaving bash in the list,
# because it should be the most reliable.
bash

# Other sections
[url]
# This section gives options to show in the menu for urls
# They can be just a command
termux-clipboard-set
# or have a menu label
Copy to clipboard=termux-clipboard-set
# Menu labels can't include equals, but commands can
test if its blah=test blah =
# Blank lines and commands are ignored
This option won't show=
[file]
# Same for file menu options
[both]
# options listed here will show in both menus

# Comments always have their own line
key=value # This is part of the value, not a comment
# That comment will most likely hide the url or file from the command
# but it's allowed for things like this:
Add as comment to config file={ printf '\n# ';cat } >>configfile <<<

# After editing, it's always a good idea to test the config file in each handler
~ $ bin/termux-url-opener test config
~ $ bin/termux-file-editor test config
# This will explain how it processes the file up to the point of
# showing the menu. It will NOT test the menu or whether commands
# work as expected once selected. For that, try sharing a file to
# Termux or running the script:
termux-url-opener http://example.com
# Then select the option to test it

# After updating/reinstallation you may want to diff with the new default config:
~ $ diff bin/.termux-url-opener.conf <(bin/termux-url-opener dump config)
```

## Backups & Uninstall
- Backups: existing handlers from `~/bin` (not .../usr/bin) are backed up by the installer. After verifying the new handlers work, move any backups you want to keep into a safe location.
- Uninstall: remove the installed scripts from `~/bin` and restore your backups. You can also manually remove duckduckgo and prj from .../usr/bin.

## Tested & compatibility
- Testing note: I now currently use this on Android 7 and 11. I tested Android 5 in the past. I had trouble on Android 7 (see issue #1) that caused me to refactor from a simple script to a state machine. If you test on another Android/Termux version, please report results in the issues.
  - Issue: https://github.com/Quasic/termux-home-bin/issues/1

## Development & Contributing
- Contributions welcome. Open an issue to discuss larger changes or submit a pull request for bug fixes and improvements.
- Prefer small, focused PRs with a short description of the change and how to test it.

## License
GPL-3

## Contact / Author
- Repository: https://github.com/Quasic/termux-home-bin
