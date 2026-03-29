GuildKey = GuildKey or {}
GuildKey.Widgets = {}

local T = GuildKey.Themes.current

-- ─── Rollen-Slot (T/H/D Anzeige) ─────────────────────────────────────────────
function GuildKey.Widgets:CreateRoleSlot(parent, role, filled)
    local T_  = GuildKey.Themes.current
    local rc  = GuildKey.Themes:GetRoleColor(role)

    local btn = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    btn:SetSize(26, 26)
    btn:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    local alpha = filled and 1.0 or 0.35
    btn:SetBackdropColor(rc.r * 0.3, rc.g * 0.3, rc.b * 0.3, alpha)
    btn:SetBackdropBorderColor(rc.r, rc.g, rc.b, alpha)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(role:sub(1, 1))  -- T, H, D
    label:SetTextColor(rc.r, rc.g, rc.b, filled and 1.0 or 0.5)

    -- Puls-Animation für freie Slots
    if not filled then
        local ag = btn:CreateAnimationGroup()
        ag:SetLooping("BOUNCE")
        local anim = ag:CreateAnimation("Alpha")
        anim:SetFromAlpha(0.3)
        anim:SetToAlpha(0.8)
        anim:SetDuration(0.8)
        ag:Play()
    end

    btn.label = label
    return btn
end

-- ─── Status-Dot (Online-Indikator) ───────────────────────────────────────────
function GuildKey.Widgets:CreateStatusDot(parent, status)
    local T_ = GuildKey.Themes.current
    local colorMap = {
        online    = T_.ONLINE,
        busy      = T_.BUSY,
        offline   = T_.OFFLINE,
        dungeon   = T_.IN_DUNGEON,
    }
    local c = colorMap[status] or T_.OFFLINE

    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetSize(8, 8)
    dot:SetTexture("Interface\\COMMON\\Indicator-Green")
    dot:SetVertexColor(c.r, c.g, c.b, c.a)
    dot.SetStatus = function(self, newStatus)
        local nc = colorMap[newStatus] or T_.OFFLINE
        self:SetVertexColor(nc.r, nc.g, nc.b, nc.a)
    end
    return dot
end

-- ─── Key-Badge (+15 etc.) ─────────────────────────────────────────────────────
function GuildKey.Widgets:CreateKeyBadge(parent, level)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(36, 20)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local colorCode = GuildKey.Constants:GetKeyColor(level or 0)
    -- Farbe parsen
    local r, g, b = 1, 1, 1
    if colorCode then
        local hex = colorCode:match("|cff(%x%x%x%x%x%x)")
        if hex then
            r = tonumber(hex:sub(1,2), 16) / 255
            g = tonumber(hex:sub(3,4), 16) / 255
            b = tonumber(hex:sub(5,6), 16) / 255
        end
    end

    frame:SetBackdropColor(r * 0.15, g * 0.15, b * 0.15, 0.9)
    frame:SetBackdropBorderColor(r, g, b, 0.8)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText("+" .. tostring(level or "?"))
    label:SetTextColor(r, g, b, 1)

    frame.label = label
    frame.SetLevel = function(self, lvl)
        self.label:SetText("+" .. tostring(lvl or "?"))
    end
    return frame
end

-- ─── Rollen-Checkbox ─────────────────────────────────────────────────────────
function GuildKey.Widgets:CreateRoleCheckbox(parent, role, label)
    local T_ = GuildKey.Themes.current
    local rc = GuildKey.Themes:GetRoleColor(role)

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(80, 20)

    local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    cb:SetSize(16, 16)
    cb:SetPoint("LEFT", frame, "LEFT", 0, 0)

    local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    lbl:SetText(label or role)
    lbl:SetTextColor(rc.r, rc.g, rc.b, 1)

    frame.checkbox = cb
    frame.IsChecked = function(self) return cb:GetChecked() end
    frame.SetChecked = function(self, val) cb:SetChecked(val) end
    frame.SetCallback = function(self, fn) cb:SetScript("OnClick", fn) end
    return frame
end

-- ─── Dropdown ────────────────────────────────────────────────────────────────
function GuildKey.Widgets:CreateDropdown(parent, options, onSelect)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(160, 24)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.07, 0.07, 0.12, 1)
    frame:SetBackdropBorderColor(0.35, 0.25, 0.55, 1)

    local selected = options[1] or ""
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", frame, "LEFT", 6, 0)
    label:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    label:SetText(selected)
    label:SetTextColor(1, 1, 1, 1)
    label:SetJustifyH("LEFT")

    local arrow = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    arrow:SetText("▼")
    arrow:SetTextColor(0.78, 0.66, 0.29, 1)

    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        -- Einfaches Drop-Down Menü
        local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu:SetSize(frame:GetWidth(), #options * 20 + 4)
        menu:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        menu:SetBackdropColor(0.07, 0.07, 0.12, 0.98)
        menu:SetBackdropBorderColor(0.35, 0.25, 0.55, 1)

        for i, opt in ipairs(options) do
            local item = CreateFrame("Button", nil, menu)
            item:SetSize(frame:GetWidth() - 8, 18)
            item:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -2 - (i - 1) * 20)
            local itemLabel = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            itemLabel:SetAllPoints()
            itemLabel:SetText(opt)
            itemLabel:SetTextColor(1, 1, 1, 1)
            itemLabel:SetJustifyH("LEFT")
            item:SetScript("OnEnter", function()
                itemLabel:SetTextColor(0.78, 0.66, 0.29, 1)
            end)
            item:SetScript("OnLeave", function()
                itemLabel:SetTextColor(1, 1, 1, 1)
            end)
            item:SetScript("OnClick", function()
                selected = opt
                label:SetText(opt)
                if onSelect then onSelect(opt, i) end
                menu:Hide()
            end)
        end

        -- Klick außerhalb schließt Menü
        local overlay = CreateFrame("Frame", nil, UIParent)
        overlay:SetAllPoints()
        overlay:SetFrameStrata("DIALOG")
        overlay:EnableMouse(true)
        overlay:SetScript("OnMouseDown", function()
            menu:Hide()
            overlay:Hide()
        end)
        menu:Show()
    end)

    frame.GetSelected = function() return selected end
    frame.SetSelected = function(self, val)
        selected = val
        label:SetText(val)
    end
    return frame
