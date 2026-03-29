GuildKey = GuildKey or {}
GuildKey.RunBoardUI = {}

local contentFrame
local runCards    = {}
local filterState = {}
local postForm    = nil

-- ─── Initialisierung ──────────────────────────────────────────────────────────
function GuildKey.RunBoardUI:Init(parent)
    contentFrame = CreateFrame("Frame", "GuildKeyRunBoardFrame", parent)
    contentFrame:SetAllPoints(parent)

    -- Filter-Leiste
    self:CreateFilterBar(contentFrame)

    -- ScrollFrame für Run-Karten
    self:CreateScrollArea(contentFrame)

    -- "Run eintragen"-Button
    local postBtn = GuildKey.Widgets:CreateButton(contentFrame, GuildKey.L["Post Run"], 120, 26)
    postBtn:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -4, 4)
    postBtn:SetScript("OnClick", function() GuildKey.RunBoardUI:ShowPostForm() end)

    GuildKey.UI:RegisterContentFrame(1, contentFrame)
    self:Refresh()
end

-- ─── Filter-Leiste ────────────────────────────────────────────────────────────
function GuildKey.RunBoardUI:CreateFilterBar(parent)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    bar:SetHeight(34)
    bar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        tile = true, tileSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    bar:SetBackdropColor(0.08, 0.06, 0.14, 0.8)

    local lbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", bar, "LEFT", 8, 0)
    lbl:SetText("|cff888888" .. GuildKey.L["Filter"] .. ":|r")

    -- Rollen-Dropdown
    local roleOptions = {
        GuildKey.L["All roles"],
        GuildKey.L["TANK"],
        GuildKey.L["HEALER"],
        GuildKey.L["DPS"],
    }
    local roleDD = GuildKey.Widgets:CreateDropdown(bar, roleOptions, function(opt)
        if opt == GuildKey.L["All roles"] then
            filterState.role = nil
        else
            local map = {
                [GuildKey.L["TANK"]]   = "TANK",
                [GuildKey.L["HEALER"]] = "HEALER",
                [GuildKey.L["DPS"]]    = "DPS",
            }
            filterState.role = map[opt]
        end
        GuildKey.RunBoardUI:Refresh()
    end)
    roleDD:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    roleDD:SetSize(110, 22)

    -- Min-Key-Input
    local minLbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minLbl:SetPoint("LEFT", roleDD, "RIGHT", 10, 0)
    minLbl:SetText("|cff888888Min:|r")

    local minInput = GuildKey.Widgets:CreateInputBox(bar, 40, 22, "1")
    minInput:SetPoint("LEFT", minLbl, "RIGHT", 4, 0)
    minInput.editBox:SetNumeric(true)
    minInput.editBox:SetScript("OnEnterPressed", function(self)
        filterState.minKey = tonumber(self:GetText())
        GuildKey.RunBoardUI:Refresh()
        self:ClearFocus()
    end)

    local maxLbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxLbl:SetPoint("LEFT", minInput, "RIGHT", 6, 0)
    maxLbl:SetText("|cff888888Max:|r")

    local maxInput = GuildKey.Widgets:CreateInputBox(bar, 40, 22, "99")
    maxInput:SetPoint("LEFT", maxLbl, "RIGHT", 4, 0)
    maxInput.editBox:SetNumeric(true)
    maxInput.editBox:SetScript("OnEnterPressed", function(self)
        filterState.maxKey = tonumber(self:GetText())
        GuildKey.RunBoardUI:Refresh()
        self:ClearFocus()
    end)

    -- Reset-Button
    local resetBtn = GuildKey.Widgets:CreateButton(bar, GuildKey.L["Reset filter"], 80, 22)
    resetBtn:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    resetBtn:SetScript("OnClick", function()
        filterState = {}
        roleDD:SetSelected(GuildKey.L["All roles"])
        minInput:SetText("")
        maxInput:SetText("")
        GuildKey.RunBoardUI:Refresh()
    end)

    self.filterBar = bar
end

-- ─── Scroll-Area ─────────────────────────────────────────────────────────────
function GuildKey.RunBoardUI:CreateScrollArea(parent)
    local scrollFrame = CreateFrame("ScrollFrame", "GuildKeyRunBoardScroll", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0, -36)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -22, 34)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 4)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
end

