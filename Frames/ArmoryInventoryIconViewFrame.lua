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

local MAX_CONTAINERS = 20;
local MAX_CONTAINER_COLUMNS = 7;
local MAX_CONTAINER_ITEMS = 160;
local CONTAINER_OFFSET_X = 22;
local CONTAINER_OFFSET_Y = -5;
local CONTAINER_ROW_HEIGHT = 37;
local NUM_CONTAINER_COLUMNS = 4;

-- Classic calls it Standard
local QUALITY_COMMON = Enum.ItemQuality.Common or Enum.ItemQuality.Standard;

-- Containers shown in the bag layout: the bags, and in Classic the bank bags too
local HasBagLayout;
if ( Armory.isClassic ) then
    HasBagLayout = function(id) return id >= BACKPACK_CONTAINER and id <= NUM_BAG_SLOTS + NUM_BANKBAGSLOTS; end;
else
    HasBagLayout = function(id) return Armory:IsBag(id); end;
end

function ArmoryInventoryIconViewFrame_OnLoad(self)
    ArmoryInventoryIconViewFrameScrollBarScrollDownButton:SetScript("OnClick", ArmoryInventoryIconViewFrameDownArrow_OnClick);
    ArmoryInventoryIconViewFrameScrollBar:SetValue(0);

    local numContainers = #ArmoryInventoryPlayerContainers;
    for i = 1, MAX_CONTAINERS do
        if ( i <= numContainers ) then
            _G["ArmoryInventoryContainer"..i.."Label"]:SetID(ArmoryInventoryPlayerContainers[i]);
            _G["ArmoryInventoryContainer"..i]:Show();
        else
            _G["ArmoryInventoryContainer"..i]:Hide();
        end
    end
end

function ArmoryInventoryIconViewFrame_OnShow(self)
    ArmoryInventoryIconViewFrame_Update();
end

function ArmoryInventoryIconViewFrameDownArrow_OnClick(self)
    local parent = self:GetParent();
    parent:SetValue(parent:GetValue() + (parent:GetHeight() / 2));
end

function ArmoryInventoryContainerItemButton_OnEnter(self)
    local containerName = self:GetParent():GetName();
    local containerButton = _G[containerName.."Label"];
    -- with combined bags a button can show an item of another bag than its container
    local containerId = self.bagId or containerButton:GetID();
    local itemIndex = self:GetID();
    Armory:SetBagItem(containerId, itemIndex);
end

-- The slots of the container, as {bag, slot}: of all bags when they are combined in the backpack
local containerSlots = {};
local function GetContainerSlots(id)
    table.wipe(containerSlots);
    for _, bagId in ipairs(Armory:GetCombinedContainers(id)) do
        for slot = 1, select(2, Armory:GetInventoryContainerInfoEx(bagId)) or 0 do
            table.insert(containerSlots, {bagId, slot});
        end
    end
    return containerSlots;
end

