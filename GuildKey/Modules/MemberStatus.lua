GuildKey = GuildKey or {}
GuildKey.MemberStatus = {}

local MSG = GuildKey.Constants.MSG

-- Instanz-Timer
local instanceStartTime = nil
local currentDungeonId  = nil

-- Gildenliste einlesen und in Data speichern
function GuildKey.MemberStatus:RefreshGuildRoster()
    if not GuildKey.Utils:IsInGuild() then return end

    local numTotal = GetNumGuildMembers()
    for i = 1, numTotal do
        local name, rankName, rankIndex, level, classDisplayName,
              zone, note, officerNote, isOnline, status, class,
              achievementPoints, achievementRank, isMobile,
              canSoR, repStanding, GUID = GetGuildRosterInfo(i)

        if name then
            -- Name normalisieren (WoW gibt "Name-Server" zurück)
            local shortName = name:match("^([^-]+)") or name

            -- Mythic+ Score (falls API vorhanden)
            local score = 0
            if GUID and C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
                local ratingInfo = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(shortName)
                if ratingInfo then
                    score = ratingInfo.currentSeasonScore or 0
                end
            end

            GuildKey.Data:UpdateMember(name, {
                name          = name,
                shortName     = shortName,
                rank          = rankName,
                rankIndex     = rankIndex,
                level         = level,
                class         = class,
                classDisplay  = classDisplayName,
                zone          = zone,
                isOnline      = isOnline,
                isMobile      = isMobile,
                score         = score,
                guildNote     = note,
            })
        end
    end

    -- UI aktualisieren
    if GuildKey.MemberStatusUI then
        GuildKey.MemberStatusUI:Refresh()
    end
end

-- Eigenen Status broadcasten
function GuildKey.MemberStatus:BroadcastStatus()
    if not GuildKey.Utils:IsInGuild() then return end

    local inInstance, instanceType = IsInInstance()
    local dungeonId  = nil
    local keyLevel   = nil
    local inMythicPlus = false

    if inInstance and instanceType == "party" then
        -- Mythic+ prüfen
        if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
            keyLevel, dungeonId = C_ChallengeMode.GetActiveKeystoneInfo()
            if keyLevel and keyLevel > 0 then
                inMythicPlus = true
            end
        elseif GetMythicPlusActiveChallengeModeID then
            local cmID = GetMythicPlusActiveChallengeModeID()
            if cmID and cmID > 0 then
                inMythicPlus = true
                dungeonId = cmID
            end
        end
    end

    local avail = GuildKeyCharDB.availability or GuildKey.Constants.AVAILABILITY.NOW

    GuildKey.Comm:Send(MSG.STATUS_UPDATE, {
        sender        = GuildKey.Utils:GetCharName(),
        class         = GuildKey.Utils:GetPlayerClass(),
        availability  = avail,
        online        = true,
        inMythicPlus  = inMythicPlus,
        dungeonId     = dungeonId,
        keyLevel      = keyLevel,
        zone          = GetZoneText and GetZoneText() or "",
    })
end

-- Instanz-Status prüfen (bei Zonen-Wechsel)
function GuildKey.MemberStatus:CheckInstanceStatus()
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType == "party" then
        -- In Party-Instanz (evtl. Mythic+)
        if not instanceStartTime then
            instanceStartTime = GetTime()
        end
    else
        instanceStartTime = nil
        currentDungeonId  = nil
    end
    self:BroadcastStatus()
end

-- Challenge Start
function GuildKey.MemberStatus:OnChallengeStart()
    instanceStartTime = GetTime()
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local level, cmID = C_ChallengeMode.GetActiveKeystoneInfo()
        currentDungeonId = cmID
    end
    self:BroadcastStatus()
end

-- Challenge Ende (abgeschlossen oder abgebrochen)
function GuildKey.MemberStatus:OnChallengeEnd()
    instanceStartTime = nil
    currentDungeonId  = nil
    -- Keystone neu einlesen
    if GuildKey.MyKey then
        GuildKey.MyKey:ReadOwnKeystone()
    end
    self:BroadcastStatus()
end

-- Verfügbarkeit setzen
function GuildKey.MemberStatus:SetAvailability(avail)
    GuildKey.Data:SetAvailability(avail)
    GuildKeyCharDB.availability = avail
    self:BroadcastStatus()
    GuildKey.Utils:Print("Verfügbarkeit gesetzt: " .. avail)
end

-- Verbleibende Dungeon-Zeit schätzen
function GuildKey.MemberStatus:GetEstimatedTimeRemaining()
    if not instanceStartTime then return nil end
    local elapsed  = GetTime() - instanceStartTime
    local dungeonTimer = 1800 -- Default 30 Min.
    if currentDungeonId then
        local dungeon = GuildKey.Constants:GetDungeonByChallengeID(currentDungeonId)
        if dungeon then dungeonTimer = dungeon.timer end
    end
    return math.max(0, dungeonTimer - elapsed)
end

-- Comm-Handler: Status-Update von anderen Mitgliedern
GuildKey.Comm:RegisterHandler(MSG.STATUS_UPDATE, function(data, sender)
    if not data or not data.sender then return end
    GuildKey.Data:UpdateMember(data.sender, {
        name         = data.sender,
        class        = data.class,
        availability = data.availability,
        online       = data.online,
        inMythicPlus = data.inMythicPlus,
        dungeonId    = data.dungeonId,
        keyLevel     = data.keyLevel,
        zone         = data.zone,
    })
    if GuildKey.MemberStatusUI then
        GuildKey.MemberStatusUI:Refresh()
    end
end)
