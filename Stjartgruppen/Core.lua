-- Stjartgruppen: quips, shared sounds, and a friendly "newer version available" notice.
-- Lua 5.1. Over the hidden addon channel it sends only short strings:
--   "V:<version>"   version (to guild/party, or as the answer to a probe)
--   "P:<version>"   probe: "do you have Stjartgruppen?" (whispered, see Greetings.lua)
--   "S:<sound name>" a shared sound (party only)
local ADDON_NAME, ns = ...

local PREFIX = "STJARTGRUPPEN" -- addon message prefix, 16 chars max
ns.PREFIX = PREFIX
local defaults = { greet = true, muteSounds = false, motd = true, song = true, hello = true }
local PROBE_REPLY_COOLDOWN = 30 -- seconds between answers to the same player's probes
local lastProbeReply = {}
local SEND_COOLDOWN = 60      -- seconds between version broadcasts per channel
local SOUND_SEND_COOLDOWN = 3 -- seconds between sounds you can send
local SOUND_RECV_COOLDOWN = 10 -- seconds between sounds accepted from the same friend

local myVersion = "0"
local notifiedVersion = nil
local lastSent = {}
local lastSoundSent = 0
local lastSoundFrom = {}

local function say(msg)
    print("|cffffcc33Stjartgruppen|r: " .. tostring(msg))
end
ns.say = say

