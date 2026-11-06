-- Stjartgruppen: saved settings, slash commands, and a friendly "newer version available" notice.
-- Lua 5.1. Over the hidden addon channel it sends only short strings:
--   "V:<version>"   version (to guild/party)
local ADDON_NAME, ns = ...

local PREFIX = "STJARTGRUPPEN" -- addon message prefix, 16 chars max
ns.PREFIX = PREFIX
local defaults = { motd = true, markWheel = true, wheelBackTransparency = 0.5, wheelMarkerTransparency = 0 }
local SEND_COOLDOWN = 60      -- seconds between version broadcasts per channel

local myVersion = "0"
local notifiedVersion = nil
local lastSent = {}

local function say(msg)
    print("|cffffcc33Stjartgruppen|r: " .. tostring(msg))
end
ns.say = say


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
-- Events
----------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        StjartgruppenDB = StjartgruppenDB or {}
        for k, v in pairs(defaults) do
            if StjartgruppenDB[k] == nil then StjartgruppenDB[k] = v end
        end
        -- settings of features removed in 0.6.0 (reunion song, greeting whispers)
        StjartgruppenDB.song, StjartgruppenDB.hello, StjartgruppenDB.known = nil, nil, nil
        StjartgruppenDB.wheelTransparency = nil -- replaced by the two settings below (test builds only)
        StjartgruppenDB.muteSounds = nil -- shared sounds were removed in 0.6.0
        StjartgruppenDB.greet = nil -- the login quip was removed in 0.6.0
        ns.SetupOptions()
        ns.ApplyWheelTransparency()
        myVersion = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0"
        ns.version = myVersion
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    elseif event == "PLAYER_LOGIN" then
        if StjartgruppenDB.motd and ns.ShowMOTD then
            C_Timer.After(2, ns.ShowMOTD) -- let the rest of the UI settle first
        end
        C_Timer.After(5, broadcastAll)
        ns.UpdateMarkWheel()
    elseif event == "GROUP_ROSTER_UPDATE" then
        if IsInGroup() then broadcast("PARTY") end
    elseif event == "CHAT_MSG_ADDON" then
        -- payload: prefix, text, channel, sender
        if arg1 ~= PREFIX then return end
        local text = tostring(arg2 or "")
        -- "P:" probes come from versions before 0.6.0; they carry a version number too.
        local remote = text:match("^[VP]:(.+)$")
        if remote then
            if isNewer(remote, myVersion) and notifiedVersion ~= remote then
                notifiedVersion = remote
                say(("a friend has version %s (you have %s). Update Stjartgruppen in the CurseForge app!"):format(remote, myVersion))
            end
            return
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
    print("  /sg options - open the options (also in Options > AddOns > Stjartgruppen)")
    print("  /sg mark - marker and ping wheels, marker rotator: your keys and how to change them")
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
    elseif cmd == "options" or cmd == "config" then
        ns.OpenOptions()
    elseif cmd == "mark" then
        if arg == "wheel off" or arg == "wheel on" then
            StjartgruppenDB.markWheel = (arg == "wheel on")
            if ns.UpdateMarkWheel() then
                say("default keys (Ctrl/Alt + middle mouse, Ctrl + scroll) are " .. (StjartgruppenDB.markWheel and "on" or "off"))
            else
                say("default keys (Ctrl/Alt + middle mouse, Ctrl + scroll) will be " .. (StjartgruppenDB.markWheel and "on" or "off") .. " when combat ends")
            end
            return
        end
        say("marker and ping wheels (they act on the mob under your mouse when you press, otherwise your target):")
        for _, entry in ipairs(ns.MarkKeys()) do
            print(("  %s: %s"):format(entry.name, entry.key or "|cff999999not bound|r"))
        end
        print("  Change the keys in Options > Keybindings > AddOns > Stjartgruppen.")
        print("  Marker wheel: hold the key, move the mouse toward a marker (or the red X to remove) and let go. Let go in the middle to cancel.")
        print("  Ping wheel: the same, with Attack, On My Way, Warning and Assist.")
        print("  Next marker goes Skull, Cross, Square, Moon, Triangle, Diamond, Circle, Star. Hold Shift to start again from Skull.")
        print("  Default keys (Ctrl + middle mouse, Alt + middle mouse, Ctrl + scroll) are " .. (StjartgruppenDB.markWheel and "on" or "off")
            .. ": /sg mark wheel off (or on). They're only used for actions you haven't bound yourself.")
        print("  Macro version: " .. ns.MARK_MACRO .. " (Shift: from Skull, Ctrl: remove)")
    elseif cmd == "version" then
        say("version " .. myVersion)
    else
        help()
    end
end