end

-- ─── Kopierfenster (für Discord-Text) ────────────────────────────────────────
function GuildKey.Widgets:ShowCopyDialog(title, text)
    if not text or text == "" then return end

    local frame = CreateFrame("Frame", "GuildKeyCopyDialog", UIParent, "BackdropTemplate")
    frame:SetSize(480, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetBackdrop(GuildKey.Themes:GetMainBackdrop())
    frame:SetBackdropColor(0.05, 0.06, 0.10, 0.97)
    frame:SetBackdropBorderColor(0.35, 0.25, 0.55, 1)

    local titleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", frame, "TOP", 0, -16)
    titleLabel:SetText("|cffA335EE" .. (title or "Text") .. "|r")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", titleLabel, "BOTTOM", 0, -6)
    hint:SetText("|cff888888Strg+A dann Strg+C zum Kopieren|r")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",  frame, "TOPLEFT",  16, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetText(text)
    editBox:HighlightText()
    scrollFrame:SetScrollChild(editBox)

    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 22)
    closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12)
    closeBtn:SetText(GuildKey.L["Close"])
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    frame:Show()
    return frame
end

-- ─── Toast-Benachrichtigung ───────────────────────────────────────────────────
function GuildKey.Widgets:ShowNotification(text, icon)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(260, 44)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.06, 0.10, 0.95)
    frame:SetBackdropBorderColor(0.64, 0.21, 0.93, 1)

    if icon then
        local iconTex = frame:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(28, 28)
        iconTex:SetPoint("LEFT", frame, "LEFT", 8, 0)
        iconTex:SetTexture(icon)
    end

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", frame, "CENTER", icon and 14 or 0, 0)
    label:SetText(text or "")
    label:SetTextColor(1, 1, 1, 1)

    -- Fade-out nach 4 Sekunden
    C_Timer.After(3.5, function()
        local ag = frame:CreateAnimationGroup()
        local fade = ag:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetDuration(0.5)
        ag:SetScript("OnFinished", function() frame:Hide() end)
        ag:Play()
    end)

    frame:Show()
    return frame
end

-- ─── Trennlinie ───────────────────────────────────────────────────────────────
function GuildKey.Widgets:CreateDivider(parent, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    if width then
        line:SetWidth(width)
    end
    line:SetColorTexture(0.35, 0.25, 0.55, 0.6)
    return line
end

-- ─── Einfacher Button ─────────────────────────────────────────────────────────
function GuildKey.Widgets:CreateButton(parent, label, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 80, height or 22)
    btn:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.20, 0.12, 0.35, 1)
    btn:SetBackdropBorderColor(0.50, 0.35, 0.75, 1)

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetAllPoints()
    txt:SetText(label or "")
    txt:SetTextColor(1, 1, 1, 1)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.30, 0.18, 0.50, 1)
        self:SetBackdropBorderColor(0.78, 0.66, 0.29, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.20, 0.12, 0.35, 1)
        self:SetBackdropBorderColor(0.50, 0.35, 0.75, 1)
    end)
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.40, 0.25, 0.65, 1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.20, 0.12, 0.35, 1)
    end)

    btn.label = txt
    return btn
end

-- ─── Input-Box ────────────────────────────────────────────────────────────────
function GuildKey.Widgets:CreateInputBox(parent, width, height, placeholder)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width or 120, height or 22)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.07, 0.07, 0.12, 1)
    frame:SetBackdropBorderColor(0.35, 0.25, 0.55, 1)

    local eb = CreateFrame("EditBox", nil, frame)
    eb:SetPoint("TOPLEFT",     frame, "TOPLEFT",     6, -3)
    eb:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6,  3)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetTextColor(1, 1, 1, 1)

    if placeholder then
        local ph = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        ph:SetPoint("LEFT", eb, "LEFT", 0, 0)
        ph:SetText(placeholder)
        eb:SetScript("OnTextChanged", function(self)
            if self:GetText() == "" then
                ph:Show()
            else
                ph:Hide()
            end
        end)
        eb:SetScript("OnEditFocusGained", function() ph:Hide() end)
        eb:SetScript("OnEditFocusLost",   function()
            if eb:GetText() == "" then ph:Show() end
        end)
    end

    frame.editBox = eb
    frame.GetText  = function(self) return eb:GetText() end
    frame.SetText  = function(self, t) eb:SetText(t or "") end
    frame.ClearFocus = function(self) eb:ClearFocus() end
    return frame
end
