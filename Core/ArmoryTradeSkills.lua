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

local Armory, _ = Armory, nil;
local LR = LibStub("LibRecipes-3.0");

local container = "Professions";
local itemContainer = "SkillLines";
local recipeContainer = "Recipes";
local reagentContainer = "Reagents";
local rankContainer = "Ranks";
local categoryContainer = "Categories";

local selectedSkill;

local tradeSkillCategoryFilter = {};
local tradeSkillFilter = "";
local tradeSkillMinLevel = 0;
local tradeSkillMaxLevel = 0;
local onlyShowMakeable = false;
local onlyShowSkillUp = false;

local categories = {};

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

local tonumber = tonumber;
local strlower = strlower;
local strtrim = strtrim;
local strmatch = strmatch;
local strjoin = strjoin;
local table = table;
local pairs = pairs;
local ipairs = ipairs;
local next = next;
local string = string;
local tostring = tostring;
local select = select;
local time = time;
local unpack = unpack;
local max = max;
local assert = assert;
local type = type;
local pcall = pcall;
local format = format;

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
    local mcrSlots = GetRecipeValue(id, "McrSlots");
    if ( mcrSlots ) then
        if ( index <= #mcrSlots ) then
            local name, count, reagentID = GetRecipeValue(id, "McrSlots", index);
            return name, nil, count, nil, true;
        end
        index = index - #mcrSlots;
    end

    local reagentID, count = GetRecipeValue(id, "Reagents", index);
    local name, texture, link = Armory:GetSharedValue(container, reagentContainer, tostring(reagentID));
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
        if ( (count or 0) > 0 and Armory:ScanInventory(link, "reagent") < count ) then
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
    local name, id, skillType, numAvailable, numIndents, difficulty, disabled, categoryID, isExpanded;
    local subgroup;

    table.wipe(professionLines);

    if ( dbEntry and dbEntry:Contains(container, selectedSkill, itemContainer) ) then
        dbEntry = SelectProfession(dbEntry, selectedSkill)

        numLines, extended = GetProfessionNumValues(dbEntry);
        if ( numLines > 0 ) then
            table.wipe(groups);

            -- apply filters
            for i = 1, numLines do
                name, skillType, numAvailable,  _, _, numIndents, _, _, difficulty, _, _, _, _, disabled, _, categoryID = dbEntry:GetValue(itemContainer, i, "Info");
                id = dbEntry:GetValue(itemContainer, i, "Data");
                isExpanded = not Armory:GetHeaderLineState(itemContainer..selectedSkill, name);
                if ( not IsRecipe(skillType) and numIndents == 0 ) then
                    if ( #tradeSkillCategoryFilter > 1 ) then
                        isIncluded = false;
                        for j = 2, #tradeSkillCategoryFilter do
                            if ( tradeSkillCategoryFilter[j] == categoryID ) then
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
                    if ( not IsRecipe(skillType) ) then
                        subgroup = { index=i, expanded=isExpanded, items={} };
                        table.insert(group.items, subgroup);
                    else
                        numReagents = GetNumReagents(id);
                        names = name or "";
                        for index = 1, numReagents do
                            names = names.."\t"..(GetReagentInfo(id, index) or "");
                        end
                        if ( #tradeSkillCategoryFilter == 2 ) then
                            isIncluded = tradeSkillCategoryFilter[2] == categoryID;
                        elseif ( #tradeSkillCategoryFilter > 1 ) then
                            isIncluded = false;
                            for j = 2, #tradeSkillCategoryFilter do
                                if ( tradeSkillCategoryFilter[j] == categoryID ) then
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
                                isIncluded = CanCraftFromInventory(id);
                            end
                        end
                        if ( isIncluded and onlyShowSkillUp ) then
                            isIncluded = difficulty and difficulty ~= "trivial" and difficulty ~= "nodifficulty";
                        end
                        if ( isIncluded and tradeSkillMinLevel > 0 and tradeSkillMaxLevel > 0 ) then
                            _, _, _, _, itemMinLevel = C_Item.GetItemInfo(GetRecipeValue(id, "ItemLink"));
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

local function UpdateProfessionItems()
    local dbEntry = Armory.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end
    for slot = ARMORY_GEARSLOT_FIRST_EQUIPPED, ARMORY_GEARSLOT_LAST_EQUIPPED do
        dbEntry:SetValue(3, container, "InventoryItems", tostring(slot), _G.GetInventoryItemLink("player", slot), _G.GetInventoryItemTexture("player", slot), _G.GetInventoryItemQuality("player", slot));
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
                    if ( i <= 2 and numSpells == 2 and not C_SpellBook.IsSpellBookItemPassive(offset + 2, Enum.SpellBookSpellBank.Player) ) then
                        local spellName, subSpellName = C_SpellBook.GetSpellBookItemName(offset + 2, Enum.SpellBookSpellBank.Player);
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
            profession = _G.GetProfessionInfo(id);
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
    local info = {};
    local dbEntry = Armory.selectedDbBaseEntry;
    local numLines = Armory:GetNumTradeSkills();
    local timestamp;

    if ( dbEntry and index > 0 and index <= numLines ) then
        info.recipeID = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Data");

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
        info.totalRanks,
        info.unlockedRecipeLevel,
        info.currentRecipeExperience,
        info.nextLevelRecipeExperience,
        info.earnedExperience,
        info.categorySkillRank,
        info.isEmptyCategory = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[index], "Info");

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
    end

    return info;
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
    UpdateProfessionItems();
end

function Armory:ClearTradeSkills()
    self:ClearModuleData(container);
    -- recollect minimal required profession data
    self:UpdateProfessions();
    dirty = true;
end

local RequirementTypeToString =
{
    [Enum.RecipeRequirementType.SpellFocus] = "SpellFocusRequirement",
    [Enum.RecipeRequirementType.Totem] = "TotemRequirement",
    [Enum.RecipeRequirementType.Area] = "AreaRequirement",
};

local function FormatRequirements(requirements)
    local formattedRequirements = {};
    for index, recipeRequirement in ipairs(requirements) do
        table.insert(formattedRequirements, LinkUtil.FormatLink(RequirementTypeToString[recipeRequirement.type], recipeRequirement.name));
        table.insert(formattedRequirements, recipeRequirement.met);
    end
    return formattedRequirements;
end

local function StoreTradeSkillInfo(dbEntry, recipeID, index)
    local skillLineID, skillLineName = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID);
    if ( skillLineName ) then
        dbEntry:SetValue(2, rankContainer, skillLineName, C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID).skillLevel);
    end

    local recipe = Armory.sharedDbEntry:SelectContainer(container, recipeContainer, tostring(recipeID));
    local reagents = Armory.sharedDbEntry:SelectContainer(container, reagentContainer);

    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID);
    local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false);
    local quantityMin, quantityMax = 1, 1;

    -- Quantity min and max in the context of salvage recipes means the reagent cost, not the output quantity.
    if  ( recipeSchematic and recipeSchematic.recipeType ~= Enum.TradeskillRecipeType.Salvage ) then
        quantityMin, quantityMax = recipeSchematic.quantityMin, recipeSchematic.quantityMax;
    end

    local function GetSlotReagents(reagentSlotSchematic)
        local reagentType = reagentSlotSchematic.reagentType;
        local slotReagents = {};
        for reagentIndex, reagent in ipairs(reagentSlotSchematic.reagents) do
            local id;
            if ( reagent.itemID ) then
                id = reagent.itemID;
                local item = Item:CreateFromItemID(id);
                item:ContinueOnItemLoad(function()
                    reagents[tostring(id)] = dbEntry.Save(item:GetItemName(), item:GetItemIcon(), item:GetItemLink());
                end);
            elseif ( reagent.currencyID ) then
                id = reagent.currencyID;
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(id);
                if ( currencyInfo ) then
                    reagents[tostring(id)] = dbEntry.Save(currencyInfo.name, currencyInfo.iconFileID, C_CurrencyInfo.GetCurrencyLink(id));
                end
            end
            if ( id ) then
                table.insert(slotReagents, id);
            end
        end
        return slotReagents;
    end

    recipe.Reagents = {};
    recipe.McrSlots = {};
    recipe.OptionalReagents = {};
    for slotIndex, reagentSlotSchematic in ipairs(recipeSchematic.reagentSlotSchematics) do
        if ( reagentSlotSchematic.dataSlotType == Enum.TradeskillSlotDataType.Reagent or reagentSlotSchematic.dataSlotType == Enum.TradeskillSlotDataType.ModifiedReagent ) then
            local reagentType = reagentSlotSchematic.reagentType;
            local isModifyingRequiredSlot = ProfessionsUtil.IsReagentSlotModifyingRequired(reagentSlotSchematic);
            if ( isModifyingRequiredSlot ) then
                local slotInfo = reagentSlotSchematic.slotInfo;
                local slotReagents = GetSlotReagents(reagentSlotSchematic);
                local reagentCount = reagentSlotSchematic.quantityRequired;
                table.insert(recipe.McrSlots, dbEntry.Save(slotInfo.slotText, reagentCount, unpack(slotReagents)));
            elseif ( reagentType == Enum.CraftingReagentType.Basic ) then
                local slotReagents = GetSlotReagents(reagentSlotSchematic);
                local reagentCount = reagentSlotSchematic.quantityRequired;
                table.insert(recipe.Reagents, dbEntry.Save(slotReagents[1], reagentCount, unpack(slotReagents, 2)));
            elseif ( reagentType == Enum.CraftingReagentType.Modifying ) then
                local slotInfo = reagentSlotSchematic.slotInfo;
                table.insert(recipe.OptionalReagents, dbEntry.Save(slotInfo.requiredSkillRank, slotInfo.slotText));
            end
        end
    end

    recipe.RecipeLink = C_TradeSkillUI.GetRecipeLink(recipeID);
    recipe.Description = C_TradeSkillUI.GetRecipeDescription(recipeID, {});
    recipe.NumMade = dbEntry.Save(quantityMin, quantityMax);
    recipe.ItemLink = C_TradeSkillUI.GetRecipeItemLink(recipeID);

    if ( #C_TradeSkillUI.GetRecipeRequirements(recipeID) > 0 ) then
        local requirements = C_TradeSkillUI.GetRecipeRequirements(recipeID);
        recipe.Tools = Armory:BuildColoredListString(unpack(FormatRequirements(requirements)));
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

local function CreateSkillList()
    local categoryNodes = {};
    local recipes = {};

    local function CreateNode(categoryInfo)
        local node = { categoryInfo = categoryInfo, subcategories = {}, recipes = {} };
        categoryNodes[categoryInfo.categoryID] = node;
        return node;
    end

    local function GetNode(categoryID)
        local node = categoryNodes[categoryID];
        if ( node == nil ) then
            local categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryID);
            if ( categoryInfo ) then
                node = CreateNode(categoryInfo);
                if ( categoryInfo.parentCategoryID ) then
                    local parentNode = GetNode(categoryInfo.parentCategoryID);
                    if ( parentNode ) then
                        table.insert(parentNode.subcategories, node);
                    end
                end
            end
        end
        return node;
    end

    local function GetFirstRecipe(recipeInfo)
        local previousRecipeID = recipeInfo.previousRecipeID;
        while ( previousRecipeID ) do
            recipeInfo = C_TradeSkillUI.GetRecipeInfo(previousRecipeID);
            previousRecipeID = recipeInfo.previousRecipeID;
        end
        return recipeInfo;
    end

    local function AddRecipe(recipeInfo)
        local nextRecipeID = recipeInfo.nextRecipeID;

        local currentRank = 1;
        do
            local previousRecipeID = recipeInfo.previousRecipeID;
            while ( previousRecipeID ) do
                currentRank = currentRank + 1;
                recipeInfo = C_TradeSkillUI.GetRecipeInfo(previousRecipeID);
                previousRecipeID = recipeInfo.previousRecipeID;
            end
        end

        local node = GetNode(recipeInfo.categoryID);

        if ( not recipes[recipeInfo.recipeID] ) then
            recipes[recipeInfo.recipeID] = true;

            recipeInfo.currentRank = currentRank;
            recipeInfo.totalRanks = currentRank;
            do
                while ( nextRecipeID ) do
                    recipeInfo.totalRanks = recipeInfo.totalRanks + 1;
                    local nextRecipeInfo = C_TradeSkillUI.GetRecipeInfo(nextRecipeID);
                    nextRecipeID = nextRecipeInfo.nextRecipeID;
                end
            end

            table.insert(node.recipes, recipeInfo);
        end
    end

    local function AddNodeInfoToList(list, node, level)
        local numIndents = level or 0;
        local categoryInfo = node.categoryInfo;
        categoryInfo.numIndents = numIndents;
        table.insert(list, categoryInfo);

        for _, recipeInfo in ipairs(node.recipes) do
            recipeInfo.numIndents = numIndents;
            table.insert(list, recipeInfo);
        end

        for _, node in ipairs(node.subcategories) do
            AddNodeInfoToList(list, node, numIndents + 1);
        end
    end

    for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs()) do
        local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID);
        if ( recipeInfo.learned ) then
            AddRecipe(recipeInfo);
        end
    end

    local nodeInfoList = {};
    local orderedNodes = {};
    for _, categoryID in ipairs({C_TradeSkillUI.GetCategories()}) do
        local node = categoryNodes[categoryID];
        if ( node ) then
            table.insert(orderedNodes, node);
            AddNodeInfoToList(nodeInfoList, node);
        end
    end

    return nodeInfoList, orderedNodes;
