# Stjartgruppen

Silly little extras for a group of friends in WoW: Forever.

## What it does
- Shows a random quip when you log in (turn it off with `/sg greet`).
- Shared sounds: play a sound for yourself, or for everyone in your party who has the addon.
- If a friend in your party or guild has a newer version, you get a one-line reminder to update.

## Commands
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

## Want your own quips or sounds?
Open `Stjartgruppen/Quips.lua` or `Stjartgruppen/Sounds.lua` in a text editor and add lines. Your friends need the same sound names to hear them.

Made for WoW: Forever (Interface 16001).
