# termux-home-bin

Small collection of Termux handler scripts and lightweight utilities:
- Menu wrappers for `termux-url-opener` and `termux-file-editor` using `dialog` or `termux-dialog`.
- A tiny directory-based project organizer (prj).
- A command-line DuckDuckGo search helper.

## Features
- Interactive menu for handling shared URLs and files in Termux.
- **Dual dialog support**: Automatically uses `termux-dialog` (if available) or falls back to `dialog`.
- Lightweight "prj" directory-based organizer (inspired by `pass`) for storing project notes/bookmarks.
- `duckduckgo` command for quick searches from the shell.
- Installer that will attempt to install `dialog` if it is missing and backs up existing handlers.

## Requirements
- Termux (Android)
- `dialog` and/or `termux-dialog` (at least one required; the installer will attempt to install `dialog` if missing)
- A POSIX shell (sh / bash) — scripts are standard shell scripts.

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
- If `dialog` is not installed or outdated, the installer will attempt to install/update it (or you can install manually with `pkg install dialog`).
- For `termux-dialog` support, install it with `pkg install termux-dialog`. The script will auto-detect and prefer it if available.

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

You can override this behavior by setting the `TERMUX_DIALOG` environment variable:

```bash
# Force termux-dialog
export TERMUX_DIALOG=termux-dialog
# or
export TERMUX_DIALOG=1

# Force dialog
export TERMUX_DIALOG=dialog
# or
export TERMUX_DIALOG=2

# Auto-detect (default)
unset TERMUX_DIALOG
```

## Backups & Uninstall
- Backups: existing handlers from `~/bin` (not .../usr/bin) are backed up by the installer. After verifying the new handlers work, move any backups you want to keep into a safe location.
- Uninstall: remove the installed scripts from `~/bin` and restore your backups. You can also manually remove duckduckgo and prj from .../usr/bin.

## Tested & compatibility
- Testing note: I currently only test this on Android 11. I tested Android 5 and 7 in the past. (see issue #1). If you test on another Android/Termux version, please report results in the issues.
  - Issue: https://github.com/Quasic/termux-home-bin/issues/1

## Development & Contributing
- Contributions welcome. Open an issue to discuss larger changes or submit a pull request for bug fixes and improvements.
- Prefer small, focused PRs with a short description of the change and how to test it.

## License
GPL-3

## Contact / Author
- Repository: https://github.com/Quasic/termux-home-bin
