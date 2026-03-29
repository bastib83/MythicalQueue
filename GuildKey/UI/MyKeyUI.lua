GuildKey = GuildKey or {}
GuildKey.MyKeyUI = {}

local contentFrame

-- ─── Initialisierung ──────────────────────────────────────────────────────────
function GuildKey.MyKeyUI:Init(parent)
    contentFrame = CreateFrame("Frame", "GuildKeyMyKeyFrame", parent)
    contentFrame:SetAllPoints(parent)

    self:BuildUI()
    GuildKey.UI:RegisterContentFrame(3, contentFrame)
    self:Refresh()
end

-- ─── UI aufbauen ─────────────────────────────────────────────────────────────
function GuildKey.MyKeyUI:BuildUI()
    local f = contentFrame
    local y = -10

    -- ── Eigener Keystone ───────────────────────────────────────
    local keyCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    keyCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, y)
    keyCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, y)
    keyCard:SetHeight(80)
    keyCard:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
    keyCard:SetBackdropColor(0.08, 0.07, 0.14, 0.95)
    keyCard:SetBackdropBorderColor(0.78, 0.66, 0.29, 0.8)
    self.keyCard = keyCard

    local keyTitle = keyCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyTitle:SetPoint("TOPLEFT", keyCard, "TOPLEFT", 12, -12)
    keyTitle:SetText("|cff888888" .. GuildKey.L["My Keystone"] .. ":|r")

    self.keyDungeonLabel = keyCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.keyDungeonLabel:SetPoint("TOPLEFT", keyTitle, "BOTTOMLEFT", 0, -6)
    self.keyDungeonLabel:SetText(GuildKey.L["No keystone"])
    self.keyDungeonLabel:SetTextColor(0.78, 0.66, 0.29, 1)

    self.keyLevelLabel = keyCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.keyLevelLabel:SetPoint("TOPRIGHT", keyCard, "TOPRIGHT", -14, -22)
    self.keyLevelLabel:SetText("")

    local refreshKeyBtn = GuildKey.Widgets:CreateButton(keyCard, GuildKey.L["Refresh"], 80, 20)
    refreshKeyBtn:SetPoint("BOTTOMRIGHT", keyCard, "BOTTOMRIGHT", -8, 8)
    refreshKeyBtn:SetScript("OnClick", function()
        GuildKey.MyKey:ReadOwnKeystone()
    end)

    local shareBtn = GuildKey.Widgets:CreateButton(keyCard, GuildKey.L["Broadcast key"], 110, 20)
    shareBtn:SetPoint("RIGHT", refreshKeyBtn, "LEFT", -6, 0)
    shareBtn:SetScript("OnClick", function()
        GuildKey.MyKey:BroadcastKey()
    end)

    y = y - 88

    -- ── Verfügbarkeit ──────────────────────────────────────────
    local availCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    availCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, y)
    availCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, y)
    availCard:SetHeight(50)
    availCard:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
    availCard:SetBackdropColor(0.08, 0.07, 0.14, 0.95)
    availCard:SetBackdropBorderColor(0.25, 0.20, 0.40, 0.6)

    local availLbl = availCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    availLbl:SetPoint("LEFT", availCard, "LEFT", 12, 0)
    availLbl:SetText("|cff888888" .. GuildKey.L["Availability"] .. ":|r")

    local C    = GuildKey.Constants
    local availOptions = {
        C.AVAILABILITY.NOW,
        C.AVAILABILITY.EVENING,
        C.AVAILABILITY.TOMORROW,
        C.AVAILABILITY.WEEKEND,
        C.AVAILABILITY.ON_REQUEST,
        C.AVAILABILITY.BUSY,
        C.AVAILABILITY.OFFLINE,
    }
    local availDD = GuildKey.Widgets:CreateDropdown(availCard, availOptions, function(opt)
        GuildKey.MyKey:SetAvailability(opt)
        GuildKey.MyKeyUI:Refresh()
    end)
    availDD:SetPoint("LEFT", availLbl, "RIGHT", 10, 0)
    availDD:SetSize(160, 22)
    self.availDD = availDD

    y = y - 58

    -- ── Bevorzugte Rollen ──────────────────────────────────────
    local rolesCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rolesCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, y)
    rolesCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, y)
    rolesCard:SetHeight(52)
    rolesCard:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
    rolesCard:SetBackdropColor(0.08, 0.07, 0.14, 0.95)
    rolesCard:SetBackdropBorderColor(0.25, 0.20, 0.40, 0.6)

    local rolesLbl = rolesCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rolesLbl:SetPoint("LEFT", rolesCard, "LEFT", 12, 8)
    rolesLbl:SetText("|cff888888" .. GuildKey.L["Preferred roles"] .. ":|r")

    local tankCB  = GuildKey.Widgets:CreateRoleCheckbox(rolesCard, "TANK",   "Tank")
    local healCB  = GuildKey.Widgets:CreateRoleCheckbox(rolesCard, "HEALER", "Healer")
    local dpsCB   = GuildKey.Widgets:CreateRoleCheckbox(rolesCard, "DPS",    "DPS")
    tankCB:SetPoint("TOPLEFT",  rolesCard, "TOPLEFT", 12, -24)
    healCB:SetPoint("LEFT", tankCB,  "RIGHT", 12, 0)
    dpsCB:SetPoint( "LEFT", healCB,  "RIGHT", 12, 0)

    self.tankCB = tankCB
    self.healCB = healCB
    self.dpsCB  = dpsCB

    local saveRolesBtn = GuildKey.Widgets:CreateButton(rolesCard, GuildKey.L["Save"], 70, 20)
    saveRolesBtn:SetPoint("RIGHT", rolesCard, "RIGHT", -10, 0)
    saveRolesBtn:SetScript("OnClick", function()
        local roles = {}
        if tankCB:IsChecked() then table.insert(roles, "TANK")   end
        if healCB:IsChecked() then table.insert(roles, "HEALER") end
        if dpsCB:IsChecked()  then table.insert(roles, "DPS")    end
        GuildKey.MyKey:SetPreferredRoles(roles)
        GuildKey.Utils:Print(GuildKey.L["Save"] .. " OK")
    end)

    y = y - 60

    -- ── Wochenfortschritt ──────────────────────────────────────
    local weekCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    weekCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, y)
    weekCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, y)
    weekCard:SetHeight(90)
    weekCard:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
    weekCard:SetBackdropColor(0.08, 0.07, 0.14, 0.95)
    weekCard:SetBackdropBorderColor(0.25, 0.20, 0.40, 0.6)

    local weekTitle = weekCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    weekTitle:SetPoint("TOPLEFT", weekCard, "TOPLEFT", 12, -10)
    weekTitle:SetText(GuildKey.L["Weekly progress"])
    weekTitle:SetTextColor(0.78, 0.66, 0.29, 1)

    -- Runs diese Woche
    self.weeklyRunsLabel = weekCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.weeklyRunsLabel:SetPoint("TOPLEFT", weekTitle, "BOTTOMLEFT", 0, -6)
    self.weeklyRunsLabel:SetText(GuildKey.L["Runs this week"] .. ": 0")

    -- In-Time-Rate
    self.inTimeRateLabel = weekCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.inTimeRateLabel:SetPoint("TOPLEFT", self.weeklyRunsLabel, "BOTTOMLEFT", 0, -4)
    self.inTimeRateLabel:SetText(GuildKey.L["In-time rate"] .. ": 0%")

    -- Mythic Score
    self.scoreLabel = weekCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.scoreLabel:SetPoint("TOPRIGHT", weekCard, "TOPRIGHT", -12, -28)
    self.scoreLabel:SetText(GuildKey.L["Mythic Score"] .. ": 0")
    self.scoreLabel:SetTextColor(0.64, 0.21, 0.93, 1)

    y = y - 98
