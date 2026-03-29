GuildKey = GuildKey or {}
GuildKey.RunBoard = {}

local MSG = GuildKey.Constants.MSG

-- Run posten
function GuildKey.RunBoard:PostRun(runData)
    if not runData then return false end

    -- Pflichtfelder setzen
    runData.leader     = GuildKey.Utils:GetCharName()
    runData.leaderChar = GuildKey.Utils:GetPlayerName()

    -- Dungeon-Namen aus ID auflösen
    local dungeon = GuildKey.Constants:GetDungeon(runData.dungeonId)
    if dungeon then
        runData.dungeonName = dungeon.name
        runData.dungeonShort = dungeon.shortName
    end

    -- Run lokal speichern
    local runId = GuildKey.Data:AddRun(runData)
    if not runId then
        GuildKey.Utils:Print("Fehler: Run konnte nicht gespeichert werden.")
        return false
    end

    -- An Gilde broadcasten
    GuildKey.Comm:Send(MSG.RUN_POST, GuildKey.Data:GetRun(runId))

    GuildKey.Utils:Print(GuildKey.L["Run posted"])

    -- UI aktualisieren
    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:Refresh()
    end

    return runId
end

-- Run absagen
function GuildKey.RunBoard:CancelRun(runId)
    if not runId then
        -- Eigenen aktiven Run finden
        local myName = GuildKey.Utils:GetCharName()
        for _, run in pairs(GuildKey.Data:GetActiveRuns()) do
            if run.leader == myName then
                runId = run.runId
                break
            end
        end
    end

    if not runId then
        GuildKey.Utils:Print(GuildKey.L["Run not found"])
        return false
    end

    local run = GuildKey.Data:GetRun(runId)
    if not run then
        GuildKey.Utils:Print(GuildKey.L["Run not found"])
        return false
    end

    -- Nur der Leader darf absagen
    if run.leader ~= GuildKey.Utils:GetCharName() then
        GuildKey.Utils:Print(GuildKey.L["You are the leader"] .. " – nur der Leader kann den Run absagen.")
        return false
    end

    GuildKey.Data:RemoveRun(runId)
    GuildKey.Comm:Send(MSG.RUN_CANCEL, { runId = runId })
    GuildKey.Utils:Print(GuildKey.L["Run cancelled"])

    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:Refresh()
    end
    return true
end

-- Run beitreten
function GuildKey.RunBoard:JoinRun(runId, role)
    if not runId then
        GuildKey.Utils:Print(GuildKey.L["Run not found"])
        return false
    end

    role = role or GuildKeyCharDB.preferredRoles[1] or GuildKey.Constants.ROLES.DPS
    local charName = GuildKey.Utils:GetCharName()

    local ok, reason = GuildKey.Data:JoinRun(runId, charName, role)
    if not ok then
        if reason == "run_not_found" then
            GuildKey.Utils:Print(GuildKey.L["Run not found"])
        elseif reason == "already_joined" then
            GuildKey.Utils:Print(GuildKey.L["Already joined"])
        else
            GuildKey.Utils:Print(GuildKey.L["Error"] .. ": " .. tostring(reason))
        end
        return false
    end

    -- An Gilde broadcasten
    GuildKey.Comm:Send(MSG.RUN_JOIN, {
        runId    = runId,
        charName = charName,
        role     = role,
    })

    GuildKey.Utils:Print(GuildKey.L["Joined run"])

    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:Refresh()
    end
    return true
end

-- Run verlassen
function GuildKey.RunBoard:LeaveRun(runId)
    local charName = GuildKey.Utils:GetCharName()

    if not runId then
        -- Aktiven Run des Spielers finden
        for _, run in pairs(GuildKey.Data:GetActiveRuns()) do
            if run.members then
                for _, m in ipairs(run.members) do
                    if m.name == charName then
                        runId = run.runId
                        break
                    end
                end
            end
            if runId then break end
        end
    end

    if not runId then
        GuildKey.Utils:Print(GuildKey.L["Not in run"])
        return false
    end

    local ok = GuildKey.Data:LeaveRun(runId, charName)
    if not ok then
        GuildKey.Utils:Print(GuildKey.L["Not in run"])
        return false
    end

    GuildKey.Comm:Send(MSG.RUN_LEAVE, {
        runId    = runId,
        charName = charName,
    })

    GuildKey.Utils:Print(GuildKey.L["Left run"])

    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:Refresh()
    end
    return true
end

-- Gefilterte Runs abrufen
function GuildKey.RunBoard:GetFilteredRuns(filter)
    local runs = GuildKey.Data:GetActiveRuns()
    if not filter then return runs end

    local filtered = {}
    for _, run in ipairs(runs) do
        local include = true

        -- Rollen-Filter
        if filter.role then
            local hasRole = false
            if filter.role == "TANK"   and run.neededRoles and run.neededRoles.tank   then hasRole = true end
            if filter.role == "HEALER" and run.neededRoles and run.neededRoles.healer then hasRole = true end
            if filter.role == "DPS"    and run.neededRoles and (run.neededRoles.dps or 0) > 0 then hasRole = true end
            if not hasRole then include = false end
        end

        -- Key-Level-Filter
        if filter.minKey and (run.keyLevel or 0) < filter.minKey then
            include = false
        end
        if filter.maxKey and (run.keyLevel or 0) > filter.maxKey then
            include = false
        end

        if include then
            table.insert(filtered, run)
        end
    end
    return filtered
end

-- Comm-Handler für RUN_JOIN und RUN_LEAVE
GuildKey.Comm:RegisterHandler(MSG.RUN_JOIN, function(data, sender)
    if not data or not data.runId then return end
    -- Prüfen ob wir der Leader sind
    local run = GuildKey.Data:GetRun(data.runId)
    if run and run.leader == GuildKey.Utils:GetCharName() then
        GuildKey.Utils:Print("|cff00ff00" .. (data.charName or sender) .. "|r " .. GuildKey.L["Player joined your run"])
        if GuildKey.Data:GetSetting("soundOnInvite") then
            PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081)
        end
    end
    -- Lokal eintragen
    GuildKey.Data:JoinRun(data.runId, data.charName, data.role)
    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:Refresh()
    end
end)

GuildKey.Comm:RegisterHandler(MSG.RUN_LEAVE, function(data, sender)
    if not data or not data.runId then return end
    local run = GuildKey.Data:GetRun(data.runId)
    if run and run.leader == GuildKey.Utils:GetCharName() then
        GuildKey.Utils:Print("|cffff4040" .. (data.charName or sender) .. "|r " .. GuildKey.L["Player left your run"])
    end
    GuildKey.Data:LeaveRun(data.runId, data.charName)
    if GuildKey.RunBoardUI then
        GuildKey.RunBoardUI:Refresh()
    end
end)
