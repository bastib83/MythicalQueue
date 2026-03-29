GuildKey = GuildKey or {}
GuildKey.StatsUI = {}

local contentFrame

-- ─── Initialisierung ──────────────────────────────────────────────────────────
function GuildKey.StatsUI:Init(parent)
    contentFrame = CreateFrame("Frame", "GuildKeyStatsFrame", parent)
    contentFrame:SetAllPoints(parent)

    self:BuildUI()
    GuildKey.UI:RegisterContentFrame(4, contentFrame)
    self:Refresh()
end

-- ─── UI aufbauen ─────────────────────────────────────────────────────────────
function GuildKey.StatsUI:BuildUI()
    local f = contentFrame
    local W = f:GetWidth() or 530

    -- ── 3 Metrik-Kacheln oben ─────────────────────────────────
    local tileW = math.floor((W - 24) / 3)
    local tileH = 72
    local tileY = -8

    local tiles = {
        { key = "weeklyRuns",   label = GuildKey.L["Runs this week"], color = { 0.00, 0.80, 1.00 } },
        { key = "inTimeRate",   label = GuildKey.L["In-time rate"],   color = { 0.00, 1.00, 0.40 } },
        { key = "highestKey",   label = GuildKey.L["Highest key"],    color = { 0.78, 0.66, 0.29 } },
    }
    self.tileLabels = {}

    for i, tile in ipairs(tiles) do
        local xOff = 8 + (i - 1) * (tileW + 4)
        local card = CreateFrame("Frame", nil, f, "BackdropTemplate")
        card:SetSize(tileW, tileH)
        card:SetPoint("TOPLEFT", f, "TOPLEFT", xOff, tileY)
        card:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
        card:SetBackdropColor(0.07, 0.08, 0.12, 0.95)
        card:SetBackdropBorderColor(tile.color[1] * 0.5, tile.color[2] * 0.5, tile.color[3] * 0.5, 0.8)

        local lbl = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOP", card, "TOP", 0, -10)
        lbl:SetText("|cff888888" .. tile.label .. "|r")

        local val = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        val:SetPoint("CENTER", card, "CENTER", 0, 6)
        val:SetText("0")
        val:SetTextColor(tile.color[1], tile.color[2], tile.color[3], 1)

        self.tileLabels[tile.key] = val
    end

    -- ── Reset-Countdown ────────────────────────────────────────
    local resetCard = CreateFrame("Frame", nil, f, "BackdropTemplate")
    resetCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, tileY - tileH - 8)
    resetCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, tileY - tileH - 8)
    resetCard:SetHeight(32)
    resetCard:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
    resetCard:SetBackdropColor(0.07, 0.08, 0.12, 0.90)
    resetCard:SetBackdropBorderColor(0.25, 0.20, 0.40, 0.5)

    local resetLbl = resetCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetLbl:SetPoint("LEFT", resetCard, "LEFT", 12, 0)
    resetLbl:SetText("|cff888888" .. GuildKey.L["Weekly reset"] .. ":|r")

    self.resetCountdownLabel = resetCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.resetCountdownLabel:SetPoint("LEFT", resetLbl, "RIGHT", 8, 0)
    self.resetCountdownLabel:SetText("--:--:--")
    self.resetCountdownLabel:SetTextColor(0.78, 0.66, 0.29, 1)

    -- OnUpdate für Countdown
    resetCard:SetScript("OnUpdate", function(self, elapsed)
        self._timer = (self._timer or 0) + elapsed
        if self._timer >= 1 then
            self._timer = 0
            local secs = GuildKey.Stats:GetTimeUntilWeeklyReset()
            local d = math.floor(secs / 86400)
            local h = math.floor((secs % 86400) / 3600)
            local m = math.floor((secs % 3600) / 60)
            local s = secs % 60
            local str
            if d > 0 then
                str = string.format("%dd %02d:%02d:%02d", d, h, m, s)
            else
                str = string.format("%02d:%02d:%02d", h, m, s)
            end
            GuildKey.StatsUI.resetCountdownLabel:SetText(str)
        end
    end)

    -- ── Top-Runs Tabelle ───────────────────────────────────────
    local tableY = tileY - tileH - 48

    local tableHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tableHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 10, tableY)
    tableHeader:SetText(GuildKey.L["Top runs"])
    tableHeader:SetTextColor(0.78, 0.66, 0.29, 1)

    -- Spaltenköpfe
    local function ColHeader(text, x, y_)
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT", x, y_)
        lbl:SetText("|cff888888" .. text .. "|r")
        return lbl
    end
    ColHeader("Dungeon",   10, tableY - 18)
    ColHeader("Level",    180, tableY - 18)
    ColHeader("Zeit",     240, tableY - 18)
    ColHeader("In Time",  320, tableY - 18)
    ColHeader("Score",    400, tableY - 18)

    -- Trennlinie
    local div = GuildKey.Widgets:CreateDivider(f)
    div:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, tableY - 30)
    div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, tableY - 30)

    -- ScrollFrame für Top-Runs
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     f, "TOPLEFT",     8, tableY - 32)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -22, 4)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 4)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    self.topRunScrollChild = scrollChild
    self.topRunRows        = {}
