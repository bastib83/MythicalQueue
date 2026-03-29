GuildKey = GuildKey or {}
GuildKey.Utils = {}

local L = function(k) return GuildKey.L and GuildKey.L[k] or k end

-- Chat-Ausgabe mit GuildKey-Prefix
function GuildKey.Utils:Print(msg)
    print("|cffA335EE[GuildKey]|r " .. tostring(msg))
end

-- Debug-Ausgabe (nur wenn GuildKey.DEBUG == true)
function GuildKey.Utils:Debug(msg)
    if GuildKey.DEBUG then
        print("|cff888888[GuildKey Debug]|r " .. tostring(msg))
    end
end

-- Aktuellen Charakter-Namen mit Server zurückgeben
function GuildKey.Utils:GetCharName()
    local name, realm = UnitName("player")
    if not name then return "Unknown" end
    realm = realm or GetRealmName() or ""
    if realm == "" then
        return name
    end
    return name .. "-" .. realm
end

-- Nur den Charakternamen (ohne Server)
function GuildKey.Utils:GetPlayerName()
    return UnitName("player") or "Unknown"
end

-- Aktuelle Serverzeit als String (HH:MM)
function GuildKey.Utils:GetTimeString(timestamp)
    if timestamp then
        local h = math.floor(timestamp / 3600) % 24
        local m = math.floor(timestamp / 60) % 60
        return string.format("%02d:%02d", h, m)
    end
    local h, m = GetGameTime()
    return string.format("%02d:%02d", h, m)
end

-- Unix-ähnlichen Timestamp (GetTime() ist relativ, nutze date())
function GuildKey.Utils:GetTimestamp()
    return time()
end

-- Dauer in lesbares Format umwandeln (Sekunden -> "1:23:45")
function GuildKey.Utils:FormatDuration(seconds)
    if not seconds or seconds <= 0 then return "0:00" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

-- Verbleibende Zeit bis Timestamp
function GuildKey.Utils:TimeUntil(timestamp)
    local now = self:GetTimestamp()
    return math.max(0, timestamp - now)
end

-- Einfache Serialisierung (key=value Paare)
-- Unterstützt flache Tabellen mit string/number/boolean Werten
function GuildKey.Utils:Serialize(t)
    if type(t) ~= "table" then
        return tostring(t)
    end
    local parts = {}
    for k, v in pairs(t) do
        local key = tostring(k)
        local val
        if type(v) == "table" then
            val = "{" .. self:Serialize(v) .. "}"
        elseif type(v) == "string" then
            -- Escape Pipes und Trennzeichen
            v = v:gsub("|", "\\|"):gsub(";", "\\;"):gsub("=", "\\=")
            val = '"' .. v .. '"'
        elseif type(v) == "boolean" then
            val = v and "true" or "false"
        else
            val = tostring(v)
        end
        table.insert(parts, key .. "=" .. val)
    end
    return table.concat(parts, ";")
end

-- Einfache Deserialisierung
function GuildKey.Utils:Deserialize(str)
    if not str or str == "" then return {} end
    local t = {}
    -- Einfaches key=value Parsing
    for pair in str:gmatch("([^;]+)") do
        local k, v = pair:match("^(.-)=(.*)$")
        if k and v then
            -- Unescape
            k = k:gsub("\\;", ";"):gsub("\\=", "="):gsub("\\|", "|")
            if v:sub(1, 1) == '"' and v:sub(-1) == '"' then
                v = v:sub(2, -2):gsub("\\;", ";"):gsub("\\=", "="):gsub("\\|", "|")
            elseif v == "true" then
                v = true
            elseif v == "false" then
                v = false
            elseif v:sub(1, 1) == "{" then
                v = self:Deserialize(v:sub(2, -2))
            else
                v = tonumber(v) or v
            end
            t[k] = v
        end
    end
    return t
end

-- Rollenfarbe als Hex-Code zurückgeben
function GuildKey.Utils:GetRoleColor(role)
    local C = GuildKey.Constants.COLORS
    if role == "TANK" then
        return C.TANK
    elseif role == "HEALER" then
        return C.HEALER
    elseif role == "DPS" then
        return C.DPS
    end
    return C.WHITE
end

-- Rollenfarbe als WoW-Farbcode
function GuildKey.Utils:GetRoleColorCode(role)
    if role == "TANK"   then return "|cff0071df" end
    if role == "HEALER" then return "|cff1eff00" end
    if role == "DPS"    then return "|cffff2020" end
    return "|cffffffff"
end

-- Klassenfarbe für Charakter
function GuildKey.Utils:GetClassColor(class)
    local classColors = {
        WARRIOR      = "|cffc79c6e",
        PALADIN      = "|cfff58cba",
        HUNTER       = "|cffabd473",
        ROGUE        = "|cfffff569",
        PRIEST       = "|cffffffff",
        DEATHKNIGHT  = "|cffc41f3b",
        SHAMAN       = "|cff0070de",
        MAGE         = "|cff69ccf0",
        WARLOCK      = "|cff9482c9",
        MONK         = "|cff00ff96",
        DRUID        = "|cffff7d0a",
        DEMONHUNTER  = "|cffa330c9",
        EVOKER       = "|cff33937f",
    }
    return classColors[class] or "|cffffffff"
end

-- Wochennummer berechnen (für wöchentliche Stats)
function GuildKey.Utils:GetWeekNumber()
    local d = date("*t")
    return d.yday and math.floor(d.yday / 7) or 0
end

-- Tabelle kopieren (flach)
function GuildKey.Utils:ShallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- Tabelle sortiert nach einem Feld
function GuildKey.Utils:SortByField(tbl, field, descending)
    table.sort(tbl, function(a, b)
        if descending then
            return (a[field] or 0) > (b[field] or 0)
        else
            return (a[field] or 0) < (b[field] or 0)
        end
    end)
    return tbl
end

-- Prüfen ob Spieler in einer Gilde ist
function GuildKey.Utils:IsInGuild()
    return IsInGuild() == true
end

-- Eigene Klasse
function GuildKey.Utils:GetPlayerClass()
    local _, class = UnitClass("player")
    return class or "WARRIOR"
end
