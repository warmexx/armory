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
local LR = LibStub("LibRecipes-2.0");

local container = "Professions";
local itemContainer = "SkillLines";
local recipeContainer = "Recipes";
local reagentContainer = "Reagents";
local rankContainer = "Ranks";

local selectedSkill;

local tradeSkillSubClassFilter = {};
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
tradeIcons[ARMORY_TRADE_JEWELCRAFTING] = "INV_Misc_Gem_01";
tradeIcons[ARMORY_TRADE_LEATHERWORKING] = "Trade_LeatherWorking";
tradeIcons[ARMORY_TRADE_MINING] = "Trade_Mining";
tradeIcons[ARMORY_TRADE_POISONS] = "Trade_BrewPoison";
tradeIcons[ARMORY_TRADE_SKINNING] = "INV_Weapon_ShortBlade_01";
tradeIcons[ARMORY_TRADE_TAILORING] = "Trade_Tailoring";
tradeIcons[ARMORY_TRADE_INSCRIPTION] = "INV_Inscription_Tradeskill01";

----------------------------------------------------------
-- TradeSkills Internals
----------------------------------------------------------

local professionLines = {};
local dirty = true;
local owner = "";
local invSlot = {};

local function GetRecipeValue(id, ...)
    return Armory:GetSharedValue(container, recipeContainer, id, ...);
end

local function GetNumReagents(id)
    return Armory:GetSharedNumValues(container, recipeContainer, id, "Reagents");
end

local function GetReagentInfo(id, index)
    local recipeID, count = GetRecipeValue(id, "Reagents", index);
    local name, texture, link = Armory:GetSharedValue(container, reagentContainer, recipeID);
    return name, texture, count, link;
end

local function IsRecipe(skillType)
    return skillType and skillType ~= "header" and skillType ~= "subheader";
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

