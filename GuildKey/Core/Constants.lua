GuildKey = GuildKey or {}
GuildKey.Constants = {

    VERSION      = "0.1.0",
    ADDON_PREFIX = "GuildKey",
    CHANNEL      = "GUILD",

    -- Mythic+ Season 1 The War Within Dungeons
    DUNGEONS = {
        { id = 1, name = "Darkflame Cleft",            shortName = "DFC",  timer = 1800 },
        { id = 2, name = "Priory of the Sacred Flame", shortName = "PSF",  timer = 2100 },
        { id = 3, name = "Cinderbrew Meadery",          shortName = "CBM",  timer = 1800 },
        { id = 4, name = "Lair of the Forsaken",        shortName = "LotF", timer = 2100 },
        { id = 5, name = "Operation: Floodgate",        shortName = "OGF",  timer = 1800 },
        { id = 6, name = "The Rookery",                 shortName = "TR",   timer = 1800 },
        { id = 7, name = "The Stonevault",              shortName = "SV",   timer = 1800 },
        { id = 8, name = "City of Threads",             shortName = "CoT",  timer = 1800 },
    },

    -- Rollen
    ROLES = { TANK = "TANK", HEALER = "HEALER", DPS = "DPS" },

    -- Run-Ziele
    GOALS = {
        INTIME   = "In Time",
        PUSH     = "Score pushen",
        FARM     = "Entspannt farmen",
        UPGRADE  = "Stein upgraden",
    },

    -- Verfügbarkeits-Status
    AVAILABILITY = {
        NOW        = "Jetzt verfügbar",
        EVENING    = "Heute Abend",
        TOMORROW   = "Morgen",
        WEEKEND    = "Wochenende",
        ON_REQUEST = "Auf Anfrage",
        BUSY       = "Beschäftigt",
        OFFLINE    = "Offline",
    },

    -- Nachrichtentypen für Addon-Comm
    MSG = {
        RUN_POST      = "RUN_POST",
        RUN_UPDATE    = "RUN_UPDATE",
        RUN_CANCEL    = "RUN_CANCEL",
        RUN_JOIN      = "RUN_JOIN",
        RUN_LEAVE     = "RUN_LEAVE",
        STATUS_UPDATE = "STATUS_UPDATE",
        KEY_UPDATE    = "KEY_UPDATE",
        STATS_SYNC    = "STATS_SYNC",
        PING          = "PING",
        PONG          = "PONG",
    },

    -- UI-Farben (RGBA 0-1)
    COLORS = {
        GOLD    = { r = 0.78, g = 0.66, b = 0.29, a = 1 },
        TANK    = { r = 0.00, g = 0.44, b = 0.87, a = 1 },
        HEALER  = { r = 0.12, g = 1.00, b = 0.00, a = 1 },
        DPS     = { r = 1.00, g = 0.12, b = 0.12, a = 1 },
        EPIC    = { r = 0.64, g = 0.21, b = 0.93, a = 1 },
        ORANGE  = { r = 1.00, g = 0.50, b = 0.00, a = 1 },
        MUTED   = { r = 0.53, g = 0.53, b = 0.53, a = 1 },
        BG_DARK = { r = 0.05, g = 0.06, b = 0.10, a = 0.95 },
        WHITE   = { r = 1.00, g = 1.00, b = 1.00, a = 1 },
        GREEN   = { r = 0.00, g = 1.00, b = 0.00, a = 1 },
        RED     = { r = 1.00, g = 0.10, b = 0.10, a = 1 },
    },

    -- Key-Farben nach Schwierigkeit
    KEY_COLORS = {
        [1]  = "|cffffffff",  -- Weiß 1-9
        [10] = "|cff1eff00",  -- Grün 10-14
        [15] = "|cff0070dd",  -- Blau 15-19
        [20] = "|cffA335EE",  -- Lila 20+
    },

    -- Maximale gespeicherte Runs
    MAX_RUNS = 50,
    -- Run-Ablaufzeit in Sekunden (8 Stunden)
    RUN_EXPIRY = 28800,
}

-- Hilfsfunktion: Dungeon per ID finden
function GuildKey.Constants:GetDungeon(id)
    for _, d in ipairs(self.DUNGEONS) do
        if d.id == id then return d end
    end
    return nil
end

-- Hilfsfunktion: Dungeon per challengeModeID finden
function GuildKey.Constants:GetDungeonByChallengeID(cmID)
    -- Mapping von C_ChallengeMode IDs zu internen IDs
    -- Diese IDs können sich mit Patches ändern; hier als Referenz TWW S1
    local cmMap = {
        [500] = 1, -- Darkflame Cleft
        [501] = 2, -- Priory of the Sacred Flame
        [502] = 3, -- Cinderbrew Meadery
        [503] = 4, -- Lair of the Forsaken
        [504] = 5, -- Operation: Floodgate
        [505] = 6, -- The Rookery
        [506] = 7, -- The Stonevault
        [507] = 8, -- City of Threads
    }
    local internalId = cmMap[cmID]
    if internalId then
        return self:GetDungeon(internalId)
    end
    return nil
end

-- Hilfsfunktion: Farbe für Key-Stufe
function GuildKey.Constants:GetKeyColor(level)
    if level >= 20 then return self.KEY_COLORS[20]
    elseif level >= 15 then return self.KEY_COLORS[15]
    elseif level >= 10 then return self.KEY_COLORS[10]
    else return self.KEY_COLORS[1]
    end
end