end

local function GetTradeSkillLineInfo(info)
    local categoryInfo = C_TradeSkillUI.GetCategoryInfo(info.categoryID);
    while ( not categoryInfo.skillLineCurrentLevel and categoryInfo.parentCategoryID ) do
        categoryInfo = C_TradeSkillUI.GetCategoryInfo(categoryInfo.parentCategoryID);
    end
    info.categorySkillRank = categoryInfo.skillLineCurrentLevel;

    info.productQuality = info.hyperlink and Armory:GetQualityFromLink(info.hyperlink) or 0;

    if ( info.relativeDifficulty == Enum.TradeskillRelativeDifficulty.Optimal ) then
        info.difficulty = "optimal";
    elseif ( info.relativeDifficulty == Enum.TradeskillRelativeDifficulty.Medium ) then
        info.difficulty = "medium";
    elseif ( info.relativeDifficulty == Enum.TradeskillRelativeDifficulty.Easy ) then
        info.difficulty = "easy";
    elseif ( info.relativeDifficulty == Enum.TradeskillRelativeDifficulty.Trivial ) then
        info.difficulty = "trivial";
    else
        info.difficulty = "nodifficulty";
    end

    return
        info.name,
        info.type or "recipe",
        info.numAvailable or 0,
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
        info.totalRanks,
        info.unlockedRecipeLevel,
        info.currentRecipeExperience,
        info.nextLevelRecipeExperience,
        info.earnedExperience,
        info.categorySkillRank,
        info.isEmptyCategory;
