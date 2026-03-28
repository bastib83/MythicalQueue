local addonName, ns = ...

-- MythicalQueue namespace
ns.addon = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        print("|cff00ff00MythicalQueue|r loaded.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
