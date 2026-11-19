-- OfaCloseProbe: measures for Armory One for All whether the data of a profession window (TradeSkill and
-- Craft) and of the guild bank can still be read right after the window closes. Armory replaced
-- CloseTradeSkill, CloseCraft and CloseGuildBankFrame to read just before closing, which taints Blizzard's
-- closing code; a hooksecurefunc runs just after closing and taints nothing, if the data is still there.
--
-- Measures at: opening (baseline), the secure hook right after the close function, the close event, and
-- one frame later. The "extended" measurement compares every line Armory's extended reading reads with
-- the same lines at opening. Reads only, except that after closing it collapses one expanded header and
-- expands it again, to see whether the list still reacts (Armory's extended reading expands all headers).
-- Leave the window alone between opening and closing (no crafting, no filter): the lines should match.
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

-- Everything Armory's extended reading reads, line by line: compared between opening and after closing
local function Join(...)
    local values = { ... };
    for i = 1, select("#", ...) do
        values[i] = tostring(values[i]);
    end
    return table.concat(values, ",");
end

local function TradeSkillLines()
    local lines = {};
    for id = 1, GetNumTradeSkills() do
        local name, kind = GetTradeSkillInfo(id);
        local line = Join(GetTradeSkillInfo(id));
        if ( kind ~= "header" ) then
            line = line .. "|" .. Join(GetTradeSkillIcon(id), GetTradeSkillItemLink(id), GetTradeSkillNumMade(id),
                GetTradeSkillTools(id), GetTradeSkillCooldown(id), GetTradeSkillNumReagents(id));
            for i = 1, GetTradeSkillNumReagents(id) do
                line = line .. "|" .. Join(GetTradeSkillReagentInfo(id, i)) .. "," .. tostring(GetTradeSkillReagentItemLink(id, i));
            end
        end
        lines[id] = line;
    end
    return lines;
end

local function CraftLines()
    local lines = {};
    for id = 1, GetNumCrafts() do
        local _, _, kind = GetCraftInfo(id);
        local line = Join(GetCraftInfo(id));
        if ( kind ~= "header" ) then
            line = line .. "|" .. Join(GetCraftIcon(id), GetCraftItemLink(id), GetCraftSpellFocus(id), GetCraftNumReagents(id));
            for i = 1, GetCraftNumReagents(id) do
                line = line .. "|" .. Join(GetCraftReagentInfo(id, i)) .. "," .. tostring(GetCraftReagentItemLink(id, i));
            end
        end
        lines[id] = line;
    end
    return lines;
end

-- Collapses the first expanded header and expands it again: does the list still react after closing?
local function TryCollapse(getNum, getState, collapse, expand)
    local before = getNum();
    for id = 1, before do
        local isHeader, isExpanded = getState(id);
        if ( isHeader and isExpanded ) then
            collapse(id);
            local collapsed = getNum();
            expand(id);
            return string.format("header %d: %d lines, collapsed %d, expanded again %d", id, before, collapsed, getNum());
        end
    end
    return "no expanded header";
end

local openLines = {};

local function CompareLines(window, lines)
    local open = openLines[window];
    if ( not open ) then
        return "no measurement at opening";
    end
    if ( #open ~= #lines ) then
        return string.format("line count differs: open %d, now %d", #open, #lines);
    end
    for i = 1, #lines do
        if ( open[i] ~= lines[i] ) then
            return string.format("line %d differs: open [%s] now [%s]", i, open[i], lines[i]);
        end
    end
    return string.format("same as at opening (%d lines)", #lines);
end

local function MeasureTradeSkillExtended(moment)
    local ok, lines = pcall(TradeSkillLines);
    if ( moment == "open" ) then
        openLines.TradeSkill = ok and lines or nil;
    end
    local subClasses = { pcall(GetTradeSkillSubClasses) };
    local invSlots = { pcall(GetTradeSkillInvSlots) };
    return {
        lines = ok and CompareLines("TradeSkill", lines) or ("error: " .. tostring(lines)),
        subClasses = subClasses[1] and (#subClasses - 1) or tostring(subClasses[2]),
        invSlots = invSlots[1] and (#invSlots - 1) or tostring(invSlots[2]),
        filters = Call(function() return GetTradeSkillSubClassFilter(0), GetTradeSkillInvSlotFilter(0); end),
        selection = Call(GetTradeSkillSelectionIndex),
        collapse = moment == "open" and "not tried" or Call(TryCollapse, GetNumTradeSkills,
            function(id) local _, kind, _, isExpanded = GetTradeSkillInfo(id); return kind == "header", isExpanded; end,
            CollapseTradeSkillSubClass, ExpandTradeSkillSubClass),
    };
end

local function MeasureCraftExtended(moment)
    local ok, lines = pcall(CraftLines);
    if ( moment == "open" ) then
        openLines.Craft = ok and lines or nil;
    end
    return {
        lines = ok and CompareLines("Craft", lines) or ("error: " .. tostring(lines)),
        selection = Call(GetCraftSelectionIndex),
        collapse = moment == "open" and "not tried" or Call(TryCollapse, GetNumCrafts,
            function(id) local _, _, kind, _, isExpanded = GetCraftInfo(id); return kind == "header", isExpanded; end,
            CollapseCraftSkillLine, ExpandCraftSkillLine),
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
HookClose("CloseTradeSkill", "TradeSkill extended", function() return MeasureTradeSkillExtended("after"); end);
HookClose("CloseCraft", "Craft extended", function() return MeasureCraftExtended("after"); end);
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
        C_Timer.After(0.5, function()
            Record("TradeSkill", "open (+0.5s)", MeasureTradeSkill);
            Record("TradeSkill extended", "open (+0.5s)", function() return MeasureTradeSkillExtended("open"); end);
        end);
    elseif ( event == "TRADE_SKILL_CLOSE" ) then
        RecordNowAndNextFrame("TradeSkill", "TRADE_SKILL_CLOSE", MeasureTradeSkill);
    elseif ( event == "CRAFT_SHOW" ) then
        C_Timer.After(0.5, function()
            Record("Craft", "open (+0.5s)", MeasureCraft);
            Record("Craft extended", "open (+0.5s)", function() return MeasureCraftExtended("open"); end);
        end);
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