local function CanCraftFromInventory(recipeID)
    if ( not Armory:HasInventory() ) then
        return false;
    end

    local numReagents = GetNumReagents(recipeID);
    if ( (numReagents or 0) == 0 ) then
        return false;
    end
    
    for i = 1, numReagents do
        local _, _, count, link = GetReagentInfo(recipeID, i);
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
    local name, id, skillType, numAvailable, difficulty, disabled, categoryID, isExpanded;
    local subgroup;

    table.wipe(professionLines);

    if ( dbEntry and dbEntry:Contains(container, selectedSkill, itemContainer) ) then
        dbEntry = SelectProfession(dbEntry, selectedSkill)

        numLines, extended = GetProfessionNumValues(dbEntry);
        if ( numLines > 0 ) then
            table.wipe(groups);
             
            -- apply filters
            for i = 1, numLines do
                name, skillType, numAvailable,  _, _, _, _, _, difficulty, _, _, _, _, disabled, _, categoryID = dbEntry:GetValue(itemContainer, i, "Info");
                id = dbEntry:GetValue(itemContainer, i, "Data");
                isExpanded = not Armory:GetHeaderLineState(itemContainer..selectedSkill, name);
                if ( skillType == "header" or (i == 1 and skillType == "subheader") ) then
                    if ( #tradeSkillSubClassFilter > 1 ) then
                        isIncluded = false;
                        for j = 2, #tradeSkillSubClassFilter do
                            if ( tradeSkillSubClassFilter[j] == categoryID ) then
                                isIncluded = true;
                                break;
                            end
                        end 
                    else
                        isIncluded = true;
                    end
                    group = { index=i, expanded=isExpanded, included=isIncluded, items={} };
                    subgroup = nil;
                    table.insert(groups, group);
                elseif ( group.included ) then
                    if ( skillType == "subheader" ) then
                        subgroup = { index=i, expanded=isExpanded, items={} };
                        table.insert(group.items, subgroup);
                    else
                        numReagents = GetNumReagents(id);
                        names = name or "";
                        for index = 1, numReagents do
                            names = names.."\t"..(GetReagentInfo(id, index) or "");
                        end

                        if ( #tradeSkillSubClassFilter == 3 ) then
                            isIncluded = tradeSkillSubClassFilter[3] == categoryID;
                        elseif ( #tradeSkillSubClassFilter == 2 ) then
                            isIncluded = tradeSkillSubClassFilter[2] == categoryID;
                        elseif ( #tradeSkillSubClassFilter > 1 ) then
                            isIncluded = false;
                            for j = 2, #tradeSkillSubClassFilter do
                                if ( tradeSkillSubClassFilter[j] == categoryID ) then
                                    isIncluded = true;
                                    break;
                                end
                            end 
                        else
                            isIncluded = true;
                        end
                        if ( isIncluded and tradeSkillInvSlotFilter ) then
                            isIncluded = false;
                            Armory:FillUnbrokenTable(invSlot, GetRecipeValue(id, "InvSlot"));
                            for _, slot in ipairs(invSlot) do
                                if ( tradeSkillInvSlotFilter == slot ) then
                                    isIncluded = true;
                                    break;
                                end
                            end
                        end
                        if ( isIncluded and onlyShowMakeable ) then
                            if ( (numAvailable or 0) > 0 ) then
                                isIncluded = true;
                            else
                                isIncluded = CanCraftFromInventory(id);
                            end
                        end
                        if ( isIncluded and onlyShowSkillUp ) then
                            isIncluded = difficulty and difficulty ~= "trivial" and difficulty ~= "nodifficulty";
                        end
                        if ( isIncluded and tradeSkillMinLevel > 0 and tradeSkillMaxLevel > 0 ) then
                            _, _, _, _, itemMinLevel = _G.GetItemInfo(GetRecipeValue(id, "ItemLink"));
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
                local name, texture, rank, maxRank, numSpells, offset, _, modifier = _G.GetProfessionInfo(id);
                local additive;
                if ( name ) then
                    if ( i <= 2 and numSpells == 2 and not _G.IsPassiveSpell(offset + 2, BOOKTYPE_PROFESSION) ) then
                        local spellName, subSpellName = _G.GetSpellBookItemName(offset + 2, BOOKTYPE_PROFESSION);
                        if ( (subSpellName or "") == "" ) then
                            additive = spellName;
                        end
                    end
                    dbEntry:SetValue(2, container, tostring(i), name, additive);
                    
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
    return name and IsProfession(name, _G.GetProfessions());
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
        local info = {
            recipeID = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Data")
        };

        info.name, 
        info.type, 
        info.numAvailable,
        info.alternateVerb,
        info.numSkillUps, 
        info.numIndents, 
        info.icon, 
        info.sourceType, 
        info.difficulty, 
        info.hasProgressBar, 
        info.skillLineCurrentLevel, 
        info.skillLineMaxLevel, 
        info.skillLineStartingRank, 
        info.disabled, 
        info.disabledReason, 
        info.categoryID,
        info.productQuality,
        info.currentRank,
        info.totalRanks = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Info");
        
        info.cooldown, 
        info.isDayCooldown, 
        timestamp, 
        info.charges, 
        info.maxCharges = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Cooldown");

        if ( info.cooldown ) then
            info.cooldown = info.cooldown - (time() - timestamp);
            if ( info.cooldown <= 0 ) then
                info.cooldown = nil;
                info.isDayCooldown = nil;
            end
        end

        return info;
    end
end

local function PreserveTradeSkillsState()
    local editBox = TradeSkillFrame.SearchBox;
    local state = { sourceTypeFilter={}, categoryFilter={}, invSlotFilter=-1, collapsed={} };
    
    if ( TradeSkillFrame.RecipeList.collapsedCategories ) then
        Armory:CopyTable(TradeSkillFrame.RecipeList.collapsedCategories, state.collapsed);
        table.wipe(TradeSkillFrame.RecipeList.collapsedCategories);
    end

    state.learned = C_TradeSkillUI.GetOnlyShowLearnedRecipes();

    if ( TradeSkillFrame.filterTbl ) then
        state.makeable = C_TradeSkillUI.GetOnlyShowMakeableRecipes();
        state.skillups = C_TradeSkillUI.GetOnlyShowSkillUpRecipes();
    
        if ( C_TradeSkillUI.AreAnyInventorySlotsFiltered() ) then
            for i = 1, table.getn(C_TradeSkillUI.GetAllFilterableInventorySlots()) do
                if ( not C_TradeSkillUI.IsInventorySlotFiltered(i) ) then
                     state.invSlotFilter = i;
                     break;
                end
            end
        end

        if ( C_TradeSkillUI.AnyRecipeCategoriesFiltered() ) then
            for _, categoryID in ipairs(C_TradeSkillUI.GetCategories()) do
                for _, subCategoryID in ipairs(C_TradeSkillUI.GetSubCategories(categoryID)) do
                    if ( not C_TradeSkillUI.IsRecipeCategoryFiltered(categoryID, subCategoryID) ) then
                        state.categoryFilter = { categoryID, subCategoryID };
                        break;
                    end
                end
                if ( table.getn(state.categoryFilter) == 0 and not C_TradeSkillUI.IsRecipeCategoryFiltered(categoryID) ) then
                    state.categoryFilter = { categoryID };
                    break;
                end
            end
        end

        local numSources = C_PetJournal.GetNumPetSources();
        for i = 1, numSources do
            if ( C_TradeSkillUI.IsAnyRecipeFromSource(i) and C_TradeSkillUI.IsRecipeSourceTypeFiltered(i) ) then
                table.insert(state.sourceTypeFilter, i);
            end
        end
    end
    if ( editBox ) then
        state.text, state.minLevel, state.maxLevel = Armory:GetTradeSkillItemFilter(editBox:GetText());
    end
    if ( (state.minLevel or 0) ~= 0 or (state.maxLevel or 0) ~= 0 ) then
        C_TradeSkillUI.SetRecipeItemLevelFilter(0, 0);
    end
    if ( state.text and state.text ~= "" ) then
        C_TradeSkillUI.SetRecipeItemNameFilter(nil);
    end
    
    C_TradeSkillUI.ClearInventorySlotFilter();
    C_TradeSkillUI.ClearRecipeCategoryFilter();
    C_TradeSkillUI.ClearRecipeSourceTypeFilter();
    C_TradeSkillUI.SetOnlyShowMakeableRecipes(false);
    C_TradeSkillUI.SetOnlyShowSkillUpRecipes(false);
	C_TradeSkillUI.SetOnlyShowLearnedRecipes(true);
	C_TradeSkillUI.SetOnlyShowUnlearnedRecipes(false);

    if ( not TradeSkillFrame.RecipeList.collapsedCategories ) then
        TradeSkillFrame.RecipeList.collapsedCategories = {};
    end
    TradeSkillFrame.RecipeList:RebuildDataList();

    return state;
end

local function RestoreTradeSkillsState(state)
    if ( TradeSkillFrame.RecipeList.collapsedCategories ) then
        TradeSkillFrame.RecipeList.collapsedCategories = state.collapsed;
    end
    
	C_TradeSkillUI.SetOnlyShowLearnedRecipes(state.learned);
	C_TradeSkillUI.SetOnlyShowUnlearnedRecipes(not state.learned);

    if ( (state.minLevel or 0) ~= 0 or (state.maxLevel or 0) ~= 0 ) then
        C_TradeSkillUI.SetRecipeItemLevelFilter(state.minLevel, state.maxLevel);
    end
    if ( state.text and state.text ~= "" ) then
        C_TradeSkillUI.SetRecipeItemNameFilter(state.text);
    end
    if ( state.makeable ) then
        C_TradeSkillUI.SetOnlyShowMakeableRecipes(state.makeable);
    end
    if ( state.skillups ) then
        C_TradeSkillUI.SetOnlyShowSkillUpRecipes(state.skillups);
    end
    
    -- just in case...
    local categoryID, subCategoryID = unpack(state.categoryFilter);
    if ( categoryID ) then
        C_TradeSkillUI.SetRecipeCategoryFilter(categoryID, subCategoryID);
    end
    if ( state.invSlotFilter > 0 ) then
        C_TradeSkillUI.SetInventorySlotFilter(state.invSlotFilter, true, true);
    end
    for i = 1, table.getn(state.sourceTypeFilter) do
        C_TradeSkillUI.SetRecipeSourceTypeFilter(i, true);
    end
    
    TradeSkillFrame.RecipeList:RebuildDataList();
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
    SetProfessions(_G.GetProfessions());
end

function Armory:ClearTradeSkills()
    self:ClearModuleData(container);
    -- recollect minimal required profession data
    self:UpdateProfessions();
    dirty = true;
end

local function StoreTradeSkillInfo(dbEntry, recipeID, index)
    local skillLineID, skillLineName = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID);
    if ( skillLineName and not dbEntry:Contains(rankContainer, skillLineName) ) then
        local _, skillLineRank = C_TradeSkillUI.GetTradeSkillLineInfoByID(skillLineID);
        dbEntry:SetValue(2, rankContainer, skillLineName, skillLineRank);
    end

    local recipe = Armory.sharedDbEntry:SelectContainer(container, recipeContainer, tostring(recipeID));
    local reagents = Armory.sharedDbEntry:SelectContainer(container, reagentContainer);

    recipe.RecipeLink = C_TradeSkillUI.GetRecipeLink(recipeID);
    recipe.Description = C_TradeSkillUI.GetRecipeDescription(recipeID);
    recipe.Tools = Armory:BuildColoredListString(C_TradeSkillUI.GetRecipeTools(recipeID));
    recipe.NumMade = dbEntry.Save(C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID));
    recipe.ItemLink = C_TradeSkillUI.GetRecipeItemLink(recipeID);
    
    local numReagents = C_TradeSkillUI.GetRecipeNumReagents(recipeID);
    if ( numReagents > 0 ) then
        recipe.Reagents = {};
        for i = 1, numReagents do
            local reagentName, reagentTexture, reagentCount, playerReagentCount = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, i);
            link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, i);
            if ( reagentName and link ) then
                local _, id = Armory:GetLinkId(link);
                reagents[id] = dbEntry.Save(reagentName, reagentTexture, link);
                recipe.Reagents[i] = dbEntry.Save(id, reagentCount);
            end
        end
    end

    local cooldown, isDayCooldown, charges, maxCharges = C_TradeSkillUI.GetRecipeCooldown(recipeID);

    -- HACK: when a cd is activated it will return 00:00, but after a relog it suddenly becomes 03:00
    if ( cooldown and isDayCooldown ) then
        cooldown = _G.GetQuestResetTime();
    end
    
    if ( (cooldown and cooldown > 0) or (maxCharges and maxCharges > 0) ) then
        dbEntry:SetValue(3, itemContainer, index, "Cooldown", cooldown, isDayCooldown, time(), charges, maxCharges);
    else
        dbEntry:SetValue(3, itemContainer, index, "Cooldown", nil);
    end

    SetItemCache(dbEntry, nil, recipe.ItemLink);
       
    return recipe;