end

-- ─── Aktualisieren ────────────────────────────────────────────────────────────
function GuildKey.StatsUI:Refresh()
    if not contentFrame then return end
    if not contentFrame:IsShown() then return end

    local stats = GuildKeyDB and GuildKeyDB.stats
    if not stats then return end

    -- Kacheln
    if self.tileLabels then
        if self.tileLabels.weeklyRuns then
            self.tileLabels.weeklyRuns:SetText(tostring(stats.weeklyRuns or 0))
        end
        if self.tileLabels.inTimeRate then
            local rate = GuildKey.Stats:GetInTimeRate()
            self.tileLabels.inTimeRate:SetText(rate .. "%")
            local r, g = rate >= 80 and 0 or 1, rate >= 80 and 1 or (rate >= 50 and 0.85 or 0.25)
            self.tileLabels.inTimeRate:SetTextColor(r, g, 0.4, 1)
        end
        if self.tileLabels.highestKey then
            local hk = stats.highestKey or 0
            local color = GuildKey.Constants:GetKeyColor(hk)
            local r, g, b = 1, 1, 1
            if color then
                local hex = color:match("|cff(%x%x%x%x%x%x)")
                if hex then
                    r = tonumber(hex:sub(1,2), 16) / 255
                    g = tonumber(hex:sub(3,4), 16) / 255
                    b = tonumber(hex:sub(5,6), 16) / 255
                end
            end
            self.tileLabels.highestKey:SetText("+" .. hk)
            self.tileLabels.highestKey:SetTextColor(r, g, b, 1)
        end
    end

    -- Top-Runs Tabelle
    local scrollChild = self.topRunScrollChild
    if not scrollChild then return end

    -- Alte Zeilen löschen
    for _, row in ipairs(self.topRunRows or {}) do
        row:Hide()
        row:SetParent(nil)
    end
    self.topRunRows = {}

    local topRuns = stats.topRuns or {}
    if #topRuns == 0 then
        local noData = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noData:SetPoint("TOP", scrollChild, "TOP", 0, -10)
        noData:SetText("|cff888888" .. GuildKey.L["No stats yet"] .. "|r")
        table.insert(self.topRunRows, noData)
        scrollChild:SetHeight(40)
        return
    end

    local rowH = 18
    for i, run in ipairs(topRuns) do
        local yOff = -(i - 1) * rowH - 4

        -- Dungeon-Name
        local dung = run.dungeonId and GuildKey.Constants:GetDungeonByChallengeID(run.dungeonId)
        local dungName = dung and dung.shortName or "?"

        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(scrollChild:GetWidth(), rowH)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)

        if i % 2 == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.10, 0.08, 0.16, 0.4)
        end

        local function Cell(text, x, color)
            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", row, "LEFT", x, 0)
            lbl:SetText(text)
            if color then lbl:SetTextColor(unpack(color)) end
            return lbl
        end

        Cell(dungName, 2, nil)

        local lvlColor = GuildKey.Constants:GetKeyColor(run.keystoneLevel or 0)
        local r_, g_, b_ = 1, 1, 1
        if lvlColor then
            local hex = lvlColor:match("|cff(%x%x%x%x%x%x)")
            if hex then
                r_ = tonumber(hex:sub(1,2), 16) / 255
                g_ = tonumber(hex:sub(3,4), 16) / 255
                b_ = tonumber(hex:sub(5,6), 16) / 255
            end
        end
        Cell("+" .. (run.keystoneLevel or "?"), 172, { r_, g_, b_, 1 })

        Cell(GuildKey.Utils:FormatDuration(run.durationSecs or 0), 232, nil)

        local itColor = run.onTime and { 0, 1, 0.4, 1 } or { 1, 0.3, 0.3, 1 }
        Cell(run.onTime and "✓" or "✗", 312, itColor)

        Cell(tostring(run.rating or 0), 392, { 0.78, 0.66, 0.29, 1 })

        table.insert(self.topRunRows, row)
    end

    scrollChild:SetHeight(#topRuns * rowH + 8)
end
