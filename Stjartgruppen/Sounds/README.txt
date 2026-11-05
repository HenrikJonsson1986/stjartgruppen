Put your own sound files (.ogg or .mp3) in this folder, then register them in ../Sounds.lua.

Example line for Sounds.lua:
    moo = { file = "Interface\\AddOns\\Stjartgruppen\\Sounds\\moo.ogg" },

The reunion song (played once when a friend walks up to you) is song.ogg in this folder.
To use another file, change ns.song.file at the bottom of ../Sounds.lua.

Restart the game fully after adding a file (/reload will not find it).
Only use files you have the right to share.

CREDITS
song.ogg - Franz Liszt, "Liebestraum No. 3 in A-flat major" (36-second excerpt).
  Recording from the Al Goldstein collection (credited to Martha Goldstein), via Wikimedia Commons:
  https://commons.wikimedia.org/wiki/File:Franz_Liszt_-_Liebestraum,_Ab_Major.ogg
  License: CC BY-SA 2.0 (https://creativecommons.org/licenses/by-sa/2.0/).
  Changes: trimmed, faded in/out and volume-levelled. This excerpt is shared under CC BY-SA 2.0.
  (The addon's code is MIT; this sound file keeps its own CC BY-SA 2.0 license.)