end

local function StoreSharedTradeSkillInfo(name)
    Armory:SetSharedValue(3, container, name, "InvSlots", C_TradeSkillUI.GetAllFilterableInventorySlots());

    local categories = { C_TradeSkillUI.GetCategories() };
    for i, categoryID in ipairs(categories) do
        local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryID);
        Armory:SetSharedValue(4, container, name, "SubClasses", i, categoryID, categoryData.name);
        
        if ( select("#", C_TradeSkillUI.GetSubCategories(categoryID)) > 0 ) then
            local subCategories = { C_TradeSkillUI.GetSubCategories(categoryID) };
            for j, subCategoryID in ipairs(subCategories) do
                local subCategoryData = C_TradeSkillUI.GetCategoryInfo(subCategoryID);
               Armory:SetSharedValue(6, container, name, "SubClasses", i, "SubClasses", j, subCategoryID, subCategoryData.name);
            end
        end
    end
end

local function GetNumTradeSkills()
    return table.getn(TradeSkillFrame.RecipeList.dataList);
end

local function GetTradeSkillLineInfo(info)
    if ( IsRecipe(info.type) and not info.currentRank ) then
        info.currentRank = 1;
        do
            local previousRecipeID = info.previousRecipeID;
            while ( previousRecipeID ) do
                info.currentRank = info.currentRank + 1;
                local previousRecipeInfo = C_TradeSkillUI.GetRecipeInfo(previousRecipeID);
                previousRecipeID = previousRecipeInfo.previousRecipeID;
            end
        end
        info.totalRanks = info.currentRank;
        do
            local nextRecipeID = info.nextRecipeID;
            while ( nextRecipeID ) do
                info.totalRanks = info.totalRanks + 1;
                local nextRecipeInfo = C_TradeSkillUI.GetRecipeInfo(nextRecipeID);
                nextRecipeID = nextRecipeInfo.nextRecipeID;
            end
        end
    end

    return 
        info.name, 
        info.type, 
        info.numAvailable,
        info.alternateVerb, 
        info.numSkillUps, 
        info.numIndents, 
        info.icon, 
        info.sourceType, 
        info.difficulty, 
        info.hasProgressBar, 
        info.skillLineCurrentLevel, 
        info.skillLineMaxLevel, 
        info.skillLineStartingRank, 
        info.disabled, 
        info.disabledReason, 
        info.categoryID,
        info.productQuality,
        info.currentRank,
        info.totalRanks;
