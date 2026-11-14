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

-- The lookup protocol of Mainline: replies carry ids, and every lookup type has its own version

ARMORY_LOOKUP_SKILLS = {
    ARMORY_TRADE_ALCHEMY = "AL",
    ARMORY_TRADE_BLACKSMITHING = "BS",
    ARMORY_TRADE_COOKING = "CO",
    ARMORY_TRADE_ENCHANTING = "EC",
    ARMORY_TRADE_ENGINEERING = "EG",
    --ARMORY_TRADE_FIRST_AID = "FA",
    ARMORY_TRADE_JEWELCRAFTING = "JC",
    ARMORY_TRADE_LEATHERWORKING = "LW",
    --ARMORY_TRADE_POISONS = "PO",
    ARMORY_TRADE_TAILORING = "TA",
    ARMORY_TRADE_INSCRIPTION = "IN",
};

ARMORY_LOOKUP_TYPE = { LOOKUP_RECIPE = "R", LOOKUP_QUEST = "Q", LOOKUP_CHARACTER = "C", LOOKUP_DOWNLOAD = "D", LOOKUP_ITEM = "I" };

ARMORY_LOOKUP_VERSION = {
    [ARMORY_LOOKUP_TYPE.LOOKUP_RECIPE] = "2",
    [ARMORY_LOOKUP_TYPE.LOOKUP_QUEST] = "2",
    [ARMORY_LOOKUP_TYPE.LOOKUP_CHARACTER] = "5",
    [ARMORY_LOOKUP_TYPE.LOOKUP_ITEM] = "1",
};

function ArmoryLookupFrame_SendDownloadRequest(guild)
    local id = ARMORY_LOOKUP_TYPE.LOOKUP_DOWNLOAD;
    local version = AgrInfo.dbVersion;
    local message = guild;
    local channel = "GUILD";

    ArmoryAddonMessageFrame_CreateRequest(id, version, message, channel);
end

