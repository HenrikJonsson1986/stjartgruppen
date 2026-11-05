# Stjartgruppen

Silly little extras for a group of friends in WoW: Forever.

## What it does
- A Message of the day window at login with a random kind word about you (turn it off with `/sg motd off`).
- Reunion song: when a group member walks up to you in the open world, a short love song plays once (`/sg song off` to turn it off).
- Shows a random quip when you log in (turn it off with `/sg greet`).
- Shared sounds: play a sound for yourself, or for everyone in your party who has the addon.
- If a friend in your party or guild has a newer version, you get a one-line reminder to update.

## Commands
- `/sg motd` - show the message of the day again (`/sg motd off` or `on` to change the login window)
- `/sg song` - play the reunion song (`/sg song stop` stops it, `/sg song off` or `on` for the automatic one)
- `/sg quip` - show a random quip
- `/sg sounds` - list the available sounds
- `/sg sound <name>` - play a sound just for you
- `/sg play <name>` - play a sound for your party (friends with the addon hear it too)
- `/sg mute` - stop (or resume) hearing sounds friends play
- `/sg greet` - turn the login quip on or off
- `/sg version` - show your version

Sounds from friends are limited to one every 10 seconds per friend, and you can mute them any time.

## Privacy
Stjartgruppen only sends two kinds of tiny messages to your party and guild over the normal addon channel: its version number (for example `V:0.2.0`) and the name of a sound you chose to play (for example `S:ping`). It collects nothing else and talks to no websites.

## Install
Install through the CurseForge app with the World of Warcraft Forever instance selected, or unzip the `Stjartgruppen` folder into `World of Warcraft/_forever_/Interface/AddOns/`.

## Want your own messages, quips or sounds?
Open `Stjartgruppen/Messages.lua`, `Stjartgruppen/Quips.lua` or `Stjartgruppen/Sounds.lua` in a text editor and add lines. Your friends need the same sound names to hear them.

## Credits
Reunion song: a 36-second excerpt of Franz Liszt, "Liebestraum No. 3", recording from the Al Goldstein collection (credited to Martha Goldstein) via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Franz_Liszt_-_Liebestraum,_Ab_Major.ogg), licensed [CC BY-SA 2.0](https://creativecommons.org/licenses/by-sa/2.0/). Trimmed, faded and volume-levelled; the excerpt is shared under the same license. The addon code is MIT.

Made for WoW: Forever (Interface 16001).
