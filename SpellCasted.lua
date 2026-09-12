local ADDON_NAME = "SpellCasted"

local DEFAULT = {
    x = 0, y = -200, size = 128, alpha = 1.0, alwaysShow = true,

    -- The row of what you have cast
    history = false,
    historyCount = 5,
    historySize = 48,
    historySpacing = 4,
    historyFade = true,
    historyNewestLeft = false,
    hx = 0, hy = -300,
}

SpellCastedDB = SpellCastedDB or {}

local function db(key)
    if SpellCastedDB[key] == nil then
        SpellCastedDB[key] = DEFAULT[key]
    end
    return SpellCastedDB[key]
end

-------------------------------------------------------------------------------
-- Icon frame
-------------------------------------------------------------------------------
local frame = CreateFrame("Frame", "SpellCastedFrame", UIParent)
frame:SetSize(db("size"), db("size"))
frame:SetPoint("CENTER", UIParent, "CENTER", db("x"), db("y"))
frame:SetAlpha(db("alpha"))
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)

frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    SpellCastedDB.x = x
    SpellCastedDB.y = y
end)

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.4)
bg:Hide()

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
icon:Hide()

local glow = frame:CreateTexture(nil, "OVERLAY")
glow:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -4,  4)
glow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  4, -4)
glow:SetColorTexture(1, 0.8, 0, 0.3)
glow:Hide()

-- Overlay shown when a cast is cancelled or interrupted
local feedbackOverlay = frame:CreateTexture(nil, "OVERLAY")
feedbackOverlay:SetPoint("CENTER", frame, "CENTER")
feedbackOverlay:SetSize(frame:GetWidth() * 0.6, frame:GetHeight() * 0.6)
feedbackOverlay:Hide()

local function UpdateFeedbackOverlaySize()
    local s = frame:GetWidth() * 0.6
    feedbackOverlay:SetSize(s, s)
end

-------------------------------------------------------------------------------
-- Spell history
--
-- A row of icons with the most recent at one end. It has a frame and a position
-- of its own: on a stream layout, the row does not always want to sit under the
-- main icon.
-------------------------------------------------------------------------------
local historyFrame = CreateFrame("Frame", "SpellCastedHistory", UIParent)
historyFrame:SetMovable(true)
historyFrame:EnableMouse(false)
historyFrame:RegisterForDrag("LeftButton")
historyFrame:SetClampedToScreen(true)
historyFrame:Hide()

historyFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
historyFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    SpellCastedDB.hx = x
    SpellCastedDB.hy = y
end)

local historyBg = historyFrame:CreateTexture(nil, "BACKGROUND")
historyBg:SetAllPoints()
historyBg:SetColorTexture(0, 0, 0, 0.4)
historyBg:Hide()

local slots = {}
local recent = {}          -- most recent first
local lastPushed, lastPushedAt = nil, 0

local function HistorySlot(index)
    if slots[index] then return slots[index] end

    local tex = historyFrame:CreateTexture(nil, "ARTWORK")
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tex:Hide()
    slots[index] = tex
    return tex
end

local function LayoutHistory()
    local count = db("historyCount")
    local size = db("historySize")
    local gap = db("historySpacing")

    historyFrame:SetSize(count * size + (count - 1) * gap, size)
    historyFrame:ClearAllPoints()
    historyFrame:SetPoint("CENTER", UIParent, "CENTER", db("hx"), db("hy"))
    historyFrame:SetAlpha(db("alpha"))

    for i = 1, count do
        local tex = HistorySlot(i)
        tex:SetSize(size, size)
        tex:ClearAllPoints()

        -- Slot one is always the most recent; only the end it is drawn at
        -- changes.
        local offset = (i - 1) * (size + gap)
        if db("historyNewestLeft") then
            tex:SetPoint("LEFT", historyFrame, "LEFT", offset, 0)
        else
            tex:SetPoint("RIGHT", historyFrame, "RIGHT", -offset, 0)
        end
    end

    -- Slots beyond the count stay where they are but stop showing.
    for i = count + 1, #slots do
        slots[i]:Hide()
    end