function ArmoryLookupFrame_FindRecipe(exact, search, arg1, arg2)
    local dbEntry = Armory.selectedDbBaseEntry;
    local dbShared;
    local skillName, skillType, ref, link, listLink, id, itemId, texture, numMade;
    local refType = "enchant";
    local result = {};

    if ( Armory:GetConfigShareProfessions() and dbEntry and dbEntry:Contains("Professions", arg1) ) then
        listLink = dbEntry:GetValue("Professions", arg1, "ListLink");
        if ( search == "*" ) then
            table.insert(result, "*");
        else
            dbEntry = ArmoryDbEntry:new(dbEntry:GetValue("Professions", arg1));

            local container = "SkillLines";
            local numEntries = dbEntry:GetNumValues(container);
            for i = 1, numEntries do
                skillName, skillType = dbEntry:GetValue(container, i, "Info");
                if ( skillType ~= "header" and ArmoryLookupFrame_IsMatch(skillName, search, exact) ) then
                    dbShared = ArmoryDbEntry:new(Armory:GetSharedValue("Professions", "Recipes", dbEntry:GetValue(container, i, "Data")));
                    if ( dbShared ) then
                        link = dbShared:GetValue("RecipeLink");
                        if ( link ) then
                            ref = link:match("|H"..refType..":(%d+)|h");
                            if ( ref ) then
                                if ( arg2 ) then
                                    itemId = Armory:GetItemId(dbShared:GetValue("ItemLink"));
                                    texture = dbShared:GetValue("Icon");
                                    if ( texture and not tonumber(texture) ) then
                                        texture = table.remove({strsplit("\\", texture)});
                                    end
                                    numMade = dbShared:GetValue("NumMade");
                                    if ( numMade == 1 ) then
                                        numMade = nil;
                                    end
                                    ref = strjoin(";", ref, itemId or "", texture or "", numMade or "");

                                end
                                table.insert(result, ref);
                            end
                        end
                    end
                elseif ( arg2 and skillType == "header" ) then
                    table.insert(result, skillName);
                end
            end
        end
    end

    if ( #result > 0 ) then
        if ( listLink and search ~= "" ) then
            table.insert(result, 1, refType..ARMORY_LOOKUP_CONTENT_SEPARATOR..listLink:match("|H(.-)|h"));
        else
            table.insert(result, 1, refType);
        end
    end

    return result;
end

local function AddRef(result, link, refType)
    if ( link ) then
        local ref = link:match("|H"..refType..":([-%d:]+)|h");
        if ( ref ) then
            table.insert(result, ref);
        end
    end
end

function ArmoryLookupFrame_FindQuest(exact, search, arg1)
    local wildcard = (search == "*" and ArmoryDropDownMenu_GetSelectedValue(ArmoryLookupChannelDropDown) == "CHANNEL");
    local dbEntry = Armory.selectedDbBaseEntry;
    local container = "Quests";

    local name, isHeader, id;
    local refType = "quest";
    local result = {};

    arg1 = arg1 or "1";

    if ( Armory:GetConfigShareQuests() and dbEntry and dbEntry:Contains(container) ) then
        local numEntries = table.getn(dbEntry:GetValue(container));
        local questIndex = 1;
        while ( questIndex <= numEntries ) do
            name, _, _, isHeader = dbEntry:GetValue(container, questIndex, "Info");
            if ( arg1 == "2" ) then
                -- area (header)
                if ( isHeader and ArmoryLookupFrame_IsMatch(name, search, exact) ) then
                    repeat
                        questIndex = questIndex + 1;
                        name, _, _, isHeader = dbEntry:GetValue(container, questIndex, "Info");
                        if ( not isHeader ) then
                            id = dbEntry:GetValue(container, questIndex, "Data");
                            AddRef(result, dbEntry:GetValue(container, id, "Link"), refType);
                        end
                    until ( isHeader or questIndex > numEntries )
                    questIndex = questIndex - 1;
                end
            elseif ( not isHeader and (wildcard or ArmoryLookupFrame_IsMatch(name, search, exact)) ) then
                -- name
                id = dbEntry:GetValue(container, questIndex, "Data");
                AddRef(result, dbEntry:GetValue(container, id, "Link"), refType);
            end
            questIndex = questIndex + 1;
        end
    end

    if ( #result > 0 ) then
        table.insert(result, 1, refType);
    end

    return result;
end

local info = {};
function ArmoryLookupFrame_InspectCharacter(exact, search, arg1)
    local result = {};
    local link, ref;

    if ( Armory:GetConfigShareCharacter() and strlower(Armory.character) == strlower(search) ) then
        table.wipe(info);

        local avgItemLevel, avgItemLevelEquipped = Armory:GetAverageItemLevel();
        local itemLevel = "";
        if ( avgItemLevel ) then
            avgItemLevel = floor(avgItemLevel);
            itemLevel = avgItemLevel;
            if ( avgItemLevelEquipped ) then
                avgItemLevelEquipped = floor(avgItemLevelEquipped);
                if ( avgItemLevel ~= avgItemLevelEquipped ) then
                    itemLevel = avgItemLevelEquipped .. "/" .. avgItemLevel;
                end
            end
        end
        info[1] = itemLevel;

        for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            link = Armory:GetInventoryItemLink("player", i);
            if ( link ) then
                ref = link:match("|Hitem:([-%d:]+)|h");
            end
            if ( link and ref ) then
                info[i + 1] = ref;
            else
                info[i + 1] = "";
            end
        end
        table.insert(result, table.concat(info, ARMORY_LOOKUP_CONTENT_SEPARATOR));

        -- Talents are not sent since the talent trees, older versions expect the empty field
        table.insert(result, "");

        table.wipe(info);
    end

    return result;
end

function ArmoryLookupFrame_DownloadRecipes(exact, search, arg1, arg2)
    local dbEntry = Armory.selectedDbBaseEntry;
    local result = {};

    if ( search == Armory:GetGuildInfo("player") and dbEntry and dbEntry:Contains("Professions") ) then
        for profession in pairs(dbEntry:GetValue("Professions")) do
            local skill, recipes;

            if ( profession == ARMORY_TRADE_ALCHEMY ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_ALCHEMY;
            elseif ( profession == ARMORY_TRADE_BLACKSMITHING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_BLACKSMITHING;
            elseif ( profession == ARMORY_TRADE_COOKING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_COOKING;
            elseif ( profession == ARMORY_TRADE_ENCHANTING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_ENCHANTING;
            elseif ( profession == ARMORY_TRADE_ENGINEERING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_ENGINEERING;
            elseif ( profession == ARMORY_TRADE_FIRST_AID ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_FIRST_AID;
            elseif ( profession == ARMORY_TRADE_JEWELCRAFTING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_JEWELCRAFTING;
            elseif ( profession == ARMORY_TRADE_LEATHERWORKING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_LEATHERWORKING;
            elseif ( profession == ARMORY_TRADE_POISONS ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_POISONS;
            elseif ( profession == ARMORY_TRADE_TAILORING ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_TAILORING;
            elseif ( profession == ARMORY_TRADE_INSCRIPTION ) then
                skill = ARMORY_LOOKUP_SKILLS.ARMORY_TRADE_INSCRIPTION;
            end

            if ( skill ) then
                recipes = ArmoryLookupFrame_FindRecipe(nil, "", profession, arg2);
                if ( #recipes > 0 ) then
                    table.insert(recipes, 1, skill);
                    table.insert(result, table.concat(recipes, ARMORY_LOOKUP_CONTENT_SEPARATOR));
                end
            end
        end
    end

    return result;
end

function ArmoryLookupFrame_ProcessResponse(id)
    local module = ArmoryAddonMessageFrame_GetModule(id);
    local data = ArmoryLookupFrame.data;
    local ownerData = ArmoryLookupFrame.ownerData;
    local sets, version, fields, values, owner, name, ref, index, link, refType;
    local sort, update, isMine, characterName, isExpanded;

    for sender, reply in pairs(module.replies) do
        sets = Armory:StringSplit(ARMORY_LOOKUP_SEPARATOR, ArmoryAddonMessageFrame_Decompress(reply.message));
        for _, set in ipairs(sets) do
            fields = Armory:StringSplit(ARMORY_LOOKUP_FIELD_SEPARATOR, set);
            if ( id == ARMORY_LOOKUP_TYPE.LOOKUP_DOWNLOAD ) then
                -- proto3: owner\nAL\fenchant\f1234\f3264\f5353\nEN\fenchant\f8262\f7265
                -- proto4: owner\nAL\fenchant\finvslot\fid;item;icon;count\fid;item;icon;count
                if ( tonumber(reply.version) >= 3 and ArmoryGuildRecipes_ProcessResponse ) then
                    for i = 2, #fields do
                        ArmoryGuildRecipes_ProcessResponse(sender, fields[1], Armory:StringSplit(ARMORY_LOOKUP_CONTENT_SEPARATOR, fields[i]));
                    end
                end

            elseif ( id == ARMORY_LOOKUP_TYPE.LOOKUP_CHARACTER ) then
                if ( reply.version == "5" ) then
                    -- owner\n(1)\n(2)
                    owner = fields[1];

                    local retry;

                    -- (1) (19 items) iLvl\f18821:0:0:0:0:0:0:0\f31333:0:0:0:0:0:0:1443794188
                    name, values = ArmoryLookupFrame_ParseCharacterEquipment(owner, fields[2]);
                    if ( name == nil ) then
                        retry = true;
                    else
                        table.insert(data, {name=name, values=values});

                        -- (2) (talents) role1;active|19354;icon|19364;icon\f;role2;active|19365;icon|19360;icon
                        local specs = Armory:StringSplit(ARMORY_LOOKUP_CONTENT_SEPARATOR, fields[3]);
                        for i = 1, #specs do
                            if ( specs[i] ~= "" ) then
                                name, values = ArmoryLookupFrame_ParseCharacterTalents(owner, i, specs[i]);
                                if ( name == nil ) then
                                    retry = true;
                                    break;
                                elseif ( #values > 0 ) then
                                    table.insert(data, {name=name, values=values});
                                end
                            end
                        end
                    end

                    if ( retry ) then
                        table.insert(data, {name=ARMORY_LOOKUP_NOT_CACHED, func=ArmoryLookupFrame_SendRequest});
                    end

                    update = true;
                end

            elseif ( id == ARMORY_LOOKUP_TYPE.LOOKUP_ITEM ) then
                local itemSort, itemUpdate = ArmoryLookupFrame_ProcessItemReply(fields, sender);
                sort = sort or itemSort;
                update = update or itemUpdate;

            elseif ( reply.version == "2" ) then
                -- owner\nenchant\ftrade:51296:409:450:1F6C481:Bp>PZygS{{iGCy{u=Fj{{?<<\\Da>\n1234\n3264\n5353
                -- owner\nquest\n2323:70\n2432:70
                owner = fields[1];
                characterName, isMine = ArmoryLookupFrame_GetCharacterName(owner, sender);
                refType, link = strsplit(ARMORY_LOOKUP_CONTENT_SEPARATOR, fields[2]);
                if ( link ) then
                    if ( not ownerData[owner] ) then
                        ownerData[owner] = {};
                    end
                    ownerData[owner].recipeList = link;
                end
                for i = 3, #fields do
                    ref = fields[i];
                    if ( ref ) then
                        index = ArmoryLookupFrame_GetData(ref);
                        if ( not index ) then
                            if ( ref == "*" ) then
                                name = _G[ArmoryDropDownMenu_GetSelectedValue(ArmoryLookupTradeSkillDropDown)];
                                link = nil;
                                isExpanded = true;
                            else
                                name, link = Armory:GetInfoFromId(refType, ref);
                                isExpanded = false;
                            end
                            if ( name ) then
                                table.insert(data, {id=ref, name=name, link=link, isMine=isMine, isExpanded=isExpanded, values={{name=characterName, owner=owner, source=sender}}});
                                sort = true;
                            else
                                Armory:PrintDebug("couldn't determine name", ref, characterName);
                            end
                        else
                            if ( isMine ) then
                                data[index].isMine = true;
                            end
                            table.insert(data[index].values, {name=characterName, owner=owner, source=sender});
                            table.sort(data[index].values, function(a, b) return a.name < b.name end);
                        end
                    end
                end
                update = true;

            end
        end
        ArmoryAddonMessageFrame_RemoveReply(module, sender);
    end

    if ( sort ) then
        table.sort(data, function(a, b) return a.name < b.name end);
    end

    if ( update ) then
        ArmoryLookupMessageFrame:Hide();
        ArmoryLookupFrame_Update();
    end
end

function ArmoryLookupFrame_ParseCharacterEquipment(owner, fields)
    local values = Armory:StringSplit(ARMORY_LOOKUP_CONTENT_SEPARATOR, fields);
    local result = {};
    local itemLevel = values[1];
    local name = ARMORY_EQUIPMENT;
    local missing;

    if ( itemLevel ~= "" ) then
        name = name.." ("..ITEM_LEVEL_ABBR.." "..itemLevel..")";
    end

    for i = 2, #values do
        local name, link = Armory:GetInfoFromId("item", values[i]);
        local slot = i - 1;
        local texture;
        if ( (name or "") ~= "" ) then
            if ( link ) then
                -- Get it in the cache
                local tooltip = Armory:AllocateTooltip();
                Armory:SetHyperlink(tooltip, link);
                Armory:ReleaseTooltip(tooltip);

                texture = C_Item.GetItemIconByID(link);
                if ( not texture ) then
                    _, _, _, _, _, _, _, _, _, texture = C_Item.GetItemInfo(link);
                end
            end
            table.insert(result, {id=values[i], name=name.." "..GRAY_FONT_COLOR_CODE..ARMORY_SLOT[slot], link=link, icon=texture});
        elseif ( (values[i] or "") ~= "" ) then
            missing = true;
        end
    end

    if ( not missing ) then
        return name, result;
    end
end

function ArmoryLookupFrame_ParseCharacterTalents(owner, talentGroup, fields)
    local values = Armory:StringSplit("|", fields);
    local role, active = Armory:Split(";", values[1]);
    local result = {};
    local name;
    local missing;

    if ( talentGroup == 1 ) then
        if ( active ) then
            name = SPECIALIZATION_PRIMARY_ACTIVE;
        else
            name = SPECIALIZATION_PRIMARY;
        end
    else
        if ( active ) then
            name = SPECIALIZATION_SECONDARY_ACTIVE;
        else
            name = SPECIALIZATION_SECONDARY;
        end
    end
    name = name.." (".._G[role]..")";

    for i = 2, #values do
        local ref, texture = Armory:Split(";", values[i]);
        local name, link = Armory:GetInfoFromId("talent", ref);
        if ( (name or "") ~= "" ) then
            table.insert(result, {id=ref, name=name, link=link, icon=tonumber(texture) or "Interface\\Icons\\"..texture});
        elseif ( (ref or "") ~= "" ) then
            missing = true;
        end
    end

    if ( not missing ) then
        return name, result;
    end
end

function ArmoryLookupFrame_StartDownload(...)
    local loaded = C_AddOns.IsAddOnLoaded(ARMORY_SHARE_DOWNLOAD_ADDON);
    local reason;

    if ( not loaded ) then
        loaded, reason = C_AddOns.LoadAddOn(ARMORY_SHARE_DOWNLOAD_ADDON);
        --if ( not loaded and reason == "DISABLED" ) then
            --EnableAddOn(ARMORY_SHARE_DOWNLOAD_ADDON);
            --loaded, reason = LoadAddOn(ARMORY_SHARE_DOWNLOAD_ADDON);
        --end
    end

    if ( loaded ) then
        ArmoryGuildRecipes_Prepare(ArmoryLookupFrame_SendDownloadRequest);
    elseif ( reason ) then
        Armory:PrintError(string.format(ARMORY_SHARE_DOWNLOAD_LOADERROR, ARMORY_SHARE_DOWNLOAD_ADDON, _G["ADDON_"..reason]));
    end
end