-- ─── Run-Karten aktualisieren ─────────────────────────────────────────────────
function GuildKey.RunBoardUI:Refresh()
    if not contentFrame then return end
    if not contentFrame:IsShown() then return end

    local runs = GuildKey.RunBoard:GetFilteredRuns(next(filterState) ~= nil and filterState or nil)

    -- Alte Karten entfernen
    for _, card in ipairs(runCards) do
        card:Hide()
        card:SetParent(nil)
    end
    runCards = {}

    local scrollChild = self.scrollChild
    if not scrollChild then return end

    -- Keine Runs Hinweis
    if #runs == 0 then
        local noRuns = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noRuns:SetPoint("TOP", scrollChild, "TOP", 0, -20)
        noRuns:SetText("|cff888888" .. GuildKey.L["No runs available"] .. "|r")
        table.insert(runCards, noRuns)
        scrollChild:SetHeight(60)
        return
    end

    local yOffset = -6
    local cardH   = 96

    for _, run in ipairs(runs) do
        local card = self:CreateRunCard(scrollChild, run)
        card:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  4, yOffset)
        card:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, yOffset)
        card:SetHeight(cardH)
        table.insert(runCards, card)
        yOffset = yOffset - cardH - 4
    end

    scrollChild:SetHeight(math.abs(yOffset) + 10)
end

-- ─── Einzelne Run-Karte ───────────────────────────────────────────────────────
function GuildKey.RunBoardUI:CreateRunCard(parent, run)
    local C = GuildKey.Constants

    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop(GuildKey.Themes:GetCardBackdrop())
    card:SetBackdropColor(0.08, 0.09, 0.14, 0.95)
    card:SetBackdropBorderColor(0.25, 0.20, 0.40, 0.8)

    -- Dungeon-Name
    local dungeon = run.dungeonId and C:GetDungeon(run.dungeonId)
    local dungName = run.dungeonName or (dungeon and dungeon.name) or GuildKey.L["Unknown"]

    local nameLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    nameLabel:SetText(dungName)
    nameLabel:SetTextColor(1, 1, 1, 1)

    -- Key-Level Badge
    local badge = GuildKey.Widgets:CreateKeyBadge(card, run.keyLevel or 0)
    badge:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)

    -- Ziel
    local goalLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    goalLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -4)
    goalLabel:SetText("|cff888888Ziel:|r " .. (run.goal or "In Time"))

    -- Zeit und Dauer
    local timeLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeLabel:SetPoint("LEFT", goalLabel, "RIGHT", 14, 0)
    local timeStr = run.plannedTime or "?"
    local durStr  = run.estimatedDuration and (run.estimatedDuration .. " Min.") or "?"
    timeLabel:SetText("|cff888888Zeit:|r " .. timeStr .. " |cff888888Dauer:|r ~" .. durStr)

    -- Leader
    local leaderLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leaderLabel:SetPoint("TOPLEFT", goalLabel, "BOTTOMLEFT", 0, -4)
    leaderLabel:SetText("|cff888888Leader:|r " .. (run.leaderChar or run.leader or "?"))

    -- Notizen
    if run.notes and run.notes ~= "" then
        local notesLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        notesLabel:SetPoint("LEFT", leaderLabel, "RIGHT", 14, 0)
        notesLabel:SetText("|cff888888Notiz:|r " .. run.notes)
        notesLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    end

    -- Rollen-Slots
    local slotX = 8
    local slotY = -60
    local neededRoles = run.neededRoles or {}
    local members     = run.members    or {}

    -- Tank-Slot
    local tankFilled = false
    for _, m in ipairs(members) do if m.role == "TANK"   then tankFilled = true break end end
    local tSlot = GuildKey.Widgets:CreateRoleSlot(card, "TANK",   neededRoles.tank   and not tankFilled)
    tSlot:SetPoint("TOPLEFT", card, "TOPLEFT", slotX, slotY)
    slotX = slotX + 32

    -- Healer-Slot
    local healFilled = false
    for _, m in ipairs(members) do if m.role == "HEALER" then healFilled = true break end end
    local hSlot = GuildKey.Widgets:CreateRoleSlot(card, "HEALER", neededRoles.healer and not healFilled)
    hSlot:SetPoint("TOPLEFT", card, "TOPLEFT", slotX, slotY)
    slotX = slotX + 32

    -- DPS-Slots
    local dpsNeeded = neededRoles.dps or 0
    local dpsFilled = 0
    for _, m in ipairs(members) do if m.role == "DPS" then dpsFilled = dpsFilled + 1 end end
    for d = 1, math.max(dpsNeeded, 3) do
        local dSlot = GuildKey.Widgets:CreateRoleSlot(card, "DPS", d <= dpsNeeded and d > dpsFilled)
        dSlot:SetPoint("TOPLEFT", card, "TOPLEFT", slotX, slotY)
        slotX = slotX + 32
    end

    -- Mitglieder-Anzahl
    local memberLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    memberLabel:SetPoint("TOPLEFT", card, "TOPLEFT", slotX + 8, slotY + 8)
    memberLabel:SetText("|cff888888" .. #members .. "/5 Mitglieder|r")

    -- Beitreten/Absagen Button (rechts)
    local myName = GuildKey.Utils:GetCharName()
    local isLeader = (run.leader == myName)
    local inRun = false
    for _, m in ipairs(members) do if m.name == myName then inRun = true break end end

    if isLeader then
        local cancelBtn = GuildKey.Widgets:CreateButton(card, GuildKey.L["Cancel run"], 90, 22)
        cancelBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
        cancelBtn:SetScript("OnClick", function()
            GuildKey.RunBoard:CancelRun(run.runId)
        end)
    elseif inRun then
        local leaveBtn = GuildKey.Widgets:CreateButton(card, GuildKey.L["Leave"], 80, 22)
        leaveBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
        leaveBtn:SetScript("OnClick", function()
            GuildKey.RunBoard:LeaveRun(run.runId)
        end)
    else
        local joinBtn = GuildKey.Widgets:CreateButton(card, GuildKey.L["Join"], 80, 22)
        joinBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
        joinBtn:SetScript("OnClick", function()
            GuildKey.RunBoard:JoinRun(run.runId, nil)
        end)
    end

    -- Discord-Share Button
    local discordBtn = GuildKey.Widgets:CreateButton(card, "Discord", 70, 22)
    discordBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8 - 86, 8)
    discordBtn:SetScript("OnClick", function()
        GuildKey.Discord:PostRun(run)
    end)

    return card
