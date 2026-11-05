# Changelog

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