function ArmoryInventoryIconViewFrame_ShowContainer(containerFrame)
    local containerName = containerFrame:GetName();
    local label = _G[containerName.."Label"];
    local id = label:GetID();
    local containerTitle, numSlots, isCollapsed = Armory:GetInventoryContainerInfoEx(id);
    local columns, isPlusTwoBag;
    local buttonBaseName = containerName.."Item";
    local buttonTemplate = "ArmoryInventoryFrameItemButtonTemplate";
    local rowHeight = CONTAINER_ROW_HEIGHT;
    local slots = GetContainerSlots(id);
    local combined = #Armory:GetCombinedContainers(id) > 1;
    numSlots = #slots;
    if ( combined ) then
        containerTitle = ARMORY_INVENTORY_COMBINEDBAG;
    end

    if ( Armory:GetInventoryBagLayout() and HasBagLayout(id) and not combined ) then
        columns = NUM_CONTAINER_COLUMNS;
        isPlusTwoBag = (mod(numSlots, columns) == 2);
    else
        columns = MAX_CONTAINER_COLUMNS;
    end

    if ( numSlots > MAX_CONTAINER_ITEMS ) then
        numSlots = MAX_CONTAINER_ITEMS;
        containerTitle = format("%s (%d+)", containerTitle, numSlots);
    end

    label:SetText(containerTitle);

    if ( isCollapsed ) then
        label:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
    else
        label:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
    end
    label.isCollapsed = isCollapsed;

    local buttonName, itemButton, itemTexture;
    local rows = 0;
    local offset = 0;

    if ( isPlusTwoBag and not isCollapsed ) then
        for i = 1, 2 do
            itemButton = _G[buttonBaseName..i];
            if ( not itemButton ) then
                itemButton = CreateFrame("CheckButton", buttonBaseName..i, containerFrame, buttonTemplate);
            end
            if ( i == 1 ) then
                itemButton:SetPoint("TOPLEFT", containerName.."Label", "BOTTOMLEFT", CONTAINER_OFFSET_X, 0);
            else
                itemButton:SetPoint("TOPLEFT", buttonBaseName..(i - 1), "TOPRIGHT", 0, 0);
            end
            itemButton:Hide();
        end
        offset = 2;
        rows = 1;
    end

    local index, template;
    for i = 1, numSlots do
        index = offset + i;
        buttonName = buttonBaseName..index;
        itemButton = _G[buttonName];
        if ( not itemButton ) then
            itemButton = CreateFrame("CheckButton", buttonName, containerFrame, buttonTemplate);
        end
        itemButton:SetID(0);
        itemButton.bagId = nil;
        if ( not isCollapsed ) then
            -- Set first button
            if ( index == 1 ) then
                itemButton:SetPoint("TOPLEFT", containerName.."Label", "BOTTOMLEFT", CONTAINER_OFFSET_X, 0);
                rows = 1;
            else
                if ( mod((index - 1), columns) == 0 ) then
                    itemButton:SetPoint("TOPLEFT", buttonBaseName..(index - columns), "BOTTOMLEFT", 0, 0);
                    rows = rows + 1;
                else
                    itemButton:SetPoint("TOPLEFT", buttonBaseName..(index - 1), "TOPRIGHT", 0, 0);
                end
            end

            itemButton.icon:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled");
            itemButton.icon:SetTexCoord(0.140625, 0.84375, 0.140625, 0.84375);
            if ( buttonTemplate == "ArmoryInventoryFrameItemButtonTemplate" ) then
                SetItemButtonCount(itemButton, nil);
            end

            Armory:SetItemLink(itemButton, nil);
            itemButton.hasItem = nil;
            itemButton.IconBorder:Hide();

            itemButton:Show();
        else
            itemButton:Hide();
        end
    end

    for i = numSlots + 1, MAX_CONTAINER_ITEMS do
        index = offset + i;
        itemButton = _G[buttonBaseName..index];
        if ( itemButton ) then
            itemButton:Hide();
        end
    end

    if ( not isCollapsed ) then
        local texture, itemCount, quality, slotId;
        local name, link, bagId, slot;
        for i = 1, numSlots do
            bagId, slot = slots[i][1], slots[i][2];
            texture, itemCount, quality, _, _, _, slotId = Armory:GetInventoryContainerValue(bagId, slot);
            if ( texture ) then
                if ( Armory:GetInventoryBagLayout() and not combined ) then
                    index = offset + (slotId or i);
                else
                    index = offset + i;
                end
                buttonName = buttonBaseName..index;

                itemButton = _G[buttonName];
                if ( itemButton ) then
                    itemButton.icon:SetTexture(texture);
                    itemButton.icon:SetTexCoord(0, 1, 0, 1);
                    if ( itemCount and itemCount > 1 ) then
                        SetItemButtonCount(itemButton, itemCount);
                    end

                    link = Armory:GetContainerItemLink(bagId, slot);
                    name = Armory:GetNameFromLink(link);
                    if ( not Armory:InventoryFilterActive() or (name and Armory:MatchInventoryItem(Armory:GetInventoryItemNameFilter(), name, link)) ) then
                        itemButton.searchOverlay:Hide();
                    else
                        itemButton.searchOverlay:Show();
                    end

                    if ( quality and quality > QUALITY_COMMON and BAG_ITEM_QUALITY_COLORS[quality] ) then
                        itemButton.IconBorder:Show();
                        itemButton.IconBorder:SetVertexColor(BAG_ITEM_QUALITY_COLORS[quality].r, BAG_ITEM_QUALITY_COLORS[quality].g, BAG_ITEM_QUALITY_COLORS[quality].b);
                    else
                        itemButton.IconBorder:Hide();
                    end

                    Armory:SetItemLink(itemButton, link);
                    itemButton.hasItem = 1;
                    itemButton:SetID(slot);
                    itemButton.bagId = combined and bagId or nil;
                end
            end
        end
    end

    containerFrame:SetHeight((rows * rowHeight) + label:GetHeight() - CONTAINER_OFFSET_Y);
    containerFrame:Show();
    ArmoryInventoryIconViewFrame_SetScroll();
end

function ArmoryInventoryIconViewFrame_CheckContainerSize(label, size)
    local numSlots;
    if ( size > MAX_CONTAINER_ITEMS ) then
        numSlots = MAX_CONTAINER_ITEMS;
        label = format("%s (%d+)", label, numSlots);
    end
    return label, numSlots;
end

