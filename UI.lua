-- UI.lua - shared design system for SpellCasted (dark, warm, gold)
--
-- The look is the Lands Between rather than a spreadsheet: a near-black ground
-- with a warm cast, thin gold rules that fade as they run, a serif for the
-- titles, and a grain over the whole thing so it reads as vellum rather than
-- glass. Sober first - nothing here glows, pulses or shouts.
--
-- All of it is built out of flat colour, gradients and textures the game
-- already ships, because an addon cannot bring image files of its own. Gold is
-- therefore a gradient rather than a metal texture: brighter along the top edge
-- and deeper along the bottom, which is what makes a hairline read as struck
-- rather than drawn. Every one of those tricks is asked for politely and falls
-- back to a flat colour if this client will not do it.
local addonName = ...

SpellCasted = SpellCasted or {}
local SC = SpellCasted

local UI = {}
SC.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8x8"
UI.WHITE = WHITE

-- Vellum. A texture the game has had for years, stretched across the ground and
-- laid on so faintly that what comes through is the mottling rather than the
-- parchment. If the path ever goes, nothing is drawn and the flat ground
-- underneath carries the window on its own.
UI.GRAIN = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
UI.grainAlpha = 0.07

UI.colors = {
    windowBg    = { 0.055, 0.047, 0.039, 0.97 },
    headerBg    = { 0.090, 0.078, 0.059, 1.00 },
    panelBg     = { 0.071, 0.061, 0.047, 0.94 },
    rowBg       = { 0.784, 0.678, 0.443, 0.040 },
    rowHover    = { 0.784, 0.678, 0.443, 0.105 },
    border      = { 0.451, 0.376, 0.235, 1.00 },
    borderSoft  = { 0.784, 0.678, 0.443, 0.200 },
    outline     = { 0.000, 0.000, 0.000, 0.920 },
    accent      = { 0.784, 0.678, 0.443, 1.00 },
    accentSoft  = { 0.784, 0.678, 0.443, 0.200 },

    -- The two ends of the gold, for anything that wants to catch the light.
    goldLit     = { 0.898, 0.816, 0.596, 1.00 },
    goldDeep    = { 0.380, 0.302, 0.173, 1.00 },

    text        = { 0.898, 0.859, 0.776, 1.00 },
    textMuted   = { 0.639, 0.596, 0.510, 1.00 },
    -- Headings across every addon are drawn in this one, so it is a dim gold
    -- rather than a grey: it gilds every section title without a single call
    -- site having to change.
    textDim     = { 0.545, 0.478, 0.345, 1.00 },

    success     = { 0.573, 0.714, 0.463, 1.00 },
    danger      = { 0.784, 0.357, 0.318, 1.00 },
    warning     = { 0.878, 0.706, 0.353, 1.00 },
}

UI.font      = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
UI.fontNum   = "Fonts\\ARIALN.TTF"
-- The quest title face: the one serif the game ships, and the reason a window
-- reads as a tome rather than a dialog box.
UI.fontTitle = "Fonts\\MORPHEUS.TTF"

local C = UI.colors

local function unpackc(c)
    return c[1], c[2], c[3], c[4] or 1
end
UI.Unpack = unpackc

function UI.Color(key)
    return unpackc(C[key] or C.text)
end

---Paints a texture with a gradient, and says whether this client would.
---@return boolean whether the gradient took
function UI.Gradient(tex, orientation, from, to)
    if not (tex.SetGradient and CreateColor) then return false end

    tex:SetTexture(WHITE)
    tex:SetVertexColor(1, 1, 1, 1)

    local ok = pcall(tex.SetGradient, tex, orientation,
        CreateColor(from[1], from[2], from[3], from[4] or 1),
        CreateColor(to[1], to[2], to[3], to[4] or 1))
    return ok and true or false
end

---A flat colour, or a gradient where the client allows one.
local function Paint(tex, color, from, to, orientation)
    if from and UI.Gradient(tex, orientation or "VERTICAL", from, to) then return end
    tex:SetColorTexture(unpackc(color))
end

-- Text -----------------------------------------------------------------------

