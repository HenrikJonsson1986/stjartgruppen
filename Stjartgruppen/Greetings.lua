-- Greeting whispers: when a fellow Stjartgruppen user comes online, whisper them a nice line
-- from ns.greetings (Messages.lua).
--
-- Who counts as a "Stjartgruppen friend"? Only people this addon has heard from:
--   * the hidden version message ("V:") every copy sends to its guild and party, and
--   * a hidden probe ("P:") we send to online friends-list and guild members we don't know yet.
--     A copy of the addon answers a probe with "V:". Players without the addon never see either
--     message (addon messages don't show up in chat).
-- Known names are saved in StjartgruppenDB.known. /sg hello add|remove <name> edits the list.
--
-- Whoever is already online sends the greeting, so the two of you don't greet each other back
-- and forth. Each friend is greeted at most once an hour, and whispers wait while the game's chat
-- lockdown is active (during boss encounters).
local _, ns = ...

local LOGIN_GRACE = 20       -- seconds after login/reload where we only record who is online
local GREET_COOLDOWN = 3600  -- seconds before the same friend can be greeted again
local DELAY_MIN, DELAY_MAX = 4, 9 -- seconds to wait after they come online (feels less robotic)
local LOCKDOWN_RETRY = 5     -- seconds between retries while chat is locked down
local MAX_WAIT = 120         -- give up on a greeting after this many seconds of lockdown
local PENDING_WINDOW = 60    -- an unknown player who answers a probe this soon after logging in still gets greeted
local PROBE_GAP = 0.5        -- seconds between probes at login
local MAX_PROBES = 30        -- probes sent at login, at most
local GUILD_REFRESH = 20     -- seconds between guild roster refresh requests

local ready = false          -- false during LOGIN_GRACE
local prev = {}              -- source ("friends"/"guild") -> { key = displayName } online last scan
local pending = {}           -- key -> GetTime() when an unknown player came online
local queued = {}            -- key -> true while a greeting is scheduled
local lastProbe = {}         -- key -> GetTime() of the last probe we sent them

local function db() return StjartgruppenDB end

-- "Name-Realm" or "Name" -> "name" (lookup key), "Name" (for display and whispering).
local function nameKey(name)
    if type(name) ~= "string" or name == "" then return nil end
    if issecretvalue and issecretvalue(name) then return nil end
    local display = Ambiguate(name, "none")
    return display:lower(), display
end

local function isMe(k)
    local me = UnitName("player")
    return me ~= nil and me:lower() == k
end

local function isOnline(k)
    for _, set in pairs(prev) do
        if set[k] then return true end
    end
    return false
end

local function pickGreeting(display)
    local list = ns.greetings
    if not list or #list == 0 then return nil end
    local d = db()
    local i = math.random(#list)
    if #list > 1 and i == d.lastGreeting then i = (i % #list) + 1 end
    d.lastGreeting = i
    return (list[i]:gsub("{name}", display))
end

local function chatLocked()
    return C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() or false
end

local function trySend(k, display, startedAt)
    if not db().hello or not isOnline(k) then queued[k] = nil return end
    if chatLocked() then
        if GetTime() - startedAt < MAX_WAIT then
            C_Timer.After(LOCKDOWN_RETRY, function() trySend(k, display, startedAt) end)
        else
            queued[k] = nil
        end
        return
    end
    queued[k] = nil
    local msg = pickGreeting(display)
    if not msg then return end
    db().greetedAt[k] = time()
    pcall(C_ChatInfo.SendChatMessage, msg, "WHISPER", nil, display)
end

local function scheduleGreeting(k, display)
    local d = db()
    if not d.hello or queued[k] or isMe(k) then return end
    if d.greetedAt[k] and time() - d.greetedAt[k] < GREET_COOLDOWN then return end
    queued[k] = true
    local delay = DELAY_MIN + math.random() * (DELAY_MAX - DELAY_MIN)
    C_Timer.After(delay, function() trySend(k, display, GetTime()) end)
end

-- Hidden "do you have Stjartgruppen?" message. Players without the addon never see it.
local function probe(k, display)
    if not ns.PREFIX or isMe(k) then return end
    local now = GetTime()
    if lastProbe[k] and now - lastProbe[k] < 30 then return end
    lastProbe[k] = now
    pcall(C_ChatInfo.SendAddonMessage, ns.PREFIX, "P:" .. (ns.version or "0"), "WHISPER", display)
end

-- Called by Core.lua whenever a hidden Stjartgruppen message arrives from someone.
function ns.LearnFriend(sender)
    local k, display = nameKey(sender)
    if not k or isMe(k) then return end
    db().known[k] = display
    if pending[k] then
        local fresh = GetTime() - pending[k] <= PENDING_WINDOW
        pending[k] = nil
        if fresh then scheduleGreeting(k, display) end
    end
end

local function cameOnline(k, display)
    if isMe(k) then return end
    if db().known[k] then
        scheduleGreeting(k, display)
    else
        pending[k] = GetTime()
        probe(k, display)
    end
end

-- Compare a fresh "who is online" list from one source with the previous one.
local function update(source, cur)
    local before = prev[source]
    local wasOnline = {}
    for k in pairs(cur) do wasOnline[k] = isOnline(k) end
    prev[source] = cur
    if not ready or not before then return end
    for k, display in pairs(cur) do
        if not before[k] and not wasOnline[k] then cameOnline(k, display) end
    end
end

-- An empty list usually means "not loaded yet", so it's ignored: otherwise the first real list
-- would make everyone look like they just came online.
local function scanFriends()
    local count = C_FriendList.GetNumFriends() or 0
    if count == 0 then return end
    local cur = {}
    for i = 1, count do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.connected then
            local k, display = nameKey(info.name)
            if k then cur[k] = display end
        end
    end
    update("friends", cur)
end

local function scanGuild()
    local cur = {}
    if IsInGuild() then
        local count = GetNumGuildMembers() or 0
        if count == 0 then return end
        for i = 1, count do
            local name, _, _, _, _, _, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(i)
            if online and not isMobile then
                local k, display = nameKey(name)
                if k then cur[k] = display end
            end
        end
    end
    update("guild", cur)
end

-- After the login grace: probe everyone online we don't know yet (learning only, no greetings).
local function probeUnknown()
    local list = {}
    for _, set in pairs(prev) do
        for k, display in pairs(set) do
            if not db().known[k] and not isMe(k) then list[k] = display end
        end
    end
    local n = 0
    for k, display in pairs(list) do
        if n >= MAX_PROBES then break end
        n = n + 1
        C_Timer.After(n * PROBE_GAP, function() probe(k, display) end)
    end
end

function ns.StartGreetings()
    local d = db()
    d.known = d.known or {}
    d.greetedAt = d.greetedAt or {}
    C_FriendList.ShowFriends()
    if IsInGuild() then C_GuildInfo.GuildRoster() end
    C_Timer.After(LOGIN_GRACE, function()
        scanFriends()
        scanGuild()
        ready = true
        probeUnknown()
    end)
    C_Timer.NewTicker(GUILD_REFRESH, function()
        if IsInGuild() then C_GuildInfo.GuildRoster() end
    end)
    if d.hello and not d.helloNoticed then
        d.helloNoticed = true
        C_Timer.After(6, function()
            ns.say("new: when a Stjartgruppen friend comes online, you whisper them a nice message. /sg hello off to stop it.")
        end)
    end
end

function ns.PreviewGreeting()
    return pickGreeting("Friend")
end

-- /sg hello helpers
function ns.AddFriend(name)
    local k = nameKey(name)
    if not k then return nil end
    local display = (k:gsub("^%l", string.upper))
    db().known[k] = display
    return display
end

function ns.RemoveFriend(name)
    local k = nameKey(name)
    if not k or not db().known[k] then return nil end
    local display = db().known[k]
    db().known[k] = nil
    return display
end

function ns.KnownFriends()
    local names = {}
    for _, display in pairs(db().known or {}) do names[#names + 1] = display end
    table.sort(names)
    return names
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("FRIENDLIST_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:SetScript("OnEvent", function(_, event)
    if not StjartgruppenDB or not StjartgruppenDB.known then return end -- not started yet
    if event == "FRIENDLIST_UPDATE" then
        scanFriends()
    else
        scanGuild()
    end
end)
