GuildKey = GuildKey or {}
GuildKey.Discord = {}

-- DUMMY: Gibt formatierten Text zurück, der manuell in Discord eingefügt werden kann
function GuildKey.Discord:FormatRunPost(runData)
    if not runData then return "" end
    local C    = GuildKey.Constants
    local dungeon = C:GetDungeon(runData.dungeonId)
    local dungeonName = dungeon and dungeon.name or "Unbekannt"
    local level = runData.keyLevel or "?"

    local neededStr = ""
    if runData.neededRoles then
        if runData.neededRoles.tank    then neededStr = neededStr .. "[Tank]" end
        if runData.neededRoles.healer  then neededStr = neededStr .. "[Healer]" end
        local dpsCount = runData.neededRoles.dps or 0
        for i = 1, dpsCount do
            neededStr = neededStr .. "[DPS]"
        end
    end
    if neededStr == "" then neededStr = "Keine Rollen mehr frei" end

    local timeStr  = runData.plannedTime or "?"
    local durStr   = runData.estimatedDuration and (runData.estimatedDuration .. " Min.") or "?"
    local goalStr  = runData.goal or "In Time"
    local leaderStr = runData.leaderChar or runData.leader or "?"
    local notes    = runData.notes and (runData.notes ~= "") and ("\nNotizen: " .. runData.notes) or ""
    local runId    = runData.runId or "?"

    local text = string.format(
        "🗝️ **GuildKey Run** | %s +%s\n" ..
        "📅 %s | ~%s | Ziel: %s\n" ..
        "👥 Leader: %s\n" ..
        "Rollen gesucht: %s\n" ..
        "Anmelden: /addon GuildKey join %s%s",
        dungeonName, tostring(level),
        timeStr, durStr, goalStr,
        leaderStr,
        neededStr,
        runId,
        notes
    )
    return text
end

-- DUMMY: Zeigt dem User einen Hinweistext im Chat
function GuildKey.Discord:PostRun(runData)
    local formatted = self:FormatRunPost(runData)
    -- Kopierfenster anzeigen
    if GuildKey.Widgets and GuildKey.Widgets.ShowCopyDialog then
        GuildKey.Widgets:ShowCopyDialog("Discord Post", formatted)
    end
    GuildKey.Utils:Print(GuildKey.L["Discord not configured"])
end

-- DUMMY: Einstellungen speichern
function GuildKey.Discord:SetWebhookUrl(url)
    GuildKeyDB.settings.discordWebhookUrl = url
    GuildKey.Utils:Print("[Discord] Webhook-URL gespeichert (Dummy-Modus aktiv).")
end

function GuildKey.Discord:IsConfigured()
    return false  -- Immer false bis echte Implementierung
end

-- Comm-Handler: Status-Updates werden auch im Discord-Format vorbereitet
GuildKey.Comm:RegisterHandler(GuildKey.Constants.MSG.RUN_POST, function(data, sender)
    -- Neuen Run aus Netzwerk empfangen
    if data and data.runId then
        GuildKey.Data:AddRun(data)
        if GuildKey.RunBoardUI then
            GuildKey.RunBoardUI:Refresh()
        end
        if GuildKey.Data:GetSetting("showNotifications") then
            GuildKey.Utils:Print(GuildKey.L["New run posted"] .. ": " .. (data.dungeonName or "?") .. " +" .. (data.keyLevel or "?"))
        end
    end
end)

GuildKey.Comm:RegisterHandler(GuildKey.Constants.MSG.RUN_CANCEL, function(data, sender)
    if data and data.runId then
        GuildKey.Data:RemoveRun(data.runId)
        if GuildKey.RunBoardUI then
            GuildKey.RunBoardUI:Refresh()
        end
    end
end)

GuildKey.Comm:RegisterHandler(GuildKey.Constants.MSG.RUN_UPDATE, function(data, sender)
    if data and data.runId then
        GuildKey.Data:UpdateRun(data.runId, data)
        if GuildKey.RunBoardUI then
            GuildKey.RunBoardUI:Refresh()
        end
    end
end)
