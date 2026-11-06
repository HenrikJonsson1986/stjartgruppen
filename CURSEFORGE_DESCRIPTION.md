# Stjartgruppen

Silly little extras for a group of friends in WoW: Forever.

## What it does
- A Message of the day window at login with a random kind word about you (turn it off with `/sg motd off`).
- Marker wheel: hold Ctrl and the middle mouse button over a mob (or with a target), move the mouse toward a marker on the wheel that appears, and let go. It marks the mob that was under your mouse, otherwise your target. Skull is straight up, and the red X (straight down) removes the marker, letting go in the middle cancels. Works in combat.
- Ping wheel: hold Alt and the middle mouse button and pick Attack, On My Way, Warning or Assist the same way. It pings the mob under your mouse, using the game's own ping system.
- Marker rotator: hold Ctrl and scroll up to put the next raid marker (Skull, Cross, Square, Moon, ...) on the mob under your mouse or your target, scroll down for the previous one. A new mob starts at Skull. It also works as a macro (`/click StjartgruppenMarkRotate`; Shift starts again from Skull, Ctrl removes the marker). Works in combat, because it uses Blizzard's own marker button.
- If a friend in your party or guild has a newer version, you get a one-line reminder to update.

The marker keys can be changed in Options > Keybindings > AddOns > Stjartgruppen. Ctrl + middle mouse (markers), Alt + middle mouse (pings) and Ctrl + scroll are the defaults.

## Commands
- `/sg motd` - show the message of the day again (`/sg motd off` or `on` to change the login window)
- `/sg options` - open the options (wheel transparency and more), also in Options > AddOns > Stjartgruppen
- `/sg mark` - your marker and ping keys and how to change them (`/sg mark wheel off` or `on` for the default keys)
- `/sg version` - show your version

## Privacy
Over the hidden addon channel, Stjartgruppen only sends tiny messages: its version number to your party and guild (for example `V:0.6.0`), so it can tell you when a friend has a newer version. Players without the addon never see it. It sends no visible chat, collects nothing and talks to no websites.

## Install
Install through the CurseForge app with the World of Warcraft Forever instance selected, or unzip the `Stjartgruppen` folder into `World of Warcraft/_forever_/Interface/AddOns/`.

## Want your own messages?
Open `Stjartgruppen/Messages.lua` in a text editor and add lines.

## Credits
The addon code is MIT. Marker icons are the game's own.

Made for WoW: Forever (Interface 16001).
