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

-- The lookup protocol of Classic: replies carry names and links, all with version c1

local VERSION = "c1";

ARMORY_LOOKUP_SKILLS = {
    ARMORY_TRADE_ALCHEMY = "AL",
    ARMORY_TRADE_BLACKSMITHING = "BS",
    ARMORY_TRADE_COOKING = "CO",
    ARMORY_TRADE_ENCHANTING = "EC",
    ARMORY_TRADE_ENGINEERING = "EG",
    ARMORY_TRADE_FIRST_AID = "FA",
    ARMORY_TRADE_LEATHERWORKING = "LW",
    ARMORY_TRADE_TAILORING = "TA",
};

ARMORY_LOOKUP_TYPE = { LOOKUP_RECIPE = "R", LOOKUP_QUEST = "Q", LOOKUP_CHARACTER = "C", LOOKUP_ITEM = "I" };

ARMORY_LOOKUP_VERSION = {
    [ARMORY_LOOKUP_TYPE.LOOKUP_RECIPE] = VERSION,
    [ARMORY_LOOKUP_TYPE.LOOKUP_QUEST] = VERSION,
    [ARMORY_LOOKUP_TYPE.LOOKUP_CHARACTER] = VERSION,
    [ARMORY_LOOKUP_TYPE.LOOKUP_ITEM] = VERSION,
};

function ArmoryLookupFrame_FindRecipe(exact, search, arg1)
    local dbEntry = Armory.selectedDbBaseEntry;
    local skillName, skillType, link, ref;
    local result = {};

    if ( Armory:GetConfigShareProfessions() and dbEntry and dbEntry:Contains("Professions", arg1) ) then
        if ( search == "*" ) then
            table.insert(result, "*");
        else
            dbEntry = ArmoryDbEntry:new(dbEntry:GetValue("Professions", arg1));

            local container = "SkillLines";
            local numEntries = dbEntry:GetNumValues(container);
            for i = 1, numEntries do
                skillName, skillType = dbEntry:GetValue(container, i, "Info");
                if ( skillType ~= "header" and ArmoryLookupFrame_IsMatch(skillName, search, exact) ) then
                    link = dbEntry:GetValue(container, i, "ItemLink");
                    if ( link ) then
                        ref = link;
                    else
                        ref = skillName;
                    end
                    table.insert(result, ref);
                end
            end
        end
    end

    return result;
end

function ArmoryLookupFrame_FindQuest(exact, search, arg1)
    local wildcard = (search == "*" and ArmoryDropDownMenu_GetSelectedValue(ArmoryLookupChannelDropDown) == "CHANNEL");
    local dbEntry = Armory.selectedDbBaseEntry;
    local container = "Quests";

    local name, isHeader, id;
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
                            table.insert(result, name);
                        end
                    until ( isHeader or questIndex > numEntries )
                    questIndex = questIndex - 1;
                end
            elseif ( not isHeader and (wildcard or ArmoryLookupFrame_IsMatch(name, search, exact)) ) then
                -- name
                table.insert(result, name);
            end
            questIndex = questIndex + 1;
        end
    end

    return result;
end