function ArmoryInventoryIconViewFrame_Update()
    local containerFrame, previousContainer, size, isCollapsed;

    ArmoryInventoryCollapseAllButton.isCollapsed = 1;
    ArmoryInventoryCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");

    for i = 1, #ArmoryInventoryPlayerContainers do
        containerFrame = _G["ArmoryInventoryContainer"..i];
        if ( containerFrame ) then
            _, size, isCollapsed = Armory:GetInventoryContainerInfo(ArmoryInventoryPlayerContainers[i]);

            -- a bag combined in the backpack has no place of its own
            if ( size and size > 0 and not Armory:IsCombinedBag(ArmoryInventoryPlayerContainers[i]) ) then
                if ( not isCollapsed and ArmoryInventoryCollapseAllButton.isCollapsed ) then
                    ArmoryInventoryCollapseAllButton.isCollapsed = nil;
                    ArmoryInventoryCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
                end

                ArmoryInventoryIconViewFrame_ShowContainer(containerFrame);
                if ( previousContainer ) then
                    containerFrame:SetPoint("TOPLEFT", previousContainer, "BOTTOMLEFT", 0, 0);
                end
                previousContainer = containerFrame:GetName();
            else
                containerFrame:Hide();
            end
        end
    end
end

function ArmoryInventoryIconViewFrame_SetScroll()
    local frameHeight = ArmoryInventoryIconViewFrame:GetHeight();
    local containerFrame;

    for i = 1, #ArmoryInventoryPlayerContainers do
        containerFrame = _G["ArmoryInventoryContainer"..i];
        if ( containerFrame and containerFrame:IsShown() ) then
            frameHeight = frameHeight - containerFrame:GetHeight();
        end
    end

    -- Show or hide the scrollbar
    if ( frameHeight > 0 ) then
        ArmoryInventoryIconViewFrameScrollBar:Hide();
        ArmoryInventoryIconViewFrameScrollBarTop:Hide();
        ArmoryInventoryIconViewFrameScrollBarBottom:Hide();
    else
        ArmoryInventoryIconViewFrameScrollBar:Show();
        ArmoryInventoryIconViewFrameScrollBarTop:Show();
        ArmoryInventoryIconViewFrameScrollBarBottom:Show();
    end
end

function ArmoryInventoryIconViewBagLayout(checked)
    Armory:SetInventoryBagLayout(checked);
    ArmoryInventoryIconViewFrame_OnShow(ArmoryInventoryIconViewFrame);
end

-- Shared by the icon and the list view
function ArmoryInventoryCombineBags(checked)
    Armory:SetInventoryCombineBags(checked);
    ArmoryInventoryFrame_Update();
end

-- The options of the icon and the list view, as checks in a dropdown next to the item filter
local function AddOption(text, tooltip, checked, setter)
    local info = ArmoryDropDownMenu_CreateInfo();
    info.text = text;
    info.tooltipTitle = text;
    info.tooltipText = tooltip;
    info.checked = checked;
    info.isNotRadio = true;
    info.keepShownOnClick = 1;
    info.func = function(_, _, _, isChecked) setter(isChecked); end;
    ArmoryDropDownMenu_AddButton(info);
end

local function InitializeOptions(self, level)
    -- Also called on load, before the settings are there; level is set when the menu opens
    if ( not level ) then
        return;
    elseif ( self.isListView ) then
        AddOption(ARMORY_INVENTORY_SEARCH_ALL, ARMORY_INVENTORY_SEARCH_ALL_TOOLTIP, Armory:GetInventorySearchAllFilter(), ArmoryInventoryListViewSearchAll);
    else
        AddOption(ARMORY_INVENTORY_BAGLAYOUT, ARMORY_INVENTORY_BAGLAYOUT_TOOLTIP, Armory:GetInventoryBagLayout(), ArmoryInventoryIconViewBagLayout);
    end
    AddOption(ARMORY_INVENTORY_COMBINEBAGS, ARMORY_INVENTORY_COMBINEBAGS_TOOLTIP, Armory:GetInventoryCombineBags(), ArmoryInventoryCombineBags);

    local info = ArmoryDropDownMenu_CreateInfo();
    info.text = CLOSE;
    info.notCheckable = 1;
    info.func = function() ArmoryHideDropDownMenu(1); end;
    ArmoryDropDownMenu_AddButton(info);
end

function ArmoryInventoryOptionsDropDown_OnLoad(self, isListView)
    self.isListView = isListView;
    ArmoryDropDownMenu_Initialize(self, InitializeOptions, "MENU");
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
    ArmoryDropDownMenu_ShowMenuArrow(self);
    ArmoryDropDownMenu_SetText(self, OPTIONS);
end