function UI.Text(parent, size, colorKey, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(UI.font, size or 12, flags or "")
    fs:SetTextColor(unpackc(C[colorKey or "text"]))
    fs:SetJustifyH("LEFT")
    return fs
end

function UI.Number(parent, size, colorKey, flags)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(UI.fontNum, size or 12, flags or "")
    fs:SetTextColor(unpackc(C[colorKey or "text"]))
    return fs
end

---A heading in the serif, for the few places that want one.
function UI.Title(parent, size, colorKey)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(UI.fontTitle, size or 15, "")
    fs:SetTextColor(unpackc(C[colorKey or "accent"]))
    fs:SetJustifyH("LEFT")
    return fs
end

function UI.Hex(colorKey)
    local r, g, b = unpackc(C[colorKey] or C.text)
    return string.format("|cff%02x%02x%02x",
        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- Frame decoration -----------------------------------------------------------

---A hairline round a frame. Gold is lit along the top and deep along the
---bottom, so an edge looks struck rather than ruled.
function UI.AddBorder(frame, color, thickness, layer)
    thickness = thickness or 1
    color = color or C.border
    layer = layer or "BORDER"

    local lit = { math.min(1, color[1] * 1.35), math.min(1, color[2] * 1.35),
                  math.min(1, color[3] * 1.35), color[4] or 1 }
    local deep = { color[1] * 0.55, color[2] * 0.55, color[3] * 0.55, color[4] or 1 }

    local edges = {}

    local top = frame:CreateTexture(nil, layer, nil, 6)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(thickness)
    Paint(top, lit)

    local bottom = frame:CreateTexture(nil, layer, nil, 6)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(thickness)
    Paint(bottom, deep)

    local left = frame:CreateTexture(nil, layer, nil, 6)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(thickness)
    Paint(left, color, lit, deep, "VERTICAL")

    local right = frame:CreateTexture(nil, layer, nil, 6)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(thickness)
    Paint(right, color, lit, deep, "VERTICAL")

    edges.top, edges.bottom, edges.left, edges.right = top, bottom, left, right
    frame.borderEdges = edges
    return edges
end

function UI.SetBorderColor(frame, color)
    if not frame.borderEdges then return end

    local lit = { math.min(1, color[1] * 1.35), math.min(1, color[2] * 1.35),
                  math.min(1, color[3] * 1.35), color[4] or 1 }
    local deep = { color[1] * 0.55, color[2] * 0.55, color[3] * 0.55, color[4] or 1 }

    Paint(frame.borderEdges.top, lit)
    Paint(frame.borderEdges.bottom, deep)
    Paint(frame.borderEdges.left, color, lit, deep, "VERTICAL")
    Paint(frame.borderEdges.right, color, lit, deep, "VERTICAL")
end

function UI.SetBorderShown(frame, shown)
    if not frame.borderEdges then return end
    for _, tex in pairs(frame.borderEdges) do
        tex:SetShown(shown and true or false)
    end
end

---A second hairline inside the first. Two rules a pixel apart is most of what
---makes a panel look bound rather than drawn.
function UI.AddInnerBorder(frame, color, inset)
    inset = inset or 2
    color = color or C.borderSoft
    local edges = {}

    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local tex = frame:CreateTexture(nil, "BORDER", nil, 7)
        Paint(tex, color)

        if side == "TOP" then
            tex:SetPoint("TOPLEFT", inset, -inset)
            tex:SetPoint("TOPRIGHT", -inset, -inset)
            tex:SetHeight(1)
        elseif side == "BOTTOM" then
            tex:SetPoint("BOTTOMLEFT", inset, inset)
            tex:SetPoint("BOTTOMRIGHT", -inset, inset)
            tex:SetHeight(1)
        elseif side == "LEFT" then
            tex:SetPoint("TOPLEFT", inset, -inset)
            tex:SetPoint("BOTTOMLEFT", inset, inset)
            tex:SetWidth(1)
        else
            tex:SetPoint("TOPRIGHT", -inset, -inset)
            tex:SetPoint("BOTTOMRIGHT", -inset, inset)
            tex:SetWidth(1)
        end

        edges[#edges + 1] = tex
    end

    frame.innerEdges = edges
    return edges
end

---Short marks at the four corners. The one piece of ornament in the whole
---thing, and it is four pairs of hairlines.
function UI.AddCorners(frame, color, length, inset)
    color = color or C.accent
    length = length or 9
    inset = inset or 4

    local marks = {}
    for _, x in ipairs({ "LEFT", "RIGHT" }) do
        for _, y in ipairs({ "TOP", "BOTTOM" }) do
            local corner = y .. x
            local sx = (x == "LEFT") and inset or -inset
            local sy = (y == "TOP") and -inset or inset

            local across = frame:CreateTexture(nil, "OVERLAY")
            across:SetPoint(corner, sx, sy)
            across:SetSize(length, 1)
            Paint(across, color,
                (x == "LEFT") and color or { color[1], color[2], color[3], 0 },
                (x == "LEFT") and { color[1], color[2], color[3], 0 } or color,
                "HORIZONTAL")

            local down = frame:CreateTexture(nil, "OVERLAY")
            down:SetPoint(corner, sx, sy)
            down:SetSize(1, length)
            Paint(down, color,
                (y == "TOP") and { color[1], color[2], color[3], 0 } or color,
                (y == "TOP") and color or { color[1], color[2], color[3], 0 },
                "VERTICAL")

            marks[#marks + 1] = across
            marks[#marks + 1] = down
        end
    end

    frame.cornerMarks = marks
    return marks
end

---The grain. Laid over the ground, never under it, so the ground still carries
---the window if the texture is not there to be had.
function UI.AddGrain(frame, alpha)
    local grain = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    grain:SetAllPoints()
    grain:SetTexture(UI.GRAIN)
    grain:SetBlendMode("ADD")
    grain:SetVertexColor(0.62, 0.50, 0.32, alpha or UI.grainAlpha)
    frame.grainTex = grain
    return grain
end

function UI.Panel(frame, bgColor, borderColor)
    frame.bgTex = frame:CreateTexture(nil, "BACKGROUND")
    frame.bgTex:SetAllPoints()
    frame.bgTex:SetColorTexture(unpackc(bgColor or C.panelBg))

    UI.AddGrain(frame)

    if borderColor ~= false then
        UI.AddBorder(frame, borderColor or C.border)
    end
    return frame
end

---A rule that fades out as it runs, rather than stopping dead at the edge.
function UI.Divider(parent, color)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)

    local c = color or C.borderSoft
    Paint(t, c, c, { c[1], c[2], c[3], 0 }, "HORIZONTAL")
    return t
end

-- Window ---------------------------------------------------------------------

function UI.CreateWindow(globalName, width, height, titleText, subtitleText)
    local f = CreateFrame("Frame", globalName, UIParent)
    f:SetSize(width, height)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()

    UI.Panel(f, C.windowBg, C.outline)
    UI.AddInnerBorder(f, C.borderSoft, 2)
    UI.AddCorners(f, C.accent, 10, 5)

    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 3, -3)
    header:SetPoint("TOPRIGHT", -3, -3)
    header:SetHeight(38)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetColorTexture(unpackc(C.headerBg))

    -- Two rules under the title: a bright one and a whisper below it.
    header.line = header:CreateTexture(nil, "ARTWORK")
    header.line:SetPoint("BOTTOMLEFT")
    header.line:SetPoint("BOTTOMRIGHT")
    header.line:SetHeight(1)
    Paint(header.line, C.accent,
        { C.accent[1], C.accent[2], C.accent[3], 0.15 },
        { C.accent[1], C.accent[2], C.accent[3], 0.85 }, "HORIZONTAL")

    header.line2 = header:CreateTexture(nil, "ARTWORK")
    header.line2:SetPoint("BOTTOMLEFT", 0, -2)
    header.line2:SetPoint("BOTTOMRIGHT", 0, -2)
    header.line2:SetHeight(1)
    Paint(header.line2, C.accent,
        { C.accent[1], C.accent[2], C.accent[3], 0.05 },
        { C.accent[1], C.accent[2], C.accent[3], 0.28 }, "HORIZONTAL")

    header.accent = header:CreateTexture(nil, "ARTWORK")
    header.accent:SetPoint("LEFT", 14, 0)
    header.accent:SetSize(2, 15)
    Paint(header.accent, C.accent, C.goldLit, C.goldDeep, "VERTICAL")

    f.title = header:CreateFontString(nil, "OVERLAY")
    f.title:SetFont(UI.fontTitle, 15, "")
    f.title:SetTextColor(unpackc(C.text))
    f.title:SetJustifyH("LEFT")
    f.title:SetPoint("LEFT", header.accent, "RIGHT", 9, -1)
    f.title:SetText(titleText or "")

    f.subtitle = UI.Text(header, 11, "textDim")
    f.subtitle:SetPoint("LEFT", f.title, "RIGHT", 8, 1)
    f.subtitle:SetText(subtitleText or "")

    local close = CreateFrame("Button", nil, header)
    close:SetSize(24, 24)
    close:SetPoint("RIGHT", -8, 0)
    close.label = UI.Text(close, 15, "textMuted")
    close.label:SetPoint("CENTER", 0, 0)
    close.label:SetText("\195\151")
    close:SetScript("OnEnter", function(self) self.label:SetTextColor(unpackc(C.goldLit)) end)
    close:SetScript("OnLeave", function(self) self.label:SetTextColor(unpackc(C.textMuted)) end)
    close:SetScript("OnClick", function() f:Hide() end)

    f.header = header
    f.closeButton = close

    if globalName then
        tinsert(UISpecialFrames, globalName)
    end

    return f
end

-- Buttons --------------------------------------------------------------------

function UI.CreateButton(parent, text, width, height, kind)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 110, height or 24)
    b.kind = kind

    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()

    if kind == "primary" then
        b.baseColor = { C.accent[1], C.accent[2], C.accent[3], 0.16 }
        b.hoverColor = { C.accent[1], C.accent[2], C.accent[3], 0.32 }
    else
        b.baseColor = C.rowBg
        b.hoverColor = C.rowHover
    end
    b.bg:SetColorTexture(unpackc(b.baseColor))

    local borderColor = C.border
    if kind == "primary" then
        borderColor = C.accent
    elseif kind == "danger" then
        borderColor = { C.danger[1], C.danger[2], C.danger[3], 0.65 }
    end
    UI.AddBorder(b, borderColor)

    local labelKey = "text"
    if kind == "danger" then labelKey = "danger"
    elseif kind == "primary" then labelKey = "accent" end

    b.label = UI.Text(b, 12, labelKey)
    b.label:SetPoint("CENTER")
    b.label:SetJustifyH("CENTER")
    b.label:SetText(text or "")

    b:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(unpackc(self.hoverColor))
        if self.kind ~= "danger" then
            self.label:SetTextColor(unpackc(C.goldLit))
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(unpackc(self.baseColor))
        if self.kind ~= "danger" then
            self.label:SetTextColor(unpackc(self.kind == "primary" and C.accent or C.text))
        end
    end)
    b:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", 0, -1) end)
    b:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER", 0, 0) end)

    function b:SetText(t) self.label:SetText(t) end

    return b
end

-- Checkbox -------------------------------------------------------------------

function UI.CreateCheck(parent, label, tooltip)
    local c = CreateFrame("Button", nil, parent)
    c:SetHeight(22)
    c:SetWidth(260)

    local box = CreateFrame("Frame", nil, c)
    box:SetSize(15, 15)
    box:SetPoint("LEFT", 0, 0)
    box.bg = box:CreateTexture(nil, "BACKGROUND")
    box.bg:SetAllPoints()
    box.bg:SetColorTexture(0, 0, 0, 0.45)
    UI.AddBorder(box, C.border)

    local check = box:CreateTexture(nil, "ARTWORK")
    check:SetPoint("TOPLEFT", 3, -3)
    check:SetPoint("BOTTOMRIGHT", -3, 3)
    Paint(check, C.accent, C.goldLit, C.goldDeep, "VERTICAL")
    check:Hide()

    c.label = UI.Text(c, 12, "textMuted")
    c.label:SetPoint("LEFT", box, "RIGHT", 9, 0)
    c.label:SetText(label or "")

    c.box, c.check = box, check
    c.tooltipText = tooltip

    function c:SetChecked(v)
        self.checked = v and true or false
        check:SetShown(self.checked)
        self.label:SetTextColor(unpackc(self.checked and C.text or C.textMuted))
    end
    function c:GetChecked() return self.checked end

    c:SetScript("OnEnter", function(self)
        UI.SetBorderColor(box, C.accent)
        if self.tooltipText then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.tooltipText, 0.85, 0.82, 0.75, true)
            GameTooltip:Show()
        end
    end)
    c:SetScript("OnLeave", function()
        UI.SetBorderColor(box, C.border)
        GameTooltip:Hide()
    end)

    c:SetChecked(false)
    return c
