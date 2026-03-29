GuildKey = GuildKey or {}
GuildKey.Themes = {}

-- WoW Dark Theme
GuildKey.Themes.current = {

    -- Hintergründe
    BG_MAIN   = { r = 0.05, g = 0.06, b = 0.10, a = 0.97 },
    BG_CARD   = { r = 0.08, g = 0.09, b = 0.14, a = 0.95 },
    BG_HEADER = { r = 0.10, g = 0.05, b = 0.20, a = 0.95 },
    BG_TAB    = { r = 0.12, g = 0.10, b = 0.18, a = 1.00 },
    BG_INPUT  = { r = 0.07, g = 0.07, b = 0.12, a = 1.00 },

    -- Rahmen
    BORDER       = { r = 0.35, g = 0.25, b = 0.55, a = 1 },
    BORDER_CARD  = { r = 0.25, g = 0.20, b = 0.40, a = 0.8 },
    BORDER_GOLD  = { r = 0.78, g = 0.66, b = 0.29, a = 1 },

    -- Text
    TEXT_TITLE   = { r = 0.78, g = 0.66, b = 0.29, a = 1 },   -- Gold
    TEXT_NORMAL  = { r = 1.00, g = 1.00, b = 1.00, a = 1 },
    TEXT_MUTED   = { r = 0.53, g = 0.53, b = 0.53, a = 1 },
    TEXT_EPIC    = { r = 0.64, g = 0.21, b = 0.93, a = 1 },

    -- Rollen
    TANK   = { r = 0.00, g = 0.44, b = 0.87, a = 1 },
    HEALER = { r = 0.12, g = 1.00, b = 0.00, a = 1 },
    DPS    = { r = 1.00, g = 0.12, b = 0.12, a = 1 },

    -- Status
    ONLINE   = { r = 0.00, g = 1.00, b = 0.00, a = 1 },
    BUSY     = { r = 1.00, g = 0.50, b = 0.00, a = 1 },
    OFFLINE  = { r = 0.40, g = 0.40, b = 0.40, a = 1 },
    IN_DUNGEON = { r = 0.00, g = 0.80, b = 1.00, a = 1 },

    -- Button
    BTN_BG      = { r = 0.20, g = 0.12, b = 0.35, a = 1 },
    BTN_HOVER   = { r = 0.30, g = 0.18, b = 0.50, a = 1 },
    BTN_ACTIVE  = { r = 0.40, g = 0.25, b = 0.65, a = 1 },
    BTN_BORDER  = { r = 0.50, g = 0.35, b = 0.75, a = 1 },

    -- Trennlinien
    DIVIDER = { r = 0.35, g = 0.25, b = 0.55, a = 0.6 },

    -- Pulsieren (für freie Slots)
    PULSE = { r = 0.78, g = 0.66, b = 0.29, a = 1 },
}

local T = GuildKey.Themes.current

-- Backdrop-Template für Hauptfenster
function GuildKey.Themes:GetMainBackdrop()
    return {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    }
end

-- Backdrop für Karten
function GuildKey.Themes:GetCardBackdrop()
    return {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    }
end

-- Hilfsfunktion: Farbe auf Frame anwenden
function GuildKey.Themes:ApplyBackgroundColor(frame, colorKey)
    local c = T[colorKey] or T.BG_MAIN
    if frame.SetBackdropColor then
        frame:SetBackdropColor(c.r, c.g, c.b, c.a)
    end
end

function GuildKey.Themes:ApplyBorderColor(frame, colorKey)
    local c = T[colorKey] or T.BORDER
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end
end

-- Statusfarbe nach Verfügbarkeit
function GuildKey.Themes:GetAvailabilityColor(availability)
    if availability == GuildKey.Constants.AVAILABILITY.NOW then
        return T.ONLINE
    elseif availability == GuildKey.Constants.AVAILABILITY.BUSY then
        return T.BUSY
    elseif availability == GuildKey.Constants.AVAILABILITY.OFFLINE then
        return T.OFFLINE
    elseif availability then
        return T.IN_DUNGEON
    end
    return T.OFFLINE
end

-- Rollenfarbe
function GuildKey.Themes:GetRoleColor(role)
    return T[role] or T.TEXT_NORMAL
end
