GuildKey = GuildKey or {}
GuildKey.Comm = {}

local PREFIX  = "GuildKey"
local VERSION = "0.1.0"
local SEP     = "|"

-- Handlers für eingehende Nachrichten
local handlers = {}

-- Handler registrieren
function GuildKey.Comm:RegisterHandler(msgType, fn)
    handlers[msgType] = fn
end

-- Initialisierung: Prefix registrieren
function GuildKey.Comm:Init()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        local ok = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        if not ok then
            GuildKey.Utils:Print("Warnung: Addon-Prefix konnte nicht registriert werden.")
        end
    end
    GuildKey.Utils:Debug("Comm initialized.")
end

-- Payload serialisieren (eigene einfache Serialisierung)
local function Encode(payload)
    if type(payload) ~= "table" then
        return tostring(payload)
    end
    return GuildKey.Utils:Serialize(payload)
end

-- Payload deserialisieren
local function Decode(str)
    return GuildKey.Utils:Deserialize(str)
end

-- Nachricht senden (GUILD-Kanal)
function GuildKey.Comm:Send(msgType, payload)
    if not GuildKey.Utils:IsInGuild() then
        GuildKey.Utils:Debug("Not in guild, cannot send.")
        return
    end
    local encoded = Encode(payload)
    local message = PREFIX .. SEP .. VERSION .. SEP .. msgType .. SEP .. encoded

    -- WoW begrenzt Addon-Nachrichten auf 255 Zeichen
    if #message > 254 then
        GuildKey.Utils:Debug("Message too long (" .. #message .. " chars), truncating.")
        message = message:sub(1, 254)
    end

    GuildKey.Utils:Debug("SEND [" .. msgType .. "]: " .. encoded)
    SendAddonMessage(PREFIX, message, GuildKey.Constants.CHANNEL)
end

-- Direktnachricht senden (Flüstern)
function GuildKey.Comm:SendWhisper(target, msgType, payload)
    if not target then return end
    local encoded = Encode(payload)
    local message = PREFIX .. SEP .. VERSION .. SEP .. msgType .. SEP .. encoded
    if #message > 254 then
        message = message:sub(1, 254)
    end
    GuildKey.Utils:Debug("WHISPER [" .. msgType .. "] -> " .. target)
    SendAddonMessage(PREFIX, message, "WHISPER", target)
end

-- Ping an alle Gildenmitglieder
function GuildKey.Comm:Ping()
    self:Send(GuildKey.Constants.MSG.PING, {
        sender  = GuildKey.Utils:GetCharName(),
        version = VERSION,
    })
end

-- Pong zurückschicken
function GuildKey.Comm:Pong(target)
    self:SendWhisper(target, GuildKey.Constants.MSG.PONG, {
        sender  = GuildKey.Utils:GetCharName(),
        version = VERSION,
    })
end

-- Eingehende Nachrichten verarbeiten
function GuildKey.Comm:OnReceive(prefix, message, channel, sender)
    if prefix ~= PREFIX then return end

    -- Eigene Nachrichten ignorieren (außer Debug)
    local myName = GuildKey.Utils:GetCharName()
    -- Sender kann "Name" oder "Name-Server" sein
    local senderBase = sender:match("^([^-]+)") or sender
    local myBase     = myName:match("^([^-]+)") or myName
    if senderBase == myBase then return end

    -- Nachrichtenformat: PREFIX|VERSION|MSGTYPE|PAYLOAD
    local parts = {}
    for p in message:gmatch("([^" .. SEP .. "]+)") do
        table.insert(parts, p)
    end

    if #parts < 3 then
        GuildKey.Utils:Debug("Malformed message from " .. sender)
        return
    end

    local msgPrefix  = parts[1]
    local msgVersion = parts[2]
    local msgType    = parts[3]
    local payload    = parts[4] or ""

    if msgPrefix ~= PREFIX then return end

    GuildKey.Utils:Debug("RECV [" .. msgType .. "] from " .. sender .. ": " .. payload)

    -- Payload dekodieren
    local data = Decode(payload)

    -- Handler aufrufen
    if handlers[msgType] then
        local ok, err = pcall(handlers[msgType], data, sender, channel)
        if not ok then
            GuildKey.Utils:Debug("Handler error [" .. msgType .. "]: " .. tostring(err))
        end
    else
        GuildKey.Utils:Debug("No handler for msgType: " .. msgType)
    end
end

-- Standard-Handler registrieren (werden von Modulen überschrieben)
do
    local MSG = GuildKey.Constants and GuildKey.Constants.MSG or {}

    -- Ping beantworten
    GuildKey.Comm:RegisterHandler(MSG.PING or "PING", function(data, sender)
        GuildKey.Comm:Pong(sender:match("^([^-]+)") or sender)
    end)

    -- Pong empfangen (Online-Status merken)
    GuildKey.Comm:RegisterHandler(MSG.PONG or "PONG", function(data, sender)
        if GuildKey.Data and data.sender then
            GuildKey.Data:UpdateMember(data.sender, { online = true, version = data.version })
        end
    end)
end