end

-- Slider ---------------------------------------------------------------------

function UI.CreateSlider(parent, label, minV, maxV, step, formatter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(38)

    row.label = UI.Text(row, 12, "textMuted")
    row.label:SetPoint("TOPLEFT", 0, 0)
    row.label:SetText(label or "")

    row.value = UI.Number(row, 13, "accent")
    row.value:SetPoint("TOPRIGHT", 0, -1)
    row.value:SetJustifyH("RIGHT")

    local s = CreateFrame("Slider", nil, row)
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(14)
    s:SetPoint("BOTTOMLEFT", 0, 2)
    s:SetPoint("BOTTOMRIGHT", 0, 2)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:EnableMouseWheel(true)

    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0, 0, 0, 0.45)
    track:SetHeight(3)
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)

    local thumb = s:CreateTexture(nil, "OVERLAY")
    Paint(thumb, C.accent, C.goldLit, C.goldDeep, "VERTICAL")
    thumb:SetSize(4, 13)
    s:SetThumbTexture(thumb)

    local fill = s:CreateTexture(nil, "ARTWORK")
    Paint(fill, C.accent,
        { C.accent[1], C.accent[2], C.accent[3], 0.45 }, C.accent, "HORIZONTAL")
    fill:SetHeight(3)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)

    s:SetScript("OnEnter", function() Paint(thumb, C.goldLit) end)
    s:SetScript("OnLeave", function()
        Paint(thumb, C.accent, C.goldLit, C.goldDeep, "VERTICAL")
    end)
    s:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * step)
    end)

    row.slider = s
    row.track, row.fill, row.thumb = track, fill, thumb
    row.formatter = formatter or tostring

    function row:SetDisplay(v)
        row.value:SetText(row.formatter(v))
    end

    return row
