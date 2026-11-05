# Stjartgruppen (developer notes)

WoW: Forever addon (Interface 16001). Source lives here in `_dev/projects/Stjartgruppen/`; the addon folder is `Stjartgruppen/`.

## Everyday workflow
1. Edit files in `Stjartgruppen/`.
2. Lint (from this folder): `& "C:\Program Files (x86)\World of Warcraft\_dev\tools\luacheck\luacheck.exe" --config .luacheckrc Stjartgruppen`
3. Test in game: `python -I build.py --install`, then `/reload` (a brand-new addon or sound file needs a full game restart).

## Releasing a new version (the update flow)
1. `python -I build.py --bump patch --notes "What changed"` (use `minor` for new features). This raises the version in the .toc, adds a CHANGELOG entry, and writes to `dist/`:
   - `Stjartgruppen-<version>.zip` (for CurseForge; the only versioned zip kept there, so the wrong one can't be uploaded)
   - `Stjartgruppen-Installer.zip` (for friends: addon + double-click Windows installer)
   - `release-notes.md` (paste this into the CurseForge upload form)
2. Commit, then tag and push: `git tag v<version>` and `git push origin main --tags`.
   The GitHub Actions workflow (`.github/workflows/release.yml`) checks the tag matches the .toc version, builds both zips and publishes a GitHub release. The friends' link then serves the new installer:
   https://github.com/HenrikJonsson1986/stjartgruppen/releases/latest/download/Stjartgruppen-Installer.zip
3. CurseForge: open the project (ID 1784894), Files, upload `Stjartgruppen-<version>.zip`, game version WoW: Forever / 1.60.1, paste the release notes, Release. Friends using the CurseForge app get it after review.

## The friends installer (`installer/`)
In the friends' zip only `Install Stjartgruppen.bat` and `README.txt` sit at the top; `install.ps1` and the addon folder go into `files/` (see `INSTALLER_TOP` in `build.py`) so it's obvious what to double-click. `Install Stjartgruppen.bat` runs `files\install.ps1` with Windows PowerShell. It finds the game folder (registry, then common folders on every drive, then a folder picker), copies `Stjartgruppen/` into `_forever_\Interface\AddOns` (replacing an older copy) and leaves the WTF settings alone. If the game folder needs admin rights it asks for them. Test it without touching the game, from an extracted copy of `dist/Stjartgruppen-Installer.zip` (the .bat expects the `files/` layout): `& ".\Install Stjartgruppen.bat" -DryRun -NoPause`, or `-WowPath "<some folder>"` to install somewhere else.

## First-time publishing on CurseForge (you do this yourself)
1. Create a CurseForge author account (log in at authors.curseforge.com).
2. Create a project: Game = World of Warcraft, Category = Addons (pick the closest sub-category).
3. Name: Stjartgruppen. Summary: "Silly little extras for a group of friends." Description: paste `CURSEFORGE_DESCRIPTION.md`. License: MIT.
4. Upload the first zip from `dist/` as above. The first file triggers moderation of the whole project.
5. Moderation runs roughly 8 AM to 3 PM CET every day, first in first out, and can take a few days. You get a notification when it's approved or rejected.
6. The name has to be unique. If it is taken, pick another and tell Claude so everything can be renamed.

## What your friends do
See `FRIENDS_INSTALL.md` (a short message you can paste in your group chat).

## Later (optional)
Automatic uploads from GitHub with an API token exist, but they need a GitHub repository and a secret token, so they are not set up.
