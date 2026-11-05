std = "lua51"
max_line_length = false
ignore = { "212/self", "212/event" }

globals = {
    "StjartgruppenDB",
    "SLASH_STJARTGRUPPEN1", "SLASH_STJARTGRUPPEN2", "SlashCmdList",
}

read_globals = {
    "CreateFrame", "print", "GetTime", "IsInGuild", "IsInGroup", "UnitName",
    "C_ChatInfo", "C_AddOns", "C_Timer",
    "PlaySound", "PlaySoundFile", "SOUNDKIT",
    "UIParent", "UISpecialFrames", "tinsert", "wipe", "StopSound",
    "IsInRaid", "GetNumGroupMembers", "GetNumSubgroupMembers", "UnitExists", "UnitIsUnit",
    "UnitIsConnected", "UnitDistanceSquared", "issecretvalue",
    "C_RestrictedActions", "InCombatLockdown",
    "Ambiguate", "C_FriendList", "C_GuildInfo", "GetNumGuildMembers", "GetGuildRosterInfo", "time",
}