end

-- Edit box -------------------------------------------------------------------

function UI.CreateEditBox(parent, width, height)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(width or 150, height or 24)
    holder.bg = holder:CreateTexture(nil, "BACKGROUND")
    holder.bg:SetAllPoints()
    holder.bg:SetColorTexture(0, 0, 0, 0.45)
    UI.AddBorder(holder, C.border)

    local eb = CreateFrame("EditBox", nil, holder)
    eb:SetPoint("TOPLEFT", 8, 0)
    eb:SetPoint("BOTTOMRIGHT", -8, 0)
    eb:SetFont(UI.font, 12, "")
    eb:SetTextColor(unpackc(C.text))
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() UI.SetBorderColor(holder, C.accent) end)
    eb:SetScript("OnEditFocusLost", function() UI.SetBorderColor(holder, C.border) end)

    holder.editBox = eb
    return holder, eb
end

function UI.CreateTextArea(parent, width, height)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(width or 300, height or 72)
    holder.bg = holder:CreateTexture(nil, "BACKGROUND")
    holder.bg:SetAllPoints()
    holder.bg:SetColorTexture(0, 0, 0, 0.45)
    UI.AddBorder(holder, C.border)

    local eb = CreateFrame("EditBox", nil, holder)
    eb:SetPoint("TOPLEFT", 6, -5)
    eb:SetPoint("BOTTOMRIGHT", -6, 5)
    eb:SetMultiLine(true)
    eb:SetFont(UI.fontNum, 11, "")
    eb:SetTextColor(unpackc(C.text))
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() UI.SetBorderColor(holder, C.accent) end)
    eb:SetScript("OnEditFocusLost", function() UI.SetBorderColor(holder, C.border) end)

    holder.editBox = eb
    return holder, eb