end

local function RefreshHistory()
    if not db("history") then
        historyFrame:Hide()
        return
    end

    LayoutHistory()
    local count = db("historyCount")

    for i = 1, count do
        local tex = HistorySlot(i)
        local entry = recent[i]

        if entry then
            tex:SetTexture(entry.texture)
            -- The older ones fade, so the last one cast reads at a glance.
            local fade = 1
            if db("historyFade") and count > 1 then
                fade = 1 - ((i - 1) / count) * 0.75
            end
            tex:SetAlpha(fade)
            tex:Show()
        else
            tex:Hide()
        end
    end

    historyFrame:Show()
end

local function PushHistory(spellID, texture)
    if not texture then return end

    -- Some spells announce their success more than once in a row, and two
    -- identical entries back to back are not two casts.
    local now = GetTime()
    if spellID and spellID == lastPushed and (now - lastPushedAt) < 0.25 then
        return
    end
    lastPushed, lastPushedAt = spellID, now

    table.insert(recent, 1, { spellID = spellID, texture = texture })
    while #recent > db("historyCount") do
        table.remove(recent)
    end

    if db("history") then RefreshHistory() end
end

local function ClearHistory()
    recent = {}
    lastPushed, lastPushedAt = nil, 0
    RefreshHistory()
end

local function FillHistoryExample()
    local samples = {
        "Interface\\Icons\\Spell_Fire_FlameBolt",
        "Interface\\Icons\\Spell_Frost_FrostBolt02",
        "Interface\\Icons\\Spell_Holy_HolySmite",
        "Interface\\Icons\\Spell_Nature_Lightning",
        "Interface\\Icons\\Spell_Shadow_ShadowBolt",
        "Interface\\Icons\\Ability_Warrior_Cleave",
        "Interface\\Icons\\Ability_Rogue_Ambush",
        "Interface\\Icons\\Spell_Arcane_Blast",
        "Interface\\Icons\\Ability_Druid_Maul",
        "Interface\\Icons\\Spell_Nature_Starfall",
        "Interface\\Icons\\Spell_Holy_Renew",
        "Interface\\Icons\\Ability_Hunter_AimedShot",
    }

    recent = {}
    for i = 1, db("historyCount") do
        recent[i] = { spellID = -i, texture = samples[((i - 1) % #samples) + 1] }
    end

    SpellCastedDB.history = true
    RefreshHistory()
end

local cancelTimer = nil
local lastTexture = nil  -- the last texture shown
local locked = true

local function HideOrKeep()
    if db("alwaysShow") then
        -- keep the last icon up, without the glow
        icon:SetVertexColor(1, 1, 1)
        if lastTexture then
            icon:SetTexture(lastTexture)
            icon:Show()
        end
        glow:Hide()
    else
        icon:Hide()
        glow:Hide()
    end
end

local function SetLocked(state)
    locked = state
    frame:EnableMouse(not locked)
    historyFrame:EnableMouse(not locked)

    if locked then
        bg:Hide()
        historyBg:Hide()
    else
        bg:Show()
        historyBg:Show()
        if not icon:IsShown() then
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            icon:Show()
        end
    end
end

local function ShowSpellIcon(texture)
    if cancelTimer then cancelTimer:Cancel() cancelTimer = nil end
    feedbackOverlay:Hide()
    if texture then
        lastTexture = texture
        icon:SetVertexColor(1, 1, 1)
        icon:SetTexture(texture)
        icon:Show()
        glow:Show()
    else
        HideOrKeep()
    end
end

local function ShowCancelFeedback(texture, overlayTex, r, g, b)
    if cancelTimer then cancelTimer:Cancel() cancelTimer = nil end
    lastTexture = texture
    icon:SetTexture(texture)
    icon:SetVertexColor(r, g, b)
    icon:Show()
    glow:Hide()
    UpdateFeedbackOverlaySize()
    feedbackOverlay:SetTexture(overlayTex)
    feedbackOverlay:Show()
    cancelTimer = C_Timer.NewTimer(1.2, function()
        cancelTimer = nil
        feedbackOverlay:Hide()
        HideOrKeep()
    end)
end

-------------------------------------------------------------------------------
-- Settings panel
-------------------------------------------------------------------------------
local UI = SpellCasted.UI

local panel = UI.CreateWindow("SpellCastedPanel", 330, 610,
    "SpellCasted", "what you are casting")

local body = CreateFrame("Frame", nil, panel)
body:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -54)
body:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 34)

-- Everything on the panel that reads a setting, so one call puts the whole
-- thing back in step after a reset or a fresh login.
local watchers = {}

local function RefreshPanel()
    for _, fn in ipairs(watchers) do fn() end
end

local function AddHeading(y, text)
    local fs = UI.Text(body, 11, "textDim")
    fs:SetPoint("TOPLEFT", 0, -y)
    fs:SetText(text)

    local rule = UI.Divider(body)
    rule:SetPoint("TOPLEFT", 0, -(y + 16))
    rule:SetPoint("TOPRIGHT", 0, -(y + 16))

    return y + 26
end

local function AddCheck(y, label, tooltip, get, set)
    local c = UI.CreateCheck(body, label, tooltip)
    c:SetPoint("TOPLEFT", 0, -y)
    c:SetPoint("TOPRIGHT", 0, -y)
    c:SetScript("OnClick", function(self)
        self:SetChecked(not self:GetChecked())
        set(self:GetChecked())
    end)

    watchers[#watchers + 1] = function() c:SetChecked(get()) end
    return y + 26
end

local function AddSlider(y, label, minV, maxV, step, get, set, formatter)
    local row = UI.CreateSlider(body, label, minV, maxV, step, formatter)
    row:SetPoint("TOPLEFT", 0, -y)
    row:SetPoint("TOPRIGHT", 0, -y)

    row.slider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value / step + 0.5) * step
        row:SetDisplay(value)
        if row.loading then return end
        set(value)
    end)

    watchers[#watchers + 1] = function()
        row.loading = true
        local v = get()
        row.slider:SetValue(v)
        row:SetDisplay(v)
        row.loading = false
    end
    return y + 42
end

local function Px(v) return string.format("%.0f px", v) end
local function Pct(v) return string.format("%.0f%%", v * 100) end
local function Count(v) return string.format("%.0f", v) end

local y = AddHeading(0, "THE ICON")

y = AddSlider(y, "Size", 32, 512, 1,
    function() return db("size") end,
    function(v)
        SpellCastedDB.size = v
        frame:SetSize(v, v)
        UpdateFeedbackOverlaySize()
    end, Px)

y = AddSlider(y, "Opacity", 0.1, 1.0, 0.05,
    function() return db("alpha") end,
    function(v)
        SpellCastedDB.alpha = v
        frame:SetAlpha(v)
        historyFrame:SetAlpha(v)
    end, Pct)

y = AddCheck(y, "Always show the icon",
    "Off hides it between casts. On leaves the last spell up.",
    function() return db("alwaysShow") end,
    function(on)
        SpellCastedDB.alwaysShow = on
        if on and lastTexture then
            icon:SetTexture(lastTexture)
            icon:Show()
        elseif not on then
            icon:Hide()
        end
    end)

y = AddHeading(y + 8, "SPELL HISTORY")

y = AddCheck(y, "Show the history",
    "A row of the spells you last cast, with a place of its own.",
    function() return db("history") end,
    function(on)
        SpellCastedDB.history = on
        RefreshHistory()
    end)

y = AddSlider(y, "How many icons", 2, 12, 1,
    function() return db("historyCount") end,
    function(v)
        SpellCastedDB.historyCount = v
        -- A shorter list keeps what still fits and drops the rest, rather than
        -- holding on to entries nothing will ever show.
        while #recent > v do table.remove(recent) end
        RefreshHistory()
    end, Count)

y = AddSlider(y, "Icon size", 16, 96, 1,
    function() return db("historySize") end,
    function(v)
        SpellCastedDB.historySize = v
        RefreshHistory()
    end, Px)

y = AddSlider(y, "Space between", 0, 24, 1,
    function() return db("historySpacing") end,
    function(v)
        SpellCastedDB.historySpacing = v
        RefreshHistory()
    end, Px)

y = AddCheck(y, "Older ones fade", nil,
    function() return db("historyFade") end,
    function(on)
        SpellCastedDB.historyFade = on
        RefreshHistory()
    end)

y = AddCheck(y, "Newest on the left", nil,
    function() return db("historyNewestLeft") end,
    function(on)
        SpellCastedDB.historyNewestLeft = on
        RefreshHistory()
    end)

local exampleBtn = UI.CreateButton(body, "Fill with examples", 140, 24)
exampleBtn:SetPoint("TOPLEFT", 0, -(y + 4))
exampleBtn:SetScript("OnClick", function()
    FillHistoryExample()
    RefreshPanel()
end)

local clearBtn = UI.CreateButton(body, "Empty it", 100, 24)
clearBtn:SetPoint("TOPLEFT", 148, -(y + 4))
clearBtn:SetScript("OnClick", function() ClearHistory() end)
y = y + 40

y = AddHeading(y, "PLACING THEM")

local lockBtn = UI.CreateButton(body, "Unlock", 120, 26, "primary")
lockBtn:SetPoint("TOPLEFT", 0, -y)
lockBtn:SetScript("OnClick", function(self)
    SetLocked(not locked)
    self:SetText(locked and "Unlock" or "Lock")
end)

local resetBtn = UI.CreateButton(body, "Reset", 100, 26, "danger")
resetBtn:SetPoint("TOPLEFT", 128, -y)
resetBtn:SetScript("OnClick", function()
    SpellCastedDB = {}
    ReloadUI()
end)

local info = UI.Text(panel, 11, "textDim")
info:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 14)
info:SetText("/sc opens and closes this panel")

