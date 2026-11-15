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

ARMORY_MAIL_CONTAINER = -3;
ARMORY_AUCTIONS_CONTAINER = -4;
ARMORY_NEUTRAL_AUCTIONS_CONTAINER = -5;
ARMORY_EQUIPMENT_CONTAINER = -6;

ARMORY_CACHE_CONTAINER = "Cache";

if ( Armory.isClassic ) then
    ArmoryInventoryContainers = {
        BACKPACK_CONTAINER, 1, 2, 3, 4, BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11,
        ARMORY_MAIL_CONTAINER,
        ARMORY_AUCTIONS_CONTAINER, ARMORY_NEUTRAL_AUCTIONS_CONTAINER,
        ARMORY_EQUIPMENT_CONTAINER
    };
    -- Shared code uses the Mainline names; Classic has no account containers
    ArmoryInventoryPlayerContainers = ArmoryInventoryContainers;
    ArmoryInventoryAccountContainers = {};
else
    ArmoryInventoryPlayerContainers = {
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
        Enum.BagIndex.ReagentBag,
        Enum.BagIndex.CharacterBankTab_1,
        Enum.BagIndex.CharacterBankTab_2,
        Enum.BagIndex.CharacterBankTab_3,
        Enum.BagIndex.CharacterBankTab_4,
        Enum.BagIndex.CharacterBankTab_5,
        Enum.BagIndex.CharacterBankTab_6,
        ARMORY_MAIL_CONTAINER,
        ARMORY_AUCTIONS_CONTAINER, ARMORY_NEUTRAL_AUCTIONS_CONTAINER,
        ARMORY_EQUIPMENT_CONTAINER
    };

    ArmoryInventoryAccountContainers = {
        Enum.BagIndex.AccountBankTab_1,
        Enum.BagIndex.AccountBankTab_2,
        Enum.BagIndex.AccountBankTab_3,
        Enum.BagIndex.AccountBankTab_4,
        Enum.BagIndex.AccountBankTab_5
    };

    ArmoryInventoryContainers = {};
    for i, v in ipairs(ArmoryInventoryPlayerContainers) do
        table.insert(ArmoryInventoryContainers, v)
    end
    for i, v in ipairs(ArmoryInventoryAccountContainers) do
        table.insert(ArmoryInventoryContainers, v)
    end
end

local NUM_BAGS = Armory.isClassic and NUM_BAG_SLOTS or NUM_TOTAL_BAG_FRAMES;
local MoneyFrame_Update = Armory.isClassic and MoneyFrame_Update or ArmoryMoneyFrame_Update;

function ArmoryInventoryFrame_Toggle()
    if ( ArmoryInventoryFrame:IsShown() ) then
        ArmoryInventoryFrame:Hide();
    else
        ArmoryCloseChildWindows();
        ArmoryInventoryFrame:Show();
    end
end

function ArmoryInventoryFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("BAG_UPDATE");
    self:RegisterEvent("BANKFRAME_OPENED");
    self:RegisterEvent("BANKFRAME_CLOSED");
    self:RegisterEvent("MAIL_SHOW");
    self:RegisterEvent("MAIL_SEND_SUCCESS");
    self:RegisterEvent("SECURE_TRANSFER_CANCEL");

    if ( Armory.isClassic ) then
        self:RegisterEvent("PLAYERBANKSLOTS_CHANGED");
        self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE");

        -- Blizzard's frame template in Classic has a button bar
        ButtonFrameTemplate_HideButtonBar(self);
        Armory:SetPortraitToTexture(ArmoryInventoryFramePortrait, "Interface\\Buttons\\Button-Backpack-Up");
        -- Classic has no account bank
        ArmoryInventoryFrameTab3:Hide();
    else
        self:RegisterEvent("BANK_TAB_SETTINGS_UPDATED");
        self:RegisterEvent("TRADE_SKILL_SHOW");
        self:RegisterEvent("TRADE_SKILL_CLOSE");
        self:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED");
        self:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED");
        self:RegisterEvent("OWNED_AUCTIONS_UPDATED");

        self:SetPortraitToAsset("Interface\\Buttons\\Button-Backpack-Up");
    end
    self:SetTitle(INVENTORY_TOOLTIP);

    self.Inset:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 4, 338);
    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", PANEL_DEFAULT_WIDTH + PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_BOTTOM_OFFSET);

    -- Tab Handling code
    ArmoryPanelTemplates_SetNumTabs(self, 2);
    ArmoryPanelTemplates_SetTab(self, 1);

    if ( Armory.isClassic ) then
        -- Classic's HandleModifiedItemClick only gets the link
        hooksecurefunc("ContainerFrameItemButton_OnModifiedClick",
            function(self, button)
                local bag = self:GetParent():GetID();
                local slot = self:GetID();
                ArmoryInventoryFramePasteItem(button, C_Container.GetContainerItemLink(bag, slot), true);
            end
        );
    else
        hooksecurefunc("HandleModifiedItemClick",
            function(link, itemButton)
                if ( type(itemButton) == "table" and itemButton.bagID ) then
                    ArmoryInventoryFramePasteItem("LeftButton", C_Container.GetContainerItemLink(itemButton.bagID, itemButton.slotIndex), true);
                end
            end
        );
    end

    DEFAULT_CHAT_FRAME:HookScript("OnHyperlinkClick",
        function(self, link, text, button)
            ArmoryInventoryFramePasteItem(button, link);
        end
    );
