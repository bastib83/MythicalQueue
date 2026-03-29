GuildKey = GuildKey or {}
GuildKey.Stats = {}

local MSG = GuildKey.Constants.MSG

-- Interner Run-Timer
local runStartTime  = nil
local runDungeonID  = nil
local runKeyLevel   = nil

-- Run gestartet
function GuildKey.Stats:OnRunStarted()
    runStartTime = GetTime()
    -- Challenge-Mode Info lesen
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        runKeyLevel, runDungeonID = C_ChallengeMode.GetActiveKeystoneInfo()
    end
    GuildKey.Utils:Debug(string.format("Run started: dungeon=%s level=%s",
        tostring(runDungeonID), tostring(runKeyLevel)))
end

-- Run abgebrochen
function GuildKey.Stats:OnRunReset()
    runStartTime = nil
    runDungeonID = nil
    runKeyLevel  = nil
end

-- Run abgeschlossen
function GuildKey.Stats:OnRunCompleted()
    local durationSecs = runStartTime and (GetTime() - runStartTime) or 0
    local dungeonID    = runDungeonID
    local keyLevel     = runKeyLevel

    -- Challenge-Mode-Ergebnis lesen
    local onTime    = false
    local rating    = 0

    if C_ChallengeMode then
        -- GetCompletionInfo liefert Ergebnis nach dem Run
        if C_ChallengeMode.GetCompletionInfo then
            local info = C_ChallengeMode.GetCompletionInfo()
            if info then
                onTime   = info.onTime or false
                rating   = info.practitionerScore or 0
                dungeonID  = info.dungeonID or dungeonID
                keyLevel   = info.level or keyLevel
                durationSecs = info.time and (info.time / 1000) or durationSecs
            end
        end
    end

    -- Fallback: Dungeon-Timer vergleichen
    if not C_ChallengeMode or not C_ChallengeMode.GetCompletionInfo then
        local dungeon = dungeonID and GuildKey.Constants:GetDungeonByChallengeID(dungeonID)
        if dungeon and durationSecs > 0 then
            onTime = durationSecs <= dungeon.timer
        end
    end

    local info = {
        onTime       = onTime,
        durationSecs = math.floor(durationSecs),
        keystoneLevel = keyLevel or 0,
        dungeonID    = dungeonID,
        rating       = rating,
    }

    GuildKey.Data:RecordRun(info)
    GuildKey.Utils:Debug(string.format(
        "Run completed: level=%s onTime=%s duration=%ss",
        tostring(keyLevel), tostring(onTime), tostring(math.floor(durationSecs))
    ))

    -- Eigenen Key neu einlesen (verändert sich nach Run)
    C_Timer.After(2, function()
        if GuildKey.MyKey then
            GuildKey.MyKey:ReadOwnKeystone()
        end
    end)

    -- Stats-UI aktualisieren
    if GuildKey.StatsUI then
        GuildKey.StatsUI:Refresh()
    end

    -- Stats an Gilde broadcasten
    self:BroadcastStats()

    -- Timer zurücksetzen
    runStartTime = nil
    runDungeonID = nil
    runKeyLevel  = nil
end

-- Wöchentlichen Reset prüfen
function GuildKey.Stats:CheckWeeklyReset()
    local weekNum = GuildKey.Utils:GetWeekNumber()
    if GuildKeyDB.stats.weekNumber ~= weekNum then
        GuildKeyDB.stats.weekNumber   = weekNum
        GuildKeyDB.stats.weeklyRuns   = 0
        GuildKeyDB.stats.weeklyInTime = 0
        GuildKey.Utils:Debug("Weekly stats reset.")
    end
end

-- In-Time-Rate berechnen
function GuildKey.Stats:GetInTimeRate()
    local stats = GuildKeyDB.stats
    if not stats or (stats.totalRuns or 0) == 0 then return 0 end
    return math.floor(((stats.inTimeCount or 0) / stats.totalRuns) * 100)
end

-- Wöchentliche In-Time-Rate
function GuildKey.Stats:GetWeeklyInTimeRate()
    local stats = GuildKeyDB.stats
    if not stats or (stats.weeklyRuns or 0) == 0 then return 0 end
    return math.floor(((stats.weeklyInTime or 0) / stats.weeklyRuns) * 100)
end

-- Zeit bis zum wöchentlichen Reset
function GuildKey.Stats:GetTimeUntilWeeklyReset()
    -- WoW-Reset ist Mittwoch 09:00 EU
    local d = date("*t")
    local dayOfWeek = d.wday  -- 1=Sonntag, 4=Mittwoch
    local daysUntil = (4 - dayOfWeek + 7) % 7
    if daysUntil == 0 and (d.hour > 9 or (d.hour == 9 and d.min >= 0)) then
        daysUntil = 7
    end
    local hoursUntilToday = 9 - d.hour
    local totalSeconds = daysUntil * 86400 + hoursUntilToday * 3600 - d.min * 60 - d.sec
    return math.max(0, totalSeconds)
end

-- Stats-Sync an Gilde senden
function GuildKey.Stats:BroadcastStats()
    if not GuildKey.Utils:IsInGuild() then return end
    local stats = GuildKeyDB.stats
    GuildKey.Comm:Send(MSG.STATS_SYNC, {
        sender       = GuildKey.Utils:GetCharName(),
        totalRuns    = stats.totalRuns,
        inTimeCount  = stats.inTimeCount,
        highestKey   = stats.highestKey,
        weeklyRuns   = stats.weeklyRuns,
        weeklyInTime = stats.weeklyInTime,
    })
end

-- Comm-Handler: Stats-Sync von anderen Mitgliedern
GuildKey.Comm:RegisterHandler(MSG.STATS_SYNC, function(data, sender)
    if not data or not data.sender then return end
    -- Mitglieder-Stats merken für spätere Anzeige
    GuildKey.Data:UpdateMember(data.sender, {
        statsTotalRuns   = data.totalRuns,
        statsInTimeCount = data.inTimeCount,
        statsHighestKey  = data.highestKey,
        statsWeeklyRuns  = data.weeklyRuns,
    })
end)