end

local invSlotTypes = {};
local recipeIDs;
local function UpdateTradeSkillExtended(dbEntry)
    -- retrieve slot types (would be to time consuming if put in funcAdditionalInfo)
    Armory:FillTable(invSlots, C_TradeSkillUI.GetAllFilterableInventorySlots());
    table.wipe(invSlotTypes);
    for i = 1, #invSlots do
        local slot = invSlots[i];
        C_TradeSkillUI.SetInventorySlotFilter(i, true, true);

        recipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs(recipeIDs);
        for _, recipeID in ipairs(recipeIDs) do
            if ( invSlotTypes[recipeID] ) then
                table.insert(invSlotTypes[recipeID], slot);
            else
                invSlotTypes[recipeID] = {slot};
            end
        end
        
        C_TradeSkillUI.ClearInventorySlotFilter();
    end

    local funcNumLines = GetNumTradeSkills;
    local funcGetLineInfo = function(index)
        local info = TradeSkillFrame.RecipeList.dataList[index];
        return GetTradeSkillLineInfo(info);
    end;
    local funcGetLineState = function(index)
        local info = TradeSkillFrame.RecipeList.dataList[index];
        local isHeader = not IsRecipe(info.type);
        return isHeader, true;
    end;
    local funcAdditionalInfo = function(index)
        local info = TradeSkillFrame.RecipeList.dataList[index];
        local spell = Spell:CreateFromSpellID(info.recipeID);
        spell:ContinueOnSpellLoad(function()
            local recipe = StoreTradeSkillInfo(dbEntry, info.recipeID, index);
            if ( invSlotTypes[info.recipeID] ) then
                recipe.InvSlot = dbEntry.Save(unpack(invSlotTypes[info.recipeID]));
            end
        end);
        return tostring(info.recipeID);
    end
    
    ClearItemCache(dbEntry);

    -- store the complete (expanded) list
    dbEntry:SetExpandableListValues(itemContainer, funcNumLines, funcGetLineState, funcGetLineInfo, nil, nil, funcAdditionalInfo);
    
    table.wipe(invSlotTypes);
