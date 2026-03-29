GuildKey = GuildKey or {}
GuildKey.MyKey = {}

local MSG = GuildKey.Constants.MSG

-- Eigenen Keystone auslesen
function GuildKey.MyKey:ReadOwnKeystone()
    local dungeonId = nil
    local level     = nil

    -- Moderne API (TWW+)
    if C_MythicPlus then
        if C_MythicPlus.GetOwnedKeystoneChallengeModeID then
            dungeonId = C_MythicPlus.GetOwnedKeystoneChallengeModeID()
        end
        if C_MythicPlus.GetOwnedKeystoneLevel then
            level = C_MythicPlus.GetOwnedKeystoneLevel()
        end
    end

    -- Fallback: Challenge-Mode API
    if (not dungeonId or not level) and C_ChallengeMode then
        if C_ChallengeMode.GetOwnedKeystoneInfo then
            local ksLevel, cmID = C_ChallengeMode.GetOwnedKeystoneInfo()
            if cmID  and cmID  > 0 then dungeonId = cmID  end
            if ksLevel and ksLevel > 0 then level = ksLevel end
        end
    end

    -- In CharDB speichern
    GuildKey.Data:SetMyKey(dungeonId, level)

    GuildKey.Utils:Debug(string.format("Own keystone: dungeonId=%s level=%s",
        tostring(dungeonId), tostring(level)))

    -- UI aktualisieren
    if GuildKey.MyKeyUI then
        GuildKey.MyKeyUI:Refresh()
    end

    return dungeonId, level
end

-- Keystone an Gilde broadcasten
function GuildKey.MyKey:BroadcastKey()
    local key = GuildKeyCharDB.currentKey
    if not key then return end

    GuildKey.Comm:Send(MSG.KEY_UPDATE, {
        sender    = GuildKey.Utils:GetCharName(),
        dungeonId = key.dungeonId,
        level     = key.level,
    })
    GuildKey.Utils:Print(GuildKey.L["Key broadcasted"])
end

-- Eigenen Mythic-Score lesen
function GuildKey.MyKey:GetOwnScore()
    local score = 0
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local info = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if info then
            score = info.currentSeasonScore or 0
        end
    end
    return score
end

-- Verfügbarkeit setzen (delegiert an MemberStatus)
function GuildKey.MyKey:SetAvailability(avail)
    if GuildKey.MemberStatus then
        GuildKey.MemberStatus:SetAvailability(avail)
    else
        GuildKey.Data:SetAvailability(avail)
    end
end

-- Bevorzugte Rollen setzen
function GuildKey.MyKey:SetPreferredRoles(roles)
    GuildKey.Data:SetPreferredRoles(roles)
    GuildKeyCharDB.preferredRoles = roles
end

-- Dungeon-Name für den eigenen Key
function GuildKey.MyKey:GetKeystoneDungeonName()
    local key = GuildKeyCharDB.currentKey
    if not key or not key.dungeonId then
        return GuildKey.L["No keystone"]
    end
    local dungeon = GuildKey.Constants:GetDungeonByChallengeID(key.dungeonId)
    if dungeon then
        return dungeon.name
    end
    return GuildKey.L["Unknown"] .. " (" .. tostring(key.dungeonId) .. ")"
end

-- Comm-Handler: Key-Update von anderen Mitgliedern
GuildKey.Comm:RegisterHandler(MSG.KEY_UPDATE, function(data, sender)
    if not data or not data.sender then return end
    GuildKey.Data:UpdateMember(data.sender, {
        keystoneDungeonId = data.dungeonId,
        keystoneLevel     = data.level,
    })
    if GuildKey.MemberStatusUI then
        GuildKey.MemberStatusUI:Refresh()
    end
end)
