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
local container = "Inventory";

local inventoryFilter = "";
local inventoryState = {};

local mailTo = "";
local mailItems = {};

local unpack = unpack;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local time = time;
local strtrim = strtrim;
local strlower = strlower;
local strsub = strsub;
local max = max;
local type = type;
local string = string;
local tonumber = tonumber;
local tostring = tostring;
local sort = sort;
local format = format;
local issecretvalue = issecretvalue;

----------------------------------------------------------
-- Inventory Internals
----------------------------------------------------------

local function GetCharacterBankTabData(id)
    local tab = id - Enum.BagIndex.CharacterBankTab_1 + 1;
    local tabs = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Character);
    if ( tabs and tabs[tab] ) then
        return tabs[tab];
    end
    return {};
end

local function GetAccountBankTabData(id)
    local tab = id - Enum.BagIndex.AccountBankTab_1 + 1;
    local tabs = C_Bank.FetchPurchasedBankTabData(Enum.BankType.Account);
    if ( tabs and tabs[tab] ) then
        return tabs[tab];
    end
    return {};
end

-- Containers per family: Classic has the bank itself (BANK_CONTAINER) with bank bags,
-- Mainline has bank tabs and an account bank
local HAS_BANK_TABS = not Armory.isClassic;
local IsBagContainer, IsGenericBagContainer, IsCharacterContainer, IsAccountContainer, IsReagentContainer;
local HasBagSlot, GetBagItemLink, GetContainerName, GetNumProfessionGearSlots, CountProfessionGear;
if ( Armory.isClassic ) then
    IsBagContainer = function(id)
        return id >= BACKPACK_CONTAINER and id <= NUM_BAG_SLOTS;
    end
    IsGenericBagContainer = IsBagContainer;
    IsCharacterContainer = function(id)
        return id == BANK_CONTAINER or (id > NUM_BAG_SLOTS and id <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS);
    end
    IsAccountContainer = function(id)
        return false;
    end
    -- reagents only count in the bags
    IsReagentContainer = IsBagContainer;

    -- a container that is a bag in an inventory slot, including the bank bags
    HasBagSlot = function(id)
        return id > BACKPACK_CONTAINER and id <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS;
    end

    -- the item of a bag itself; the bank bags are in the bank's own slots
    GetBagItemLink = function(id)
        if ( id > BACKPACK_CONTAINER and id <= NUM_BAG_SLOTS ) then
            return Armory:GetInventoryItemLink("player", C_Container.ContainerIDToInventoryID(id));
        elseif ( id > NUM_BAG_SLOTS and id <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS ) then
            return Armory:GetContainerItemLink(BANK_CONTAINER, NUM_BANKGENERIC_SLOTS + id - NUM_BAG_SLOTS);
        end
    end
    GetContainerName = function(id, name)
        return C_Container.GetBagName(id) or name;
    end

    -- no profession gear
    GetNumProfessionGearSlots = function()
        return 0;
    end
    CountProfessionGear = function(itemId)
        return 0;
    end

    function Armory:GetCharacterContainerIndex(id)
        return id == BANK_CONTAINER and 0 or id - NUM_BAG_SLOTS;
    end
else
    IsBagContainer = function(id)
        return id >= Enum.BagIndex.Backpack and id <= NUM_TOTAL_BAG_FRAMES;
    end
    IsGenericBagContainer = function(id)
        return id >= Enum.BagIndex.Backpack and id <= Constants.InventoryConstants.NumBagSlots;
    end
    IsCharacterContainer = function(id)
        return id >= Enum.BagIndex.CharacterBankTab_1 and id <= Enum.BagIndex.CharacterBankTab_6;
    end
    IsAccountContainer = function(id)
        return id >= Enum.BagIndex.AccountBankTab_1 and id <= Enum.BagIndex.AccountBankTab_5;
    end
    IsReagentContainer = function(id)
        return IsBagContainer(id) or IsCharacterContainer(id);
    end

    HasBagSlot = IsBagContainer;

    GetBagItemLink = function(id)
        if ( IsBagContainer(id) ) then
            return Armory:GetInventoryItemLink("player", C_Container.ContainerIDToInventoryID(id));
        end
    end
    GetContainerName = function(id, name)
        if ( IsCharacterContainer(id ) ) then
            return GetCharacterBankTabData(id).name or name;
        elseif ( IsAccountContainer(id) ) then
            return GetAccountBankTabData(id).name or name;
        end
        return C_Container.GetBagName(id) or name;
    end

    -- the slots are defined by the paperdoll frame, which loads later
    GetNumProfessionGearSlots = function()
        return ARMORY_GEARSLOT_LAST_EQUIPPED - ARMORY_GEARSLOT_FIRST_EQUIPPED + 1;
    end
    CountProfessionGear = function(itemId)
        local count = 0;
        for slot = ARMORY_GEARSLOT_FIRST_EQUIPPED, ARMORY_GEARSLOT_LAST_EQUIPPED do
            if ( Armory:GetUniqueItemId(Armory:GetProfessionItems(slot)) == itemId ) then
                count = count + 1;
            end
        end
        return count;
    end

    function Armory:GetCharacterContainerIndex(id)
        return id - Enum.BagIndex.CharacterBankTab_1 + 1;
    end
end

local function IsBankContainer(id)
    return IsCharacterContainer(id) or IsAccountContainer(id);
end

function Armory:IsBag(id)
    if ( id ) then
        return IsBagContainer(id);
    end
end

local function InventoryContainerName(id)
    return "Container" .. id;
end

local function GetInventoryStateKey(line)
    local name, id, _, _, _, _, _, realm, character = unpack(line);
    if ( id ) then
        return (name or UNKNOWN)..(realm or "")..(character or "")..id;
    end
end

local inventoryLines = { player = {}, account = {} };
local inventoryList = { player = {}, account = {} };
local itemLines = { player = {}, account = {} };
local dirty = { player = true, account = true };
local owner = "";