-------------------------------------------------------------------------------
-- Cast events
-------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, unit, _, spellID)
    if event == "ADDON_LOADED" then
        if unit == ADDON_NAME then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", db("x"), db("y"))
            frame:SetSize(db("size"), db("size"))
            frame:SetAlpha(db("alpha"))
            RefreshPanel()
            RefreshHistory()
        end
        return
    end

    if unit ~= "player" then return end

    local castStart = event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"

    if castStart and spellID then
        ShowSpellIcon(C_Spell.GetSpellTexture(spellID))
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and spellID then
        local tex = C_Spell.GetSpellTexture(spellID)
        ShowSpellIcon(tex)
        PushHistory(spellID, tex)
        C_Timer.After(0.5, function() HideOrKeep() end)
    elseif event == "UNIT_SPELLCAST_FAILED" and spellID then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then ShowCancelFeedback(tex, "Interface\\RaidFrame\\ReadyCheck-NotReady", 1, 0.2, 0.2) end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" and spellID then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then ShowCancelFeedback(tex, "Interface\\PVPFrame\\Icon-Combat", 1, 0.5, 0) end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        HideOrKeep()
    end
end)

-------------------------------------------------------------------------------
-- Slash command
-------------------------------------------------------------------------------
SLASH_SPELLCASTED1 = "/sc"
SLASH_SPELLCASTED2 = "/spellcasted"

SlashCmdList["SPELLCASTED"] = function()
    if panel:IsShown() then
        panel:Hide()
    else
        RefreshPanel()
        panel:Show()
    end
end

SetLocked(true)
