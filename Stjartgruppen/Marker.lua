-- Stjartgruppen: raid markers and pings from the mouse.
-- Marking units (SetRaidTarget) and pinging are only allowed from Blizzard's secure code,
-- so a /run macro gets blocked. Instead this is a secure action button. A secure snippet
-- decides what each click does, then Blizzard's own secure actions (raid marker, /tm,
-- /ping) do the work.
--
-- Keys (each one can be changed in Options > Keybindings > AddOns > Stjartgruppen; these
-- are the defaults, used only while you haven't bound that action or used that key yourself):
--   Ctrl + hold middle button  marker wheel around the cursor. Move the cursor in the
--                              direction of a marker (any distance) and let go to put it
--                              on the mob under the mouse when you pressed, otherwise on
--                              your target. The red X removes the marker. Letting go near
--                              the middle cancels.
--   Alt + hold middle button   ping wheel: Attack, On My Way, Warning, Assist, the same way.
--                              It pings the unit under the mouse when you pressed; with no
--                              unit there it's a plain /ping and Blizzard picks the spot.
--   Ctrl + scroll up           next marker: Skull, Cross, Square, Moon, Triangle, Diamond, Circle, Star
--   Ctrl + scroll down         previous marker
--   Ctrl + Shift + scroll up   start again from Skull
-- The same button works from a macro:  /click StjartgruppenMarkRotate
--   press        next marker
--   Shift+press  start again from Skull
--   Ctrl+press   remove the marker
-- Scrolling and the macro mark the unit under the mouse, otherwise the target.
-- Out of combat, a different mob (or the end of a fight) starts the count again from Skull.
-- The default keys are override bindings (/sg mark wheel off turns them off).
local _, ns = ...

local BUTTON_NAME = "StjartgruppenMarkRotate"
ns.MARK_MACRO = "/click " .. BUTTON_NAME

-- The bindable actions (see Bindings.xml). `button` is the mouse button name the binding
-- "clicks" with; the secure snippet reads it. `keys` are the default keys.
local ACTIONS = {
    { button = "MarkMenu", short = "Marker wheel", label = "Marker wheel (hold)", keys = { "CTRL-BUTTON3" } },
    { button = "PingMenu", short = "Ping wheel", label = "Ping wheel (hold)", keys = { "ALT-BUTTON3" } },
    { button = "WheelUp", short = "Next marker", label = "Next marker (Shift: start from Skull)",
      keys = { "CTRL-MOUSEWHEELUP", "CTRL-SHIFT-MOUSEWHEELUP" } },
    { button = "WheelDown", short = "Previous marker", label = "Previous marker", keys = { "CTRL-MOUSEWHEELDOWN" } },
}
BINDING_HEADER_STJARTGRUPPEN = "Stjartgruppen"
for _, action in ipairs(ACTIONS) do
    action.command = "CLICK " .. BUTTON_NAME .. ":" .. action.button
    _G["BINDING_NAME_" .. action.command] = action.label
end

local WHEEL_SIZE = 320     -- the visible wheel, in pixels (its inner disc is ~100 px in radius)
local WHEEL_RADIUS = 76    -- distance from the middle to each icon
local WHEEL_DEADZONE = 24  -- letting go closer to the middle than this cancels
local PICK_AREA = 4096     -- invisible area around the cursor where the direction counts
local ICON_SIZE = 34
local ICON_SIZE_HOVER = 44
-- Look: see art-bible/STYLE.md (gold on dark iron, teal for "selected", the group's face in the middle).
local MEDIA = "Interface\\AddOns\\Stjartgruppen\\Media\\"
local RING_TEXTURE = MEDIA .. "wheel-ring"
local FACE_TEXTURE = MEDIA .. "wheel-face" -- the group's hero: a round, feathered portrait from the logo
-- Game texture file IDs: interface/targetingframe/ui-raidtargetingicon_1..8 are 137001..137008,
-- characterframe/tempportraitalphamask (a white circle) and buttons/ui-grouploot-pass-up (red X).
local MARKER_TEXTURE_BASE = 137000
local CIRCLE_TEXTURE = 130924
local CLEAR_TEXTURE = 130775
local TEAL = { 0x22 / 255, 0x5A / 255, 0x50 / 255 }

-- The two wheels. Angles in degrees, clockwise from straight up; `value` is what the secure
-- snippet acts on. The pick is the nearest slot by direction, so uneven spacing is fine.
local WHEELS = {
    {
        -- Marker wheel: value = raid marker 1..8, 0 = remove. Skull straight up, remove straight
        -- down. Nine slots can't be evenly spaced with both at the poles, so the right side has
        -- four markers (36 degrees apart) and the left side three (45 apart).
        id = "m", button = "MarkMenu", frameName = "StjartgruppenMarkWheel",
        slots = {
            { value = 8, angle = 0 },   -- Skull
            { value = 7, angle = 36 },  -- Cross
            { value = 6, angle = 72 },  -- Square
            { value = 5, angle = 108 }, -- Moon
            { value = 4, angle = 144 }, -- Triangle
            { value = 0, angle = 180 }, -- remove the marker
            { value = 3, angle = 225 }, -- Diamond
            { value = 2, angle = 270 }, -- Circle
            { value = 1, angle = 315 }, -- Star
        },
        icon = function(tex, value)
            tex:SetTexture(value == 0 and CLEAR_TEXTURE or (MARKER_TEXTURE_BASE + value))
        end,
        name = function(value)
            if value == 0 then return "Remove marker" end
            return _G["RAID_TARGET_" .. value] or ("Marker " .. value)
        end,
    },
    {
        -- Ping wheel: value = the /ping type number (1 Attack, 2 Warning, 3 On My Way, 4 Assist;
        -- Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua), so it works in any language.
        id = "p", button = "PingMenu", frameName = "StjartgruppenPingWheel",
        slots = {
            { value = 1, angle = 0, atlas = "ping_wheel_icon_attack", text = "PING_TYPE_ATTACK", fallback = "Attack" },
            { value = 3, angle = 90, atlas = "ping_wheel_icon_onmyway", text = "PING_TYPE_ON_MY_WAY", fallback = "On My Way" },
            { value = 2, angle = 180, atlas = "ping_wheel_icon_warning", text = "PING_TYPE_WARNING", fallback = "Warning" },
            { value = 4, angle = 270, atlas = "ping_wheel_icon_assist", text = "PING_TYPE_ASSIST", fallback = "Assist" },
        },
    },
}

-- Runs in the restricted (secure) environment before Blizzard's click handler.
-- Key bindings send a "down" and usually an "up" click, /click sends only "up".
--
-- Wheels: the press opens the wheel. If a unit is under the mouse it's put in the (empty)
-- focus slot with "/focus mouseover", because by the time you let go the mouse is
-- somewhere else. The release picks the slot by the direction of the cursor from the
-- middle, marks or pings the focus and clears the focus again. If you already use a
-- focus, the marker wheel marks your target and the ping wheel sends a plain /ping.
-- "unit" is set to "none" for the macros: Blizzard skips the click if the button's unit
-- doesn't exist, and an old "target" may not (SecureTemplates.lua:722).
--
-- Scrolling: the marker is picked on the first click of a press. The matching "up"
-- keeps the same choice: "set" does nothing if the unit already has that marker, so
-- the press marks once whichever of the two clicks Blizzard's handler acts on.
local PICK_NEXT = [[
    if button == "MarkMenu" or button == "PingMenu" then
        local w = (button == "MarkMenu") and "m" or "p"
        local ring = self:GetFrameRef(w .. "ring")
        if down and not ring:IsShown() then
            local borrow = UnitExists("mouseover") and not UnitExists("focus")
            if w == "m" and not borrow and not UnitExists("target") then return false end
            self:SetAttribute("sg-borrowed", borrow)
            ring:ClearAllPoints()
            ring:SetPoint("CENTER", "$cursor")
            ring:Show()
            if borrow then
                self:SetAttribute("unit", "none")
                self:SetAttribute("type", "macro")
                self:SetAttribute("macrotext", "/focus mouseover")
                self:SetAttribute("useOnKeyDown", true)
                return
            end
            return false
        end

        -- release (or a second press, if no release came): pick by direction
        local x, y = ring:GetMousePosition()
        ring:Hide()
        local borrowed = self:GetAttribute("sg-borrowed")
        self:SetAttribute("sg-borrowed", nil)
        self:SetAttribute("sg-pressed", nil)
        self:SetAttribute("useOnKeyDown", down and true or false)

        local value
        if x then
            local size = self:GetAttribute("sg-area")
            local px, py = (x - 0.5) * size, (y - 0.5) * size
            local dead = self:GetAttribute("sg-deadzone")
            if px * px + py * py >= dead * dead then
                local best, bestDot
                for i = 1, self:GetAttribute("sg-" .. w .. "-slots") do
                    local dot = px * self:GetAttribute("sg-" .. w .. "-x" .. i) + py * self:GetAttribute("sg-" .. w .. "-y" .. i)
                    if not bestDot or dot > bestDot then
                        best, bestDot = i, dot
                    end
                end
                value = self:GetAttribute("sg-" .. w .. "-value" .. best)
            end
        end

        local text
        if w == "p" then
            if value and borrowed then
                text = "/ping [@focus,exists] " .. value .. "\n/clearfocus"
            elseif value then
                text = "/ping " .. value
            elseif borrowed then
                text = "/clearfocus"
            end
        else
            if value == 0 then
                self:SetAttribute("sg-step", 0)
            elseif value then
                self:SetAttribute("sg-step", 9 - value) -- Ctrl + scroll goes on from here
            end
            if borrowed then
                text = "/clearfocus"
                if value == 0 then
                    text = "/tm [@focus,exists] 0\n/clearfocus"
                elseif value then
                    text = "/tm [@focus,exists] !" .. value .. "\n/clearfocus"
                end
            elseif value then
                self:SetAttribute("type", "raidtarget")
                self:SetAttribute("unit", "target")
                if value == 0 then
                    self:SetAttribute("action", "clear")
                else
                    self:SetAttribute("action", "set")
                    self:SetAttribute("marker", value)
                end
                return
            end
        end
        if not text then return false end
        self:SetAttribute("unit", "none")
        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", text)
        return
    end

    self:SetAttribute("type", "raidtarget")
    if down then
        self:SetAttribute("sg-pressed", button)
        self:SetAttribute("useOnKeyDown", true)
    else
        self:SetAttribute("useOnKeyDown", false)
        if self:GetAttribute("sg-pressed") == button then
            self:SetAttribute("sg-pressed", nil)
            return
        end
    end

    if UnitExists("mouseover") then
        self:SetAttribute("unit", "mouseover")
    else
        self:SetAttribute("unit", "target")
    end

    local wheel = (button == "WheelUp" or button == "WheelDown")
    if not wheel and IsControlKeyDown() then
        self:SetAttribute("action", "clear")
        self:SetAttribute("sg-step", 0) -- the next mark starts again from Skull
        return
    end
    self:SetAttribute("action", "set")

    local step = self:GetAttribute("sg-step") or 0
    if button == "WheelDown" then
        if step < 2 then
            step = 8
        else
            step = step - 1
        end
    else
        if IsShiftKeyDown() then
            step = 0
        end
        step = step % 8 + 1
    end
    self:SetAttribute("sg-step", step)
    self:SetAttribute("marker", 9 - step) -- step 1 = Skull (8) ... step 8 = Star (1)
]]

local inCombat = (C_RestrictedActions and C_RestrictedActions.InCombatLockdown) or InCombatLockdown

local button
local lastGUID -- the mob the rotator last aimed at

-- Addons can't read a unit's marker (GetRaidTargetIndex returns a secret value), and
-- the secure snippet can't tell mobs apart. So this insecure PreClick resets the
-- count when you aim at a different mob, which makes a new mob start at Skull.
-- Attributes can only be changed by addon code out of combat; in combat the count
-- just carries on (Skull, Cross, ... for the adds).
local function preClick(self, mouseButton)
    if inCombat() or mouseButton == "PingMenu" then return end
    local unit = UnitExists("mouseover") and "mouseover" or "target"
    local guid = UnitGUID(unit)
    if guid == nil or issecretvalue(guid) then return end
    if guid ~= lastGUID then
        lastGUID = guid
        self:SetAttribute("sg-step", 0)
    end
end

-- Slot directions (unit vectors, y up) and icon offsets in pixels.
for _, wheel in ipairs(WHEELS) do
    for _, slot in ipairs(wheel.slots) do
        local angle = math.rad(slot.angle)
        slot.ux, slot.uy = math.sin(angle), math.cos(angle)
        slot.dx, slot.dy = WHEEL_RADIUS * slot.ux, WHEEL_RADIUS * slot.uy
    end
end

-- Same choice as the secure snippet, for the hover highlight. nil = cancel.
local function slotToward(slots, px, py)
    if px * px + py * py < WHEEL_DEADZONE * WHEEL_DEADZONE then return nil end
    local best, bestDot
    for i, slot in ipairs(slots) do
        local dot = px * slot.ux + py * slot.uy
        if not bestDot or dot > bestDot then
            best, bestDot = i, dot
        end
    end
    return best
end

local function slotName(wheel, slot)
    if wheel.name then return wheel.name(slot.value) end
    return _G[slot.text] or slot.fallback
end

local function setSlotIcon(wheel, slot, tex)
    if wheel.icon then
        wheel.icon(tex, slot.value)
    elseif slot.atlas and C_Texture.GetAtlasInfo(slot.atlas) then
        tex:SetAtlas(slot.atlas)
    else
        tex:SetTexture(CIRCLE_TEXTURE) -- this client lacks the ping icons: a gold dot
        tex:SetVertexColor(1, 0.82, 0)
    end
end

-- Options > AddOns > Stjartgruppen: "Wheel transparency" and "Icon transparency" (0 = solid).
local layers = {} -- { back = frame, icons = frame } per wheel

local function opacity(key, default)
    local t = StjartgruppenDB and tonumber(StjartgruppenDB[key]) or default
    return 1 - math.min(math.max(t, 0), 0.9)
end

function ns.ApplyWheelTransparency()
    for _, layer in ipairs(layers) do
        layer.back:SetAlpha(opacity("wheelBackTransparency", 0.5))
        layer.icons:SetAlpha(opacity("wheelMarkerTransparency", 0))
    end
end

local function createWheel(wheel)
    -- A large invisible protected frame (SecureFrameTemplate), so the secure snippet may
    -- show and move it in combat and read the cursor direction anywhere on screen.
    -- Only the small wheel in its middle is drawn.
    local ring = CreateFrame("Frame", wheel.frameName, UIParent, "SecureHandlerBaseTemplate")
    ring:SetSize(PICK_AREA, PICK_AREA)
    ring:SetFrameStrata("DIALOG")
    ring:EnableMouse(false)
    ring:Hide()

    -- Everything visible lives on ordinary (unprotected) child frames, so addon code may
    -- animate it in combat. They show and hide together with the protected frame.
    -- `art` animates (pop open). Inside it two layers carry the two transparency options.
    local art = CreateFrame("Frame", nil, ring)
    art:SetSize(WHEEL_SIZE, WHEEL_SIZE)
    art:SetPoint("CENTER")
    local back = CreateFrame("Frame", nil, art)
    back:SetAllPoints()
    local icons = CreateFrame("Frame", nil, art)
    icons:SetAllPoints()
    icons:SetFrameLevel(back:GetFrameLevel() + 2)
    layers[#layers + 1] = { back = back, icons = icons }
    ns.ApplyWheelTransparency()

    local shadow = back:CreateTexture(nil, "BACKGROUND", nil, -1)
    shadow:SetTexture(CIRCLE_TEXTURE)
    shadow:SetSize(WHEEL_SIZE * 0.9, WHEEL_SIZE * 0.9)
    shadow:SetPoint("CENTER", 0, -4)
    shadow:SetVertexColor(0, 0, 0, 0.55)

    local frame = back:CreateTexture(nil, "BACKGROUND")
    frame:SetTexture(RING_TEXTURE)
    frame:SetAllPoints()

    -- the group's face in the middle. On the icon layer, so it stays clear when the
    -- wheel itself is see-through (it follows "Icon transparency").
    local face = icons:CreateTexture(nil, "ARTWORK", nil, -2)
    face:SetTexture(FACE_TEXTURE)
    face:SetSize(104, 104)
    face:SetPoint("CENTER")

    -- name of what you're pointing at, gold, just above the wheel
    local label = icons:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    label:SetPoint("BOTTOM", art, "TOP", 0, -6)
    label:SetShadowOffset(2, -2)

    local slotArt = {}
    for i, slot in ipairs(wheel.slots) do
        local plate = icons:CreateTexture(nil, "ARTWORK", nil, -1) -- teal = selected (art bible)
        plate:SetTexture(CIRCLE_TEXTURE)
        plate:SetSize(ICON_SIZE_HOVER + 6, ICON_SIZE_HOVER + 6)
        plate:SetPoint("CENTER", slot.dx, slot.dy)
        plate:SetVertexColor(TEAL[1], TEAL[2], TEAL[3], 0.95)
        plate:Hide()

        local icon = icons:CreateTexture(nil, "ARTWORK")
        setSlotIcon(wheel, slot, icon)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("CENTER", slot.dx, slot.dy)
        icon:SetAlpha(0.8)
        slotArt[i] = { plate = plate, icon = icon }
    end

    -- pop open: grow from 70% and fade in
    local open = art:CreateAnimationGroup()
    local grow = open:CreateAnimation("Scale")
    grow:SetScaleFrom(0.7, 0.7)
    grow:SetScaleTo(1, 1)
    grow:SetDuration(0.14)
    grow:SetSmoothing("OUT")
    local appear = open:CreateAnimation("Alpha")
    appear:SetFromAlpha(0)
    appear:SetToAlpha(1)
    appear:SetDuration(0.1)

    local picked -- slot index under the cursor direction, nil = cancel
    local function highlight(pick)
        for i, parts in ipairs(slotArt) do
            local on = (i == pick)
            parts.plate:SetShown(on)
            parts.icon:SetSize(on and ICON_SIZE_HOVER or ICON_SIZE, on and ICON_SIZE_HOVER or ICON_SIZE)
            parts.icon:SetAlpha((on or not pick) and 1 or 0.8)
        end
        if pick then
            label:SetText(slotName(wheel, wheel.slots[pick]))
            label:SetTextColor(1, 0.82, 0)
        else
            label:SetText(CANCEL or "Cancel")
            label:SetTextColor(0.6, 0.6, 0.6)
        end
    end

    art:SetScript("OnShow", function()
        picked = nil
        highlight(nil)
        open:Play()
    end)

    -- Follow the cursor direction while the wheel is open (only runs while it's shown).
    art:SetScript("OnUpdate", function(self)
        local midX, midY = self:GetCenter()
        if not midX then return end
        local scale = self:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        local pick = slotToward(wheel.slots, cx / scale - midX, cy / scale - midY)
        if pick ~= picked then
            if picked and pick then PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end
            picked = pick
            highlight(pick)
        end
    end)
    return ring
end

local function createButton()
    button = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate, SecureHandlerBaseTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("type", "raidtarget")
    button:SetAttribute("action", "set")
    button:SetAttribute("marker", 8)
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("sg-step", 0)
    button:SetScript("PreClick", preClick)

    -- The wheel layouts, for the secure snippet.
    button:SetAttribute("sg-area", PICK_AREA)
    button:SetAttribute("sg-deadzone", WHEEL_DEADZONE)
    for _, wheel in ipairs(WHEELS) do
        local p = "sg-" .. wheel.id .. "-"
        button:SetAttribute(p .. "slots", #wheel.slots)
        for i, slot in ipairs(wheel.slots) do
            button:SetAttribute(p .. "x" .. i, slot.ux)
            button:SetAttribute(p .. "y" .. i, slot.uy)
            button:SetAttribute(p .. "value" .. i, slot.value)
        end
        SecureHandlerSetFrameRef(button, wheel.id .. "ring", createWheel(wheel))
    end
    SecureHandlerWrapScript(button, "OnClick", button, PICK_NEXT)
end

-- Default keys: only for an action you haven't bound yourself, and only on a key that
-- isn't bound to something else. Your own bindings are normal WoW bindings and always win.
local activeDefaults = {} -- key -> action, as currently set

local function wantedDefaults()
    local wanted = {}
    if not (StjartgruppenDB and StjartgruppenDB.markWheel) then return wanted end
    for _, action in ipairs(ACTIONS) do
        if not GetBindingKey(action.command) then
            for _, key in ipairs(action.keys) do
                local bound = GetBindingAction(key)
                if bound == nil or bound == "" then
                    wanted[key] = action
                end
            end
        end
    end
    return wanted
end

local function applyBindings()
    local wanted = wantedDefaults()
    local same = true
    for key, action in pairs(wanted) do
        if activeDefaults[key] ~= action then same = false end
    end
    for key in pairs(activeDefaults) do
        if not wanted[key] then same = false end
    end
    if same then return end -- nothing to change (also stops an UPDATE_BINDINGS loop)
    ClearOverrideBindings(button)
    for key, action in pairs(wanted) do
        SetOverrideBindingClick(button, false, key, BUTTON_NAME, action.button)
    end
    activeDefaults = wanted
end

-- For /sg mark: each action's name and the key that runs it right now (nil = none).
function ns.MarkKeys()
    local list = {}
    for _, action in ipairs(ACTIONS) do
        local key = GetBindingKey(action.command)
        if not key then
            for k, a in pairs(activeDefaults) do
                if a == action and (not key or #k < #key) then key = k end
            end
        end
        list[#list + 1] = { name = action.short, key = key and GetBindingText(key) }
    end
    return list
end

-- Secure frames and bindings can't be changed in combat (e.g. a /reload mid-fight),
-- so wait for combat to end. Ending a fight also starts the count again from Skull.
local wantBindings = false
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UPDATE_BINDINGS") -- you changed a key in the Keybindings menu
events:SetScript("OnEvent", function(_, event)
    if event == "UPDATE_BINDINGS" then
        if button and not inCombat() then applyBindings() else wantBindings = true end
        return
    end
    if not button then createButton() end
    button:SetAttribute("sg-step", 0)
    lastGUID = nil
    if wantBindings then
        wantBindings = false
        applyBindings()
    end
end)

-- Called at login and by /sg mark wheel on|off. Returns false if it has to wait for combat to end.
function ns.UpdateMarkWheel()
    if inCombat() then
        wantBindings = true
        return false
    end
    if not button then createButton() end
    applyBindings()
    return true
end

if not inCombat() then
    createButton()
end
