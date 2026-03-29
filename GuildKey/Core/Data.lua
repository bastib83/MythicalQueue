GuildKey = GuildKey or {}
GuildKey.Data = {}

-- Standard-Werte für GuildKeyDB
local DB_DEFAULTS = {
    runs    = {},
    members = {},
    stats   = {
        totalRuns    = 0,
        inTimeCount  = 0,
        highestKey   = 0,
        topRuns      = {},
        weekNumber   = 0,
        weeklyRuns   = 0,
        weeklyInTime = 0,
    },
    settings = {
        showNotifications  = true,
        autoPostToDiscord  = false,
        discordWebhookUrl  = "",
        minimapButton      = true,
        soundOnInvite      = true,
    },
    version = "0.1.0",
}

-- Standard-Werte für GuildKeyCharDB
local CHAR_DEFAULTS = {
    myChars        = {},
    availability   = "Offline",
    preferredRoles = {},
    currentKey     = {
        dungeonId   = nil,
        level       = nil,
        lastUpdated = nil,
    },
}

-- Initialisierung beim Login
function GuildKey.Data:Init()
    -- GuildKeyDB initialisieren
    if not GuildKeyDB then
        GuildKeyDB = {}
    end
    -- Fehlende Felder mit Defaults füllen
    for k, v in pairs(DB_DEFAULTS) do
        if GuildKeyDB[k] == nil then
            if type(v) == "table" then
                GuildKeyDB[k] = GuildKey.Utils:ShallowCopy(v)
            else
                GuildKeyDB[k] = v
            end
        end
    end
    -- Stats-Unterfelder prüfen
    for k, v in pairs(DB_DEFAULTS.stats) do
        if GuildKeyDB.stats[k] == nil then
            GuildKeyDB.stats[k] = v
        end
    end
    for k, v in pairs(DB_DEFAULTS.settings) do
        if GuildKeyDB.settings[k] == nil then
            GuildKeyDB.settings[k] = v
        end
    end

    -- GuildKeyCharDB initialisieren
    if not GuildKeyCharDB then
        GuildKeyCharDB = {}
    end
    for k, v in pairs(CHAR_DEFAULTS) do
        if GuildKeyCharDB[k] == nil then
            if type(v) == "table" then
                GuildKeyCharDB[k] = GuildKey.Utils:ShallowCopy(v)
            else
                GuildKeyCharDB[k] = v
            end
        end
    end
    if not GuildKeyCharDB.currentKey then
        GuildKeyCharDB.currentKey = GuildKey.Utils:ShallowCopy(CHAR_DEFAULTS.currentKey)
    end

    -- Abgelaufene Runs beim Start bereinigen
    self:PruneExpiredRuns()
    GuildKey.Utils:Debug("Data initialized.")
end

-- Run-ID generieren
local function GenerateRunId()
    local name = GuildKey.Utils:GetPlayerName()
    local ts   = GuildKey.Utils:GetTimestamp()
    return name .. "_" .. ts
end

-- Run hinzufügen
function GuildKey.Data:AddRun(runData)
    if not runData then return nil end
    if #GuildKeyDB.runs >= GuildKey.Constants.MAX_RUNS then
        self:PruneExpiredRuns()
    end
    local runId = GenerateRunId()
    runData.runId     = runId
    runData.createdAt = GuildKey.Utils:GetTimestamp()
    runData.members   = runData.members or {}
    GuildKeyDB.runs[runId] = runData
    return runId
end

-- Run aktualisieren
function GuildKey.Data:UpdateRun(runId, changes)
    if not runId or not GuildKeyDB.runs[runId] then return false end
    local run = GuildKeyDB.runs[runId]
    for k, v in pairs(changes) do
        run[k] = v
    end
    return true
end

-- Run löschen
function GuildKey.Data:RemoveRun(runId)
    if not runId then return false end
    GuildKeyDB.runs[runId] = nil
    return true
end

-- Einzelnen Run abrufen
function GuildKey.Data:GetRun(runId)
    if not runId then return nil end
    return GuildKeyDB.runs[runId]
end

-- Alle aktiven (nicht abgelaufenen) Runs
function GuildKey.Data:GetActiveRuns()
    local now    = GuildKey.Utils:GetTimestamp()
    local expiry = GuildKey.Constants.RUN_EXPIRY
    local active = {}
    for runId, run in pairs(GuildKeyDB.runs) do
        if run.createdAt and (now - run.createdAt) < expiry then
            table.insert(active, run)
        end
    end
    -- Sortieren: neueste zuerst
    table.sort(active, function(a, b)
        return (a.createdAt or 0) > (b.createdAt or 0)
    end)
    return active