end

-- Dropdown -------------------------------------------------------------------

local openMenu

function UI.CreateDropdown(parent, width, items, getValue, onSelect)
    local dd = CreateFrame("Button", nil, parent)
    dd:SetSize(width or 170, 24)
    dd.bg = dd:CreateTexture(nil, "BACKGROUND")
    dd.bg:SetAllPoints()
    dd.bg:SetColorTexture(unpackc(C.rowBg))
    UI.AddBorder(dd, C.border)

    dd.label = UI.Text(dd, 12, "text")
    dd.label:SetPoint("LEFT", 9, 0)
    dd.label:SetPoint("RIGHT", -20, 0)
    dd.label:SetWordWrap(false)

    dd.arrow = UI.Text(dd, 9, "accent")
    dd.arrow:SetPoint("RIGHT", -8, 0)
    dd.arrow:SetText("\226\150\188")

    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetWidth(width or 170)
    menu:Hide()
    UI.Panel(menu, C.headerBg, C.outline)
    UI.AddInnerBorder(menu, C.borderSoft, 2)
    menu.buttons = {}

    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN")
    catcher:EnableMouse(true)
    catcher:Hide()

    local function CloseMenu()
        menu:Hide()
        catcher:Hide()
        if openMenu == menu then openMenu = nil end
    end

    catcher:SetScript("OnMouseDown", CloseMenu)

    local function BuildMenu()
        local list = type(items) == "function" and items() or items
        for _, b in ipairs(menu.buttons) do b:Hide() end
        local y = 5
        for i, item in ipairs(list) do
            local b = menu.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, menu)
                b:SetHeight(22)
                b.hl = b:CreateTexture(nil, "HIGHLIGHT")
                b.hl:SetAllPoints()
                b.hl:SetColorTexture(unpackc(C.rowHover))
                b.text = UI.Text(b, 12, "textMuted")
                b.text:SetPoint("LEFT", 11, 0)
                b.text:SetPoint("RIGHT", -10, 0)
                b.text:SetWordWrap(false)
                menu.buttons[i] = b
            end
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -y)
            b:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -2, -y)
            b.text:SetText(item.text)
            local isCurrent = getValue and getValue() == item.value
            b.text:SetTextColor(unpackc(isCurrent and C.accent or C.textMuted))
            b:SetScript("OnClick", function()
                if onSelect then onSelect(item.value, item) end
                dd.label:SetText(item.text)
                CloseMenu()
            end)
            b:Show()
            y = y + 22
        end
        menu:SetHeight(y + 5)
    end

    dd:SetScript("OnClick", function(self)
        if menu:IsShown() then CloseMenu() return end
        if openMenu then openMenu:Hide() end
        BuildMenu()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        catcher:Show()
        menu:Show()
        openMenu = menu
    end)
    dd:SetScript("OnEnter", function(self)
        UI.SetBorderColor(self, C.accent)
        self.label:SetTextColor(unpackc(C.goldLit))
    end)
    dd:SetScript("OnLeave", function(self)
        UI.SetBorderColor(self, C.border)
        self.label:SetTextColor(unpackc(C.text))
    end)
    dd:SetScript("OnHide", CloseMenu)

    function dd:Refresh()
        local list = type(items) == "function" and items() or items
        local current = getValue and getValue()
        for _, item in ipairs(list) do
            if item.value == current then dd.label:SetText(item.text) return end
        end
        dd.label:SetText(list[1] and list[1].text or "")
    end

    dd.menu = menu
    dd:Refresh()
    return dd