end

local function QueryOwnedAuctions()
    if ( not ArmoryInventoryFrame.queryOwnedAuctions ) then
        return;
    end
    ArmoryInventoryFrame.queryOwnedAuctions = false;
    C_AuctionHouse.QueryOwnedAuctions({});
end

local function UpdateBankContainers()
    for i = 1, Constants.InventoryConstants.NumCharacterBankSlots do
        ArmoryInventoryFrame_UpdateContainer(Enum.BagIndex.CharacterBankTab_1 + i - 1);
    end
    if ( C_PlayerInfo.HasAccountInventoryLock() ) then
        for i = 1, Constants.InventoryConstants.NumAccountBankSlots do
            ArmoryInventoryFrame_UpdateContainer(Enum.BagIndex.AccountBankTab_1 + i - 1);
        end
    end
end

-- Bag, bank and auction events per family; returns false if the frame needs no update
local OnContainerEvent;

if ( Armory.isClassic ) then
    OnContainerEvent = function(self, event, arg1)
        if ( event == "BAG_UPDATE" and arg1 >= BACKPACK_CONTAINER and arg1 <= NUM_BAG_SLOTS ) then
            if ( self.mailOpen ) then
                Armory:Execute(ArmoryInventoryFrame_UpdateContainer(ARMORY_MAIL_CONTAINER));
            end
            Armory:Execute(ArmoryInventoryFrame_UpdateContainer, arg1);
        elseif ( event == "BAG_UPDATE" and self.bankOpen ) then
            -- Must execute immediately
            ArmoryInventoryFrame_UpdateContainer(arg1);
        elseif ( event == "PLAYERBANKSLOTS_CHANGED" and arg1 <= NUM_BANKGENERIC_SLOTS ) then
            -- Must execute immediately
            ArmoryInventoryFrame_UpdateContainer(BANK_CONTAINER);
        elseif ( event == "BANKFRAME_OPENED" ) then
            self.bankOpen = true;
            -- Must execute immediately
            ArmoryInventoryFrame_UpdateContainer(BANK_CONTAINER);
            for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
                ArmoryInventoryFrame_UpdateContainer(i);
            end
        elseif ( event == "BANKFRAME_CLOSED" ) then
            self.bankOpen = false;
            return false;
        elseif ( event == "AUCTION_OWNED_LIST_UPDATE" ) then
            -- Must execute immediately
            if ( GetAuctionHouseDepositRate() > 5 ) then
                ArmoryInventoryFrame_UpdateContainer(ARMORY_NEUTRAL_AUCTIONS_CONTAINER);
            else
                ArmoryInventoryFrame_UpdateContainer(ARMORY_AUCTIONS_CONTAINER);
            end
        end
        return true;
    end;
