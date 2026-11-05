-- Sounds your group can play. Names must be lowercase letters, digits, "_" or "-".
-- Everyone needs the same name in their Sounds.lua for a shared sound to play for them.
--
-- Two kinds of entries:
--   { kit  = "NAME" }   a built-in game sound (a key of the game's SOUNDKIT table)
--   { file = "path" }   your own .ogg or .mp3 inside this addon's Sounds folder
--
-- To add your own sound: put moo.ogg in Stjartgruppen/Sounds/ and add a line like
--   moo = { file = "Interface\\AddOns\\Stjartgruppen\\Sounds\\moo.ogg" },
-- A new sound file only works after a full game restart, not /reload.
-- Only add files you have the right to share. Bump the version in the .toc after editing.
local _, ns = ...

ns.sounds = {
    ping  = { kit = "MAP_PING" },
    ready = { kit = "READY_CHECK" },
    alert = { kit = "RAID_WARNING" },
    done  = { kit = "IG_QUEST_LIST_COMPLETE" },
    bell  = { kit = "ALARM_CLOCK_WARNING_3" },
}

-- The "reunion song": plays once (it never loops) when a friend in your group walks up to you.
-- See Proximity.lua for when it triggers. If the file is missing, the short "kit" sound plays instead.
-- The song goes into the public download, so only use music you have the right to share.
--
-- song.ogg: a 36-second excerpt (the love theme, from 13:05) of Pyotr Ilyich Tchaikovsky,
-- "Romeo and Juliet" overture-fantasy, performed by the Skidmore College Orchestra,
-- courtesy of Musopen (musopen.org), via Wikimedia Commons:
-- https://commons.wikimedia.org/wiki/File:Pyotr_Ilyich_Tchaikovsky_-_romeo_and_juliet-_overture-fantasy.ogg
-- Public domain. Trimmed, faded and volume-levelled for this addon.
ns.song = {
    file = "Interface\\AddOns\\Stjartgruppen\\Sounds\\song.ogg",
    kit = "IG_QUEST_LIST_COMPLETE",
}
