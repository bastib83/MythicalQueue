GuildKey = GuildKey or {}
GuildKey.Events = {}

local eventFrame = CreateFrame("Frame", "GuildKeyEventFrame")

-- Alle Events die wir registrieren
local EVENTS = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "GUILD_ROSTER_UPDATE",
    "PLAYER_ENTERING_WORLD",
    "CHALLENGE_MODE_START",
    "CHALLENGE_MODE_COMPLETED",
    "CHALLENGE_MODE_RESET",
    "CHAT_MSG_ADDON",
    "PLAYER_LOGOUT",
}

for _, event in ipairs(EVENTS) do
    eventFrame:RegisterEvent(event)
end

-- Event-Handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    GuildKey.Utils:Debug("Event: " .. event)
    if GuildKey.Events[event] then
        local ok, err = pcall(GuildKey.Events[event], GuildKey.Events, ...)
        if not ok then
            GuildKey.Utils:Debug("Event error [" .. event .. "]: " .. tostring(err))
        end
    end
end)

-- ADDON_LOADED
function GuildKey.Events:ADDON_LOADED(addonName)
    if addonName ~= "GuildKey" then return end
    -- Daten initialisieren
    GuildKey.Data:Init()
    -- Comm initialisieren
    GuildKey.Comm:Init()
    GuildKey.Utils:Print("|cffA335EEGuildKey v" .. GuildKey.Constants.VERSION .. "|r geladen. /gk für Hilfe.")
end

-- PLAYER_LOGIN
function GuildKey.Events:PLAYER_LOGIN()
    -- Gildenliste anfordern
    GuildRoster()
    -- Eigenen Keystone auslesen
    if GuildKey.MyKey then
        GuildKey.MyKey:ReadOwnKeystone()
    end
    -- Ping an Gilde senden
    C_Timer.After(3, function()
        if GuildKey.Utils:IsInGuild() then
            GuildKey.Comm:Ping()
        end
    end)
    -- Status des eigenen Charakters broadcasten
    C_Timer.After(5, function()
        if GuildKey.MemberStatus then
            GuildKey.MemberStatus:BroadcastStatus()
        end
    end)
end

-- GUILD_ROSTER_UPDATE
function GuildKey.Events:GUILD_ROSTER_UPDATE()
    if GuildKey.MemberStatus then
        GuildKey.MemberStatus:RefreshGuildRoster()
    end
    if GuildKey.UI and GuildKey.UI.tabs and GuildKey.UI.tabs[2] then
        -- MemberStatusUI aktualisieren falls geöffnet
        if GuildKey.MemberStatusUI then
            GuildKey.MemberStatusUI:Refresh()
        end
    end
end

-- PLAYER_ENTERING_WORLD
function GuildKey.Events:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    if GuildKey.MemberStatus then
        GuildKey.MemberStatus:CheckInstanceStatus()
    end
end

-- CHALLENGE_MODE_START
function GuildKey.Events:CHALLENGE_MODE_START()
    GuildKey.Utils:Debug("Challenge mode started.")
    if GuildKey.Stats then
        GuildKey.Stats:OnRunStarted()
    end
    if GuildKey.MemberStatus then
        GuildKey.MemberStatus:OnChallengeStart()
    end
end

-- CHALLENGE_MODE_COMPLETED
function GuildKey.Events:CHALLENGE_MODE_COMPLETED()
    GuildKey.Utils:Debug("Challenge mode completed.")
    if GuildKey.Stats then
        GuildKey.Stats:OnRunCompleted()
    end
    if GuildKey.MemberStatus then
        GuildKey.MemberStatus:OnChallengeEnd()
    end
end

-- CHALLENGE_MODE_RESET
function GuildKey.Events:CHALLENGE_MODE_RESET()
    GuildKey.Utils:Debug("Challenge mode reset.")
    if GuildKey.Stats then
        GuildKey.Stats:OnRunReset()
    end
    if GuildKey.MemberStatus then
        GuildKey.MemberStatus:OnChallengeEnd()
    end
end

-- CHAT_MSG_ADDON
function GuildKey.Events:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == GuildKey.Constants.ADDON_PREFIX then
        GuildKey.Comm:OnReceive(prefix, message, channel, sender)
    end
end

-- PLAYER_LOGOUT
function GuildKey.Events:PLAYER_LOGOUT()
    -- Status auf Offline setzen und broadcasten
    if GuildKey.Utils:IsInGuild() then
        GuildKey.Comm:Send(GuildKey.Constants.MSG.STATUS_UPDATE, {
            sender       = GuildKey.Utils:GetCharName(),
            availability = GuildKey.Constants.AVAILABILITY.OFFLINE,
            online       = false,
        })
    end
end

GuildKey.Events.frame = eventFrame
