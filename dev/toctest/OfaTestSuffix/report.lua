local addonName, ns = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version, build, _, interface = GetBuildInfo()
    local result = {
        build = version .. "." .. build,
        interface = interface,
        projectID = WOW_PROJECT_ID,
        tocUsed = GetMeta(addonName, "X-Ofa-Toc"),
        files = table.concat(ns.files or {}, ","),
        checkAddonVersion = GetCVar("checkAddonVersion"),
        hasCAddOnsDisable = (C_AddOns and C_AddOns.DisableAddOn) and true or false,
        constants = {
            MAINLINE = WOW_PROJECT_MAINLINE,
            CLASSIC = WOW_PROJECT_CLASSIC,
            BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC,
            CAMELOT = WOW_PROJECT_CAMELOT,
        },
    }
    local db = addonName .. "DB"
    _G[db] = _G[db] or {}
    _G[db][version] = result
    print("|cff33ff99" .. addonName .. "|r toc=" .. tostring(result.tocUsed)
        .. " project=" .. tostring(result.projectID) .. " files=" .. result.files)
end)