end

function Armory:GetCurrentProfessionInfo()
    local childProfessionInfos = C_TradeSkillUI.GetChildProfessionInfos();
    local professionInfo = childProfessionInfos and childProfessionInfos[1];
    if ( not professionInfo or professionInfo.professionID == 0 ) then
        professionInfo = C_TradeSkillUI.GetBaseProfessionInfo();
    end
    if ( professionInfo ) then
        professionInfo.displayName = professionInfo.parentProfessionName and professionInfo.parentProfessionName or professionInfo.professionName;
    end
    return professionInfo;
end

function Armory:UpdateTradeSkill()
    local name, rank, maxRank, modifier;

    if ( not self.playerDbBaseEntry ) then
        return;
    elseif ( not self:HasTradeSkills() ) then
        ClearProfessions();
        return;
    end

    local professionInfo = self:GetCurrentProfessionInfo();
    if ( not professionInfo ) then
        return;
    end
    local name = professionInfo.displayName;

    if ( name and name ~= "UNKNOWN" ) then
        if ( not IsTradeSkill(name) ) then
            self:PrintDebug(name, "is not a profession");

        elseif ( not self:IsLocked(itemContainer) ) then
            self:Lock(itemContainer);

            self:PrintDebug("UPDATE", name);

            SetProfessionValue(name, "Rank", professionInfo.skillLevel, professionInfo.maxSkillLevel, professionInfo.skillModifier);
            SetProfessionValue(name, "ID", professionInfo.profession, professionInfo.professionID);

            local dbEntry = SelectProfession(self.playerDbBaseEntry, name);

            dbEntry:ClearContainer(itemContainer);

            ClearItemCache(dbEntry);

            local nodeInfoList, categoryNodes = CreateSkillList();

            for i, node in ipairs(categoryNodes) do
                local categoryInfo = node.categoryInfo;
                dbEntry:SetValue(2, categoryContainer, i, categoryInfo.categoryID, categoryInfo.name);
                for j, subnode in ipairs(node.subcategories) do
                    categoryInfo = subnode.categoryInfo;
                    dbEntry:SetValue(4, categoryContainer, i, categoryContainer, j, categoryInfo.categoryID, categoryInfo.name);
                end
            end

            for i, info in ipairs(nodeInfoList) do
                dbEntry:SetValue(3, itemContainer, i, "Info", GetTradeSkillLineInfo(info));
                if ( info.recipeID ) then
                    dbEntry:SetValue(3, itemContainer, i, "Data", tostring(info.recipeID));

                    local spell = Spell:CreateFromSpellID(info.recipeID);
                    spell:ContinueOnSpellLoad(function()
                        StoreTradeSkillInfo(dbEntry, info.recipeID, i);
                    end);
                end
            end

            self:Unlock(itemContainer);
        else
            self:PrintDebug("LOCKED", name);
        end
    end

    return name;
