-- Reunion song: when a friend in your group comes close to you, play ns.song.
-- Every player with the addon runs this for themselves, so both of you hear it when you meet.
--
-- How "close" works: once a second (only while you are in a group) it asks the game how far
-- each group member is (UnitDistanceSquared). A friend has to have been FAR away first and then
-- come NEAR, so standing next to each other doesn't replay it. The game only gives distances in
-- the open world, not in dungeons, raids, battlegrounds or arenas, so nothing happens there.
local _, ns = ...

local NEAR = 10            -- yards: this close counts as "met up"
local FAR = 40             -- yards: this far counts as "apart again"
local FRIEND_COOLDOWN = 600 -- seconds before the same friend can trigger it again
local SONG_COOLDOWN = 120  -- seconds between songs, whoever triggers it
local TICK = 1             -- seconds between distance checks

local NEAR_SQ, FAR_SQ = NEAR * NEAR, FAR * FAR

local ticker
local state = {}        -- friend name -> "near" | "far"
local lastFriend = {}   -- friend name -> GetTime() of their last trigger
local lastSong = -SONG_COOLDOWN
local songHandle

local function inCombat()
    local f = (C_RestrictedActions and C_RestrictedActions.InCombatLockdown) or InCombatLockdown
    return f and f() or false
end

local function stopSong()
    if songHandle then
        StopSound(songHandle)
        songHandle = nil
    end
end

-- Plays the song (or the fallback sound if the file is missing). Returns true if anything played.
local function playSong()
    local song = ns.song or {}
    stopSong()
    if song.file then
        local willPlay, handle = PlaySoundFile(song.file, "Master")
        if willPlay then
            songHandle = handle
            return true
        end
    end
    if song.kit and SOUNDKIT and SOUNDKIT[song.kit] then
        PlaySound(SOUNDKIT[song.kit])
        return true
    end
    return false
end

-- Unit tokens built once, so the once-a-second check allocates no strings.
local RAID, PARTY = {}, {}
for i = 1, 40 do RAID[i] = "raid" .. i end
for i = 1, 4 do PARTY[i] = "party" .. i end

local function check()
    local now = GetTime()
    local units, count = PARTY, GetNumSubgroupMembers()
    if IsInRaid() then units, count = RAID, GetNumGroupMembers() end
    for i = 1, math.min(count, #units) do
        local unit = units[i]
        if UnitExists(unit) and not UnitIsUnit(unit, "player") and UnitIsConnected(unit) then
            local name = UnitName(unit)
            local d2, checked = UnitDistanceSquared(unit)
            local usable = name and checked and type(d2) == "number"
                and not (issecretvalue and (issecretvalue(d2) or issecretvalue(name)))
            if usable then
                if d2 <= NEAR_SQ then
                    if state[name] == "far" then
                        state[name] = "near"
                        local ready = now - lastSong >= SONG_COOLDOWN
                            and now - (lastFriend[name] or -FRIEND_COOLDOWN) >= FRIEND_COOLDOWN
                        if ready and not inCombat() and StjartgruppenDB.song then
                            lastSong, lastFriend[name] = now, now
                            playSong()
                            ns.say(name .. " is here! (/sg song off to turn the reunion song off)")
                        end
                    elseif state[name] == nil then
                        state[name] = "near" -- already together when we started looking
                    end
                elseif d2 >= FAR_SQ then
                    state[name] = "far"
                end
            end
        end
    end
end

-- Start checking while in a group, stop when not. Called from Core.lua on login and roster changes.
function ns.UpdateProximity()
    if IsInGroup() and StjartgruppenDB.song then
        if not ticker then ticker = C_Timer.NewTicker(TICK, check) end
    elseif ticker then
        ticker:Cancel()
        ticker = nil
        wipe(state)
    end
end

ns.PlaySong = playSong
ns.StopSong = stopSong
