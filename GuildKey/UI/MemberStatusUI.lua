GuildKey = GuildKey or {}
GuildKey.MemberStatusUI = {}

local contentFrame
local memberCards = {}

-- ─── Initialisierung ──────────────────────────────────────────────────────────
function GuildKey.MemberStatusUI:Init(parent)
    contentFrame = CreateFrame("Frame", "GuildKeyMemberStatusFrame", parent)
    contentFrame:SetAllPoints(parent)

    -- Kopfzeile
    local header = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -6)
    header:SetText("|cff888888" .. GuildKey.L["Online members"] .. " – " .. GuildKey.L["Mythic Score"] .. "|r")

    local refreshBtn = GuildKey.Widgets:CreateButton(contentFrame, GuildKey.L["Refresh"], 80, 20)
    refreshBtn:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", -4, -4)
    refreshBtn:SetScript("OnClick", function()
        GuildRoster()
        GuildKey.MemberStatus:RefreshGuildRoster()
    end)

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "GuildKeyMemberScroll", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     contentFrame, "TOPLEFT",     0, -28)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -22, 4)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 4)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild

    GuildKey.UI:RegisterContentFrame(2, contentFrame)
    self:Refresh()
end

-- ─── Aktualisieren ────────────────────────────────────────────────────────────
function GuildKey.MemberStatusUI:Refresh()
    if not contentFrame then return end
    if not contentFrame:IsShown() then return end

    local scrollChild = self.scrollChild
    if not scrollChild then return end

    -- Alte Karten löschen
    for _, card in ipairs(memberCards) do
        card:Hide()
        card:SetParent(nil)
    end
    memberCards = {}

    -- Mitglieder sammeln und sortieren
    local members    = GuildKey.Data:GetMembers()
    local memberList = {}
    for name, data in pairs(members) do
        data.name = data.name or name
        table.insert(memberList, data)
    end

    -- Aus WoW-Gildenliste ergänzen
    if GuildKey.Utils:IsInGuild() then
        local num = GetNumGuildMembers()
        local seenNames = {}
        for _, m in ipairs(memberList) do seenNames[m.name] = true end
        for i = 1, num do
            local name, _, _, level, _, zone, _, _, isOnline, _, class = GetGuildRosterInfo(i)
            if name and not seenNames[name] then
                table.insert(memberList, {
                    name     = name,
                    level    = level,
                    class    = class,
                    zone     = zone,
                    isOnline = isOnline,
                    score    = 0,
                })
            end
        end
    end

    -- Sortieren: Online zuerst, dann nach Score
    table.sort(memberList, function(a, b)
        if a.isOnline ~= b.isOnline then
            return (a.isOnline and 1 or 0) > (b.isOnline and 1 or 0)
        end
        return (a.score or 0) > (b.score or 0)
    end)

    if #memberList == 0 then
        local noMem = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noMem:SetPoint("TOP", scrollChild, "TOP", 0, -20)
        noMem:SetText("|cff888888" .. GuildKey.L["No guild members found"] .. "|r")
        table.insert(memberCards, noMem)
        scrollChild:SetHeight(60)
        return
    end

    -- Grid 2-spaltig
    local CARD_W = math.floor((scrollChild:GetWidth() - 12) / 2)
    local CARD_H = 68
    local COL    = 2

    for i, member in ipairs(memberList) do
        local col   = (i - 1) % COL
        local row   = math.floor((i - 1) / COL)
        local xOff  = 4 + col * (CARD_W + 4)
        local yOff  = -4 - row * (CARD_H + 4)

        local card = self:CreateMemberCard(scrollChild, member, CARD_W)
        card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", xOff, yOff)
        card:SetHeight(CARD_H)
        table.insert(memberCards, card)
    end

    local rows = math.ceil(#memberList / COL)
    scrollChild:SetHeight(rows * (CARD_H + 4) + 8)
end

-- ─── Mitglieder-Karte ─────────────────────────────────────────────────────────
function GuildKey.MemberStatusUI:CreateMemberCard(parent, member, width)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetWidth(width)
    card:SetBackdrop(GuildKey.Themes:GetCardBackdrop())

    local online   = member.isOnline
    local inDungeon = member.inMythicPlus

    -- Hintergrundfarbe nach Status
    if inDungeon then
        card:SetBackdropColor(0.05, 0.10, 0.16, 0.95)
        card:SetBackdropBorderColor(0.00, 0.60, 0.90, 0.8)
    elseif online then
        card:SetBackdropColor(0.06, 0.10, 0.08, 0.95)
        card:SetBackdropBorderColor(0.15, 0.55, 0.15, 0.6)
    else
        card:SetBackdropColor(0.08, 0.08, 0.10, 0.80)
        card:SetBackdropBorderColor(0.25, 0.20, 0.35, 0.5)
    end

    -- Status-Dot
    local statusKey = inDungeon and "dungeon" or (online and "online" or "offline")
    local dot = GuildKey.Widgets:CreateStatusDot(card, statusKey)
    dot:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -10)

    -- Name (klassenfarbe)
    local classCode = GuildKey.Utils:GetClassColor(member.class or "")
    local nameLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", dot, "RIGHT", 5, 0)
    nameLabel:SetPoint("RIGHT", card, "RIGHT", -8, 0)
    local shortName = (member.name or "?"):match("^([^-]+)") or member.name
    nameLabel:SetText(classCode .. shortName .. "|r")
    nameLabel:SetJustifyH("LEFT")

    -- Klasse / Spec
    local classLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -28)
    local classText = member.classDisplay or member.class or GuildKey.L["Unknown"]
    classLabel:SetText("|cff888888" .. classText .. "|r")

    -- Mythic Score
    local scoreLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scoreLabel:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -28)
    local score = member.score or 0
    local scoreColor = score >= 2500 and "|cffFF8000" or (score >= 2000 and "|cffA335EE" or (score >= 1500 and "|cff0070dd" or "|cff888888"))
    scoreLabel:SetText(scoreColor .. "M+ " .. tostring(score) .. "|r")

    -- Zone oder Dungeon-Info
    local infoLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoLabel:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 8)
    infoLabel:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    infoLabel:SetJustifyH("LEFT")

    if inDungeon then
        local remaining = GuildKey.MemberStatus:GetEstimatedTimeRemaining()
        local dungName = "Mythic+"
        if member.dungeonId then
            local dung = GuildKey.Constants:GetDungeonByChallengeID(member.dungeonId)
            if dung then dungName = dung.shortName end
        end
        local timeStr = remaining and GuildKey.Utils:FormatDuration(remaining) or "?"
        infoLabel:SetText("|cff00CCFFIm Dungeon: " .. dungName .. " ~" .. timeStr .. "|r")
    elseif member.zone and member.zone ~= "" then
        infoLabel:SetText("|cff888888" .. (member.zone or "") .. "|r")
    else
        local avail = member.availability or ""
        if avail ~= "" and avail ~= "Offline" then
            infoLabel:SetText("|cff888888" .. avail .. "|r")
        else
            infoLabel:SetText("|cff888888" .. GuildKey.L["Offline"] .. "|r")
        end
    end

    -- Keystone-Info
    if member.keystoneLevel and member.keystoneLevel > 0 then
        local ksColor = GuildKey.Constants:GetKeyColor(member.keystoneLevel)
        local ksDung = member.keystoneDungeonId and GuildKey.Constants:GetDungeonByChallengeID(member.keystoneDungeonId)
        local ksName = ksDung and ksDung.shortName or "?"
        local ksLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ksLabel:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -44)
        ksLabel:SetText(ksColor .. "🗝️ " .. ksName .. " +" .. member.keystoneLevel .. "|r")
    end

    return card
end