end

----------------------------------------------------------
-- TradeSkills Interface
----------------------------------------------------------

-- A gathering profession without recipes, like Skinning in Forever, stores an empty list; withRecipes leaves it out
-- (the frame has nothing to show), the summary still lists its rank. Classic stores no empty list
function Armory:HasTradeSkillLines(name, withRecipes)
    local dbEntry = self.selectedDbBaseEntry;
    if ( withRecipes ) then
        return dbEntry and dbEntry:GetNumValues(container, name, itemContainer) > 0;
    end
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
        extended = false;
    elseif ( dbEntry ) then
        _, skillType = dbEntry:GetValue(container, selectedSkill, itemContainer, professionLines[1], "Info");
        -- keep for handling old data
        extended = not IsRecipe(skillType);
    end
    return numSkills, extended;
end

function Armory:GetTradeSkillInfo(index)
    local info = GetProfessionLineValue(index);
    if ( info ) then
        if ( not IsRecipe(info.type) ) then
            info.collapsed = self:GetHeaderLineState(itemContainer..selectedSkill, info.name);
        end

        local QuestionMarkIconFileDataID = 134400;
        if ( info.icon == QuestionMarkIconFileDataID ) then
            info.icon = self:GetProfessionTexture(self:GetSelectedProfession());
        end
    end

    return info;