else
    OnContainerEvent = function(self, event, arg1)
        if ( event == "BAG_UPDATE" and Armory:IsBag(arg1) ) then
            if ( self.mailOpen ) then
                Armory:Execute(ArmoryInventoryFrame_UpdateContainer(ARMORY_MAIL_CONTAINER));
            end
            Armory:Execute(ArmoryInventoryFrame_UpdateContainer, arg1);
            Armory:Execute(ArmoryGearSets_Update);
            if ( self.tradeSkillOpen ) then
                -- crafting may have taken reagents from the bank
                Armory:Execute(UpdateBankContainers);
            end
        elseif ( event == "BAG_UPDATE" and self.bankOpen ) then
            -- Must execute immediately
            ArmoryInventoryFrame_UpdateContainer(arg1);
        elseif ( event == "BAG_UPDATE" and Armory:IsBankContainer(arg1) ) then
            -- bank tabs stay readable while the bank is closed (e.g. reagents taken from the bank while crafting)
            Armory:Execute(ArmoryInventoryFrame_UpdateContainer, arg1);
        elseif ( event == "BANKFRAME_OPENED" ) then
            self.bankOpen = true;
            -- Must execute immediately
            UpdateBankContainers();
        elseif ( event == "BANKFRAME_CLOSED" ) then
            self.bankOpen = false;
            return false;
        elseif ( event == "BANK_TAB_SETTINGS_UPDATED" ) then
            if ( arg1 == Enum.BankType.Character ) then
                for i = 1, Constants.InventoryConstants.NumCharacterBankSlots do
                    local bankTabID = Enum.BagIndex.CharacterBankTab_1 + i - 1;
                    Armory:UpdateCharacterContainerName(bankTabID);
                end
            elseif ( arg1 == Enum.BankType.Account ) then
                for i = 1, Constants.InventoryConstants.NumAccountBankSlots do
                    local bankTabID = Enum.BagIndex.AccountBankTab_1 + i - 1;
                    Armory:UpdateAccountContainerName(bankTabID);
                end
            end
        elseif ( event == "TRADE_SKILL_SHOW" ) then
            self.tradeSkillOpen = true;
            -- bank tabs become readable while a profession is open
            Armory:Execute(UpdateBankContainers);
            return false;
        elseif ( event == "TRADE_SKILL_CLOSE" ) then
            self.tradeSkillOpen = false;
            return false;
        elseif ( event == "AUCTION_HOUSE_AUCTION_CREATED" ) then
            self.queryOwnedAuctions = true;
        elseif ( event == "COMMODITY_SEARCH_RESULTS_UPDATED" ) then
            if ( self.queryOwnedAuctions ) then
                Armory:ExecuteConditional(C_AuctionHouse.IsThrottledMessageSystemReady, QueryOwnedAuctions);
            end
        elseif ( event == "OWNED_AUCTIONS_UPDATED" ) then
            self.queryOwnedAuctions = false;
            -- Must execute immediately
            ArmoryInventoryFrame_UpdateContainer(ARMORY_AUCTIONS_CONTAINER);
        end
        return true;
    end;
end

function ArmoryInventoryFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:ContainerExists(Enum.BagIndex.Backpack, "player") ) then
            Armory:Execute(ArmoryInventoryFrame_UpdateContainer, Enum.BagIndex.Backpack);
        end
        for i = 1, NUM_BAGS do
            if ( Armory.forceScan or not Armory:ContainerExists(i, "player") ) then
                Armory:Execute(ArmoryInventoryFrame_UpdateContainer, i);
            end
        end
        return;
    end

    local arg1 = ...;
    local update = true;

    -- make sure no Blizz id will match (e.g. -4 was introduced for tokens bag)
    if ( arg1 and arg1 <= ARMORY_MAIL_CONTAINER ) then
        arg1 = arg1 * 100;
    end

    if ( event == "MAIL_SHOW" ) then
        self.mailOpen = true;
        return;
    elseif ( event == "MAIL_SEND_SUCCESS" ) then
        update = Armory:AddMail();
    elseif ( event == "SECURE_TRANSFER_CANCEL" ) then
        if ( self.mailOpen ) then
            self.mailOpen = false;

            ArmoryInventoryFrame_UpdateContainer(ARMORY_MAIL_CONTAINER);
            ArmoryInventoryFrame_UpdateFrame(true);

            if ( Armory:GetConfigMailCheckCount() and Armory:GetConfigExpirationDays() > 0 and not Armory:GetConfigMailHideCount() ) then
                local count = Armory:GetNumRemainingMailItems("player");
                if ( count > 0 ) then
                    Armory:PrintWarning(format(ARMORY_MAIL_COUNT_WARNING1, count));
                    Armory:PlayWarningSound();
                end
            end
        end
    elseif ( not OnContainerEvent(self, event, arg1) ) then
        return;
    end

    ArmoryInventoryFrame_UpdateFrame(update);
