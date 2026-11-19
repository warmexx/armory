-- OfaCloseProbe: measures for Armory One for All whether the data of a profession window (TradeSkill and
-- Craft) and of the guild bank can still be read right after the window closes. Armory replaced
-- CloseTradeSkill, CloseCraft and CloseGuildBankFrame to read just before closing, which taints Blizzard's
-- closing code; a hooksecurefunc runs just after closing and taints nothing, if the data is still there.
--
-- Measures at: opening (baseline), the secure hook right after the close function, the close event, and
-- one frame later. Reads only; changes nothing.
--
-- Open and close a profession (and in Classic Era Enchanting/Beast Training, which use the Craft window),
-- and the guild bank. Close in different ways: the X button, Escape, walking away.
--
-- /ocp        print the measurements of this session
-- /ocp clear  remove all measurements
--
-- After testing: /reload or log out, so the game writes OfaCloseProbeDB (WTF\...\SavedVariables).

OfaCloseProbeDB = OfaCloseProbeDB or {};

local function Call(func, ...)
    if ( type(func) ~= "function" ) then
        return "no function";
    end
    local result = { pcall(func, ...) };
    if ( not result[1] ) then
        return "error: " .. tostring(result[2]);
    end
    table.remove(result, 1);
    for i = 1, #result do
        result[i] = tostring(result[i]);
    end
    return table.concat(result, ", ");
end

-- kindPosition: where the info function returns the type ("header" or a difficulty)
local function FirstRecipe(getNum, getInfo, kindPosition)
    local ok, num = pcall(getNum or error);
    if ( not ok or type(num) ~= "number" or type(getInfo) ~= "function" ) then
        return nil;
    end
    for i = 1, num do
        if ( select(kindPosition, getInfo(i)) ~= "header" ) then
            return i;
        end
    end
end

local function MeasureTradeSkill()
    local index = FirstRecipe(GetNumTradeSkills, GetTradeSkillInfo, 2);
    return {
        line = Call(GetTradeSkillLine),
        num = Call(GetNumTradeSkills),
        recipe = index and Call(GetTradeSkillInfo, index) or "none",
        reagents = index and Call(GetTradeSkillNumReagents, index) or "none",
        link = index and Call(GetTradeSkillItemLink, index) or "none",
    };
end

local function MeasureCraft()
    local index = FirstRecipe(GetNumCrafts, GetCraftInfo, 3);
    return {
        line = Call(GetCraftDisplaySkillLine),
        num = Call(GetNumCrafts),
        recipe = index and Call(GetCraftInfo, index) or "none",
        reagents = index and Call(GetCraftNumReagents, index) or "none",
        link = index and Call(GetCraftItemLink, index) or "none",
    };
end

local function MeasureGuildBank()
    local items = 0;
    local ok, tab = pcall(GetCurrentGuildBankTab);
    if ( ok and type(tab) == "number" and GetGuildBankItemLink ) then
        for i = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
            if ( GetGuildBankItemLink(tab, i) ) then
                items = items + 1;
            end
        end
    end
    return {
        tabs = Call(GetNumGuildBankTabs),
        currentTab = tostring(tab),
        tabInfo = ok and Call(GetGuildBankTabInfo, tab) or "none",
        items = items,
        money = Call(GetGuildBankMoney),
    };
end

local session = {};

local function Record(window, moment, measure)
    local entry = { window = window, moment = moment, time = GetTime(), data = measure() };
    table.insert(session, entry);
    table.insert(OfaCloseProbeDB, entry);
end

local function RecordNowAndNextFrame(window, moment, measure)
    Record(window, moment, measure);
    C_Timer.After(0, function() Record(window, moment .. " +1 frame", measure); end);
end

local function HookClose(name, window, measure)
    if ( type(_G[name]) == "function" ) then
        hooksecurefunc(name, function() RecordNowAndNextFrame(window, "after " .. name, measure); end);
    end
end

HookClose("CloseTradeSkill", "TradeSkill", MeasureTradeSkill);
HookClose("CloseCraft", "Craft", MeasureCraft);
HookClose("CloseGuildBankFrame", "GuildBank", MeasureGuildBank);

local GUILDBANKER = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.GuildBanker;

local frame = CreateFrame("Frame");
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "CRAFT_SHOW", "CRAFT_CLOSE",
                         "GUILDBANKBAGSLOTS_CHANGED", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
    pcall(frame.RegisterEvent, frame, event);
end
local guildBankSeen;
frame:SetScript("OnEvent", function(self, event, arg1)
    if ( event == "TRADE_SKILL_SHOW" ) then
        C_Timer.After(0.5, function() Record("TradeSkill", "open (+0.5s)", MeasureTradeSkill); end);
    elseif ( event == "TRADE_SKILL_CLOSE" ) then
        RecordNowAndNextFrame("TradeSkill", "TRADE_SKILL_CLOSE", MeasureTradeSkill);
    elseif ( event == "CRAFT_SHOW" ) then
        C_Timer.After(0.5, function() Record("Craft", "open (+0.5s)", MeasureCraft); end);
    elseif ( event == "CRAFT_CLOSE" ) then
        RecordNowAndNextFrame("Craft", "CRAFT_CLOSE", MeasureCraft);
    elseif ( event == "GUILDBANKBAGSLOTS_CHANGED" ) then
        if ( not guildBankSeen ) then
            guildBankSeen = true;
            Record("GuildBank", "first GUILDBANKBAGSLOTS_CHANGED", MeasureGuildBank);
        end
    elseif ( event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and arg1 == GUILDBANKER ) then
        guildBankSeen = nil;
        RecordNowAndNextFrame("GuildBank", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE", MeasureGuildBank);
    end
end);

SLASH_OFACLOSEPROBE1 = "/ocp";
SlashCmdList["OFACLOSEPROBE"] = function(msg)
    if ( msg == "clear" ) then
        table.wipe(OfaCloseProbeDB);
        table.wipe(session);
        print("OfaCloseProbe: cleared");
        return;
    end
    if ( #session == 0 ) then
        print("OfaCloseProbe: nothing measured yet in this session");
    end
    for _, entry in ipairs(session) do
        local parts = {};
        for key, value in pairs(entry.data) do
            table.insert(parts, key .. "=" .. tostring(value));
        end
        table.sort(parts);
        print(string.format("%.2f %s | %s | %s", entry.time, entry.window, entry.moment, table.concat(parts, " | ")));
    end
end;
