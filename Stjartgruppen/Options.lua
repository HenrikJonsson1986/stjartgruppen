-- Stjartgruppen: options panel (Options > AddOns > Stjartgruppen, or /sg options).
-- Built with Blizzard's Settings API (vertical list). Each option is a proxy setting that
-- reads and writes StjartgruppenDB and applies the change straight away.
-- Core.lua calls ns.SetupOptions() once the saved variables are loaded.
local _, ns = ...

local category

local function addSlider(variable, key, name, tooltip, default, minValue, maxValue, step, format, onChange)
    local function get()
        return tonumber(StjartgruppenDB[key]) or default
    end
    local function set(value)
        StjartgruppenDB[key] = value
        if onChange then onChange(value) end
    end
    local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Number, name, default, get, set)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, format)
    Settings.CreateSlider(category, setting, options, tooltip)
end

local function addCheckbox(variable, key, name, tooltip, default, onChange)
    local function get()
        local value = StjartgruppenDB[key]
        if value == nil then return default end
        return value and true or false
    end
    local function set(value)
        StjartgruppenDB[key] = value
        if onChange then onChange(value) end
    end
    local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, name, default, get, set)
    Settings.CreateCheckbox(category, setting, tooltip)
end

local function percent(value)
    return ("%d%%"):format(math.floor(value * 100 + 0.5))
end

function ns.SetupOptions()
    if category or not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
    category = Settings.RegisterVerticalLayoutCategory("Stjartgruppen")

    addSlider("STJARTGRUPPEN_WHEEL_TRANSPARENCY", "wheelBackTransparency", "Wheel transparency",
        "How see-through the ring and background of the marker and ping wheels are. 0% is solid.",
        0.5, 0, 0.9, 0.05, percent, ns.ApplyWheelTransparency)

    addSlider("STJARTGRUPPEN_MARKER_TRANSPARENCY", "wheelMarkerTransparency", "Icon transparency",
        "How see-through the icons on the marker and ping wheels, the face in the middle and the name above the wheel are. 0% is solid.",
        0, 0, 0.9, 0.05, percent, ns.ApplyWheelTransparency)

    addCheckbox("STJARTGRUPPEN_MARK_DEFAULT_KEYS", "markWheel", "Default wheel keys",
        "Use Ctrl + middle mouse for the marker wheel, Alt + middle mouse for the ping wheel and Ctrl + scroll for next and previous marker, "
            .. "for the actions you haven't bound yourself in Keybindings > AddOns > Stjartgruppen.",
        true, function() ns.UpdateMarkWheel() end)

    addCheckbox("STJARTGRUPPEN_MOTD", "motd", "Message of the day at login",
        "Show the Stjartgruppen window with a kind word when you log in. /sg motd shows it any time.", true)

    Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
    if not category then
        ns.say("the options panel isn't available in this client.")
        return
    end
    Settings.OpenToCategory(category:GetID())
end