local function GetInventoryLines(unit)
    local id, header, group;
    local containers = unit == "account" and ArmoryInventoryAccountContainers or ArmoryInventoryPlayerContainers;
    local link, name, numSlots, itemCount, itemId, isCollapsed, containerName;
    local currentProfile = Armory:CurrentProfile();
    local numRealms = table.getn(Armory:RealmList());

    table.wipe(inventoryLines[unit]);
    table.wipe(inventoryList[unit]);

    if ( unit == "player" and Armory.inventorySearchAll ) then
        for _, realm in ipairs(Armory:RealmList()) do
            for _, character in ipairs(Armory:CharacterList(realm)) do
                table.insert(inventoryList[unit], {realm=realm, character=character});
            end
        end
    else
        table.insert(inventoryList[unit], currentProfile);
    end

    for _, profile in ipairs(inventoryList[unit]) do
        Armory:SelectProfile(profile);

        if ( unit == "player" and Armory.inventorySearchAll ) then
            if ( numRealms > 1 ) then
                group = {profile.character.." ("..profile.realm..")", nil, 0};
            else
                group = {profile.character, nil, 0};
            end
        end

        for i = 1, #containers do
            id = containers[i];
            name, numSlots, isCollapsed, containerName = Armory:GetInventoryContainerInfoEx(id);
            header = {name, id, numSlots, isCollapsed, true, nil, nil, profile.realm, profile.character, 0, containerName};
            if ( numSlots and numSlots > 0 ) then
                table.wipe(itemLines[unit]);
                for index = 1, numSlots do
                    link = Armory:GetContainerItemLink(id, index);
                    name = Armory:GetNameFromLink(link);
                    if ( name and Armory:MatchInventoryItem(inventoryFilter, name, link, true) ) then
                        _, itemCount = Armory:GetContainerItemInfo(id, index);
                        table.insert(itemLines[unit], {name, id, itemCount, nil, nil, index, link, profile.realm, profile.character});
                    else
                        -- free slot
                        header[10] = header[10] + 1;
                    end
                end
                if ( #itemLines[unit] == 0 and not Armory:InventoryFilterActive() ) then
                    table.insert(itemLines[unit], {EMPTY, id, 0, nil, nil, 0, nil, profile.realm, profile.character});
                end
                if ( #itemLines[unit] > 0 ) then
                    if ( group ) then
                        table.insert(inventoryLines[unit], group);
                        group = nil;
                    end
                    table.insert(inventoryLines[unit], header);
                    -- if inventory of all characters is viewed the states are kept in a separate state table
                    if ( unit == "player" and Armory.inventorySearchAll ) then
                        isCollapsed = inventoryState[GetInventoryStateKey(header)];
                    end
                    if ( not isCollapsed ) then
                        table.sort(itemLines[unit], function(a, b) return a[1] < b[1] end);
                        for _, v in ipairs(itemLines[unit]) do
                            table.insert(inventoryLines[unit], v);
                        end
                    end
                end
            end
        end
    end

    Armory:SelectProfile(currentProfile);

    dirty[unit] = false;
    owner = Armory:SelectedCharacter();

    return inventoryLines[unit];
end

local function UpdateContainerState(id, isCollapsed)
    if ( id == 9999 ) then
        for _, id in ipairs(ArmoryInventoryContainers) do
            UpdateContainerState(id, isCollapsed)
        end
    else
        local itemContainer = InventoryContainerName(id);
        local dbEntry = IsAccountContainer(id) and Armory.sharedDbEntry or Armory.selectedDbBaseEntry;
        if ( dbEntry ) then
            if ( id == ARMORY_EQUIPMENT_CONTAINER or dbEntry:Contains(container, itemContainer) ) then
                Armory:SetHeaderLineState(container, itemContainer, isCollapsed);
            end
        end
    end
end

local function UpdateInventoryState(unit, id, state)
    if ( not Armory.inventorySearchAll ) then
        if ( id == 9999 ) then
            for i = 1, #inventoryLines[unit] do
                UpdateInventoryState(unit, i, state);
            end
        else
            local _, containerId, _, _, isHeader = Armory:GetInventoryLineInfo(id, unit);
            if ( isHeader ) then
                UpdateContainerState(containerId, state);
            end
        end
    elseif ( id == 9999 ) then
        if ( state ) then
            for i = 1, #inventoryLines[unit] do
                UpdateInventoryState(unit, i, state);
            end
        else
            table.wipe(inventoryState);
        end
    elseif ( id > 0 and id <= #inventoryLines[unit] ) then
        local key = GetInventoryStateKey(inventoryLines[unit][id]);
        local isHeader = inventoryLines[unit][id][5];
        if ( key ) then
            if ( state and isHeader ) then
                inventoryState[key] = 1;
            else
                inventoryState[key] = nil;
            end
        end
    end
end

local function ArtifactIsHeirloomColor()
    local _, _, _, artifactColor = C_Item.GetItemQualityColor(6);
    local _, _, _, heirloomColor = C_Item.GetItemQualityColor(7);
    return (artifactColor == heirloomColor);
end

----------------------------------------------------------
-- Inventory Caching
----------------------------------------------------------

local function SetItemCache(itemContainer, link, count, unit)
    if ( Armory:GetConfigShowItemCount() and not Armory:GetConfigUseEncoding() ) then
        local dbEntry = Armory.selectedDbBaseEntry;
        if ( unit == "account" ) then
            dbEntry = Armory.sharedDbEntry;
        elseif ( unit == "player" ) then
            dbEntry = Armory.playerDbBaseEntry;
        end

        local itemId = Armory:GetUniqueItemId(link);
        if ( dbEntry and itemId ) then
            if ( dbEntry:Contains(container, itemContainer, ARMORY_CACHE_CONTAINER, itemId) ) then
                local cache = dbEntry:GetValue(container, itemContainer, ARMORY_CACHE_CONTAINER);
                cache[itemId] = cache[itemId] + count;
            else
                dbEntry:SetValue(4, container, itemContainer, ARMORY_CACHE_CONTAINER, itemId, count);
            end
        end
    end
end

local function GetCachedItemCount(itemContainer, itemString, unit)
    local dbEntry = unit == "account" and Armory.sharedDbEntry or Armory.selectedDbBaseEntry;
    if ( dbEntry and itemString ) then
        local itemId = Armory:GetUniqueItemId("item:"..itemString);
        return dbEntry:GetValue(container, itemContainer, ARMORY_CACHE_CONTAINER, itemId) or 0;
    end
    return 0;
end

local function RemoveFromItemCache(itemContainer, itemId, count, unit)
    local dbEntry = unit == "account" and Armory.sharedDbEntry or Armory.playerDbBaseEntry;
    if ( dbEntry and dbEntry:Contains(container, itemContainer, ARMORY_CACHE_CONTAINER, itemId) ) then
        local cache = dbEntry:GetValue(container, itemContainer, ARMORY_CACHE_CONTAINER);
        local remaining = cache[itemId] - count;
        if ( remaining > 0 ) then
            cache[itemId] = remaining;
        else
            cache[itemId] = nil;
        end
    end
end

local function ClearItemCache(itemContainer, unit)
    local dbEntry = Armory.selectedDbBaseEntry;
    if ( unit == "player" ) then
        dbEntry = Armory.playerDbBaseEntry;
    elseif ( unit == "account" ) then
        dbEntry = Armory.sharedDbEntry;
    end
    if ( dbEntry ) then
        dbEntry:SetValue(3, container, itemContainer, ARMORY_CACHE_CONTAINER, nil);
    end
end

local function ItemCacheExists(itemContainer, unit)
    local dbEntry = unit == "account" and Armory.sharedDbEntry or Armory.selectedDbBaseEntry;
    return dbEntry and dbEntry:Contains(container, itemContainer, ARMORY_CACHE_CONTAINER);
end

----------------------------------------------------------
-- Inventory Storage
----------------------------------------------------------

local function SetInventoryValue(dbEntry, itemContainer, index, texture, count, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp)
    dbEntry:SetValue(3, container, itemContainer, index, texture, count, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp);
end

local function GetInventoryValue(dbEntry, itemContainer, index)
    return dbEntry:GetValue(container, itemContainer, index);
end

local function ClearInventoryValue(dbEntry, itemContainer, index)
    dbEntry:SetValue(3, container, itemContainer, index, nil);
end

local function SetContainerInfo(dbEntry, itemContainer, name, numSlots, remaining, timestamp, outOfSync)
    dbEntry:SetValue(3, container, itemContainer, "Info", name, numSlots, remaining, timestamp or time(), outOfSync);
end

local function GetContainerInfo(dbEntry, itemContainer)
    return dbEntry:GetValue(container, itemContainer, "Info");
end

local function UpdateContainerName(dbEntry, id, containerName)
    local itemContainer = InventoryContainerName(id);
    local name, numSlots, remaining, timestamp = GetContainerInfo(dbEntry, itemContainer);
    
    SetContainerInfo(dbEntry, itemContainer, containerName or name, numSlots, remaining, timestamp);
end

-- Tinkers (engineering on gloves, belt and cloak) only exist in Mainline
local GetTinker;
if ( Armory.isClassic ) then
    GetTinker = function(id, slotId, link)
    end
else
    GetTinker = function(id, slotId, link)
        if ( link and (IsGenericBagContainer(id) or IsCharacterContainer(id) or IsAccountContainer(id)) and C_Item.IsEquippableItem(link) ) then
            local _, _, _, equipLoc = C_Item.GetItemInfoInstant(link);
            if ( equipLoc == "INVTYPE_HAND" or equipLoc == "INVTYPE_WAIST" or equipLoc == "INVTYPE_CLOAK" ) then
                local tooltip1 = Armory:AllocateTooltip();
                local tooltip2 = Armory:AllocateTooltip();
                tooltip1:SetBagItem(id, slotId);
                tooltip2:SetHyperlink(link);
                local tinker, anchor = Armory:GetTinkerFromTooltip(tooltip1, tooltip2);
                Armory:ReleaseTooltip(tooltip2);
                Armory:ReleaseTooltip(tooltip1);
                return tinker, anchor;
            end
        end
    end
end

local function SetSlotInfo(id, index, texture, count, quality, link, expires, equipable, slotId, ignorable)
    local dbEntry = IsAccountContainer(id) and Armory.sharedDbEntry or Armory.playerDbBaseEntry;
    local itemContainer = InventoryContainerName(id);
    if ( not dbEntry ) then
        return;
    end

    if ( link and issecretvalue(link) ) then
        link = nil;
    end

    local tinker, anchor = GetTinker(id, slotId, link);

    SetInventoryValue(dbEntry, itemContainer, index, texture, count, quality, link, expires, equipable, slotId, ignorable, tinker, anchor);
end

local function ClearSlotInfo(itemContainer, index, unit)
    local dbEntry = unit == "account" and Armory.sharedDbEntry or Armory.playerDbBaseEntry;
    if ( dbEntry ) then
        ClearInventoryValue(dbEntry, itemContainer, index);
    end
end

function Armory:ContainerExists(id, unit)
    local dbEntry = self.selectedDbBaseEntry;
    if ( unit == "account" ) then
        dbEntry = self.sharedDbEntry;
    elseif ( unit == "player" ) then
        dbEntry = self.playerDbBaseEntry;
    end

    local itemContainer = InventoryContainerName(id);
    if ( dbEntry ) then
        return dbEntry:Contains(container, itemContainer);
    end
end

function Armory:ClearInventory()
    self:ClearModuleData(container);
    dirty.player = true;
    dirty.account = true;
end

-- Owned auctions per family: Classic still has the old auction house API
local GetNumOwnedAuctions, GetOwnedAuction;
if ( Armory.isClassic ) then
    GetNumOwnedAuctions = function()
        return _G.GetNumAuctionItems("owner");
    end
    GetOwnedAuction = function(index)
        local _, texture, count, quality, _, _, _, _, _, _, _, _, _, _, _, saleStatus = _G.GetAuctionItemInfo("owner", index);
        if ( texture and saleStatus ~= 1 ) then
            return texture, count, quality, _G.GetAuctionItemLink("owner", index), _G.GetAuctionItemTimeLeft("owner", index);
        end
    end
else
    GetNumOwnedAuctions = function()
        return C_AuctionHouse.GetNumOwnedAuctions();
    end
    GetOwnedAuction = function(index)
        local info = C_AuctionHouse.GetOwnedAuctionInfo(index);
        if ( info and info.itemKey and info.status ~= Enum.AuctionStatus.Sold ) then
            local link, timeLeft, count = info.itemLink, info.timeLeftSeconds, info.quantity;
            info = C_AuctionHouse.GetItemKeyInfo(info.itemKey);
            if ( info and info.iconFileID ) then
                return info.iconFileID, count, info.quality, link, timeLeft;
            end
        end
    end
end

function Armory:SetContainer(id)
    local itemContainer = InventoryContainerName(id);
    local dbEntry = IsAccountContainer(id) and self.sharedDbEntry or self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    -- Make sure money gets updated
    self:GetMoney();

    dirty.player = dirty.player or self:IsPlayerSelected();
    dirty.account = self:IsPlayerSelected();

    if ( not self:HasInventory() ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    -- bank tabs can be read while the bank is closed, but the client does not always have the data;
    -- do not wipe what is stored in that case (in Classic an empty bank bag slot is 0 as well)
    if ( HAS_BANK_TABS and IsBankContainer(id) and C_Container.GetContainerNumSlots(id) == 0 ) then
        local _, oldNum = GetContainerInfo(dbEntry, itemContainer);
        if ( (oldNum or 0) > 0 ) then
            return;
        end
    end

    -- signal some update triggers
    local name, numSlots = self:GetInventoryContainerInfo(id, "player");
    local link, texture;
    if ( HasBagSlot(id) ) then
        -- if stored within container, see below
        local bagSlot = C_Container.ContainerIDToInventoryID(id);
        link = self:GetInventoryItemLink("player", bagSlot);
        texture = self:GetInventoryItemTexture("player", bagSlot);
    end

    if ( not self:IsLocked(itemContainer) ) then
        self:Lock(itemContainer);

        self:PrintDebug("UPDATE", itemContainer);

        local _, oldNum = GetContainerInfo(dbEntry, itemContainer);

        local daysLeft, timeLeft, count, quality, remaining;
        local nextSlot = 1;

        local unit = IsAccountContainer(id) and "account" or "player";

        ClearItemCache(itemContainer, unit);

        if ( id == ARMORY_MAIL_CONTAINER ) then
            local sender, itemCount;
            numSlots, count = _G.GetInboxNumItems();
            if ( count > numSlots ) then
                remaining = count - numSlots;
            end

            local warned;
            for index = 1, numSlots do
                _, _, sender, _, _, _, daysLeft, itemCount = _G.GetInboxHeaderInfo(index);
                if ( itemCount ) then
                    local ignorable;
                    if ( not sender ) then
                        if ( not warned ) then
                            self:PrintWarning(ARMORY_MAIL_COUNT_WARNING3);
                            warned = true;
                        end
                    elseif ( not _G.InboxItemCanDelete(index) ) then
                        -- original message from player (can be cross faction for account bound items)
                        for _, profile in ipairs(self:Profiles()) do
                            if ( self:IsMyMail(sender, profile) ) then
                                ignorable = true;
                                break;
                            end
                        end
                    end
                    for i = 1, ATTACHMENTS_MAX_RECEIVE do
                        _, _, texture, count, quality = _G.GetInboxItem(index, i);
                        if ( texture ) then
                            link = _G.GetInboxItemLink(index, i);
                            SetSlotInfo(id, nextSlot, texture, count, quality, link, daysLeft, self:CanEquip(link), nil, ignorable);
                            SetItemCache(itemContainer, link, count, unit);
                            nextSlot = nextSlot + 1;
                        end
                    end
                end
            end

            if ( warned ) then
                self:PlayWarningSound();
            end

        elseif ( id == ARMORY_AUCTIONS_CONTAINER or id == ARMORY_NEUTRAL_AUCTIONS_CONTAINER ) then
            for i = 1, GetNumOwnedAuctions() do
                texture, count, quality, link, timeLeft = GetOwnedAuction(i);
                if ( texture ) then
                    SetSlotInfo(id, nextSlot, texture, count, quality, link, timeLeft);
                    SetItemCache(itemContainer, link, count, unit);
                    nextSlot = nextSlot + 1;
                end
            end

        else
            for i = 1, C_Container.GetContainerNumSlots(id) do
                local info = C_Container.GetContainerItemInfo(id, i);
                if ( info and info.iconFileID ) then
                    SetSlotInfo(id, nextSlot, info.iconFileID, info.stackCount, info.quality, info.hyperlink, nil, self:CanEquip(info.hyperlink), i);
                    SetItemCache(itemContainer, info.hyperlink, info.stackCount, unit);
                    nextSlot = nextSlot + 1;
                end
            end

        end

        for index = nextSlot, (oldNum or 0) do
            ClearSlotInfo(itemContainer, index, unit);
        end

        if ( id == BANK_CONTAINER ) then
            -- Classic: the bank itself
            numSlots = NUM_BANKGENERIC_SLOTS;
        elseif ( id > ARMORY_MAIL_CONTAINER ) then
            numSlots = C_Container.GetContainerNumSlots(id);
            name = GetContainerName(id, name);
        else
            numSlots = nextSlot - 1;
        end

        SetContainerInfo(dbEntry, itemContainer, name, numSlots, remaining, time());

        self:Unlock(itemContainer);
    else
        self:PrintDebug("LOCKED", itemContainer);
    end
end

function Armory:SetMailSent(name)
    mailTo = strtrim(name);
    table.wipe(mailItems);

    local link, itemID, texture, count, quality;
    for i = 1, ATTACHMENTS_MAX_SEND do
        if ( _G.HasSendMailItem(i) ) then
            _, itemID, texture, count, quality = _G.GetSendMailItem(i);
            if ( itemID ) then
                _, link = C_Item.GetItemInfo(itemID);

                local itemInfo = {};
                itemInfo.Texture = texture;
                itemInfo.Count = count;
                itemInfo.Quality = quality;
                itemInfo.Link = link;
                itemInfo.Ignorable = true;
                table.insert(mailItems, itemInfo);
            end
        end
    end
end

function Armory:SetMailReturned(id)
    local _, _, sender, _, _, _, _, itemCount = _G.GetInboxHeaderInfo(id);

    mailTo = sender or "";
    table.wipe(mailItems);

    local texture, count, quality;
    if ( itemCount ) then
        for i = 1, ATTACHMENTS_MAX_RECEIVE do
            _, _, texture, count, quality = _G.GetInboxItem(id, i);
            if ( texture ) then
                local itemInfo = {};
                itemInfo.Texture = texture;
                itemInfo.Count = count;
                itemInfo.Quality = quality;
                itemInfo.Link = _G.GetInboxItemLink(id, i);
                table.insert(mailItems, itemInfo);
            end
        end
        ArmoryInventoryFrame_UpdateFrame(Armory:AddMail());
    end
end

function Armory:IsMyMail(address, profile)
    local character, realm;
    local pos = address:find("%-");
    if ( pos ) then
        character = address:sub(1, pos - 1);
        realm = self:GetPostalRealmName(address:sub(pos + 1));
    else
        character = address;
        realm = self.playerRealm;
    end
    return strlower(profile.realm .. profile.character) == strlower(realm .. character);
end

function Armory:AddMail()
    local id = ARMORY_MAIL_CONTAINER;
    local numItems = #mailItems;

    if ( self:HasInventory() and mailTo ~= "" and numItems > 0 ) then
        local currentProfile = self:CurrentProfile();
        local itemContainer = InventoryContainerName(id);
        local dbEntry, name, numSlots, remaining, timestamp, index, itemInfo;
        for _, profile in ipairs(self:Profiles()) do
            -- mail can be cross faction (account bound items)
            if ( self:IsMyMail(mailTo, profile) ) then
                self:SelectProfile(profile);

                dbEntry = self.selectedDbBaseEntry;
                name, numSlots, remaining, timestamp = GetContainerInfo(dbEntry, itemContainer);
                index = (numSlots or 0);

                SetContainerInfo(dbEntry, itemContainer, name, index + numItems, remaining, timestamp);

                for i = 1, numItems do
                    itemInfo = mailItems[i];
                    index = index + 1;

                    SetInventoryValue(dbEntry, itemContainer, index, itemInfo.Texture, itemInfo.Count, itemInfo.Quality, itemInfo.Link, 30, self:CanEquip(itemInfo.Link), nil, itemInfo.Ignorable, _, _, time());

                    SetItemCache(itemContainer, itemInfo.Link, itemInfo.Count);
                end

                dirty.player = dirty.player or self:IsPlayerSelected();
                break;
            end
        end
        self:SelectProfile(currentProfile);
    end

    mailTo = "";

    return dirty.player;
end

local updater = ArmoryBackgroundUpdater:new();

function Armory:UpdateInventoryEquippable()
    local semaphore = "Equippable";
    if ( not self:IsLocked(semaphore) ) then
        self:Lock(semaphore);

        self:PrintDebug("UPDATE", semaphore);

        updater:Start(
            function(updater)
                local id, itemContainer, numSlots;
                local texture, count, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp;
                for i = 1, #ArmoryInventoryContainers do
                    id = ArmoryInventoryContainers[i];
                    if ( id > ARMORY_AUCTIONS_CONTAINER ) then
                        itemContainer = InventoryContainerName(id);
                        if ( not self:IsLocked(itemContainer) ) then
                            self:Lock(itemContainer);

                            self:PrintDebug("UPDATE (equip)", itemContainer);

                            local dbEntry = IsAccountContainer(id) and self.sharedDbEntry or self.playerDbBaseEntry;
                            if ( dbEntry ) then
                                _, numSlots = GetContainerInfo(dbEntry, itemContainer);
                                if ( numSlots ) then
                                    for index = 1, numSlots do
                                        texture, count, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp = GetInventoryValue(dbEntry, itemContainer, index);
                                        if ( not equipable and link ) then
                                            equipable = self:CanEquip(link);
                                            SetInventoryValue(dbEntry, itemContainer, index, texture, count, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp);
                                        end
                                    end
                                end
                            end

                            self:Unlock(itemContainer);

                            updater:Suspend();
                        else
                            self:PrintDebug("LOCKED (equip)", itemContainer);
                        end
                    end
                end

                self:Unlock(semaphore);
            end
        );
    else
        self:PrintDebug("LOCKED", semaphore);
    end
end

local auctionItems = {};
function Armory:RemoveOldAuctions()
    if ( self:HasInventory() ) then
        local currentProfile = self:CurrentProfile();
        local name, numSlots, remaining, timestamp;

        for _, profile in ipairs(self:Profiles()) do
            self:SelectProfile(profile);
            mailTo = profile.character;
            table.wipe(mailItems);

            for _, id in ipairs( { ARMORY_AUCTIONS_CONTAINER, ARMORY_NEUTRAL_AUCTIONS_CONTAINER } ) do
                local dbEntry = self.selectedDbBaseEntry;
                local itemContainer = InventoryContainerName(id);

                name, numSlots, remaining, timestamp = GetContainerInfo(dbEntry, itemContainer);
                if ( numSlots and numSlots > 0 ) then
                    table.wipe(auctionItems);
                    for i = 1, numSlots do
                        local itemInfo = {};
                        itemInfo.Texture, itemInfo.Count, itemInfo.Quality, itemInfo.Link, itemInfo.Expires, _, _, _, _, _, itemInfo.timestamp = GetInventoryValue(dbEntry, itemContainer, i);
                        if ( time() - (itemInfo.timestamp or timestamp or time()) <= 48 * 60 * 60 ) then
                            table.insert(auctionItems, itemInfo);
                        else
                            table.insert(mailItems, itemInfo);
                        end
                    end

                    local newNum = #auctionItems;
                    if ( newNum ~= numSlots ) then
                        ClearItemCache(itemContainer);

                        SetContainerInfo(dbEntry, itemContainer, name, newNum, remaining, timestamp);
                        for i = 1, max(newNum, numSlots) do
                            if ( i > newNum ) then
                                ClearInventoryValue(dbEntry, itemContainer, i);
                            else
                                local itemInfo = auctionItems[i];
                                SetInventoryValue(dbEntry, itemContainer, i, itemInfo.Texture, itemInfo.Count, itemInfo.Quality, itemInfo.Link, itemInfo.Expires, nil, nil, nil, nil, nil, itemInfo.timestamp);
                                SetItemCache(itemContainer, itemInfo.Link, itemInfo.Count);
                            end
                        end
                    end
                end
            end
            self:AddMail();
            self:SelectProfile(currentProfile);
        end
    end
end

----------------------------------------------------------
-- Inventory Hooks
----------------------------------------------------------

do
    hooksecurefunc("SendMail", function(name)
        Armory:SetMailSent(name);
    end);

    hooksecurefunc("ReturnInboxItem", function(id)
        Armory:SetMailReturned(id);
    end);
end

----------------------------------------------------------
-- Inventory Interface
----------------------------------------------------------

function Armory:UpdateCharacterContainerName(id)
    UpdateContainerName(self.playerDbBaseEntry, id, GetCharacterBankTabData(id).name)
end

function Armory:UpdateAccountContainerName(id)
    local dbEntry = self.sharedDbEntry;
    UpdateContainerName(self.sharedDbEntry, id, GetAccountBankTabData(id).name);
end

function Armory:GetAccountContainerIndex(id)
    return id - Enum.BagIndex.AccountBankTab_1 + 1;
end

function Armory:GetInventoryContainerInfo(id, unit)
    local dbEntry = self.selectedDbBaseEntry;
    if ( IsAccountContainer(id) ) then
        dbEntry = self.sharedDbEntry;
    elseif ( unit == "player" ) then
        dbEntry = self.playerDbBaseEntry;
    end

    local itemContainer = InventoryContainerName(id);
    local isCollapsed = self:GetHeaderLineState(container, itemContainer);
    local name, numSlots, timestamp, outOfSync;
    if ( id == ARMORY_EQUIPMENT_CONTAINER ) then
        name = ARMORY_EQUIPMENT;
        numSlots = INVSLOT_LAST_EQUIPPED - INVSLOT_FIRST_EQUIPPED + 1 + GetNumProfessionGearSlots();
    elseif ( dbEntry ) then
        name, numSlots, _, timestamp, outOfSync = GetContainerInfo(dbEntry, itemContainer);
    end

    return name, numSlots or 0, isCollapsed, timestamp or time(), outOfSync;
end

function Armory:GetInventoryContainerInfoEx(id, unit)
    local containerName, numSlots, isCollapsed, _, outOfSync = self:GetInventoryContainerInfo(id, unit);
    local name;

    if ( id == BANK_CONTAINER ) then
        -- Classic: the bank itself
        name = ARMORY_BANK_CONTAINER_NAME;
    elseif ( id == ARMORY_MAIL_CONTAINER ) then
        name = INBOX;
    elseif ( id == ARMORY_AUCTIONS_CONTAINER ) then
        name = AUCTIONS;
    elseif ( id == ARMORY_NEUTRAL_AUCTIONS_CONTAINER ) then
        name = format(COLORBLIND_NAMEWRAPPER_NEUTRAL, AUCTIONS);
    elseif ( id == ARMORY_EQUIPMENT_CONTAINER ) then
        name = ARMORY_EQUIPPED;
    elseif ( IsAccountContainer(id) ) then
        name = ACCOUNT_BANK_PANEL_TITLE;
    elseif ( containerName ) then
        local prefix = "";
        if ( IsCharacterContainer(id) ) then
            prefix = ARMORY_BANK_CONTAINER_NAME.." #"..self:GetCharacterContainerIndex(id).." - ";
            if ( outOfSync ) then
                -- contents were corrected without reading the bank itself
                prefix = "~"..prefix;
            end
        elseif ( id > 0 ) then
            prefix = "#"..id.." - ";
        end
        name = prefix..format(CONTAINER_SLOTS, numSlots, containerName);
    else
        name = UNKNOWN;
    end

    return name, numSlots, isCollapsed, containerName;
end

function Armory:GetInventoryContainerValue(id, index, unit)
    local dbEntry = self.selectedDbBaseEntry;
    if ( IsAccountContainer(id) ) then
        dbEntry = self.sharedDbEntry;
    elseif ( unit == "player" ) then
        dbEntry = self.playerDbBaseEntry;
    end

    if ( dbEntry ) then
        local itemContainer = InventoryContainerName(id);
        if ( id == ARMORY_EQUIPMENT_CONTAINER ) then
            local texture, quality, link;
            if ( index >= INVSLOT_FIRST_EQUIPPED and index <= INVSLOT_LAST_EQUIPPED ) then
                texture = dbEntry:GetValue("InventoryItemTexture"..index);
                quality = dbEntry:GetValue("InventoryItemQuality"..index);
                link = dbEntry:GetValue("InventoryItemLink"..index);
            elseif ( index >= ARMORY_GEARSLOT_FIRST_EQUIPPED and index <= ARMORY_GEARSLOT_LAST_EQUIPPED ) then
                link, texture, quality = self:GetProfessionItems(index);
            end
            return texture, 1, quality, link;
        elseif ( type(index) == "number" ) then
            return GetInventoryValue(dbEntry, itemContainer, index);
        else
            return GetContainerInfo(dbEntry, itemContainer);
        end
    end
end

function Armory:GetBagName(id)
    return ( self:GetInventoryContainerInfo(id) );
end

function Armory:GetNumRemainingMailItems(unit)
    local _, _, remaining = self:GetInventoryContainerValue(ARMORY_MAIL_CONTAINER, nil, unit);
    return remaining or 0;
end

function Armory:GetContainerNumSlots(id)
    local _, numSlots = self:GetInventoryContainerInfo(id);
    return numSlots or 0;
end

function Armory:GetContainerItemInfo(id, index)
    -- GetContainerItemInfo returns: texture, itemCount, locked, quality, readable
    local texture, count, quality = self:GetInventoryContainerValue(id, index);
    return texture, count, nil, quality, nil;
end

function Armory:GetContainerItemLink(id, index)
    local _, _, _, link, _, _, _, _, tinker, anchor = self:GetInventoryContainerValue(id, index);
    return link, tinker, anchor;
end

function Armory:GetContainerItemExpiration(id, index)
    local dbEntry = self.selectedDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    local itemContainer = InventoryContainerName(id);
    local _, _, _, _, expires, _, _, ignorable, _, _, timestamp = GetInventoryValue(dbEntry, itemContainer, index);
    if ( not timestamp ) then
        _, _, _, timestamp = GetContainerInfo(dbEntry, itemContainer);
    end
    local remaining = time() - timestamp;
    if ( id == ARMORY_MAIL_CONTAINER and expires ) then
        expires = expires - remaining / (24 * 60 * 60);
    end
    return expires, ignorable, remaining;
end

function Armory:GetContainerItemCanEquip(id, index)
    local _, _, _, _, _, _, equipable = self:GetInventoryContainerValue(id, index);
    return equipable;
end

function Armory:GetNumInventoryLines(unit)
    if ( ArmoryItemFilter_IsUpdated() ) then
        dirty.player = true;
        dirty.account = true;
    end
    if ( dirty[unit] or (unit == "player" and not self:IsSelectedCharacter(owner)) ) then
        GetInventoryLines(unit);
    end
    return #inventoryLines[unit];
end

function Armory:GetInventoryLineInfo(index, unit)
    local numLines = self:GetNumInventoryLines(unit);
    if ( index > 0 and index <= numLines ) then
        return unpack(inventoryLines[unit][index]);
    end
end

function Armory:GetInventoryLineState(id, unit)
    local isCollapsed;
    if ( self.inventorySearchAll ) then
        local key = GetInventoryStateKey(inventoryLines[unit][id]);
        if ( key ) then
            isCollapsed = inventoryState[key];
        end
    else
        _, _, _, isCollapsed = Armory:GetInventoryLineInfo(id, unit);
    end
    return isCollapsed;
end

function Armory:ExpandContainer(id)
    UpdateContainerState(id, false);
    dirty[IsAccountContainer(id) and "account" or "player"] = true;
end

function Armory:CollapseContainer(id)
    UpdateContainerState(id, true);
    dirty[IsAccountContainer(id) and "account" or "player"] = true;
end

function Armory:ExpandInventoryHeader(id, unit)
    UpdateInventoryState(unit, id, false);
    dirty[unit] = true;
end

function Armory:CollapseInventoryHeader(id, unit)
    UpdateInventoryState(unit, id, true);
    dirty[unit] = true;
end

function Armory:InventoryFilterActive()
    return (inventoryFilter ~= "" or ArmoryItemFilter_IsEnabled());
end

function Armory:MatchInventoryItem(filter, name, link, emptyMatch)
    local match;

    if ( filter == "" ) then
        match = ArmoryItemFilter(link);
        if ( not emptyMatch ) then
            match = match and ArmoryItemFilter_IsEnabled();
        end
    else
        if ( string.match(filter, "^=%d$") ) then
            local quality = tonumber(strsub(filter, 2));
            local _, _, itemRarity = C_Item.GetItemInfo(link);
            if ( itemRarity ) then
                match = (itemRarity == quality);
            elseif ( quality == 7 and ArtifactIsHeirloomColor() ) then
                match = (self:GetQualityFromLink(link) == 6);
            else
                match = (self:GetQualityFromLink(link) == quality);
            end
        else
            match = string.find(strlower(name), strlower(filter), 1, true);
        end
        match = match and ArmoryItemFilter(link);
    end
    return match;
end

function Armory:NormalizeInventoryFilterText(text)
    if ( strsub(text, 1, 1) == "=" ) then
        text = strlower(strsub(text, 2));
        if ( not tonumber(text) ) then
            for i = 0, 7 do
                if ( text == strlower(_G["ITEM_QUALITY"..i.."_DESC"]) ) then
                    text = tostring(i);
                    break;
                end
            end
        end
        if ( not text:match("[0-7]") ) then
            return;
        end
        text = "="..text;
    end
    return text;
end

function Armory:SetInventoryItemNameFilter(text)
    local refresh;
    text = self:NormalizeInventoryFilterText(text);
    if ( text ) then
        refresh = (inventoryFilter ~= text);
        inventoryFilter = text;
        if ( refresh ) then
            dirty.player = true;
            dirty.account = true;
            table.wipe(inventoryState);
        end
    end
    return refresh;
end

function Armory:GetInventoryItemNameFilter()
    return inventoryFilter;
end

function Armory:SetInventorySearchAllFilter(searchAll)
    local refresh = (self.inventorySearchAll ~= searchAll);
    self.inventorySearchAll = searchAll;
    if ( refresh ) then
        dirty.player = true;
        dirty.account = true;
        table.wipe(inventoryState);
    end
    return refresh;
end

function Armory:GetInventorySearchAllFilter()
    return self.inventorySearchAll;
end

local function SetBankOutOfSync(dbEntry)
    for id = Enum.BagIndex.CharacterBankTab_1, Enum.BagIndex.CharacterBankTab_6 do
        local itemContainer = InventoryContainerName(id);
        if ( dbEntry:Contains(container, itemContainer) ) then
            local name, numSlots, remaining, timestamp = GetContainerInfo(dbEntry, itemContainer);
            SetContainerInfo(dbEntry, itemContainer, name, numSlots, remaining, timestamp, true);
        end
    end
end

local function RemoveBankItems(dbEntry, itemString, count)
    local itemId = Armory:GetUniqueItemId("item:"..itemString);
    for id = Enum.BagIndex.CharacterBankTab_6, Enum.BagIndex.CharacterBankTab_1, -1 do
        local itemContainer = InventoryContainerName(id);
        local _, numSlots = GetContainerInfo(dbEntry, itemContainer);
        local taken = 0;
        for index = (numSlots or 0), 1, -1 do
            local texture, slotCount, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp = GetInventoryValue(dbEntry, itemContainer, index);
            if ( link and (slotCount or 0) > 0 and Armory:GetUniqueItemId(link) == itemId ) then
                local removed = slotCount;
                if ( removed > count ) then
                    removed = count;
                end
                if ( removed == slotCount ) then
                    ClearInventoryValue(dbEntry, itemContainer, index);
                else
                    SetInventoryValue(dbEntry, itemContainer, index, texture, slotCount - removed, quality, link, expires, equipable, slotId, ignorable, tinker, anchor, timestamp);
                end
                count = count - removed;
                taken = taken + removed;
                if ( count == 0 ) then
                    break;
                end
            end
        end
        if ( taken > 0 ) then
            RemoveFromItemCache(itemContainer, itemId, taken, "player");
        end
        if ( count == 0 ) then
            return;
        end
    end
end

-- The character bank can only be scanned while its tabs are accessible (e.g. a profession is open),
-- but the client always knows how many of an item it holds. Adjust the stored contents with that
-- number, so the counts of this character remain correct for its alts as well, and mark the bank as
-- out of sync until it has been visited again.
local function ReconcileBankCount(result, itemString)
    local dbEntry = Armory.playerDbBaseEntry;
    local itemId = tonumber(itemString and itemString:match("^%d+"));
    if ( not (dbEntry and itemId) ) then
        return;
    end

    local bagCount = C_Item.GetItemCount(itemId);
    if ( bagCount ~= result.bags ) then
        -- counts cannot be compared (e.g. several variants share this item id)
        return;
    end

    local bankCount = C_Item.GetItemCount(itemId, true, false, true, false) - bagCount;
    if ( bankCount == result.bank ) then
        return;
    end

    if ( bankCount < result.bank ) then
        RemoveBankItems(dbEntry, itemString, result.bank - bankCount);
    end
    SetBankOutOfSync(dbEntry);

    result.count = result.count - result.bank + bankCount;
    result.bank = bankCount;
    result.bankEstimate = true;
    if ( result.perSlot ) then
        -- the tabs the items were taken from are unknown
        result.perSlot.bank = nil;
    end
end

local scanItem = {};
function Armory:ScanInventory(link, scanType)
    local count, bagCount, bankCount, mailCount, auctionCount, accountCount = 0, 0, 0, 0, 0, 0;
    local perSlotCount, result, bankEstimate;
    if ( link ) then
        scanItem[1] = link;
        result = self:ScanInventoryItems(scanItem, scanType)[1];
        count = result.count;
        bagCount = result.bags;
        bankCount = result.bank;
        mailCount = result.mail;
        auctionCount = result.auction;
        perSlotCount = result.perSlot;
        accountCount = result.account;
        bankEstimate = result.bankEstimate;
    end
    return count, bagCount, bankCount, mailCount, auctionCount, perSlotCount, accountCount, bankEstimate;
end

local scanResult = {};
function Armory:ScanInventoryItems(items, scanType)
    local reagentScan = (scanType == "reagent");
    local result = scanResult;
    local unit, id, itemCount, name, link, itemString, qualityTier;
    local itemContainer;
    local buildCache;

    local saveResult = function(result, id, count)
        if ( count == 0 ) then
            return;

        elseif ( IsAccountContainer(id) or self:GetConfigShowItemCountPerSlot() ) then
            if ( not result.perSlot ) then
                result.perSlot = {
                    bags = {},
                    bank = {},
                    account = {}
                };
            end
            local perSlot, where;
            if ( IsBagContainer(id) ) then
                perSlot = result.perSlot.bags;
                where = tostring(id);
            elseif ( IsCharacterContainer(id) ) then
                perSlot = result.perSlot.bank;
                where = tostring(self:GetCharacterContainerIndex(id));
            elseif ( IsAccountContainer(id) ) then
                perSlot = result.perSlot.account;
                where = tostring(self:GetAccountContainerIndex(id));
            end
            if ( perSlot ) then
                perSlot[where] = (perSlot[where] or 0) + count;
            end
        end

        if ( id == ARMORY_MAIL_CONTAINER ) then
            result.mail = result.mail + count;
        elseif ( IsBagContainer(id) ) then
            result.bags = result.bags + count;
        elseif ( IsCharacterContainer(id) ) then
            result.bank = result.bank + count;
        elseif ( id == ARMORY_AUCTIONS_CONTAINER or id == ARMORY_NEUTRAL_AUCTIONS_CONTAINER ) then
            result.auction = result.auction + count;
        elseif ( IsAccountContainer(id) ) then
            result.account = result.account + count;
        end
        result.count = result.count + count;
    end;

    local scanContainerItems = function(result, id)
        local itemContainer = InventoryContainerName(id);
        local unit = IsAccountContainer(id) and "account" or nil;
        if ( result.item and ItemCacheExists(itemContainer, unit) ) then
            itemCount = GetCachedItemCount(itemContainer, result.item, unit);
            saveResult(result, id, itemCount);
        else
            buildCache = not ItemCacheExists(itemContainer, unit);
            for index = 1, self:GetContainerNumSlots(id) do
                link = self:GetContainerItemLink(id, index);
                name = self:GetNameFromLink(link);
                _, itemCount = self:GetContainerItemInfo(id, index);
                if ( name and itemCount ) then
                    if ( buildCache ) then
                        SetItemCache(itemContainer, link, itemCount, unit);
                    end
                    if ( strtrim(name) == strtrim(result.name) ) then
                        saveResult(result, id, itemCount);
                        if ( not result.item ) then
                            result.item = self:SetCachedItemString(name, link);
                        end
                    end
                end
            end
        end
    end;

    table.wipe(result);

    local bankOutOfSync = self:IsBankOutOfSync();

    for k, item in ipairs(items) do
        if ( type(item) == "table" ) then
            name = unpack(item);
            itemString = self:GetCachedItemString(name);
        elseif ( item:find("|H") ) then
            name = self:GetNameFromLink(item);
            itemString = self:GetItemString(item);
            self:CheckUnknownCacheItems(name, itemString);
        else
            name = item;
            itemString = self:GetCachedItemString(name);
        end
        qualityTier = self:GetQualityTierFromName(name);
        result[k] = { name=name or UNKNOWN, item=itemString, tier=qualityTier, count=0, bags=0, bank=0, mail=0, auction=0, account=0 };

        if ( scanType == "account" or reagentScan ) then
            for _, id in ipairs(ArmoryInventoryAccountContainers) do
                scanContainerItems(result[k], id);
            end
        end

        if ( scanType ~= "account" ) then
            for _, id in ipairs(ArmoryInventoryPlayerContainers) do
                if ( (reagentScan and IsReagentContainer(id)) or (not reagentScan and not self:IsDummyContainer(id)) ) then
                    scanContainerItems(result[k], id);
                end
            end
        end

        if ( scanType ~= "account" and self:IsPlayerSelected() ) then
            ReconcileBankCount(result[k], itemString or result[k].item);
        end
        if ( bankOutOfSync and result[k].bank > 0 ) then
            result[k].bankEstimate = true;
            if ( result[k].perSlot ) then
                result[k].perSlot.bank = nil;
            end
        end
    end

    return result;
end

function Armory:GetEquipCount(link)
    local itemId = self:GetUniqueItemId(link);
    local count = 0;

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        link = self:GetInventoryItemLink("player", slot);
        if ( self:GetUniqueItemId(link) == itemId ) then
            count = count + 1;
        end
    end

    return count + CountProfessionGear(itemId);
end

function Armory:IsBankContainer(id)
    return id and IsBankContainer(id);
end

function Armory:IsBankOutOfSync()
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        for id = Enum.BagIndex.CharacterBankTab_1, Enum.BagIndex.CharacterBankTab_6 do
            local _, _, _, _, outOfSync = GetContainerInfo(dbEntry, InventoryContainerName(id));
            if ( outOfSync ) then
                return true;
            end
        end
    end
end

if ( not HAS_BANK_TABS ) then
    -- Classic's bank can only be counted while it is open, so there is nothing to correct
    ReconcileBankCount = function(result, itemString)
    end
    function Armory:IsBankOutOfSync()
    end
end

function Armory:IsDummyContainer(id)
    return id == ARMORY_EQUIPMENT_CONTAINER;
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

local findInventoryUpdater = ArmoryBackgroundUpdater:new();
function Armory:FindInventory(callback, ...)
    local searchArgs = {...};
    local numArgs = select("#", ...);

    local findItemInContainer = function(id, items, ...)
        local _, numSlots = self:GetInventoryContainerInfoEx(id);
        if ( (numSlots or 0) > 0 ) then
            for index = 1, numSlots do
                local link, tinker, anchor = self:GetContainerItemLink(id, index);
                local itemId = self:GetUniqueItemId(link);
                local text;
                if ( self:GetConfigExtendedSearch() ) then
                    text = self:GetFindText(link, tinker);
                else
                    text = self:GetNameFromLink(link);
                end
                if ( itemId and self:FindTextParts(text, ...) ) then
                    local _, itemCount = self:GetContainerItemInfo(id, index);
                    if ( items[itemId] ) then
                        items[itemId].count = items[itemId].count + itemCount;
                    else
                        items[itemId] = {link=link, tinker=tinker, anchor=anchor, count=itemCount, bags=0, bank=0, mail=0, alts=0, equipped=0, account=0};
                    end
                    if ( IsAccountContainer(id) ) then
                        items[itemId].account = items[itemId].account + itemCount;
                    elseif ( self:IsPlayerSelected() ) then
                        if ( id == ARMORY_MAIL_CONTAINER ) then
                            items[itemId].mail = items[itemId].mail + itemCount;
                        elseif ( IsBagContainer(id) ) then
                            items[itemId].bags = items[itemId].bags + itemCount;
                        elseif ( IsCharacterContainer(id) ) then
                            items[itemId].bank = items[itemId].bank + itemCount;
                        elseif ( id == ARMORY_EQUIPMENT_CONTAINER ) then
                            items[itemId].equipped = items[itemId].equipped + itemCount;
                        end
                    else
                        items[itemId].alts = items[itemId].alts + itemCount;
                    end
                end

                self:FindYield();
            end
        end
    end;

    findInventoryUpdater:Start(
        function(updater)
            local currentProfile = self:CurrentProfile();
            local list = {};
            local items = {};

            self:FindYieldReset();
            for _, profile in ipairs(self:Profiles()) do
                if ( self:IsFindCancelled() ) then
                    break;
                end
                if ( self:GetConfigGlobalSearch() or self:IsConnectedRealm(profile.realm) ) then
                    self:SelectProfile(profile);

                    for _, id in ipairs(ArmoryInventoryPlayerContainers) do
                        findItemInContainer(id, items, unpack(searchArgs, 1, numArgs));
                    end
                end
                self:SelectProfile(currentProfile);

                self:FindYield(true);
            end

            if ( self:IsFindCancelled() ) then
                self:PrintFindStats();
                return;
            end

            for _, id in ipairs(ArmoryInventoryAccountContainers) do
                findItemInContainer(id, items, unpack(searchArgs, 1, numArgs));
            end

            local text, name;
            for _, info in pairs(items) do
                text = self:GetCountDetails(info.bags, info.bank, info.mail, nil, info.alts, nil, info.equipped, info.account);
                name = self:GetNameFromLink(info.link);
                table.insert(list, {label="", name=name, extra=text, link=info.link, tinker=info.tinker, anchor=info.anchor, count=info.count});
            end
            sort(list, function(a, b) return a.name < b.name; end);

            for _, line in ipairs(list) do
                self:PrintSearchResult("", line);
            end

            self:PrintFindStats();
            callback(#list);
        end
    );
end

function Armory:FindContainerItem(id, items, ...)
    local container, numSlots, _, containerName = self:GetInventoryContainerInfoEx(id);
    if ( (numSlots or 0) > 0 ) then
        if ( IsCharacterContainer(id) or IsAccountContainer(id) ) then
            container = containerName;
        end
        for index = 1, numSlots do
            local link, tinker, anchor = self:GetContainerItemLink(id, index);
            local name = self:GetNameFromLink(link);
            local text;
            if ( self:GetConfigExtendedSearch() ) then
                text = self:GetFindText(link, tinker);
            else
                text = name;
            end
            if ( self:FindTextParts(text, ...) ) then
                local _, itemCount = self:GetContainerItemInfo(id, index);
                if ( itemCount > 1 ) then
                    table.insert(items, {label=container, name=name, link=link, tinker=tinker, anchor=anchor, count=itemCount});
                else
                    table.insert(items, {label=container, name=name, link=link, tinker=tinker, anchor=anchor});
                end
            end

            self:FindYield();
        end
    end
end

function Armory:FindInventoryItem(itemList, ...)
    local list = itemList or {};

    for _, id in ipairs(ArmoryInventoryPlayerContainers) do
        self:FindContainerItem(id, list, ...);

        local link, text = GetBagItemLink(id);
        if ( link ) then
            if ( self:GetConfigExtendedSearch() ) then
                text = self:GetFindText(link);
            else
                text = self:GetNameFromLink(link);
            end
            if ( self:FindTextParts(text, ...) ) then
                table.insert(list, {label=ARMORY_EQUIPPED, name=(self:GetInventoryContainerInfoEx(id)), link=link})
            end
        end
    end

    return list;
end

local knownBy = {};
local function AddKnownBy(name)
    if ( Armory:GetConfigShowKnownBy() and name ~= Armory.player ) then
        table.insert(knownBy, name);
    end
end

local canLearn = {};
local function AddCanLearn(name)
    if ( Armory:GetConfigShowCanLearn() ) then
        table.insert(canLearn, name);
    end
end

local hasSkill = {};
local function AddHasSkill(name)
    if ( Armory:GetConfigShowHasSkill() ) then
        table.insert(hasSkill, name);
    end
end