local function randomQuip()
    local quips = ns.quips
    if not quips or #quips == 0 then return nil end
    return quips[math.random(#quips)]
end

-- "1.2.10" -> {1, 2, 10}
local function parseVersion(v)
    local parts = {}
    for n in tostring(v or ""):gmatch("%d+") do parts[#parts + 1] = tonumber(n) end
    return parts
end

-- true if a is newer than b
local function isNewer(a, b)
    local pa, pb = parseVersion(a), parseVersion(b)
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

local function broadcast(channel)
    local now = GetTime()
    if lastSent[channel] and now - lastSent[channel] < SEND_COOLDOWN then return end
    lastSent[channel] = now
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, "V:" .. myVersion, channel)
end

local function broadcastAll()
    if IsInGuild() then broadcast("GUILD") end
    if IsInGroup() then broadcast("PARTY") end
end

----------------------------------------------------------------------
-- Sounds
----------------------------------------------------------------------
local function validName(name)
    return type(name) == "string" and #name > 0 and #name <= 20 and name:match("^[%w_%-]+$") ~= nil
end

-- Plays a sound from ns.sounds by name. Returns true if it played.
local function playSound(name)
    local s = validName(name) and ns.sounds and ns.sounds[name]
    if not s then return false end
    if s.file then
        PlaySoundFile(s.file, "Master")
        return true
    elseif s.kit and SOUNDKIT and SOUNDKIT[s.kit] then
        PlaySound(SOUNDKIT[s.kit])
        return true
    end
    return false
end

local function soundNames()
    local names = {}
    for k in pairs(ns.sounds or {}) do names[#names + 1] = k end
    table.sort(names)
    return names
end

local function sendSound(name)
    if not IsInGroup() then
        say("you are not in a party, so nobody can hear it. (/sg sound " .. name .. " plays it just for you.)")
        return
    end
    local now = GetTime()
    if now - lastSoundSent < SOUND_SEND_COOLDOWN then
        say("slow down a little.")
        return
    end
    lastSoundSent = now
    playSound(name)
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, "S:" .. name, "PARTY")
end

local function shortName(sender)
    return (tostring(sender or "?"):match("^[^-]+")) or "?"
end

local function handleSound(name, sender)
    if StjartgruppenDB.muteSounds then return end
    local who = shortName(sender)
    if who == UnitName("player") then return end -- our own message echoed back
    local now = GetTime()
    if lastSoundFrom[who] and now - lastSoundFrom[who] < SOUND_RECV_COOLDOWN then return end
    lastSoundFrom[who] = now
    if playSound(name) then
        say(who .. " played '" .. name .. "'. (/sg mute to silence shared sounds)")
    else
        say(who .. " played '" .. tostring(name) .. "', but you don't have that sound. Update the addon!")
    end
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        StjartgruppenDB = StjartgruppenDB or {}
        for k, v in pairs(defaults) do
            if StjartgruppenDB[k] == nil then StjartgruppenDB[k] = v end
        end
        myVersion = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0"
        ns.version = myVersion
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    elseif event == "PLAYER_LOGIN" then
        if StjartgruppenDB.greet then
            local q = randomQuip()
            if q then say(q) end
        end
        if StjartgruppenDB.motd and ns.ShowMOTD then
            C_Timer.After(2, ns.ShowMOTD) -- let the rest of the UI settle first
        end
        C_Timer.After(5, broadcastAll)
        ns.UpdateProximity()
        ns.StartGreetings()
    elseif event == "GROUP_ROSTER_UPDATE" then
        if IsInGroup() then broadcast("PARTY") end
        ns.UpdateProximity()
    elseif event == "CHAT_MSG_ADDON" then
        -- payload: prefix, text, channel, sender
        if arg1 ~= PREFIX then return end
        local text = tostring(arg2 or "")
        local kind, remote = text:match("^([VP]):(.+)$")
        if remote then
            -- Whoever sent this runs Stjartgruppen: remember them for greeting whispers.
            ns.LearnFriend(arg4)
            if kind == "P" and type(arg4) == "string" and not (issecretvalue and issecretvalue(arg4)) then
                -- answer a probe so they learn about us too (rate-limited per player)
                local now = GetTime()
                if not lastProbeReply[arg4] or now - lastProbeReply[arg4] >= PROBE_REPLY_COOLDOWN then
                    lastProbeReply[arg4] = now
                    pcall(C_ChatInfo.SendAddonMessage, PREFIX, "V:" .. myVersion, "WHISPER", arg4)
                end
            end
            if isNewer(remote, myVersion) and notifiedVersion ~= remote then
                notifiedVersion = remote
                say(("a friend has version %s (you have %s). Update Stjartgruppen in the CurseForge app!"):format(remote, myVersion))
            end
            return
        end
        local sound = text:match("^S:(.+)$")
        if sound and arg3 == "PARTY" then
            handleSound(sound, arg4)
        end
    end
end)

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
local function help()
    say("commands:")
    print("  /sg motd - show the message of the day window")
    print("  /sg motd off | on - stop (or start) showing it at login")
    print("  /sg song - play the reunion song (it plays by itself when a group member walks up to you)")
    print("  /sg song stop - stop it, /sg song off | on - turn the automatic song off or on")
    print("  /sg hello - greeting whispers: status and the Stjartgruppen friends you know")
    print("  /sg hello off | on - stop (or start) whispering friends when they come online")
    print("  /sg hello add | remove <name> - add or remove a friend by hand")
    print("  /sg hello test - show a sample greeting (only you see it)")
    print("  /sg quip - show a random quip")
    print("  /sg sounds - list available sounds")
    print("  /sg sound <name> - play a sound just for you")
    print("  /sg play <name> - play a sound for your whole party (friends with the addon)")
    print("  /sg mute - stop (or resume) hearing sounds friends play")
    print("  /sg greet - toggle the login quip")
    print("  /sg version - show your version")
end

SLASH_STJARTGRUPPEN1 = "/sg"
SLASH_STJARTGRUPPEN2 = "/stjartgruppen"
SlashCmdList["STJARTGRUPPEN"] = function(msg)
    local cmd, arg = tostring(msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "motd" then
        if arg == "off" or arg == "on" then
            StjartgruppenDB.motd = (arg == "on")
            say("message of the day at login: " .. arg)
        else
            ns.ShowMOTD()
        end
    elseif cmd == "song" then
        if arg == "stop" then
            ns.StopSong()
        elseif arg == "off" or arg == "on" then
            StjartgruppenDB.song = (arg == "on")
            ns.UpdateProximity()
            say("reunion song when a friend comes close: " .. arg)
        elseif not ns.PlaySong() then
            say("no song found. Put song.ogg in Stjartgruppen/Sounds/ and restart the game.")
        end
    elseif cmd == "hello" then
        local sub, who = arg:match("^(%S*)%s*(.-)$")
        if sub == "off" or sub == "on" then
            StjartgruppenDB.hello = (sub == "on")
            say("greeting whispers when a Stjartgruppen friend comes online: " .. sub)
        elseif sub == "add" and who ~= "" then
            local name = ns.AddFriend(who)
            say(name and (name .. " added to your Stjartgruppen friends.") or "that name doesn't look right.")
        elseif sub == "remove" and who ~= "" then
            local name = ns.RemoveFriend(who)
            say(name and (name .. " removed.") or (who .. " wasn't on the list."))
        elseif sub == "test" then
            say("sample greeting: " .. (ns.PreviewGreeting() or "no greetings loaded"))
        else
            local names = ns.KnownFriends()
            say("greeting whispers are " .. (StjartgruppenDB.hello and "on" or "off") .. ". Stjartgruppen friends seen so far: "
                .. (#names > 0 and table.concat(names, ", ") or "none yet (they show up once you've both been online)"))
        end
    elseif cmd == "quip" then
        say(randomQuip() or "no quips loaded")
    elseif cmd == "sounds" then
        say("sounds: " .. table.concat(soundNames(), ", "))
    elseif cmd == "sound" then
        if not playSound(arg) then say("unknown sound. Try /sg sounds") end
    elseif cmd == "play" then
        if ns.sounds and ns.sounds[arg] and validName(arg) then
            sendSound(arg)
        else
            say("unknown sound. Try /sg sounds")
        end
    elseif cmd == "mute" then
        StjartgruppenDB.muteSounds = not StjartgruppenDB.muteSounds
        say("shared sounds: " .. (StjartgruppenDB.muteSounds and "muted" or "on"))
    elseif cmd == "greet" then
        StjartgruppenDB.greet = not StjartgruppenDB.greet
        say("login quip: " .. (StjartgruppenDB.greet and "on" or "off"))
    elseif cmd == "version" then
        say("version " .. myVersion)
    else
        help()
    end
end