end

function ArmoryInventoryFrame_UpdateFrame(update)
    if ( update and ArmoryInventoryFrame:IsShown() ) then
        Armory:ExecuteDelayed(1.5, ArmoryInventoryFrame_Update);
    end
end

function ArmoryInventoryFrame_UpdateContainer(id)
    Armory:SetContainer(id);
    Armory:ResetTooltipHook();
    Armory:Execute(ArmoryInventoryFrame_UpdateTooltips);
end

function ArmoryInventoryFrame_UpdateTooltips()
    Armory:RefreshTooltip(ItemRefTooltip);
end

function ArmoryInventoryFrameButton_OnClick(self)
    local id = self:GetID();
    local unit;
    if ( ArmoryInventoryListViewFrame:IsShown() ) then
        unit = "player";
    elseif ( ArmoryInventoryAccountBankFrame and ArmoryInventoryAccountBankFrame:IsShown() ) then
        unit = "account";
    end
    if ( unit ) then
        if ( self.isCollapsed ) then
            Armory:ExpandInventoryHeader(id, unit);
        else
            Armory:CollapseInventoryHeader(id, unit);
        end
    else
        if ( self.isCollapsed ) then
            Armory:ExpandContainer(id);
        else
            Armory:CollapseContainer(id);
        end
    end
    ArmoryInventoryFrame_Update();
end

