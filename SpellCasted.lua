local ADDON_NAME = "SpellCasted"

local DEFAULT = { x = 0, y = -200, size = 128, alpha = 1.0, alwaysShow = true }

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

-- Feedback overlay icon (Annulé / Interrompu)
local feedbackOverlay = frame:CreateTexture(nil, "OVERLAY")
feedbackOverlay:SetPoint("CENTER", frame, "CENTER")
feedbackOverlay:SetSize(frame:GetWidth() * 0.6, frame:GetHeight() * 0.6)
feedbackOverlay:Hide()

local function UpdateFeedbackOverlaySize()
    local s = frame:GetWidth() * 0.6
    feedbackOverlay:SetSize(s, s)
end

local cancelTimer = nil
local lastTexture = nil  -- dernière texture affichée
local locked = true

local function HideOrKeep()
    if db("alwaysShow") then
        -- garde la dernière icône visible, sans glow
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
    if locked then
        bg:Hide()
    else
        bg:Show()
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
local panel = CreateFrame("Frame", "SpellCastedPanel", UIParent, "BasicFrameTemplateWithInset")
panel:SetSize(320, 310)
panel:SetPoint("CENTER")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
panel:SetClampedToScreen(true)
panel:Hide()

panel.TitleText:SetText("SpellCasted — Paramètres")

local function MakeLabel(parent, text, x, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    lbl:SetText(text)
    return lbl
end

local function MakeSlider(parent, label, minVal, maxVal, step, initVal, x, y, onChange)
    local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    s:SetWidth(200)
    s:SetMinMaxValues(minVal, maxVal)
    s:SetValueStep(step)
    s:SetValue(initVal)
    s.Text:SetText(label)
    s.Low:SetText(minVal)
    s.High:SetText(maxVal)
    local val = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    val:SetPoint("TOP", s, "BOTTOM", 0, -2)
    val:SetText(initVal)
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        val:SetText(string.format(step < 1 and "%.2f" or "%d", v))
        onChange(v)
    end)
    return s
end

-- Taille
MakeLabel(panel, "Taille de l'icône", 18, -40)
MakeSlider(panel, "", 32, 512, 1, db("size"), 18, -60, function(v)
    SpellCastedDB.size = v
    frame:SetSize(v, v)
    UpdateFeedbackOverlaySize()
end)

-- Opacité
MakeLabel(panel, "Opacité", 18, -110)
MakeSlider(panel, "", 0.1, 1.0, 0.05, db("alpha"), 18, -130, function(v)
    SpellCastedDB.alpha = v
    frame:SetAlpha(v)
end)

-- Toujours afficher l'icône
MakeLabel(panel, "Comportement", 18, -180)
local alwaysCb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
alwaysCb:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -198)
alwaysCb:SetChecked(db("alwaysShow"))
alwaysCb.Text:SetText("Toujours afficher l'icône")
alwaysCb:SetScript("OnClick", function(self)
    SpellCastedDB.alwaysShow = self:GetChecked()
    if not self:GetChecked() and not icon:IsShown() then
        icon:Hide()
    elseif self:GetChecked() and lastTexture then
        icon:SetTexture(lastTexture)
        icon:Show()
    end
end)

-- Lock / Unlock
MakeLabel(panel, "Position", 18, -232)
local lockBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
lockBtn:SetSize(120, 26)
lockBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -250)
lockBtn:SetText(locked and "Déverrouiller" or "Verrouiller")
lockBtn:SetScript("OnClick", function(self)
    SetLocked(not locked)
    self:SetText(locked and "Déverrouiller" or "Verrouiller")
end)

-- Reset
local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(100, 26)
resetBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 150, -250)
resetBtn:SetText("Réinitialiser")
resetBtn:SetScript("OnClick", function()
    SpellCastedDB = {}
    ReloadUI()
end)

local info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
info:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 16)
info:SetText("|cffaaaaaa/sc  pour ouvrir/fermer ce panneau|r")

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
            alwaysCb:SetChecked(db("alwaysShow"))
        end
        return
    end

    if unit ~= "player" then return end

    local castStart = event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"

    if castStart and spellID then
        ShowSpellIcon(C_Spell.GetSpellTexture(spellID))
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and spellID then
        ShowSpellIcon(C_Spell.GetSpellTexture(spellID))
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
    if panel:IsShown() then panel:Hide() else panel:Show() end
end

SetLocked(true)