end

-- ─── Run-Eintragen Formular ───────────────────────────────────────────────────
function GuildKey.RunBoardUI:ShowPostForm()
    if postForm and postForm:IsShown() then
        postForm:Hide()
        return
    end
    if not postForm then
        postForm = self:CreatePostForm()
    end
    postForm:Show()
    postForm:Raise()
end

function GuildKey.RunBoardUI:CreatePostForm()
    local C = GuildKey.Constants

    local form = CreateFrame("Frame", "GuildKeyPostRunForm", UIParent, "BackdropTemplate")
    form:SetSize(380, 420)
    form:SetPoint("CENTER")
    form:SetMovable(true)
    form:EnableMouse(true)
    form:RegisterForDrag("LeftButton")
    form:SetScript("OnDragStart", form.StartMoving)
    form:SetScript("OnDragStop",  form.StopMovingOrSizing)
    form:SetFrameStrata("DIALOG")
    form:SetBackdrop(GuildKey.Themes:GetMainBackdrop())
    form:SetBackdropColor(0.05, 0.06, 0.10, 0.97)
    form:SetBackdropBorderColor(0.78, 0.66, 0.29, 1)

    local titleLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleLabel:SetPoint("TOP", form, "TOP", 0, -18)
    titleLabel:SetText("|cffA335EE" .. GuildKey.L["Post Run"] .. "|r")

    local closeBtn = CreateFrame("Button", nil, form, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", form, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() form:Hide() end)

    local y = -46

    -- Hilfsfunktion: Beschriftung
    local function Label(text, yPos)
        local lbl = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", form, "TOPLEFT", 16, yPos)
        lbl:SetText("|cff888888" .. text .. ":|r")
        return lbl
    end

    -- Dungeon-Dropdown
    Label(GuildKey.L["Dungeon"], y)
    local dungeonOptions = {}
    for _, d in ipairs(C.DUNGEONS) do
        table.insert(dungeonOptions, d.name)
    end
    local dungeonDD = GuildKey.Widgets:CreateDropdown(form, dungeonOptions, nil)
    dungeonDD:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    dungeonDD:SetSize(220, 22)
    y = y - 28

    -- Key-Stufe
    Label(GuildKey.L["Key Level"], y)
    local keyInput = GuildKey.Widgets:CreateInputBox(form, 60, 22, "15")
    keyInput:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    keyInput.editBox:SetNumeric(true)
    y = y - 28

    -- Geplante Zeit
    Label(GuildKey.L["Planned Time"], y)
    local timeInput = GuildKey.Widgets:CreateInputBox(form, 80, 22, "20:00")
    timeInput:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    y = y - 28

    -- Dauer
    Label(GuildKey.L["Duration"] .. " (Min.)", y)
    local durInput = GuildKey.Widgets:CreateInputBox(form, 60, 22, "45")
    durInput:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    durInput.editBox:SetNumeric(true)
    y = y - 28

    -- Ziel-Dropdown
    Label(GuildKey.L["Goal"], y)
    local goalOptions = { C.GOALS.INTIME, C.GOALS.PUSH, C.GOALS.FARM, C.GOALS.UPGRADE }
    local goalDD = GuildKey.Widgets:CreateDropdown(form, goalOptions, nil)
    goalDD:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    goalDD:SetSize(180, 22)
    y = y - 34

    -- Gesucht: Rollen
    Label(GuildKey.L["Slots needed"], y)

    local tankCB   = GuildKey.Widgets:CreateRoleCheckbox(form, "TANK",   "Tank")
    local healCB   = GuildKey.Widgets:CreateRoleCheckbox(form, "HEALER", "Healer")
    tankCB:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    healCB:SetPoint("LEFT", tankCB, "RIGHT", 10, 0)
    y = y - 28

    local dpsLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpsLabel:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 6)
    dpsLabel:SetText("|cffff2020DPS:|r")
    local dpsInput = GuildKey.Widgets:CreateInputBox(form, 40, 22, "2")
    dpsInput:SetPoint("LEFT", dpsLabel, "RIGHT", 6, -4)
    dpsInput.editBox:SetNumeric(true)
    y = y - 28

    -- Eigene Rolle
    Label("Meine Rolle", y)
    local myRoleOptions = { "TANK", "HEALER", "DPS" }
    local myRoleDD = GuildKey.Widgets:CreateDropdown(form, myRoleOptions, nil)
    myRoleDD:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    myRoleDD:SetSize(100, 22)
    -- Default auf bevorzugte Rolle
    if GuildKeyCharDB and GuildKeyCharDB.preferredRoles and GuildKeyCharDB.preferredRoles[1] then
        myRoleDD:SetSelected(GuildKeyCharDB.preferredRoles[1])
    end
    y = y - 28

    -- Notizen
    Label(GuildKey.L["Notes"], y)
    local notesInput = GuildKey.Widgets:CreateInputBox(form, 220, 22, "Optional...")
    notesInput:SetPoint("TOPLEFT", form, "TOPLEFT", 130, y + 3)
    y = y - 36

    -- Buttons
    local submitBtn = GuildKey.Widgets:CreateButton(form, GuildKey.L["Post"], 100, 26)
    submitBtn:SetPoint("BOTTOMRIGHT", form, "BOTTOMRIGHT", -16, 16)
    submitBtn:SetScript("OnClick", function()
        -- Dungeon-ID aus Namen ermitteln
        local selectedDungeon = dungeonDD:GetSelected()
        local dungeonId = nil
        for _, d in ipairs(C.DUNGEONS) do
            if d.name == selectedDungeon then
                dungeonId = d.id
                break
            end
        end

        local runData = {
            dungeonId         = dungeonId,
            keyLevel          = tonumber(keyInput:GetText()) or 15,
            plannedTime       = timeInput:GetText(),
            estimatedDuration = tonumber(durInput:GetText()) or 45,
            goal              = goalDD:GetSelected(),
            leaderRole        = myRoleDD:GetSelected(),
            neededRoles       = {
                tank   = tankCB:IsChecked(),
                healer = healCB:IsChecked(),
                dps    = tonumber(dpsInput:GetText()) or 0,
            },
            notes = notesInput:GetText(),
        }

        -- Leader sofort zu Run hinzufügen
        local runId = GuildKey.RunBoard:PostRun(runData)
        if runId then
            GuildKey.Data:JoinRun(runId, GuildKey.Utils:GetCharName(), runData.leaderRole)
        end

        form:Hide()
    end)

    local cancelBtn2 = GuildKey.Widgets:CreateButton(form, GuildKey.L["Cancel"], 80, 26)
    cancelBtn2:SetPoint("RIGHT", submitBtn, "LEFT", -8, 0)
    cancelBtn2:SetScript("OnClick", function() form:Hide() end)

    form:Hide()
    return form
end
