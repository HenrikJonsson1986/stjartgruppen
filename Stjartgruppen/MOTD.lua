-- Message of the day window: shows a random line from ns.messages on login.
-- Core.lua calls ns.ShowMOTD(); the window itself is built the first time it is needed.
local _, ns = ...

local frame -- created lazily

local function pickMessage()
    local list = ns.messages
    if not list or #list == 0 then return "Have a great day!" end
    local db = StjartgruppenDB or {}
    local i = math.random(#list)
    -- avoid showing the same message twice in a row
    if #list > 1 and i == db.lastMessage then
        i = (i % #list) + 1
    end
    db.lastMessage = i
    return list[i]
end

local function build()
    local f = CreateFrame("Frame", "StjartgruppenMOTDFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(420, 390)
    f:SetPoint("CENTER", 0, 60)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f.TitleText:SetText("Stjärtgruppen")

    -- The group logo (Media/logo.tga, 256x256). New texture files need a full game restart.
    local logo = f:CreateTexture(nil, "ARTWORK")
    logo:SetSize(180, 180)
    logo:SetPoint("TOP", 0, -32)
    logo:SetTexture("Interface\\AddOns\\Stjartgruppen\\Media\\logo")

    local header = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOP", logo, "BOTTOM", 0, -10)
    header:SetText("Message of the day")

    local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    text:SetPoint("TOP", header, "BOTTOM", 0, -8)
    text:SetWidth(372)
    text:SetHeight(90)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(true)
    f.message = text

    local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    close:SetSize(110, 24)
    close:SetPoint("BOTTOMRIGHT", -18, 16)
    close:SetText("Thanks!")
    close:SetScript("OnClick", function() f:Hide() end)

    local another = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    another:SetSize(110, 24)
    another:SetPoint("RIGHT", close, "LEFT", -8, 0)
    another:SetText("Another one")
    another:SetScript("OnClick", function() f.message:SetText(pickMessage()) end)

    local hint = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 18, 22)
    hint:SetText("/sg motd off to hide")

    -- Escape closes it like other windows
    tinsert(UISpecialFrames, "StjartgruppenMOTDFrame")
    return f
end

function ns.ShowMOTD()
    frame = frame or build()
    frame.message:SetText(pickMessage())
    frame:Show()
end