end

-- Spieler zu Run hinzufügen
function GuildKey.Data:JoinRun(runId, charName, role)
    local run = self:GetRun(runId)
    if not run then return false, "run_not_found" end
    if not run.members then run.members = {} end
    -- Bereits beigetreten?
    for _, m in ipairs(run.members) do
        if m.name == charName then
            return false, "already_joined"
        end
    end
    table.insert(run.members, { name = charName, role = role, joinedAt = GuildKey.Utils:GetTimestamp() })
    return true
end

-- Spieler aus Run entfernen
function GuildKey.Data:LeaveRun(runId, charName)
    local run = self:GetRun(runId)
    if not run or not run.members then return false end
    for i, m in ipairs(run.members) do
        if m.name == charName then
            table.remove(run.members, i)
            return true
        end
    end
    return false
end

-- Mitglied-Status aktualisieren
function GuildKey.Data:UpdateMember(name, memberData)
    if not name then return end
    if not GuildKeyDB.members[name] then
        GuildKeyDB.members[name] = {}
    end
    local member = GuildKeyDB.members[name]
    for k, v in pairs(memberData) do
        member[k] = v
    end
    member.lastSeen = GuildKey.Utils:GetTimestamp()
end

-- Alle bekannten Mitglieder
function GuildKey.Data:GetMembers()
    return GuildKeyDB.members
end

-- Abgelaufene Runs bereinigen
function GuildKey.Data:PruneExpiredRuns()
    local now    = GuildKey.Utils:GetTimestamp()
    local expiry = GuildKey.Constants.RUN_EXPIRY
    local removed = 0
    for runId, run in pairs(GuildKeyDB.runs) do
        if not run.createdAt or (now - run.createdAt) >= expiry then
            GuildKeyDB.runs[runId] = nil
            removed = removed + 1
        end
    end
    if removed > 0 then
        GuildKey.Utils:Debug("Pruned " .. removed .. " expired run(s).")
    end
end

-- Einstellung abrufen
function GuildKey.Data:GetSetting(key)
    return GuildKeyDB.settings[key]
end

-- Einstellung setzen
function GuildKey.Data:SetSetting(key, value)
    GuildKeyDB.settings[key] = value
end

-- Char-DB: Keystone aktualisieren
function GuildKey.Data:SetMyKey(dungeonId, level)
    GuildKeyCharDB.currentKey = {
        dungeonId   = dungeonId,
        level       = level,
        lastUpdated = GuildKey.Utils:GetTimestamp(),
    }
end

-- Char-DB: Verfügbarkeit setzen
function GuildKey.Data:SetAvailability(avail)
    GuildKeyCharDB.availability = avail
end

-- Char-DB: Bevorzugte Rollen setzen
function GuildKey.Data:SetPreferredRoles(roles)
    GuildKeyCharDB.preferredRoles = roles
end

-- Stats: Run abgeschlossen
function GuildKey.Data:RecordRun(info)
    local stats = GuildKeyDB.stats
    stats.totalRuns = (stats.totalRuns or 0) + 1
    if info.onTime then
        stats.inTimeCount = (stats.inTimeCount or 0) + 1
    end
    if info.keystoneLevel and info.keystoneLevel > (stats.highestKey or 0) then
        stats.highestKey = info.keystoneLevel
    end
    -- Wöchentliche Stats
    local weekNum = GuildKey.Utils:GetWeekNumber()
    if stats.weekNumber ~= weekNum then
        stats.weekNumber   = weekNum
        stats.weeklyRuns   = 0
        stats.weeklyInTime = 0
    end
    stats.weeklyRuns = (stats.weeklyRuns or 0) + 1
    if info.onTime then
        stats.weeklyInTime = (stats.weeklyInTime or 0) + 1
    end
    -- Top 10 Runs
    if not stats.topRuns then stats.topRuns = {} end
    table.insert(stats.topRuns, {
        dungeonId      = info.dungeonID,
        keystoneLevel  = info.keystoneLevel,
        durationSecs   = info.durationSecs,
        onTime         = info.onTime,
        rating         = info.rating or 0,
        timestamp      = GuildKey.Utils:GetTimestamp(),
    })
    table.sort(stats.topRuns, function(a, b)
        return (a.rating or 0) > (b.rating or 0)
    end)
    if #stats.topRuns > 10 then
        for i = 11, #stats.topRuns do
            stats.topRuns[i] = nil
        end
    end
end
