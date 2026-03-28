local addonName, ns = ...

-- ============================================================
--  MythicalQueue – Hello World Demo Window
--  Zeigt verschiedene Schriftarten und Farben als Stilvorlage
-- ============================================================

local function CreateDemoWindow()

    -- ── Hauptrahmen ──────────────────────────────────────────
    local frame = CreateFrame("Frame", "MythicalQueueDemo", UIParent, "BackdropTemplate")
    frame:SetSize(360, 640)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")

    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.97)
    frame:SetBackdropBorderColor(0.4, 0.3, 0.6, 1)

    -- ── Titelleiste ──────────────────────────────────────────
    local titleBar = frame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",   12, -12)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
    titleBar:SetHeight(28)
    titleBar:SetColorTexture(0.15, 0.05, 0.3, 0.9)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -20)
    title:SetText("|cffA335EE✦ Mythical Queue ✦|r")

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("Hello World – Style Demo")

    -- ── Trennlinie ───────────────────────────────────────────
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT",  frame, "TOPLEFT",   16, -56)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT",  -16, -56)
    divider:SetHeight(1)
    divider:SetColorTexture(0.4, 0.3, 0.6, 0.8)

    -- ── Hilfsfunction: Label + Text-Zeile ────────────────────
    local yOffset = -68
    local function AddRow(label, content, fontObj)
        local lbl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
        lbl:SetText("|cff888888" .. label .. ":|r")

        local val = frame:CreateFontString(nil, "OVERLAY", fontObj or "GameFontNormal")
        val:SetPoint("TOPLEFT", frame, "TOPLEFT", 120, yOffset)
        val:SetText(content)
        yOffset = yOffset - 22
    end

    local function AddSpacer()
        yOffset = yOffset - 8
    end

    -- ── Schriftarten ─────────────────────────────────────────
    local sec1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sec1:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    sec1:SetText("|cff00CCFF── Schriftarten ──────────────────|r")
    yOffset = yOffset - 20

    AddRow("Normal",       "Normale Schrift",          "GameFontNormal")
    AddRow("Highlight",    "Highlighted Text",         "GameFontHighlight")
    AddRow("Large",        "Große Überschrift",        "GameFontNormalLarge")
    AddRow("Small",        "Kleiner Hinweis",          "GameFontNormalSmall")
    AddRow("Disabled",     "Deaktiviert",              "GameFontDisable")
    AddRow("Quest",        "Quest-Stil",               "QuestFont")
    AddRow("Number",       "1.234.567",                "NumberFontNormal")
    AddRow("Chat",         "Chat-Nachrichten",         "ChatFontNormal")

    AddSpacer()

    -- ── Itemqualitäts-Farben ─────────────────────────────────
    local sec2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sec2:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    sec2:SetText("|cff00CCFF── Item-Qualitäten ─────────────────|r")
    yOffset = yOffset - 20

    AddRow("Poor",      "|cff9d9d9dGrauer Text (Poor)|r")
    AddRow("Common",    "|cffffffffWeißer Text (Common)|r")
    AddRow("Uncommon",  "|cff1eff00Grüner Text (Uncommon)|r")
    AddRow("Rare",      "|cff0070ddBlauer Text (Rare)|r")
    AddRow("Epic",      "|cffA335EELila Text (Epic)|r")
    AddRow("Legendary", "|cffFF8000Oranger Text (Legendary)|r")
    AddRow("Artifact",  "|cffe6cc80Goldener Text (Artifact)|r")

    AddSpacer()

    -- ── UI-Farben ────────────────────────────────────────────
    local sec3 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sec3:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    sec3:SetText("|cff00CCFF── UI-Farben ────────────────────────|r")
    yOffset = yOffset - 20

    AddRow("Info",    "|cff00CCFFInfo-Blau|r")
    AddRow("Success", "|cff00FF96Erfolg-Grün|r")
    AddRow("Warning", "|cffFFD100Warnung-Gelb|r")
    AddRow("Danger",  "|cffFF4040Fehler-Rot|r")
    AddRow("Muted",   "|cff888888Gedämpftes Grau|r")

    -- ── Schließen-Button ─────────────────────────────────────
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- ── Slash-Befehl ─────────────────────────────────────────
    frame:Show()
    return frame
end

-- Fenster nach dem Laden öffnen
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns.demoWindow = CreateDemoWindow()
        SLASH_MQDEMO1 = "/mqdemo"
        SlashCmdList["MQdemo"] = function()
            if ns.demoWindow:IsShown() then
                ns.demoWindow:Hide()
            else
                ns.demoWindow:Show()
            end
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