end

local function UpdateTradeSkillSimple(dbEntry)
    dbEntry:ClearContainer(itemContainer);

    ClearItemCache(dbEntry);
    
    local index = 1;
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs();
    for _, recipeID in ipairs(recipeIDs) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID);
        if ( info.learned and IsRecipe(info.type) ) then
            local spell = Spell:CreateFromSpellID(recipeID);
            spell:ContinueOnSpellLoad(function()
                StoreTradeSkillInfo(dbEntry, recipeID, index);
            end);
            dbEntry:SetValue(3, itemContainer, index, "Info", GetTradeSkillLineInfo(info));
            dbEntry:SetValue(3, itemContainer, index, "Data", tostring(recipeID));

            index = index + 1;
        end
    end
end

function Armory:PullTradeSkillItems()
    if ( self:HasTradeSkills() ) then
        local info, numReagents;
        local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs();
        for _, recipeID in ipairs(recipeIDs) do
            info = C_TradeSkillUI.GetRecipeInfo(recipeID);
            if ( info.name and info.learned and IsRecipe(info.type) ) then
                C_TradeSkillUI.GetRecipeItemLink(recipeID);
                numReagents = C_TradeSkillUI.GetRecipeNumReagents(recipeID);
                for i = 1, numReagents do
                    C_TradeSkillUI.GetRecipeReagentInfo(recipeID, i);
                    C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, i);
                end
            end
        end 
    end
