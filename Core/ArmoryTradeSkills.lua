--[[
    Armory Addon for World of Warcraft(tm).
    Revision: @file-revision@ @file-date-iso@
    URL: http://www.wow-neighbours.com

    License:
        This program is free software; you can redistribute it and/or
        modify it under the terms of the GNU General Public License
        as published by the Free Software Foundation; either version 2
        of the License, or (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program(see GPL.txt); if not, write to the Free Software
        Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

    Note:
        This AddOn's source code is specifically designed to work with
        World of Warcraft's interpreted AddOn system.
        You have an implicit licence to use this AddOn with these facilities
        since that is it's designated purpose as per:
        http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
--]]

local Armory, _ = Armory;
local LR = LibStub("LibRecipes-1.0");

local container = "Professions";
local itemContainer = "SkillLines";
local reagentContainer = "Reagents";

local selectedSkill;

local tradeSkillSubClassFilter = nil;
local tradeSkillInvSlotFilter = nil;
local tradeSkillFilter = "";
local tradeSkillMinLevel = 0;
local tradeSkillMaxLevel = 0;
local onlyShowMakeable = false;
local onlyShowSkillUp = false;

local invSlots = {};
local subClasses = {};

local tradeIcons = {};
tradeIcons[ARMORY_TRADE_ALCHEMY] = "Trade_Alchemy";
tradeIcons[ARMORY_TRADE_BLACKSMITHING] = "Trade_BlackSmithing";
tradeIcons[ARMORY_TRADE_COOKING] = "INV_Misc_Food_15";
tradeIcons[ARMORY_TRADE_ENCHANTING] = "Trade_Engraving";
tradeIcons[ARMORY_TRADE_ENGINEERING] = "Trade_Engineering";
tradeIcons[ARMORY_TRADE_FIRST_AID] = "Spell_Holy_SealOfSacrifice";
tradeIcons[ARMORY_TRADE_FISHING] = "Trade_Fishing";
tradeIcons[ARMORY_TRADE_HERBALISM] = "Trade_Herbalism";
tradeIcons[ARMORY_TRADE_LEATHERWORKING] = "Trade_LeatherWorking";
tradeIcons[ARMORY_TRADE_MINING] = "Trade_Mining";
tradeIcons[ARMORY_TRADE_POISONS] = "Trade_BrewPoison";
tradeIcons[ARMORY_TRADE_SKINNING] = "INV_Weapon_ShortBlade_01";
tradeIcons[ARMORY_TRADE_TAILORING] = "Trade_Tailoring";

----------------------------------------------------------
-- TradeSkills Internals
----------------------------------------------------------

local professionLines = {};
local dirty = true;
local owner = "";
local invSlot = {};

local primarySkills = {}
local secondarySkills = {}
local function GetProfessions()
    local inPrimary = false;
    local inSecondary = false;
    local index = 1;

    table.wipe(primarySkills);
    table.wipe(secondarySkills);

    while ( _G.GetSkillLineInfo(index) ) do
        local skillName, header = _G.GetSkillLineInfo(index);
        if ( header and skillName == TRADE_SKILLS ) then
            inPrimary = true;
            inSecondary = false;
        elseif ( header and (SECONDARY_SKILLS:sub(1, #skillName) == skillName or SECONDARY_SKILLS:sub(-#skillName) == skillName) ) then
            inPrimary = false;
            inSecondary = true;
        elseif ( header and (inPrimary or inSecondary) ) then
            inPrimary = false;
            inSecondary = false;
        elseif ( inPrimary ) then
            table.insert(primarySkills, index);
        elseif ( inSecondary ) then
            table.insert(secondarySkills, index);
        end
        index = index + 1;
    end

    local prof1, prof2 = unpack(primarySkills);
    local prof3, prof4, prof5 = unpack(secondarySkills);

    return prof1, prof2, prof3, prof4, prof5;
end

local function GetProfessionInfo(index)
    local skillName, _, _, skillRank, _, skillModifier, skillMaxRank = _G.GetSkillLineInfo(index);
    local _, _, _, numSpells = _G.GetSpellTabInfo(1);

    for i = 1, numSpells do
        local spellName, _, spellID = _G.GetSpellBookItemName(i, BOOKTYPE_SPELL);
        if ( spellID == 2656 ) then
            local texture = "Interface\\Icons\\"..tradeIcons[ARMORY_TRADE_MINING];
            return skillName, texture, skillRank, skillMaxRank, skillModifier;
        elseif ( spellID == 2383 ) then
            local texture = "Interface\\Icons\\"..tradeIcons[ARMORY_TRADE_HERBALISM];
            return skillName, texture, skillRank, skillMaxRank, skillModifier;
        elseif ( spellName == skillName ) then
            local texture = _G.GetSpellBookItemTexture(i, BOOKTYPE_SPELL);
            return skillName, texture, skillRank, skillMaxRank, skillModifier;
        end
    end
end

local function GetRecipeValue(index, ...)
    return Armory.selectedDbBaseEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], ...);
end

local function GetNumReagents(index)
    local reagents = GetRecipeValue(index, "Reagents") or {};
    return #reagents;
end

local function GetReagentInfo(id, index)
    local itemID, count = GetRecipeValue(id, "Reagents", index);
    if ( not tonumber(itemID) ) then
        return itemID or UNKNOWN, "Interface\\Icons\\INV_Misc_QuestionMark", count;
    end
    local name, texture, link = Armory:GetSharedValue(container, reagentContainer, itemID);
    return name, texture, count, link;
end

local function IsRecipe(skillType)
    return skillType and skillType ~= "header";
end

local function IsSameRecipe(skillName, recipeName, ...)
    skillName = strlower(strtrim(skillName));
    recipeName = strlower(strtrim(recipeName));
    if ( skillName:find(recipeName) ) then
        return true;
    elseif ( recipeName:find("[%-%:%(]%s*"..skillName) or recipeName:find(skillName.."%s*%-") ) then
        -- not 100% but we tried
        Armory:FillUnbrokenTable(invSlot, ...);
        for _, slot in ipairs(invSlot) do
            if ( recipeName:find(strlower(slot)) ) then
                return true;
            end
        end
    end
    --return skillName:sub(1, strlen(recipeName)) == recipeName;
    --return skillName:find(recipeName);
    return false;
end

local function SelectProfession(baseEntry, name)
    local dbEntry = ArmoryDbEntry:new(baseEntry);
    dbEntry:SetPosition(container, name);
    return dbEntry;
end

local function GetProfessionNumValues(dbEntry)
    local numLines = dbEntry:GetNumValues(itemContainer);
    local _, skillType = dbEntry:GetValue(itemContainer, 1, "Info");
    local extended = not IsRecipe(skillType);
    return numLines, extended;
end

local function CanCraftFromInventory(dbEntry, index)
    if ( not Armory:HasInventory() ) then
        return false;
    end

    local numReagents = GetNumReagents(index);
    if ( (numReagents or 0) == 0 ) then
        return false;
    end
    
    for i = 1, numReagents do
        local _, _, count, link = GetRecentInfo(index, i);
        if ( (count or 0) > 0 and Armory:ScanInventory(link, true) < count ) then
            return false;
        end
    end
    
    return true;
end

local groups = {};
local function GetProfessionLines()
    local dbEntry = Armory.selectedDbBaseEntry;
    local group = { index=0, expanded=true, included=true, items={} };
    local numReagents, oldPosition, names, isIncluded, itemMinLevel;
    local numLines, extended;
    local name, skillType, numAvailable, isExpanded;
    local subgroup;

    table.wipe(professionLines);

    if ( dbEntry and dbEntry:Contains(container, selectedSkill, itemContainer) ) then
        dbEntry = SelectProfession(dbEntry, selectedSkill)

        numLines, extended = GetProfessionNumValues(dbEntry);
        if ( numLines > 0 ) then
            table.wipe(groups);
             
            -- apply filters
            for i = 1, numLines do
                name, skillType, numAvailable = dbEntry:GetValue(itemContainer, i, "Info");
                isExpanded = not Armory:GetHeaderLineState(itemContainer..selectedSkill, name);
                if ( not IsRecipe(skillType) ) then
                    isIncluded = not tradeSkillSubClassFilter or tradeSkillSubClassFilter == name;
                    group = { index=i, expanded=isExpanded, included=isIncluded, items={} };
                    subgroup = nil;
                    table.insert(groups, group);
                elseif ( group.included ) then
                    if ( not IsRecipe(skillType) ) then
                        subgroup = { index=i, expanded=isExpanded, items={} };
                        table.insert(group.items, subgroup);
                    else
                        numReagents = GetNumReagents(i);
                        names = name or "";
                        for index = 1, numReagents do
                            names = names.."\t"..(GetReagentInfo(i, index) or "");
                        end

                        if ( tradeSkillInvSlotFilter ) then
                            isIncluded = false;
                            Armory:FillUnbrokenTable(invSlot, dbEntry:GetValue(itemContainer, i, "InvSlot"));
                            for _, slot in ipairs(invSlot) do
                                if ( tradeSkillInvSlotFilter == slot ) then
                                    isIncluded = true;
                                    break;
                                end
                            end
                        else
                            isIncluded = true;
                        end
                        if ( isIncluded and onlyShowMakeable ) then
                            if ( (numAvailable or 0) > 0 ) then
                                isIncluded = true;
                            else
                                isIncluded = CanCraftFromInventory(dbEntry, i);
                            end
                        end
                        if ( isIncluded and onlyShowSkillUp ) then
                            isIncluded = skillType ~= "trivial";
                        end
                        if ( isIncluded and tradeSkillMinLevel > 0 and tradeSkillMaxLevel > 0 ) then
                            _, _, _, _, itemMinLevel = _G.GetItemInfo(dbEntry:GetValue(itemContainer, i, "ItemLink"));
                            isIncluded = itemMinLevel and itemMinLevel >= tradeSkillMinLevel and itemMinLevel <= tradeSkillMaxLevel;
                        elseif ( isIncluded and not name or (tradeSkillFilter ~= "" and not string.find(strlower(names), strlower(tradeSkillFilter), 1, true)) ) then
                            isIncluded = false;
                        end
                        if ( isIncluded ) then
                            group.hasItems = true;
                            if ( subgroup ) then
                                subgroup.hasItems = true;
                                table.insert(subgroup.items, {index=i, name=name});
                            else
                                table.insert(group.items, {index=i, name=name});
                            end
                        end
                    end
                end
            end

            -- build the list
            if ( #groups == 0 ) then
                if ( not extended ) then
                    table.sort(group.items, function(a, b) return a.name < b.name; end);
                end
                for _, v in ipairs(group.items) do
                    table.insert(professionLines, v.index);
                end
            else
                local hasFilter = Armory:HasTradeSkillFilter();
                for i = 1, #groups do
                    if ( groups[i].included and (groups[i].hasItems or not hasFilter) ) then
                        table.insert(professionLines, groups[i].index);
                        if ( groups[i].expanded ) then
                            for _, item in ipairs(groups[i].items) do
                                if ( not item.items or item.hasItems or not hasFilter ) then
                                    table.insert(professionLines, item.index);
                                    if ( item.items and item.expanded ) then
                                        for _, subitem in ipairs(item.items) do
                                            table.insert(professionLines, subitem.index);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            table.wipe(groups);
        end
    end

    dirty = false;
    owner = Armory:SelectedCharacter();
    
    return professionLines;
end

local function UpdateTradeSkillHeaderState(index, isCollapsed)
    local dbEntry = SelectProfession(Armory.selectedDbBaseEntry, selectedSkill);
    if ( dbEntry ) then
        if ( index == 0 ) then
            for i = 1, dbEntry:GetNumValues(itemContainer) do
                local name, skillType = dbEntry:GetValue(itemContainer, i, "Info");
                if ( not IsRecipe(skillType) ) then
                    Armory:SetHeaderLineState(itemContainer..selectedSkill, name, isCollapsed);
                end
            end
        else
            local numLines = Armory:GetNumTradeSkills();
            if ( index > 0 and index <= numLines ) then
                local name = dbEntry:GetValue(itemContainer, professionLines[index], "Info");
                Armory:SetHeaderLineState(itemContainer..selectedSkill, name, isCollapsed);
            end
        end
    end
    dirty = true;
end

local function ClearProfessions()
    local dbEntry = Armory.playerDbBaseEntry;
    if ( dbEntry ) then
        dbEntry:SetValue(container, nil);
        -- recollect minimal required profession data
        Armory:UpdateProfessions();
    end
end

local function SetProfessionValue(name, key, ...)
    local dbEntry = Armory.playerDbBaseEntry;
    if ( dbEntry and name ~= "UNKNOWN" ) then
        dbEntry:SetValue(3, container, name, key, ...);
    end
end

local professionNames = {};
local function SetProfessions(...)
    local dbEntry = Armory.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    table.wipe(professionNames);
    
    if ( dbEntry ) then
        for i = 1, select("#", ...) do
            local id = select(i, ...);
            if ( id ) then
                local name, texture, rank, maxRank, modifier = GetProfessionInfo(id);
                if ( name ) then
                    dbEntry:SetValue(2, container, tostring(i), name);
                    
                    SetProfessionValue(name, "Rank", rank, maxRank, modifier);
                    SetProfessionValue(name, "Texture", texture);

                    professionNames[name] = 1;
                end
            else
                dbEntry:SetValue(2, container, tostring(i), nil);
            end
        end

        -- check if the stored trade skills are still valid    
        local professions = dbEntry:GetValue(container);
        for name in pairs(professions) do
            if ( not tonumber(name) and not professionNames[name] ) then
                Armory:PrintDebug("DELETE profession", name);
                dbEntry:SetValue(2, container, name, nil);
            end
        end
    end
end

local function IsProfession(name, ...)
    local id, profession;
    for i = 1, select("#", ...) do
        id = select(i, ...);
        if ( id ) then
            profession = GetProfessionInfo(id);
            if ( name == profession ) then
                return true;
            end
        end
    end
end

local function IsTradeSkill(name)
    return name and IsProfession(name, GetProfessions());
end

local function GetProfessionValue(key)
    local dbEntry = Armory.selectedDbBaseEntry;
    if ( dbEntry and dbEntry:Contains(container, selectedSkill, key) ) then
        return dbEntry:GetValue(container, selectedSkill, key);
    end
end

local function GetProfessionLineValue(index)
    local dbEntry = Armory.selectedDbBaseEntry;
    local numLines = Armory:GetNumTradeSkills();
    local timestamp;
    if ( dbEntry and index > 0 and index <= numLines ) then
        local info = {};

        info.name, 
        info.type, 
        info.numAvailable = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Info");
        
        if ( IsRecipe(info.type) ) then
            info.difficulty = info.type;
            info.type = "recipe";
        end

        info.icon = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Icon");

        info.cooldown,
        timestamp = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Cooldown");

        if ( info.cooldown ) then
            info.cooldown = info.cooldown - (time() - timestamp);
            if ( info.cooldown <= 0 ) then
                info.cooldown = nil;
            end
        end

        return info;
    end
end

local function PreserveTradeSkillsState(isCraft)
    local state = { subClassFilter=0, invSlotFilter=0, index=isCraft and _G.GetCraftSelectionIndex() or _G.GetTradeSkillSelectionIndex() };

    if ( not isCraft ) then
        local subClasses = { _G.GetTradeSkillSubClasses() };
        local invSlots = { _G.GetTradeSkillInvSlots() };
        for i = 0, #subClasses do
            if ( _G.GetTradeSkillSubClassFilter(i) ) then
                state.subClassFilter = i;
                break;
            end
        end
        for i = 0, #invSlots do
            if ( _G.GetTradeSkillInvSlotFilter(i) ) then
                state.invSlotFilter = i;
                break;
            end
        end

        _G.SetTradeSkillSubClassFilter(0, 1, 1);
        _G.SetTradeSkillInvSlotFilter(0, 1, 1);
    end

    return state;
end

local function RestoreTradeSkillsState(state, isCraft)
    if ( isCraft ) then
        _G.SelectCraft(state.index);
    else
        _G.SetTradeSkillSubClassFilter(state.subClassFilter, 1, 1);
        _G.SetTradeSkillInvSlotFilter(state.invSlotFilter, 1, 1);
        _G.SelectTradeSkill(state.index);
    end
end


----------------------------------------------------------
-- TradeSkills Item Caching
----------------------------------------------------------

local function SetItemCache(dbEntry, profession, link)
    if ( Armory:GetConfigShowCrafters() and not Armory:GetConfigUseEncoding() ) then
        local itemId = Armory:GetItemId(link);
        if ( itemId ) then
            if ( profession ) then
                dbEntry:SetValue(4, container, profession, ARMORY_CACHE_CONTAINER, itemId, 1);
            else
                dbEntry:SetValue(2, ARMORY_CACHE_CONTAINER, itemId, 1);
            end
        end
    end
end

local function ItemIsCached(dbEntry, profession, itemId)
    if ( itemId ) then
        return dbEntry:Contains(container, profession, ARMORY_CACHE_CONTAINER, itemId);
    end
    return false;
end

local function ClearItemCache(dbEntry)
    dbEntry:SetValue(ARMORY_CACHE_CONTAINER, nil);
end

local function ItemCacheExists(dbEntry, profession)
    return dbEntry:Contains(container, profession, ARMORY_CACHE_CONTAINER);
end

----------------------------------------------------------
-- TradeSkills Storage
----------------------------------------------------------

function Armory:ProfessionsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:UpdateProfessions()
    SetProfessions(GetProfessions());
end

function Armory:ClearTradeSkills()
    self:ClearModuleData(container);
    -- recollect minimal required profession data
    self:UpdateProfessions();
    dirty = true;
end

local function GetInvSlot(invType, ...)
    if ( invType and invType ~= "" ) then
        invType = _G[invType];
        for i = 1, select("#", ...) do
            if ( invType == select(i, ...) ) then
                return invType;
            end
        end
    end
    return NONEQUIPSLOT;
end

local function StoreTradeSkillInfo(dbEntry, index, id, isCraft)
    local recipe = dbEntry:SelectContainer(itemContainer, index);
    local reagents = Armory.sharedDbEntry:SelectContainer(container, reagentContainer);

    id = id or index;

    recipe.Icon = isCraft and _G.GetCraftIcon(id) or _G.GetTradeSkillIcon(id);
    recipe.ItemLink = isCraft and _G.GetCraftItemLink(id) or _G.GetTradeSkillItemLink(id);
    
    if ( isCraft ) then
        recipe.SpellFocus = _G.GetCraftSpellFocus(id);
    else
        local invType = recipe.ItemLink and select(4, _G.GetItemInfoInstant(recipe.ItemLink)) or nil;
        recipe.InvSlot = GetInvSlot(invType, _G.GetTradeSkillInvSlots());
        recipe.NumMade = _G.GetTradeSkillNumMade(id);
        recipe.Tools = _G.GetTradeSkillTools(id);

        local cooldown = _G.GetTradeSkillCooldown(id);
        if ( (cooldown and cooldown > 0) ) then
            dbEntry:SetValue(3, itemContainer, index, "Cooldown", cooldown, time());
        else
            dbEntry:SetValue(3, itemContainer, index, "Cooldown", nil);
        end
    end

    local numReagents = isCraft and _G.GetCraftNumReagents(id) or _G.GetTradeSkillNumReagents(id);
    if ( numReagents > 0 ) then
        recipe.Reagents = {};
        for i = 1, numReagents do
            local reagentName, reagentTexture, reagentCount;
            if ( isCraft ) then
                reagentName, reagentTexture, reagentCount = _G.GetCraftReagentInfo(id, i);
            else
                reagentName, reagentTexture, reagentCount = _G.GetTradeSkillReagentInfo(id, i);
            end
            local link = isCraft and _G.GetCraftReagentItemLink(id, i) or _G.GetTradeSkillReagentItemLink(id, i);
            if ( reagentName and link ) then
                local _, id = Armory:GetLinkId(link);
                reagents[id] = dbEntry.Save(reagentName, reagentTexture, link);
                recipe.Reagents[i] = dbEntry.Save(id, reagentCount);
            else
                recipe.Reagents[i] = dbEntry.Save(reagentName, reagentCount);
            end
        end
    end

    SetItemCache(dbEntry, nil, recipe.ItemLink);
       
    return recipe;
end

local function GetSkillInfo(id, isCraft)
    local skillName, subName, skillType, numAvailable, isExpanded;
    if ( isCraft ) then
        skillName, subName, skillType, numAvailable, isExpanded = _G.GetCraftInfo(id);
    else
        skillName, skillType, numAvailable, isExpanded = _G.GetTradeSkillInfo(id);
    end
    return skillName, skillType, numAvailable, isExpanded
end

local function UpdateTradeSkillExtended(dbEntry, isCraft)
    local funcNumLines = isCraft and _G.GetNumCrafts or _G.GetNumTradeSkills;
    local funcGetLineInfo = function(index)
        return GetSkillInfo(index, isCraft);
    end;
    local funcGetLineState = function(index)
        local _, skillType, _, isExpanded = GetSkillInfo(index, isCraft);
        local isHeader = not IsRecipe(skillType);
        return isHeader, isExpanded;
    end;
    local funcExpand = isCraft and _G.ExpandCraftSkillLine or _G.ExpandTradeSkillSubClass;
    local funcCollapse = isCraft and _G.CollapseCraftSkillLine or _G.CollapseTradeSkillSubClass;
    local funcAdditionalInfo = function(index)
        local _, skillType = GetSkillInfo(index, isCraft);
        if ( IsRecipe(skillType) ) then
            StoreTradeSkillInfo(dbEntry, index, nil, isCraft);
        end
    end

    ClearItemCache(dbEntry);

    -- store the complete (expanded) list
    dbEntry:SetExpandableListValues(itemContainer, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse, funcAdditionalInfo);
end

local function UpdateTradeSkillSimple(dbEntry, isCraft)
    dbEntry:ClearContainer(itemContainer);

    ClearItemCache(dbEntry);

    local id = 1;
    local index = 1;
    while ( GetSkillInfo(id, isCraft) ) do
        local skillName, skillType, numAvailable, isExpanded = GetSkillInfo(id, isCraft);
        if ( IsRecipe(skillType) ) then
            dbEntry:SetValue(3, itemContainer, index, "Info", skillName, skillType, numAvailable, isExpanded);
            StoreTradeSkillInfo(dbEntry, index, id, isCraft);
            index = index + 1;
        end
        id = id + 1;
    end
end

function Armory:PullTradeSkillItems(isCraft)
    if ( self:HasTradeSkills() ) then
        local id = 1;
        while ( GetSkillInfo(id, isCraft) ) do
            local _, skillType = GetSkillInfo(id, isCraft);
            if ( IsRecipe(skillType) ) then
                _G.GetItemInfo(isCraft and _G.GetCraftItemLink(id) or _G.GetTradeSkillItemLink(id));
                local numReagents = isCraft and _G.GetCraftNumReagents(id) or _G.GetTradeSkillNumReagents(id);
                for i = 1, numReagents do
                    _G.GetItemInfo(isCraft and _G.GetCraftReagentItemLink(id, i) or _G.GetTradeSkillReagentItemLink(id, i));
                end
            end
            id = id + 1;
        end
    end
end

function Armory:UpdateTradeSkill(isCraft)
    local name, rank, maxRank;
    local modeChanged;
    local warned;
 
    if ( not self.playerDbBaseEntry ) then
        return;
    elseif ( not self:HasTradeSkills() ) then
        ClearProfessions();
        return;
    end

    if ( isCraft ) then
        name, rank, maxRank = _G.GetCraftDisplaySkillLine();
    else
        name, rank, maxRank = _G.GetTradeSkillLine();
    end

    if ( name and name ~= "UNKNOWN" ) then
        if ( not IsTradeSkill(name) ) then
            self:PrintDebug(name, "is not a profession");

        elseif ( not self:IsLocked(itemContainer) ) then
            self:Lock(itemContainer);

            self:PrintDebug("UPDATE", name);
            
            SetProfessionValue(name, "Rank", rank, maxRank);

            local dbEntry = SelectProfession(self.playerDbBaseEntry, name);
            local _, extended = GetProfessionNumValues(dbEntry);
            local success;

            if ( self:GetConfigExtendedTradeSkills() ) then
                if ( not isCraft ) then
                    SetProfessionValue(name, "SubClasses", _G.GetTradeSkillSubClasses());
                    SetProfessionValue(name, "InvSlots", _G.GetTradeSkillInvSlots());
                end
                local state = PreserveTradeSkillsState(isCraft);
                if ( (isCraft and _G.GetNumCrafts() or _G.GetNumTradeSkills()) == 0 ) then
                    extended = true;
                else
                    UpdateTradeSkillExtended(dbEntry, isCraft);
                end
                RestoreTradeSkillsState(state, isCraft);
                modeChanged = not extended;
            else
                UpdateTradeSkillSimple(dbEntry, isCraft);
                modeChanged = extended;
            end

            self:Unlock(itemContainer);
        else
            self:PrintDebug("LOCKED", name);
        end
    elseif ( Armory:GetConfigExtendedTradeSkills() ) then
        self:PrintWarning(ARMORY_TRADE_UPDATE_WARNING);
        warned = true;
    end
    
    if ( warned ) then
        self:PlayWarningSound();
    end

    return name, modeChanged;
end


----------------------------------------------------------
-- TradeSkills Interface
----------------------------------------------------------

function Armory:HasTradeSkillLines(name)
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:GetValue(container, name, itemContainer) ~= nil;
end

function Armory:SetSelectedProfession(name)
    selectedSkill = name;
    dirty = true;
end

function Armory:GetSelectedProfession()
    return selectedSkill;
end

function Armory:GetProfessionTexture(name)
    local dbEntry = self.selectedDbBaseEntry;
    local texture;

    if ( dbEntry and dbEntry:Contains(container, name, "Texture") ) then
        texture = SelectProfession(dbEntry, name):GetValue("Texture");
    end

    -- Note: Sometimes the name cannot be found because it differs from the spellbook (e.g. "Mining" vs "Smelting")
    if ( not texture ) then
        if ( tradeIcons[name] ) then
            texture = "Interface\\Icons\\"..tradeIcons[name];
        else
            texture = "Interface\\Icons\\INV_Misc_QuestionMark";
        end
    end

    return texture;
end

local professionNames = {};
function Armory:GetProfessionNames()
    local dbEntry = self.selectedDbBaseEntry;

    table.wipe(professionNames);
    
    if ( dbEntry ) then
        local data = dbEntry:GetValue(container);
        if ( data ) then
            for name, _ in pairs(data) do
                if ( not tonumber(name) ) then
                    table.insert(professionNames, name);
                end
            end
            table.sort(professionNames);
        end
    end
    
    return professionNames;
end

function Armory:GetNumTradeSkills()
    local dbEntry = self.selectedDbBaseEntry;
    local numSkills, extended, skillType;
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetProfessionLines();
    end
    numSkills = #professionLines;
    if ( numSkills == 0 ) then
        extended = false; --self:GetConfigExtendedTradeSkills();
    elseif ( dbEntry ) then
        _, skillType = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[1], "Info");
        extended = not IsRecipe(skillType);
    end
    return numSkills, extended;
end

function Armory:GetTradeSkillInfo(index)
    local info = GetProfessionLineValue(index);
    if ( info and not IsRecipe(info.type) ) then
        info.collapsed = self:GetHeaderLineState(itemContainer..selectedSkill, info.name);
    end
    return info;
end

function Armory:ExpandTradeSkillSubClass(index)
    UpdateTradeSkillHeaderState(index, false);
end

function Armory:CollapseTradeSkillSubClass(index)
    UpdateTradeSkillHeaderState(index, true);
end

function Armory:SetTradeSkillInvSlotFilter(index)
    self:FillTable(invSlots, self:GetTradeSkillInvSlots());

    if ( (index or 0) == 0 ) then
        tradeSkillInvSlotFilter = nil;
    else
        tradeSkillInvSlotFilter = invSlots[index];
    end

    self:ExpandTradeSkillSubClass(0);
end

function Armory:GetTradeSkillInvSlotFilter()
    return tradeSkillInvSlotFilter;
end

function Armory:SetTradeSkillSubClassFilter(index)
    tradeSkillSubClassFilter = nil;

    if ( (index or 0) ~= 0 ) then
        self:FillTable(subClasses, self:GetTradeSkillSubClasses());
        for i = 1, #subClasses do
            if ( i == index ) then
                tradeSkillSubClassFilter = subClasses[i];
                break;
            end    
        end
    end

    self:ExpandTradeSkillSubClass(0);
end

function Armory:GetTradeSkillSubClassFilter()
    return tradeSkillSubClassFilter;
end

function Armory:SetOnlyShowMakeableRecipes(on)
    local refresh = (onlyShowMakeable ~= on);
    onlyShowMakeable = on;
    if ( refresh ) then
        dirty = true;
    end
    return refresh;
end

function Armory:GetOnlyShowMakeableRecipes()
    return onlyShowMakeable;
end

function Armory:SetOnlyShowSkillUpRecipes(on)
    local refresh = (onlyShowSkillUp ~= on);
    onlyShowSkillUp = on;
    if ( refresh ) then
        dirty = true;
    end
    return refresh;
end

function Armory:GetOnlyShowSkillUpRecipes()
    return onlyShowSkillUp;
end

function Armory:SetTradeSkillItemNameFilter(text)
    local refresh = (tradeSkillFilter ~= text);
    tradeSkillFilter = text;
    if ( refresh ) then
        dirty = true;
    end
    return refresh;
end

function Armory:GetTradeSkillItemNameFilter()
    return tradeSkillFilter;
end

function Armory:SetTradeSkillItemLevelFilter(minLevel, maxLevel)
    local refresh = (tradeSkillMinLevel ~= minLevel or tradeSkillMaxLevel ~= maxLevel);
    tradeSkillMinLevel = max(0, minLevel);
    tradeSkillMaxLevel = max(0, maxLevel);
    if ( refresh ) then
        dirty = true;
    end
    return refresh;
end

function Armory:GetTradeSkillItemLevelFilter()
    return tradeSkillMinLevel, tradeSkillMaxLevel;
end

function Armory:GetTradeSkillItemFilter(text)
    if ( not text ) then
        text = tradeSkillItemNameFilter or "";
    end
    
    local minLevel, maxLevel;
    local approxLevel = strmatch(text, "^~(%d+)");
    if ( approxLevel ) then
        minLevel = approxLevel - 2;
        maxLevel = approxLevel + 2;
    else
        minLevel, maxLevel = strmatch(text, "^(%d+)%s*-*%s*(%d*)$");
    end
    if ( minLevel ) then
        if ( maxLevel == "" or maxLevel < minLevel ) then
            maxLevel = minLevel;
        end
        text = "";
    else
        minLevel = 0;
        maxLevel = 0;
    end

    return text, minLevel, maxLevel;
end

function Armory:HasTradeSkillFilter()
    if ( onlyShowMakeable ) then
        return true;
    elseif ( onlyShowSkillUp ) then
        return true;
    elseif ( tradeSkillSubClassFilter ) then
        return true;
    elseif ( tradeSkillInvSlotFilter ) then
        return true;
    elseif ( tradeSkillMinLevel > 0 and tradeSkillMaxLevel > 0 ) then
        return true;
    elseif ( tradeSkillFilter ~= "" ) then
        return true;
    end
    return false;
end

function Armory:GetTradeSkillLine()
    if ( selectedSkill ) then
        local rank, maxRank, modifier = GetProfessionValue("Rank");
        return selectedSkill, rank, maxRank, (modifier or 0);
    else
        return "UNKNOWN", 0, 0, 0;
    end
end

function Armory:GetFirstTradeSkill()
    local numLines = self:GetNumTradeSkills();
    for i = 1, numLines do
        local info = self:GetTradeSkillInfo(i);
        if ( IsRecipe(info.type) ) then
            return i;
        end
    end
    return 0;
end

function Armory:GetTradeSkillSubClasses()
    return GetProfessionValue("SubClasses");
end

function Armory:GetTradeSkillInvSlots()
    return GetProfessionValue("InvSlots");
end

function Armory:GetTradeSkillCooldown(index)
    local info = GetProfessionLineValue(index);
    return info.cooldown;
end

function Armory:GetTradeSkillNumMade(index)
    local minMade, maxMade = GetRecipeValue(index, "NumMade");
    return minMade or 0, maxMade or 0;
end

function Armory:GetTradeSkillNumReagents(index)
    return GetNumReagents(index);
end

function Armory:GetTradeSkillTools(index)
    return GetRecipeValue(index, "Tools") or "";
end

function Armory:GetTradeSkillItemLink(index)
    return GetRecipeValue(index, "ItemLink");
end

function Armory:GetTradeSkillSpellFocus(index)
    return GetRecipeValue(index, "SpellFocus");
end

function Armory:GetTradeSkillReagentInfo(index, id)
    return GetReagentInfo(index, id);
end

function Armory:GetTradeSkillReagentItemLink(index, id)
    local _, _, _, link = self:GetTradeSkillReagentInfo(index, id);
    return link;
end

local primarySkills = {};
function Armory:GetPrimaryTradeSkills()
    local dbEntry = self.selectedDbBaseEntry;
    local skillName, skillRank, skillMaxRank, skillModifier;

    table.wipe(primarySkills);

    if ( dbEntry ) then
        for i = 1, 2 do
            skillName = dbEntry:GetValue(container, tostring(i));
            if ( skillName ) then
                skillRank, skillMaxRank, skillModifier = dbEntry:GetValue(container, skillName, "Rank");
                table.insert(primarySkills, {skillName, skillRank, skillMaxRank});
            end
        end
    end
            
    return primarySkills;
end

function Armory:GetTradeSkillRank(profession)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        local rank, maxRank = dbEntry:GetValue(container, profession, "Rank");
        return rank, maxRank;
    end
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindSkill(itemList, ...)
    local dbEntry = self.selectedDbBaseEntry;
    local list = itemList or {};

    if ( dbEntry ) then
        -- need low-level access because of all the possible active filters
        local professions = dbEntry:GetValue(container);
        if ( professions ) then
            local text, link, skillName, skillType, slotInfo;
            for name in pairs(professions) do
                for i = 1, dbEntry:GetNumValues(container, name, itemContainer) do
                    skillName, skillType = dbEntry:GetValue(container, name, itemContainer, i, "Info");
                    if ( IsRecipe(skillType) ) then
                        link = dbEntry:GetValue(container, name, itemContainer, i, "ItemLink");
                        if ( link and self:GetConfigExtendedSearch() ) then
                            text = self:GetTextFromLink(link);
                        else
                            text = skillName;
                        end
                        if ( self:FindTextParts(text, ...) ) then
                            slotInfo = strjoin(", ", dbEntry:GetValue(container, name, itemContainer, i, "InvSlot"));
                            if ( slotInfo ) then
                                skillName = skillName .. " ("..slotInfo..")";
                            end
                            table.insert(list, {label=name, name=skillName, link=link});
                        end
                    end
                end
            end
        end
    end

    return list;
end

local recipeOwners = {};
function Armory:GetRecipeOwners(id)
    table.wipe(recipeOwners);

    if ( self:HasTradeSkills() and self:GetConfigShowKnownBy() ) then
        local currentProfile = self:CurrentProfile();

        for _, profile in ipairs(self:GetConnectedProfiles()) do
            self:SelectProfile(profile);

            local dbEntry = self.selectedDbBaseEntry;
            if ( dbEntry:Contains(container) ) then
                local data = dbEntry:SelectContainer(container);
                for profession in pairs(data) do
                    if ( dbEntry:Contains(container, profession, id) ) then
                        table.insert(recipeOwners, self:GetQualifiedCharacterName());
                        break;
                    end
                end
            end
        end
        self:SelectProfile(currentProfile);
    end

    return recipeOwners;
end

local function AddKnownBy()
    if ( Armory:GetConfigShowKnownBy() and not Armory:IsPlayerSelected() ) then
        table.insert(recipeOwners, Armory:GetQualifiedCharacterName());
    end
end

local recipeCanLearn = {};
local function AddCanLearn(name)
    if ( Armory:GetConfigShowCanLearn() ) then
        table.insert(recipeCanLearn, name);
    end
end

local recipeHasSkill = {};
local function AddHasSkill(name)
    if ( Armory:GetConfigShowHasSkill() ) then
        table.insert(recipeHasSkill, name);
    end
end

function Armory:GetRecipeAltInfo(name, link, profession, reqProfession, reqRank, reqReputation, reqStanding, reqSkill)
    table.wipe(recipeOwners);
    table.wipe(recipeHasSkill);
    table.wipe(recipeCanLearn);

	if ( name and name ~= "" and self:HasTradeSkills() and (self:GetConfigShowKnownBy() or self:GetConfigShowHasSkill() or self:GetConfigShowCanLearn()) ) then
        local currentProfile = self:CurrentProfile();
        local skillItemID, skillName, dbEntry, character;

        local recipeID = self:GetItemId(link);
        local spellID, itemID = LR:GetRecipeInfo(recipeID); itemID = itemID or spellID;
        local warn = not itemID;

        for _, profile in ipairs(self:GetConnectedProfiles()) do
            self:SelectProfile(profile);

            dbEntry = self.selectedDbBaseEntry;
            
            local known;
            for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                skillItemID = tonumber(select(2, self:GetLinkId(dbEntry:GetValue(container, profession, itemContainer, i, "ItemLink"))));
                if ( skillItemID ) then
                    if ( itemID ) then
                        known = itemID == skillItemID;
                    else
                        skillName = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                        known = IsSameRecipe(skillName, name, GetRecipeValue(i, "InvSlot"));
                    end
                    if ( known ) then
                        warn = false;
                        AddKnownBy();
                        break;
                    end
                end
            end

            if ( not known and dbEntry:Contains(container, profession) and (self:GetConfigShowHasSkill() or self:GetConfigShowCanLearn()) ) then
				local character = self:GetQualifiedCharacterName();
                local skillName, subSkillName, standingID, standing;
                local rank = dbEntry:GetValue(container, profession, "Rank");
                local learnable = reqRank <= rank;
                local attainable = not learnable;
                local unknown = false;

                if ( reqSkill or reqReputation ) then
                    local isValid = reqSkill == nil;
                    if ( reqSkill ) then
                        for i = 1, 5 do
                            skillName, subSkillName = dbEntry:GetValue(container, tostring(i));
                            if ( skillName == profession ) then
                                isValid = reqSkill == skillName or reqSkill == subSkillName;
                                break;
                            end
                        end
                    end
                    if ( not isValid ) then
                        learnable = false;
                        attainable = false;
                    elseif ( reqReputation ) then
                        if ( not self:HasReputation() ) then
                            unknown = true;
                        else
                            standingID, standing = self:GetFactionStanding(reqReputation);
                            if ( learnable ) then
                                learnable = reqStanding <= standingID;
                                attainable = not learnable;
                            end
                        end
                    end
                end

                if ( unknown ) then
                    AddCanLearn(character.." (?)");
                elseif ( attainable ) then
                    character = character.." ("..rank;
                    if ( reqReputation ) then
                        character = character.."/"..standing;
                    end
                    character = character..")";
                    AddHasSkill(character);
                elseif ( learnable ) then
                    AddCanLearn(character);
                end
            end
        end
        self:SelectProfile(currentProfile);

        if ( warn ) then
            self:PrintWarning(format(ARMORY_RECIPE_WARNING, recipeID));
        end
    end

    return recipeOwners, recipeHasSkill, recipeCanLearn;
end

local cooldowns = {};
function Armory:GetTradeSkillCooldowns(dbEntry)
    table.wipe(cooldowns);

    if ( dbEntry and self:HasTradeSkills() ) then
        local professions = dbEntry:GetValue(container);
        if ( professions ) then
            local cooldown, timestamp, skillName;
            for profession in pairs(professions) do
                for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                    cooldown, timestamp = dbEntry:GetValue(container, profession, itemContainer, i, "Cooldown");
                    if ( cooldown ) then
                        cooldown = self:MinutesTime(cooldown + timestamp, true);
                        if ( cooldown > time() ) then
                            skillName = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                            if ( skillName:find(ARMORY_TRANSMUTE) ) then
                                skillName = ARMORY_TRANSMUTE;
                            end
                            table.insert(cooldowns, {skill=skillName, time=cooldown});
                        end
                    end
                end
            end
        end
    end

    return cooldowns;
end

function Armory:CheckTradeSkillCooldowns()
    local currentProfile = self:CurrentProfile();
    local cooldowns, cooldown, name;
    local total = 0;
    for _, profile in ipairs(self:Profiles()) do
        self:SelectProfile(profile);
        name = self:GetQualifiedCharacterName(true);
        cooldowns = self:GetTradeSkillCooldowns(self.selectedDbBaseEntry);
        for _, v in ipairs(cooldowns) do
            cooldown = SecondsToTime(v.time - time(), true, true);
            self:PrintTitle(format("%s (%s) %s %s", v.skill, name, COOLDOWN_REMAINING, cooldown));
            total = total + 1;
        end
    end
    self:SelectProfile(currentProfile);
    if ( total == 0 ) then
        self:PrintRed(ARMORY_CHECK_CD_NONE);
    end
end

local crafters = {};
function Armory:GetCrafters(itemId)
    table.wipe(crafters);

    if ( itemId and self:HasTradeSkills() and self:GetConfigShowCrafters() ) then
        local currentProfile = self:CurrentProfile();
        local dbEntry, buildCache, found, id, link;
        local character;

        for _, profile in ipairs(self:GetConnectedProfiles()) do
            self:SelectProfile(profile);

            dbEntry = self.selectedDbBaseEntry;
            if ( dbEntry:Contains(container) ) then
				character = self:GetQualifiedCharacterName();
                found = false;

                for profession in pairs(dbEntry:GetValue(container)) do
                    if ( not ItemCacheExists(dbEntry, profession) ) then
                        for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                            link = GetRecipeValue(i, "ItemLink");
                            SetItemCache(dbEntry, profession, link);
                            if ( itemId == self:GetItemId(link) ) then
                                table.insert(crafters, character);
                                if ( self:GetConfigUseEncoding() ) then
                                    found = true;
                                    break;
                                end
                            end
                        end
                        if ( found ) then
                            break;
                        end
                    elseif ( ItemIsCached(dbEntry, profession, itemId) ) then
                        table.insert(crafters, character);
                    end
                end
            end
        end
        self:SelectProfile(currentProfile);
    end

    return crafters;
end


----------------------------------------------------------
-- API Methods
----------------------------------------------------------

local registeredAddOns = {};
function Armory:RegisterTradeSkillAddOn(addOnName, unregisterUpdateEvents, registerUpdateEvents)
    assert(type(addOnName) == "string", "Bad argument #1 to 'RegisterTradeSkillAddOn' (string expected)");
    assert(type(unregisterUpdateEvents) == "function", "Bad argument #2 to 'RegisterTradeSkillAddOn' (function expected)");
    assert(type(registerUpdateEvents) == "function", "Bad argument #3 to 'RegisterTradeSkillAddOn' (function expected)");
    if ( not registeredAddOns[addOnName] ) then
        registeredAddOns[addOnName] = {};
    end
    registeredAddOns[addOnName].unregisterUpdateEvents = unregisterUpdateEvents;
    registeredAddOns[addOnName].registerUpdateEvents = registerUpdateEvents;
end

function Armory:UnregisterTradeSkillUpdateEvents()
    for _, addOn in pairs(registeredAddOns) do
        pcall(addOn.unregisterUpdateEvents);
    end
end

function Armory:RegisterTradeSkillUpdateEvents()
    for _, addOn in pairs(registeredAddOns) do
        pcall(addOn.registerUpdateEvents);
    end
end
