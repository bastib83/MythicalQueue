GuildKey = GuildKey or {}
GuildKey.UI = {}

local FRAME_W = 560
local FRAME_H = 520

local TAB_NAMES = {
    GuildKey.L["Runs"],
    GuildKey.L["Members"],
    GuildKey.L["MyKey"],
    GuildKey.L["Stats"],
}

local mainFrame
local tabs      = {}
local tabBtns   = {}
local contentFrames = {}
local activeTab = 1

-- ─── Hauptfenster erstellen ───────────────────────────────────────────────────
local function CreateMainFrame()
    mainFrame = CreateFrame("Frame", "GuildKeyMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(FRAME_W, FRAME_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetClampedToScreen(true)

    mainFrame:SetBackdrop(GuildKey.Themes:GetMainBackdrop())
    mainFrame:SetBackdropColor(0.05, 0.06, 0.10, 0.97)
    mainFrame:SetBackdropBorderColor(0.35, 0.25, 0.55, 1)

    -- ── Titelleiste ────────────────────────────────────────────
    local titleBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",   12, -12)
    titleBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT",  -12, -12)
    titleBg:SetHeight(32)
    titleBg:SetColorTexture(0.10, 0.05, 0.20, 0.95)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -22)
    title:SetText("|cffA335EE✦ GuildKey ✦|r")

    local version = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    version:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -44, -26)
    version:SetText("v" .. GuildKey.Constants.VERSION)

    -- ── Schließen-Button ────────────────────────────────────────
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() GuildKey.UI:Hide() end)

    -- ── Trennlinie unter Titel ──────────────────────────────────
    local divider = mainFrame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",   16, -50)
    divider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT",  -16, -50)
    divider:SetHeight(1)
    divider:SetColorTexture(0.35, 0.25, 0.55, 0.8)

    -- ── Tab-Buttons ─────────────────────────────────────────────
    local tabBarBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    tabBarBg:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",   12, -52)
    tabBarBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT",  -12, -52)
    tabBarBg:SetHeight(28)
    tabBarBg:SetColorTexture(0.08, 0.06, 0.14, 0.9)

    local tabWidth = (FRAME_W - 40) / #TAB_NAMES
    for i, name in ipairs(TAB_NAMES) do
        local tb = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
        tb:SetSize(tabWidth - 4, 24)
        tb:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14 + (i - 1) * tabWidth, -54)
        tb:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        tb:SetBackdropColor(0.10, 0.07, 0.18, 0.9)
        tb:SetBackdropBorderColor(0.25, 0.18, 0.40, 0.8)

        local tbl = tb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tbl:SetAllPoints()
        tbl:SetText(name)
        tbl:SetTextColor(0.70, 0.60, 0.85, 1)

        local tabIdx = i
        tb:SetScript("OnClick", function()
            GuildKey.UI:SelectTab(tabIdx)
        end)
        tb:SetScript("OnEnter", function(self)
            if activeTab ~= tabIdx then
                self:SetBackdropBorderColor(0.50, 0.35, 0.75, 1)
                tbl:SetTextColor(1, 1, 1, 1)
            end
        end)
        tb:SetScript("OnLeave", function(self)
            if activeTab ~= tabIdx then
                self:SetBackdropBorderColor(0.25, 0.18, 0.40, 0.8)
                tbl:SetTextColor(0.70, 0.60, 0.85, 1)
            end
        end)

        tb.label = tbl
        tabBtns[i] = tb
    end

    -- ── Content-Area ────────────────────────────────────────────
    local contentArea = CreateFrame("Frame", nil, mainFrame)
    contentArea:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     14, -84)
    contentArea:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -14, 14)
    mainFrame.contentArea = contentArea

    mainFrame:Hide()
    return mainFrame
end

-- ─── Tab auswählen ────────────────────────────────────────────────────────────
function GuildKey.UI:SelectTab(idx)
    activeTab = idx

    -- Alle Content-Frames verstecken
    for i, cf in ipairs(contentFrames) do
        if cf then cf:Hide() end
    end

    -- Tab-Buttons aktualisieren
    for i, tb in ipairs(tabBtns) do
        if i == idx then
            tb:SetBackdropColor(0.20, 0.10, 0.38, 1)
            tb:SetBackdropBorderColor(0.78, 0.66, 0.29, 1)
            tb.label:SetTextColor(0.78, 0.66, 0.29, 1)
        else
            tb:SetBackdropColor(0.10, 0.07, 0.18, 0.9)
            tb:SetBackdropBorderColor(0.25, 0.18, 0.40, 0.8)
            tb.label:SetTextColor(0.70, 0.60, 0.85, 1)
        end
    end

    -- Richtigen Content-Frame anzeigen und aktualisieren
    local cf = contentFrames[idx]
    if cf then
        cf:Show()
        -- Refresh aufrufen
        local refreshers = {
            function() if GuildKey.RunBoardUI    then GuildKey.RunBoardUI:Refresh()    end end,
            function() if GuildKey.MemberStatusUI then GuildKey.MemberStatusUI:Refresh() end end,
            function() if GuildKey.MyKeyUI       then GuildKey.MyKeyUI:Refresh()       end end,
            function() if GuildKey.StatsUI       then GuildKey.StatsUI:Refresh()       end end,
        }
        if refreshers[idx] then refreshers[idx]() end
    end
end

-- ─── Content-Frame registrieren ──────────────────────────────────────────────
function GuildKey.UI:RegisterContentFrame(idx, frame)
    contentFrames[idx] = frame
    if mainFrame and mainFrame.contentArea then
        frame:SetParent(mainFrame.contentArea)
        frame:SetAllPoints(mainFrame.contentArea)
    end
    if idx ~= activeTab then
        frame:Hide()
    end
end

-- ─── Öffentliche API ─────────────────────────────────────────────────────────
function GuildKey.UI:Show()
    if not mainFrame then
        mainFrame = CreateMainFrame()
        -- Sub-UIs initialisieren
        if GuildKey.RunBoardUI    then GuildKey.RunBoardUI:Init(mainFrame.contentArea)    end
        if GuildKey.MemberStatusUI then GuildKey.MemberStatusUI:Init(mainFrame.contentArea) end
        if GuildKey.MyKeyUI       then GuildKey.MyKeyUI:Init(mainFrame.contentArea)       end
        if GuildKey.StatsUI       then GuildKey.StatsUI:Init(mainFrame.contentArea)       end
        -- Tab 1 aktivieren
        self:SelectTab(1)
    end
    mainFrame:Show()
    self:SelectTab(activeTab)
end

function GuildKey.UI:Hide()
    if mainFrame then mainFrame:Hide() end
end

function GuildKey.UI:Toggle()
    if mainFrame and mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function GuildKey.UI:IsShown()
    return mainFrame and mainFrame:IsShown() or false
end

-- Run-Eintragen Formular öffnen
function GuildKey.UI:ShowPostRunForm()
    self:Show()
    self:SelectTab(1)
    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:ShowPostForm()
    end
end

-- Referenzen für Sub-UIs
GuildKey.UI.tabs = contentFrames
GuildKey.UI.frame = mainFrame