end

function Armory:UpdateTradeSkill()
    local name, rank, maxRank;
    local modeChanged;
    local warned;
    
    if ( not self.playerDbBaseEntry ) then
        return;
    elseif ( not self:HasTradeSkills() ) then
        ClearProfessions();
        return;
    end

    tradeSkillID, _, rank, maxRank, modifier, _, name = C_TradeSkillUI.GetTradeSkillLine();

    if ( name and name ~= "UNKNOWN" ) then
        if ( not IsTradeSkill(name) ) then
            self:PrintDebug(name, "is not a profession");

        elseif ( not self:IsLocked(itemContainer) ) then
            self:Lock(itemContainer);

            self:PrintDebug("UPDATE", name);
            
            SetProfessionValue(name, "Rank", rank, maxRank, modifier);

            StoreSharedTradeSkillInfo(name);
 
            local dbEntry = SelectProfession(self.playerDbBaseEntry, name);
            local _, extended = GetProfessionNumValues(dbEntry);
            local success;

            if ( self:GetConfigExtendedTradeSkills() ) then
                local state = PreserveTradeSkillsState();
                if ( GetNumTradeSkills() == 0 ) then
                    extended = true;
                else
                    UpdateTradeSkillExtended(dbEntry);
                end
                RestoreTradeSkillsState(state);
                modeChanged = not extended;
            else
                UpdateTradeSkillSimple(dbEntry);
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

    return name, modeChanged, hasCooldown;
end

----------------------------------------------------------
-- TradeSkills Hooks
----------------------------------------------------------

hooksecurefunc(C_TradeSkillUI, "SetRecipeItemNameFilter", function(text)
    if ( not Armory:IsLocked(itemContainer) ) then
        tradeSkillItemNameFilter = text;
    end
end);

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