local info = {};
local tab = {};
function ArmoryLookupFrame_InspectCharacter(exact, search, arg1)
    local result = {};
    local link, ref;

    if ( Armory:GetConfigShareCharacter() and strlower(Armory.character) == strlower(search) ) then
        table.wipe(info);

        for i = EQUIPPED_FIRST, EQUIPPED_LAST do
            link = Armory:GetInventoryItemLink("player", i);
            if ( link ) then
                ref = link:match("|Hitem:([-%d:]+)|h");
            end
            if ( link and ref ) then
                info[i] = ref;
            else
                info[i] = "";
            end
        end
        table.insert(result, table.concat(info, ARMORY_LOOKUP_CONTENT_SEPARATOR));

        table.wipe(info);
        table.wipe(tab);
        for i = 1, Armory:GetNumTalentTabs(true) do
            local name, _, pointsSpent = Armory:GetTalentTabInfo(i, true);
            tab[i] = name..":"..pointsSpent;
            for j = 1, Armory:GetNumTalents(i, true) do
                local name, texture, _, _, rank, maxRank = Armory:GetTalentInfo(i, j, true);
                if ( not tonumber(texture) ) then
                    texture = table.remove({strsplit("\\", texture)});
                end
                if ( rank and rank > 0 ) then
                    table.insert(info, strjoin(";", name, texture, rank, maxRank));
                end
            end
        end

        if ( #info > 0 ) then
            table.insert(info, 1, table.concat(tab, " "));
        end
        table.insert(result, table.concat(info, ARMORY_LOOKUP_CONTENT_SEPARATOR));

        table.wipe(info);
        table.wipe(tab);
    end

    return result;
end

function ArmoryLookupFrame_ProcessResponse(id)
    local module = ArmoryAddonMessageFrame_GetModule(id);
    local data = ArmoryLookupFrame.data;
    local ownerData = ArmoryLookupFrame.ownerData;
    local sets, fields, values, owner, name, ref, index, link;
    local sort, update, isMine, characterName, isExpanded;

    for sender, reply in pairs(module.replies) do
        if ( reply.version == VERSION ) then
            sets = Armory:StringSplit(ARMORY_LOOKUP_SEPARATOR, ArmoryAddonMessageFrame_Decompress(reply.message));
            for _, set in ipairs(sets) do
                fields = Armory:StringSplit(ARMORY_LOOKUP_FIELD_SEPARATOR, set);

                if ( id == ARMORY_LOOKUP_TYPE.LOOKUP_CHARACTER ) then
                    -- owner\n(1)\n(2)
                    owner = fields[1];

                    local retry;

                    -- (1) (19 items) 18821:0:0:0:0:0:0:0\f31333:0:0:0:0:0:0:1443794188
                    name, values = ArmoryLookupFrame_ParseCharacterEquipment(owner, fields[2]);
                    if ( name == nil ) then
                        retry = true;
                    else
                        table.insert(data, {name=name, values=values});

                        -- (2) (talents) tab1 (1) / tab2 (20) / tab3 (40)\fname;icon;rank;maxRank\fname;icon;rank;maxRank
                        name, values = ArmoryLookupFrame_ParseCharacterTalents(owner, fields[3]);
                        if ( #values > 0 ) then
                            table.insert(data, {name=name, values=values});
                        end
                    end

                    if ( retry ) then
                        table.insert(data, {name=ARMORY_LOOKUP_NOT_CACHED, func=ArmoryLookupFrame_SendRequest});
                    end

                    update = true;

                elseif ( id == ARMORY_LOOKUP_TYPE.LOOKUP_ITEM ) then
                    local itemSort, itemUpdate = ArmoryLookupFrame_ProcessItemReply(fields, sender);
                    sort = sort or itemSort;
                    update = update or itemUpdate;

                elseif ( id == ARMORY_LOOKUP_TYPE.LOOKUP_QUEST ) then
                    -- owner\nA New Plague\nA Putrid Task
                    owner = fields[1];
                    characterName, isMine = ArmoryLookupFrame_GetCharacterName(owner, sender);
                    for i = 2, #fields do
                        ref = fields[i];
                        if ( ref ) then
                            name = ref;
                            index = ArmoryLookupFrame_GetData(ref);
                            if ( not index ) then
                                table.insert(data, {id=ref, name=name, isMine=isMine, values={{name=characterName, owner=owner, source=sender}}});
                                sort = true;
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

                elseif ( id == ARMORY_LOOKUP_TYPE.LOOKUP_RECIPE ) then
                    -- owner\n|cffffffff|Hitem:6888::::::::6::::1:3524:::|h[Herb Baked Egg]|h|r\n|cffffffff|Henchant:7428|h[Enchant Bracer - Minor Deflect]|h|r
                    owner = fields[1];
                    characterName, isMine = ArmoryLookupFrame_GetCharacterName(owner, sender);
                    for i = 2, #fields do
                        ref = fields[i];
                        index = ArmoryLookupFrame_GetData(ref);
                        if ( not index ) then
                            if ( ref == "*" ) then
                                name = _G[ArmoryDropDownMenu_GetSelectedValue(ArmoryLookupTradeSkillDropDown)];
                                link = nil;
                                isExpanded = true;
                            else
                                name = Armory:GetNameFromLink(ref);
                                isExpanded = false;
                                if ( name ) then
                                    link = ref;
                                else
                                    name = ref;
                                    link = nil;
                                end
                            end
                            table.insert(data, {id=ref, name=name, link=link, isMine=isMine, isExpanded=isExpanded, values={{name=characterName, owner=owner, source=sender}}});
                            sort = true;
                        else
                            if ( isMine ) then
                                data[index].isMine = true;
                            end
                            table.insert(data[index].values, {name=characterName, owner=owner, source=sender});
                            table.sort(data[index].values, function(a, b) return a.name < b.name end);
                        end
                    end
                    update = true;

                end
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
    local name = ARMORY_EQUIPMENT;
    local missing;

    for i = 1, #values do
        local name, link = Armory:GetInfoFromId("item", values[i]);
        local texture;
        if ( (name or "") ~= "" ) then
            if ( link ) then
                -- Get it in the cache
                local tooltip = Armory:AllocateTooltip();
                Armory:SetHyperlink(tooltip, link);
                Armory:ReleaseTooltip(tooltip);

                texture = GetItemIcon(link);
                if ( not texture ) then
                    _, _, _, _, _, _, _, _, _, texture = GetItemInfo(link);
                end
            end
            table.insert(result, {id=values[i], name=name.." "..GRAY_FONT_COLOR_CODE..ARMORY_SLOT[i], link=link, icon=texture});
        elseif ( (values[i] or "") ~= "" ) then
            missing = true;
        end
    end

    if ( not missing ) then
        return name, result;
    end
end

function ArmoryLookupFrame_ParseCharacterTalents(owner, fields)
    local values = Armory:StringSplit(ARMORY_LOOKUP_CONTENT_SEPARATOR, fields);
    local build = values[1];
    local result = {};

    for i = 2, #values do
        local name, texture, rank, maxRank = strsplit(";", values[i]);
        table.insert(result, {id=name, name=string.format("%s (%s/%s)", name, rank, maxRank), icon=tonumber(texture) or "Interface\\Icons\\"..texture});
    end

    return build, result;
end