end

-- ─── Aktualisieren ────────────────────────────────────────────────────────────
function GuildKey.MyKeyUI:Refresh()
    if not contentFrame then return end
    if not contentFrame:IsShown() then return end

    -- Keystone
    local key = GuildKeyCharDB and GuildKeyCharDB.currentKey
    if key and key.level and key.level > 0 then
        local dungName = GuildKey.MyKey:GetKeystoneDungeonName()
        self.keyDungeonLabel:SetText(dungName)
        local colorCode = GuildKey.Constants:GetKeyColor(key.level)
        self.keyLevelLabel:SetText(colorCode .. "+" .. key.level .. "|r")
    else
        self.keyDungeonLabel:SetText(GuildKey.L["No keystone"])
        self.keyDungeonLabel:SetTextColor(0.53, 0.53, 0.53, 1)
        self.keyLevelLabel:SetText("")
    end

    -- Verfügbarkeit
    local avail = GuildKeyCharDB and GuildKeyCharDB.availability or GuildKey.Constants.AVAILABILITY.OFFLINE
    if self.availDD then
        self.availDD:SetSelected(avail)
    end

    -- Bevorzugte Rollen
    if GuildKeyCharDB and GuildKeyCharDB.preferredRoles then
        local roles = GuildKeyCharDB.preferredRoles
        local hasRole = function(r)
            for _, v in ipairs(roles) do if v == r then return true end end
            return false
        end
        if self.tankCB then self.tankCB:SetChecked(hasRole("TANK"))   end
        if self.healCB then self.healCB:SetChecked(hasRole("HEALER")) end
        if self.dpsCB  then self.dpsCB:SetChecked( hasRole("DPS"))    end
    end

    -- Wöchentliche Stats
    local stats = GuildKeyDB and GuildKeyDB.stats
    if stats then
        if self.weeklyRunsLabel then
            self.weeklyRunsLabel:SetText(GuildKey.L["Runs this week"] .. ": " .. (stats.weeklyRuns or 0))
        end
        if self.inTimeRateLabel then
            local rate = GuildKey.Stats:GetWeeklyInTimeRate()
            local rateColor = rate >= 80 and "|cff1eff00" or (rate >= 50 and "|cffffd100" or "|cffff4040")
            self.inTimeRateLabel:SetText(GuildKey.L["In-time rate"] .. ": " .. rateColor .. rate .. "%|r")
        end
    end

    -- Mythic Score
    if self.scoreLabel then
        local score = GuildKey.MyKey:GetOwnScore()
        local scoreColor = score >= 2500 and "|cffFF8000" or (score >= 2000 and "|cffA335EE" or (score >= 1500 and "|cff0070dd" or "|cff888888"))
        self.scoreLabel:SetText(GuildKey.L["Mythic Score"] .. ": " .. scoreColor .. score .. "|r")
    end
end