function Armory:SetTradeSkillSubClassFilter(categoryID, subCategoryID)
    local subClasses = self:GetTradeSkillSubClasses();

    table.wipe(tradeSkillSubClassFilter);
    
    for _, categoryData in ipairs(subClasses) do
        if ( categoryData.id == categoryID ) then
            tradeSkillSubClassFilter[1] = categoryData.name;
            tradeSkillSubClassFilter[2] = categoryID;
            
            if ( categoryData.sub ) then
                for i, subCategoryData in ipairs(categoryData.sub) do
                    if ( (subCategoryID or 0) ~= 0 ) then
                        if ( subCategoryData.id == subCategoryID ) then
                            tradeSkillSubClassFilter[1] = subCategoryData.name;
                            tradeSkillSubClassFilter[3] = subCategoryID;
                            break;
                        end
                    else
                        tradeSkillSubClassFilter[2+i] = subCategoryData.id;
                    end
                end
            end
            break;
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
    elseif ( #tradeSkillSubClassFilter > 1 ) then
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
    local data = Armory:GetSharedValue(container, selectedSkill, "SubClasses");

    table.wipe(subClasses);

    for i, categoryData in ipairs(data) do
        local id, name = ArmoryDbEntry.Load(categoryData);
        subClasses[i] = {id=id, name=name};
        if ( categoryData.SubClasses ) then
            subClasses[i].sub = {};
            for j, subCategoryData in ipairs(categoryData.SubClasses) do
                local id, name = ArmoryDbEntry.Load(subCategoryData);
                subClasses[i].sub[j] = {id=id, name=name};
            end
        end
    end
    
    return subClasses;
end

local categories = {};
function Armory:GetTradeSkillCategories()
    local subClasses = self:GetTradeSkillSubClasses();
    table.wipe(categories);

    for _, categoryInfo in ipairs(subClasses) do
        table.insert(categories, categoryInfo.id);
    end
    
    return categories;
end

local subCategories = {};
function Armory:GetTradeSkillSubCategories(categoryID)
    local subClasses = self:GetTradeSkillSubClasses();
    table.wipe(subCategories);
    
    for _, categoryInfo in ipairs(subClasses) do
        if ( categoryID == categoryInfo.id ) then
            if ( categoryInfo.sub ) then
                for _, subCategoryInfo in ipairs(categoryInfo.sub) do
                    table.insert(subCategories, subCategoryInfo.id);
                end
            end
            break;
        end
    end
    
    return subCategories;
end

function Armory:GetTradeSkillCategoryInfo(categoryID)
    local subClasses = self:GetTradeSkillSubClasses();
    
    for _, categoryInfo in ipairs(subClasses) do
        if ( categoryID == categoryInfo.id ) then
            return categoryInfo;
        end
        if ( categoryInfo.sub ) then
            for _, subCategoryInfo in ipairs(categoryInfo.sub) do
                if ( categoryID == subCategoryInfo.id ) then
                    return subCategoryInfo;
                end
            end
        end
    end
end

function Armory:GetTradeSkillInvSlots()
    return Armory:GetSharedValue(container, selectedSkill, "InvSlots");
end

function Armory:GetTradeSkillDescription(index)
    local id = GetProfessionLineValue(index).recipeID;
    return GetRecipeValue(id, "Description");
end

function Armory:GetTradeSkillCooldown(index)
    local info = GetProfessionLineValue(index);
    return info.cooldown, info.isDayCooldown, info.charges or 0, info.maxCharges or 0;
end

function Armory:GetTradeSkillNumMade(index)
    local id = GetProfessionLineValue(index).recipeID;
    local minMade, maxMade = GetRecipeValue(id, "NumMade");
    minMade = minMade or 0;
    maxMade = maxMade or 0;
    return minMade, maxMade;
end

function Armory:GetTradeSkillNumReagents(index)
    local id = GetProfessionLineValue(index).recipeID;
    return GetNumReagents(id);
end

function Armory:GetTradeSkillTools(index)
    local id = GetProfessionLineValue(index).recipeID;
    return GetRecipeValue(id, "Tools") or "";
end

function Armory:GetTradeSkillItemLink(index)
    local id = GetProfessionLineValue(index).recipeID;
    return GetRecipeValue(id, "ItemLink");
end

function Armory:GetTradeSkillRecipeLink(index)
    local id = GetProfessionLineValue(index).recipeID;
    return GetRecipeValue(id, "RecipeLink");
end

function Armory:GetTradeSkillReagentInfo(index, id)
    return GetReagentInfo(GetProfessionLineValue(index).recipeID, id);
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
            local text, link, skillName, skillType, id, slotInfo;
            for name in pairs(professions) do
                for i = 1, dbEntry:GetNumValues(container, name, itemContainer) do
                    skillName, skillType = dbEntry:GetValue(container, name, itemContainer, i, "Info");
                    if ( IsRecipe(skillType) ) then
                        id = dbEntry:GetValue(container, name, itemContainer, i, "Data");
                        if ( itemList ) then
                            link = GetRecipeValue(id, "ItemLink");
                        else
                            link = GetRecipeValue(id, "RecipeLink");
                        end
                        if ( self:GetConfigExtendedSearch() ) then
                            text = self:GetTextFromLink(link);
                        else
                            text = skillName;
                        end
                        if ( self:FindTextParts(text, ...) ) then
                            slotInfo = strjoin(", ", GetRecipeValue(id, "InvSlot"));
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
        local skillID, skillName, dbEntry, character;

        local recipeID = self:GetItemId(link);
        local spellID = LR:GetRecipeInfo(recipeID);
        local warn = not spellID;

        for _, profile in ipairs(self:GetConnectedProfiles()) do
            self:SelectProfile(profile);

            dbEntry = self.selectedDbBaseEntry;
            
            local known;
            for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                skillID = dbEntry:GetValue(container, profession, itemContainer, i, "Data");
                if ( skillID ) then
                    if ( spellID ) then
                        known = LR:Teaches(recipeID, skillID);
                    else
                        skillName = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                        known = IsSameRecipe(skillName, name, GetRecipeValue(skillID, "InvSlot"));
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
                local rank = reqProfession and dbEntry:GetValue(container, profession, rankContainer, reqProfession) or dbEntry:GetValue(container, profession, "Rank");
                local learnable = reqRank <= rank;
                local attainable = not learnable;
                local unknown = false;

                if ( reqSkill or reqReputation ) then
                    local isValid = reqSkill == nil;
                    if ( reqSkill ) then
                        for i = 1, 6 do
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

local gemResearch = {
    ["131593"] = true, -- blue
    ["131686"] = true, -- red
    ["131688"] = true, -- green
    ["131690"] = true, -- orange
    ["131691"] = true, -- purple
    ["131695"] = true, -- yellow
};
local cooldowns = {};
function Armory:GetTradeSkillCooldowns(dbEntry)
    table.wipe(cooldowns);

    if ( dbEntry and self:HasTradeSkills() ) then
        local professions = dbEntry:GetValue(container);
        if ( professions ) then
            local cooldown, isDayCooldown, timestamp, skillName, data;
            for profession in pairs(professions) do
                for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                    cooldown, isDayCooldown, timestamp = dbEntry:GetValue(container, profession, itemContainer, i, "Cooldown");
                    if ( cooldown ) then
                        cooldown = self:MinutesTime(cooldown + timestamp, true);
                        if ( cooldown > time() ) then
                            data = dbEntry:GetValue(container, profession, itemContainer, i, "Data");
                            if ( gemResearch[data] ) then
                                skillName = ARMORY_PANDARIA_GEM_RESEARCH;
                            else
                                skillName = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                                if ( skillName:find(ARMORY_TRANSMUTE) ) then
                                    skillName = ARMORY_TRANSMUTE;
                                end
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
                            id = dbEntry:GetValue(container, profession, itemContainer, i, "Data");
                            link = GetRecipeValue(id, "ItemLink");
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


-- TODO: LibRecipes could be used 
local buzzWords;
local words = {};
local function GetGlyphKey(name)
    if ( not buzzWords ) then
        buzzWords = "|";
        for word in ARMORY_BUZZ_WORDS:gmatch("%S+") do
            buzzWords = buzzWords..strupper(word).."|";
        end
    end

    name = strtrim(strupper(name):gsub(strupper(ARMORY_GLYPH), ""));
    table.wipe(words);
    for word in name:gmatch("%S+") do
        if ( not buzzWords:find("|"..word.."|") ) then
            table.insert(words, word);
        end
    end
    return strjoin("_", unpack(words)):gsub("^%p(.+)%p$", "%1");
end

function Armory:GetInscribers(glyphName, class, classEn)
    table.wipe(crafters);

    if ( glyphName and class and self:HasTradeSkills() and self:GetConfigShowCrafters() ) then
        local currentProfile = self:CurrentProfile();
        local profession = ARMORY_TRADE_INSCRIPTION;
        local key = GetGlyphKey(glyphName);
        local dbEntry, id, link, name;
        local character;
        if ( classEn ) then
            class = LOCALIZED_CLASS_NAMES_MALE[classEn];
        end

        for _, profile in ipairs(self:GetConnectedProfiles()) do
            self:SelectProfile(profile);

            dbEntry = self.selectedDbBaseEntry;
            if ( dbEntry:Contains(container, profession) ) then
                for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                    name = dbEntry:GetValue(container, profession, itemContainer, i, "Info");
                    if ( GetGlyphKey(name) == key ) then
                        id = dbEntry:GetValue(container, profession, itemContainer, i, "Data");
                        link = GetRecipeValue(id, "ItemLink");
                        if ( link ) then
                            local _, _, _, _, _, _, _, reqClass = self:GetRequirementsFromLink(link);
		                    character = self:GetQualifiedCharacterName();
                            if ( not reqClass ) then
                                table.insert(crafters, character.."(?)");
                                break;
                            elseif ( class == reqClass ) then
                                table.insert(crafters, character);
                                break;
                            end
                        end
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