end

function Armory:ExpandTradeSkillCategory(index)
    UpdateTradeSkillHeaderState(index, false);
end

function Armory:CollapseTradeSkillCategory(index)
    UpdateTradeSkillHeaderState(index, true);
end

function Armory:SetTradeSkillCategoryFilter(categoryID)
    local categories = self:GetTradeSkillCategories();

    table.wipe(tradeSkillCategoryFilter);

    for _, categoryInfo in ipairs(categories) do
        if ( categoryInfo.categoryID == categoryID ) then
            tradeSkillCategoryFilter[1] = categoryInfo.name;
            tradeSkillCategoryFilter[2] = categoryInfo.categoryID;
            if ( categoryInfo.subcategories ) then
                for i, subCategoryInfo in ipairs(categoryInfo.subcategories) do
                    tradeSkillCategoryFilter[2+i] = subCategoryInfo.categoryID;
                end
            end
            break;
        end
    end

    self:ExpandTradeSkillCategory(0);
end

function Armory:GetTradeSkillCategoryFilter()
    return tradeSkillCategoryFilter;
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
    elseif ( #tradeSkillCategoryFilter > 1 ) then
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
        local profession, professionID = GetProfessionValue("ID");
        return selectedSkill, rank, maxRank, (modifier or 0), profession, professionID;
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

local categories = {};
function Armory:GetTradeSkillCategories()
    table.wipe(categories);

    local dbEntry = SelectProfession(Armory.selectedDbBaseEntry, selectedSkill);
    if ( dbEntry ) then
        for i = 1, dbEntry:GetNumValues(categoryContainer) do
            local categoryID, name = dbEntry:GetValue(categoryContainer, i);
            categories[i] = {categoryID=categoryID, name=name, subcategories={}};
            for j = 1, dbEntry:GetNumValues(categoryContainer, i, categoryContainer) do
                categoryID, name = dbEntry:GetValue(categoryContainer, i, categoryContainer, j);
                categories[i].subcategories[j] = {categoryID=categoryID, name=name};
            end
        end
    end

    return categories;
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
    local mcrSlots = GetRecipeValue(id, "McrSlots");
    return GetNumReagents(id) + (mcrSlots and #mcrSlots or 0);
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

function Armory:GetOptionalReagentSlots(index)
    local id = GetProfessionLineValue(index).recipeID;
    local optionalReagents = GetRecipeValue(id, "OptionalReagents");
    local optionalReagentSlots = {};
    if ( optionalReagents ) then
        for optionalReagentIndex, optionalReagent in ipairs(optionalReagents) do
            local slot = {};
            slot.requiredSkillRank, slot.slotText, slot.options = ArmoryDbEntry.Load(optionalReagent);
            optionalReagentSlots[optionalReagentIndex] = slot;
        end
    end
    return optionalReagentSlots;
end

function Armory:GetMcrSlotItems(index, id)
    return { select(3, GetRecipeValue(GetProfessionLineValue(index).recipeID, "McrSlots", id)) };
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

function Armory:GetReagents(recipeID, index)
    local reagents = {
        [1] = { itemID = GetRecipeValue(recipeID, "Reagents", index) }
    };
    local reagentIDs = { select(3, GetRecipeValue(recipeID, "Reagents", index)) };
    if ( reagentIDs ) then
        for _, reagentID in ipairs(reagentIDs) do
            table.insert(reagents, { itemID = reagentID });
        end
    end
    return reagents;
end

function Armory:GetProfessionItems(slotID)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, "InventoryItems", tostring(slotID));
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
                            text = self:GetFindText(link);
                        else
                            text = skillName;
                        end
                        if ( self:FindTextParts(text, ...) ) then
                            table.insert(list, {label=name, name=skillName, link=link});
                        end

                        self:FindYield();
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
                        known = IsSameRecipe(skillName, name);
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

local competition = {};
function Armory:GetCompetition(profession, categoryID)
    table.wipe(competition);

    local currentProfile = self:CurrentProfile();
    local hasProgressBar, skillLineCurrentLevel, skillLineMaxLevel, skillLineStartingRank, skillLineCategoryID;
    local dbEntry, name, found;

    for _, profile in ipairs(self:GetConnectedProfiles()) do
        self:SelectProfile(profile);

        dbEntry = self.selectedDbBaseEntry;
        name = self:GetQualifiedCharacterName();
        if ( dbEntry:Contains(container, profession) ) then
            found = false;
            for i = 1, dbEntry:GetNumValues(container, profession, itemContainer) do
                hasProgressBar, skillLineCurrentLevel, skillLineMaxLevel, skillLineStartingRank, _, _, skillLineCategoryID = select(10, dbEntry:GetValue(container, profession, itemContainer, i, "Info"));
                if ( hasProgressBar and skillLineCategoryID == categoryID ) then
                    table.insert(competition, {name=name, currentLevel=skillLineCurrentLevel, maxLevel=skillLineMaxLevel, startingRank=skillLineStartingRank});
                    found = true;
                    break;
                end
            end
            if ( not found ) then
                table.insert(competition, {name=name});
            end
        end
    end
    self:SelectProfile(currentProfile);

    table.sort(competition, function(a, b) return (a.currentLevel or 0) > (b.currentLevel or 0); end);

    return competition;
end