function ArmoryInventoryFrame_OnShow(self)
    ArmoryInventoryFrameEditBox:SetText(Armory:GetInventoryItemNameFilter());
    if ( Armory:GetInventoryListViewMode() ) then
        ArmoryPanelTemplates_SetTab(self, 2);
    else
        ArmoryPanelTemplates_SetTab(self, 1);
    end

    -- only the visible tabs: no account bank in Classic, and the guild bank tab only with a guild
    local tabs = {};
    local totalTabWidth = 0;
    local tabWidthCache = {};
    for _, tab in ipairs(self.Tabs) do
        if ( tab:IsShown() ) then
            ArmoryPanelTemplates_TabResize(tab, 0);
            tab.Text:SetWidth(0);
            table.insert(tabs, tab);
            table.insert(tabWidthCache, ArmoryPanelTemplates_GetTabWidth(tab));
            totalTabWidth = totalTabWidth + tabWidthCache[#tabWidthCache];
        end
    end
    ArmoryPanelTemplates_ResizeTabsToFit(tabs, totalTabWidth, self:GetWidth(), tabWidthCache);

    ArmoryInventoryFrame_Update();
end

function ArmoryInventoryFrame_Update()
    -- Classic has no account bank
    local accountBankFrame = ArmoryInventoryAccountBankFrame;

    if ( accountBankFrame and ArmoryPanelTemplates_GetSelectedTab(ArmoryInventoryFrame) == 3 ) then
        ArmoryInventoryIconViewFrame:Hide();
        ArmoryInventoryListViewFrame:Hide();
        accountBankFrame:Show();
        if ( accountBankFrame:IsShown() ) then
            ArmoryInventoryAccountBankFrame_Update();
        end
    elseif ( Armory:GetInventoryListViewMode() ) then
        ArmoryInventoryIconViewFrame:Hide();
        if ( accountBankFrame ) then
            accountBankFrame:Hide();
        end
        if ( ArmoryInventoryListViewFrame:IsShown() ) then
            ArmoryInventoryListViewFrame_Update();
        else
            ArmoryInventoryListViewFrame:Show();
        end
    else
        ArmoryInventoryListViewFrame:Hide();
        if ( accountBankFrame ) then
            accountBankFrame:Hide();
        end
        if ( ArmoryInventoryIconViewFrame:IsShown() ) then
            ArmoryInventoryIconViewFrame_Update();
        else
            ArmoryInventoryIconViewFrame:Show();
        end
    end
end

function ArmoryInventoryFrameTab_OnClick(self)
    ArmoryCloseDropDownMenus();
    ArmoryPanelTemplates_SetTab(ArmoryInventoryFrame, self:GetID());
    ArmoryInventoryFrameEnableListView(self:GetID() == 2);
end

function ArmoryInventoryFrameEnableListView(checked)
    Armory:SetInventoryListViewMode(checked);
    ArmoryInventoryFrame_Update();
end

function ArmoryInventoryMoneyFrame_OnShow(self)
    MoneyFrame_Update("ArmoryInventoryMoneyFrame", Armory:GetMoney());
end

function ArmoryInventoryMoneyFrame_OnEnter(self)
    local currentRealm, currentCharacter = Armory:GetPaperDollLastViewed();
    local currentFaction = Armory:UnitFactionGroup("player");
    local money = {};

    local addToFactionTotal = function (realm)
        if ( Armory:UnitFactionGroup("player") == currentFaction ) then
            if ( not money[realm] ) then
                money[realm] = 0;
            end
            money[realm] = money[realm] + Armory:GetMoney();
        end
    end;

    if ( Armory:IsConnectedRealm(currentRealm) ) then
        for _, profile in ipairs(Armory:GetConnectedProfiles()) do
            Armory:SelectProfile(profile);
            addToFactionTotal(profile.realm);
        end
    else
        for _, character in ipairs(Armory:CharacterList(currentRealm)) do
            Armory:LoadProfile(currentRealm, character);
            addToFactionTotal(currentRealm);
        end
    end
    Armory:LoadProfile(currentRealm, currentCharacter);

    local total = money[currentRealm];
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine(format(ARMORY_MONEY_TOTAL, currentRealm, currentFaction), "", 1, 1, 1);
    SetTooltipMoney(GameTooltip, total, "TOOLTIP");

    local grandTotal;
    for realm, realmTotal in pairs(money) do
        if ( realm ~= currentRealm ) then
            GameTooltip:AddLine(format(ARMORY_MONEY_TOTAL, realm, currentFaction), "", 1, 1, 1);
            SetTooltipMoney(GameTooltip, realmTotal);
            total = total + realmTotal;
            grandTotal = true;
        end
    end
    if ( AGB ) then
        local pgbTotal = AGB:GetPGBMoney(currentRealm, currentFaction);
        if ( pgbTotal > 0 ) then
            GameTooltip:AddLine(format(ARMORY_MONEY_TOTAL, ARMORY_PERSONAL_GUILDBANK, currentFaction), "", 1, 1, 1);
            SetTooltipMoney(GameTooltip, pgbTotal);
            total = total + pgbTotal;
            grandTotal = true;
        end
    end
    if ( grandTotal ) then
        GameTooltip:AddLine(format(ARMORY_MONEY_TOTAL, "-", currentFaction), "", 1, 1, 1);
        SetTooltipMoney(GameTooltip, total);
    end

    if ( self.showTooltip and self.staticMoney ~= total ) then
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(currentCharacter..":", "", 1, 1, 1);
        SetTooltipMoney(GameTooltip, self.staticMoney);
    end

    GameTooltip:Show();
end

function ArmoryInventoryMoneyFrame_OnLeave(self)
    GameTooltip:Hide();
end

function ArmoryInventoryFilter_OnTextChanged(self)
    ArmorySearchBoxTemplate_OnTextChanged(self);

    local text = self:GetText();
    local refresh;

    if ( text ~= "=" ) then
        refresh = Armory:SetInventoryItemNameFilter(text);
    end
    if ( refresh ) then
        ArmoryInventoryFrame_Update();
    end
end

function ArmoryInventoryFilterDropDown_OnLoad(self)
    ArmoryItemFilter_InitializeDropDown(self);
end

function ArmoryInventoryFilterDropDown_OnShow(self)
    ArmoryItemFilter_SelectDropDown(self, ArmoryInventoryFrame_Update);
end

-- Alt-click on an item in the bags (Shift-click also opens Blizzard's stack split there),
-- Shift-click on a chat link (Alt-click on a chat link can start a search with /find)
function ArmoryInventoryFrame_IsPasteClick(button, isBagItem)
    if ( isBagItem ) then
        return button == "LeftButton" and IsAltKeyDown();
    end
    return IsModifiedClick("CHATLINK");
end

function ArmoryInventoryFramePasteItem(button, link, isBagItem)
    if ( not ArmoryInventoryFrameEditBox:IsVisible() ) then
        return;
    elseif ( ArmoryInventoryFrame_IsPasteClick(button, isBagItem) ) then
        local itemName = C_Item.GetItemInfo(link);
        if ( itemName ) then
            ArmoryInventoryFrameEditBox:SetText(itemName);
        end
    end
end
