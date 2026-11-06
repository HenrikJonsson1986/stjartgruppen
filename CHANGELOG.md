# Changelog

## 0.6.0
- New: ping wheel. Hold Alt and the middle mouse button (or your own key) and pick Attack, On My Way, Warning or Assist by direction. It pings the mob under your mouse, using the game's ping system. Same look as the marker wheel.
- The middle of the wheels shows the group's hero in a round portrait.
- New: options panel in Options > AddOns > Stjartgruppen (or /sg options): wheel transparency (default 50%) and marker transparency (default 0%, fully visible), default marker keys, message of the day.
- Removed: the reunion song, the greeting whispers, the shared sounds (/sg play, /sg sound, /sg sounds, /sg mute) and the login quip (/sg quip, /sg greet). The message of the day stays. Stjartgruppen no longer sends any visible chat or whispers.
- New: pick your own keys for the marker wheel, next marker and previous marker in Options > Keybindings > AddOns > Stjartgruppen. Ctrl + middle mouse and Ctrl + scroll are the defaults, used only for actions you haven't bound and keys you haven't used. /sg mark shows your keys.
- New: marker wheel. Hold Ctrl and the middle mouse button over a mob (or with a target), and a wheel with all eight markers and a red X appears around the cursor. Move the mouse in the direction of a marker, any distance, and let go: it goes on the mob that was under the mouse, otherwise on your target. Skull is straight up and the red X (straight down) removes the marker, letting go in the middle cancels. Works in combat. Painted iron-and-gold look to match the group logo.
- New: marker rotator. Hold Ctrl and scroll up for the next marker (Skull, Cross, Square, Moon, Triangle, Diamond, Circle, Star) on the mob under your mouse or your target, scroll down for the previous one, Removing a marker starts the count at Skull again. A new mob starts at Skull (out of combat), and Ctrl + Shift + scroll up starts again from Skull. Works in combat. /sg mark wheel off turns the mouse keys off.
- The same rotator works from a macro: /click StjartgruppenMarkRotate (Shift+press starts again from Skull, Ctrl+press removes the marker). /sg mark shows how.

## 0.5.0
- New: greeting whispers. When a fellow Stjartgruppen user on your friends list or in your guild comes online, you whisper them a random nice message (at most once an hour per friend). Only people the addon has seen running Stjartgruppen get one; it finds them with hidden addon messages that players without the addon never see.
- New: /sg hello shows who it knows, /sg hello off (or on), /sg hello add or remove <name>, /sg hello test.

## 0.4.1
- New reunion song: the love theme from Tchaikovsky's "Romeo and Juliet" (36 seconds, plays once). It replaces Liebestraum.
- The Message of the day window now shows the Stjartgruppen logo.
- Friends installer: only 'Install Stjartgruppen.bat' and README.txt are at the top of the zip now; the other files are in a 'files' folder.

## 0.4.0
- New: reunion song. When a group member who was 40+ yards away walks up to within 10 yards of you, a 36-second excerpt of Liszt's "Liebestraum No. 3" plays once (open world only; the game gives no distances in dungeons, raids or PvP). Max once per 2 minutes, and once per 10 minutes per friend.
- New: /sg song plays it, /sg song stop stops it, /sg song off (or on) turns the automatic song off.

## 0.3.0
- New: a Message of the day window at login with a random kind word about you (40 messages). Click 'Another one' for more.
- New: /sg motd shows it again, /sg motd off (or on) turns it off at login.

## 0.2.0
- Shared sounds: `/sg sounds`, `/sg sound <name>` (just for you), `/sg play <name>` (for your whole party), `/sg mute`.
- Built-in game sounds to start with: ping, ready, alert, done, bell. Add your own in `Sounds.lua`.
- Sounds from friends are rate-limited (one per 10 seconds per friend) and can be muted.

## 0.1.0
- First version for WoW: Forever (Interface 16001).
- Random quip at login, `/sg quip`, `/sg greet`, `/sg version`.
- Tells you when a friend running Stjartgruppen has a newer version.
