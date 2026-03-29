-- GuildKey.lua - Entry Point & Slash Commands
-- Wird zuletzt geladen; alle Module sind zu diesem Zeitpunkt bereits initialisiert.

GuildKey = GuildKey or {}

-- ─── Slash-Commands ───────────────────────────────────────────────────────────
SLASH_GUILDKEY1 = "/gk"
SLASH_GUILDKEY2 = "/guildkey"

SlashCmdList["GUILDKEY"] = function(msg)
    local cmd, rest = (msg or ""):match("^(%S*)%s*(.*)")
    cmd = cmd and cmd:lower() or ""

    if cmd == "" then
        GuildKey.UI:Toggle()

    elseif cmd == "post" then
        GuildKey.UI:ShowPostRunForm()

    elseif cmd == "join" then
        local runId = rest and rest:match("^(%S+)")
        if runId and runId ~= "" then
            GuildKey.RunBoard:JoinRun(runId, nil)
        else
            GuildKey.Utils:Print(GuildKey.L["Usage: /gk join <runId>"])
        end

    elseif cmd == "leave" then
        GuildKey.RunBoard:LeaveRun(nil)

    elseif cmd == "status" then
        if rest and rest ~= "" then
            GuildKey.MemberStatus:SetAvailability(rest)
        else
            GuildKey.Utils:Print(GuildKey.L["Usage: /gk status <text>"])
        end

    elseif cmd == "debug" then
        GuildKey.DEBUG = not GuildKey.DEBUG
        GuildKey.Utils:Print("Debug: " .. (GuildKey.DEBUG and "|cff00ff00ON|r" or "|cffff4040OFF|r"))

    elseif cmd == "ping" then
        GuildKey.Comm:Ping()
        GuildKey.Utils:Print("Ping gesendet.")

    elseif cmd == "reload" then
        ReloadUI()

    elseif cmd == "help" then
        GuildKey.Utils:Print(GuildKey.L["GuildKey Commands"])
        GuildKey.Utils:Print(GuildKey.L["/gk - Main window"])
        GuildKey.Utils:Print(GuildKey.L["/gk post - Post run"])
        GuildKey.Utils:Print(GuildKey.L["/gk join - Join run"])
        GuildKey.Utils:Print(GuildKey.L["/gk leave - Leave run"])
        GuildKey.Utils:Print(GuildKey.L["/gk status - Set status"])
        GuildKey.Utils:Print(GuildKey.L["/gk debug - Debug mode"])
        GuildKey.Utils:Print(GuildKey.L["/gk help - Show help"])

    else
        -- Unbekannter Befehl: Hauptfenster öffnen
        GuildKey.UI:Toggle()
    end
end

-- DEBUG-Flag global (kann auch per /gk debug umgeschaltet werden)
GuildKey.DEBUG = false