end

-- Color swatch ---------------------------------------------------------------

function UI.CreateSwatch(parent, size)
    local sw = CreateFrame("Button", nil, parent)
    sw:SetSize(size or 44, 18)

    sw.checker = sw:CreateTexture(nil, "BACKGROUND")
    sw.checker:SetAllPoints()
    sw.checker:SetColorTexture(0.09, 0.08, 0.06, 1)

    sw.color = sw:CreateTexture(nil, "ARTWORK")
    sw.color:SetPoint("TOPLEFT", 1, -1)
    sw.color:SetPoint("BOTTOMRIGHT", -1, 1)

    UI.AddBorder(sw, C.border)

    sw:SetScript("OnEnter", function(self) UI.SetBorderColor(self, C.accent) end)
    sw:SetScript("OnLeave", function(self) UI.SetBorderColor(self, C.border) end)

    function sw:SetColorValue(c)
        self.color:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    end

    return sw
end

-- Scroll frame (thin gold scrollbar) -----------------------------------------

function UI.CreateScroll(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(1, 1)
    sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)

    local bar = CreateFrame("Frame", nil, sf)
    bar:SetWidth(3)
    bar:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 0, 0)
    bar.track = bar:CreateTexture(nil, "BACKGROUND")
    bar.track:SetAllPoints()
    bar.track:SetColorTexture(0, 0, 0, 0.35)

    local thumb = CreateFrame("Frame", nil, bar)
    thumb:SetWidth(3)
    thumb:SetPoint("TOP", bar, "TOP", 0, 0)
    thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
    thumb.tex:SetAllPoints()
    thumb.tex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.40)
    thumb:EnableMouse(true)

    local function UpdateThumb()
        local range = math.max(0, content:GetHeight() - sf:GetHeight())
        if range <= 1 then
            bar:Hide()
            return
        end
        bar:Show()
        local h = sf:GetHeight()
        local thumbH = math.max(24, h * (h / content:GetHeight()))
        thumb:SetHeight(thumbH)
        local pct = sf:GetVerticalScroll() / range
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", bar, "TOP", 0, -pct * (h - thumbH))
    end

    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, content:GetHeight() - self:GetHeight())
        local new = math.min(math.max(self:GetVerticalScroll() - delta * 34, 0), range)
        self:SetVerticalScroll(new)
        UpdateThumb()
    end)
    sf:SetScript("OnVerticalScroll", function() UpdateThumb() end)
    sf:SetScript("OnScrollRangeChanged", function() UpdateThumb() end)
    sf:SetScript("OnSizeChanged", function(self, w)
        content:SetWidth(math.max(1, w - 8))
        UpdateThumb()
    end)

    thumb:SetScript("OnEnter", function(self)
        self.tex:SetColorTexture(C.goldLit[1], C.goldLit[2], C.goldLit[3], 0.75)
    end)
    thumb:SetScript("OnLeave", function(self)
        if not self.dragging then
            self.tex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.40)
        end
    end)
    thumb:SetScript("OnMouseDown", function(self)
        self.dragging = true
        self.startY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        self.startScroll = sf:GetVerticalScroll()
        self:SetScript("OnUpdate", function(s)
            local y = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta = s.startY - y
            local h = sf:GetHeight()
            local range = math.max(0, content:GetHeight() - h)
            local usable = math.max(1, h - s:GetHeight())
            local new = math.min(math.max(s.startScroll + delta * (range / usable), 0), range)
            sf:SetVerticalScroll(new)
            UpdateThumb()
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self.dragging = false
        self:SetScript("OnUpdate", nil)
        self.tex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.40)
    end)

    sf.content = content
    sf.UpdateThumb = UpdateThumb
    return sf, content
end

-- Bar textures ---------------------------------------------------------------

UI.barTextures = {
    { value = "Interface\\Buttons\\WHITE8x8",             text = "Flat" },
    { value = "Interface\\TargetingFrame\\UI-StatusBar",  text = "Blizzard" },
    { value = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",   text = "Smooth" },
    { value = "Interface\\PVPFrame\\UI-PVP-Progress-Bar", text = "Glossy" },
}

function UI.BarTextureName(path)
    for _, t in ipairs(UI.barTextures) do
        if t.value == path then return t.text end
    end
    return "Custom"
end
