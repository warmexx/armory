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

local MONEY_ICON_WIDTH = 19;
local MONEY_ICON_WIDTH_SMALL = 13;

local MONEY_BUTTON_SPACING = -4;
local MONEY_BUTTON_SPACING_SMALL = -4;

local MONEY_TEXT_VADJUST = 0;

local COIN_BUTTON_WIDTH = 32;

local MoneyTypeInfo = { };

MoneyTypeInfo["STATIC"] = {
    UpdateFunc = function(self)
        return self.staticMoney;
    end,
    collapse = 1
};
MoneyTypeInfo["AUCTION"] = {
    UpdateFunc = function(self)
        return self.staticMoney;
    end,
    showSmallerCoins = "Backpack",
    fixedWidth = 1,
    collapse = 1
};

function ArmoryMoneyFrame_OnLoad(self)
    ArmoryMoneyFrame_SetType(self, "STATIC");
end

function ArmorySmallMoneyFrame_OnLoad(self)
    ArmoryMoneyFrame_OnLoad(self);
    self.small = 1;
end

function ArmoryMoneyFrame_OnEnter(moneyFrame)
    if ( moneyFrame.showTooltip ) then
        GameTooltip:SetOwner(_G[moneyFrame:GetName().."CopperButton"], "ANCHOR_TOPRIGHT", 20, 2);
        SetTooltipMoney(GameTooltip, moneyFrame.staticMoney, "TOOLTIP", "");
        GameTooltip:Show();
    end
end

function ArmoryMoneyFrame_OnLeave(moneyFrame)
    if ( moneyFrame.showTooltip ) then
        GameTooltip:Hide();
    end
end

function ArmoryMoneyFrame_SetType(self, type)
    local info = MoneyTypeInfo[type];
    if ( not info ) then
        message("Invalid money type: "..type);
        return;
    end
    self.info = info;
    self.moneyType = type;
end

function ArmoryMoneyFrame_SetMaxDisplayWidth(moneyFrame, width)
    moneyFrame.maxDisplayWidth = width;
end

-- Update the money shown in a money frame
function ArmoryMoneyFrame_UpdateMoney(moneyFrame)
    assert(moneyFrame);

    if ( moneyFrame.info ) then
        local money = moneyFrame.info.UpdateFunc(moneyFrame);
        if ( money ) then
            ArmoryMoneyFrame_Update(moneyFrame:GetName(), money);
        end
    else
        message("Error moneyType not set");
    end
end

local function InitCoinButton(button, atlas, iconWidth)
    if ( not button or not atlas ) then
        return;
    end
    local texture = button:CreateTexture();
    texture:SetAtlas(atlas, true);
    texture:SetWidth(iconWidth);
    texture:SetHeight(iconWidth);
    texture:SetPoint("RIGHT");
    button:SetNormalTexture(texture);
end

function ArmoryMoneyFrame_Update(frameName, money, forceShow)
    local frame;
    if ( type(frameName) == "table" ) then
        frame = frameName;
        frameName = frame:GetName();
    else
        frame = _G[frameName];
    end

    local info = frame.info;
    if ( not info ) then
        message("Error moneyType not set");
    end

    -- Breakdown the money into denominations
    local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD));
    local goldDisplay = BreakUpLargeNumbers(gold);
    local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER);
    local copper = mod(money, COPPER_PER_SILVER);

    local goldButton = _G[frameName.."GoldButton"];
    local silverButton = _G[frameName.."SilverButton"];
    local copperButton = _G[frameName.."CopperButton"];

    local iconWidth = MONEY_ICON_WIDTH;
    local spacing = MONEY_BUTTON_SPACING;
    if ( frame.small ) then
        iconWidth = MONEY_ICON_WIDTH_SMALL;
        spacing = MONEY_BUTTON_SPACING_SMALL;
    end

    local maxDisplayWidth = frame.maxDisplayWidth;

    -- Set values for each denomination
    if ( ENABLE_COLORBLIND_MODE == "1" ) then
        if ( not frame.colorblind or not frame.vadjust or frame.vadjust ~= MONEY_TEXT_VADJUST ) then
            frame.colorblind = true;
            frame.vadjust = MONEY_TEXT_VADJUST;
            goldButton:SetNormalTexture("");
            silverButton:SetNormalTexture("");
            copperButton:SetNormalTexture("");
            _G[frameName.."GoldButtonText"]:SetPoint("RIGHT", 0, MONEY_TEXT_VADJUST);
            _G[frameName.."SilverButtonText"]:SetPoint("RIGHT", 0, MONEY_TEXT_VADJUST);
            _G[frameName.."CopperButtonText"]:SetPoint("RIGHT", 0, MONEY_TEXT_VADJUST);
        end
        goldButton:SetText(goldDisplay .. GOLD_AMOUNT_SYMBOL);
        goldButton:SetWidth(goldButton:GetTextWidth());
        goldButton:Show();
        silverButton:SetText(silver .. SILVER_AMOUNT_SYMBOL);
        silverButton:SetWidth(silverButton:GetTextWidth());
        silverButton:Show();
        copperButton:SetText(copper .. COPPER_AMOUNT_SYMBOL);
        copperButton:SetWidth(copperButton:GetTextWidth());
        copperButton:Show();
    else
        if ( frame.colorblind or not frame.vadjust or frame.vadjust ~= MONEY_TEXT_VADJUST ) then
            frame.colorblind = nil;
            frame.vadjust = MONEY_TEXT_VADJUST;

            InitCoinButton(goldButton, "coin-gold", iconWidth);
            InitCoinButton(silverButton, "coin-silver", iconWidth);
            InitCoinButton(copperButton, "coin-copper", iconWidth);

            _G[frameName.."GoldButtonText"]:SetPoint("RIGHT", -iconWidth, MONEY_TEXT_VADJUST);
            _G[frameName.."SilverButtonText"]:SetPoint("RIGHT", -iconWidth, MONEY_TEXT_VADJUST);
            _G[frameName.."CopperButtonText"]:SetPoint("RIGHT", -iconWidth, MONEY_TEXT_VADJUST);
        end
        goldButton:SetText(goldDisplay);
        goldButton:SetWidth(goldButton:GetTextWidth() + iconWidth);
        goldButton:Show();
        silverButton:SetText(silver);
        silverButton:SetWidth(silverButton:GetTextWidth() + iconWidth);
        silverButton:Show();
        copperButton:SetText(copper);
        copperButton:SetWidth(copperButton:GetTextWidth() + iconWidth);
        copperButton:Show();
    end

    -- Store how much money the frame is displaying
    frame.staticMoney = money;
    frame.showTooltip = nil;

    -- If not collapsable or not using maxDisplayWidth don't need to continue
    if ( not info.collapse and not maxDisplayWidth ) then
        return;
    end

    local width = iconWidth;

    local showLowerDenominations, truncateCopper;
    if ( gold > 0 ) then
        width = width + goldButton:GetWidth();
        if ( info.showSmallerCoins ) then
            showLowerDenominations = 1;
        end
        if ( info.truncateSmallCoins ) then
            truncateCopper = 1;
        end
    else
        goldButton:Hide();
    end

    goldButton:ClearAllPoints();
    local hideSilver = true;
    if ( silver > 0 or showLowerDenominations ) then
        hideSilver = false;
        -- Exception if showLowerDenominations and fixedWidth
        if ( showLowerDenominations and info.fixedWidth ) then
            silverButton:SetWidth(COIN_BUTTON_WIDTH);
        end

        local silverWidth = silverButton:GetWidth();
        goldButton:SetPoint("RIGHT", frameName.."SilverButton", "LEFT", spacing, 0);
        if ( goldButton:IsShown() ) then
            silverWidth = silverWidth - spacing;
        end
        if ( info.showSmallerCoins ) then
            showLowerDenominations = 1;
        end
        -- hide silver if not enough room
        if ( maxDisplayWidth and (width + silverWidth) > maxDisplayWidth ) then
            hideSilver = true;
            frame.showTooltip = true;
        else
            width = width + silverWidth;
        end
    end
    if ( hideSilver ) then
        silverButton:Hide();
        goldButton:SetPoint("RIGHT", frameName.."SilverButton",    "RIGHT", 0, 0);
    end

    -- Used if we're not showing lower denominations
    silverButton:ClearAllPoints();
    local hideCopper = true;
    if ( (copper > 0 or showLowerDenominations or info.showSmallerCoins == "Backpack" or forceShow) and not truncateCopper) then
        hideCopper = false;
        -- Exception if showLowerDenominations and fixedWidth
        if ( showLowerDenominations and info.fixedWidth ) then
            copperButton:SetWidth(COIN_BUTTON_WIDTH);
        end

        local copperWidth = copperButton:GetWidth();
        silverButton:SetPoint("RIGHT", frameName.."CopperButton", "LEFT", spacing, 0);
        if ( silverButton:IsShown() or goldButton:IsShown() ) then
            copperWidth = copperWidth - spacing;
        end
        -- hide copper if not enough room
        if ( maxDisplayWidth and (width + copperWidth) > maxDisplayWidth ) then
            hideCopper = true;
            frame.showTooltip = true;
        else
            width = width + copperWidth;
        end
    end
    if ( hideCopper ) then
        copperButton:Hide();
        silverButton:SetPoint("RIGHT", frameName.."CopperButton", "RIGHT", 0, 0);
    end

    -- make sure the copper button is in the right place
    copperButton:ClearAllPoints();
    copperButton:SetPoint("RIGHT", frameName, "RIGHT", -13, 0);

    -- attach text now that denominations have been computed
    local prefixText = _G[frameName.."PrefixText"];
    if ( prefixText ) then
        if ( prefixText:GetText() and money > 0 ) then
            prefixText:Show();
            copperButton:ClearAllPoints();
            copperButton:SetPoint("RIGHT", frameName.."PrefixText", "RIGHT", width, 0);
            width = width + prefixText:GetWidth();
        else
            prefixText:Hide();
        end
    end
    local suffixText = _G[frameName.."SuffixText"];
    if ( suffixText ) then
        if ( suffixText:GetText() and money > 0 ) then
            suffixText:Show();
            suffixText:ClearAllPoints();
            suffixText:SetPoint("LEFT", frameName.."CopperButton", "RIGHT", 0, 0);
            width = width + suffixText:GetWidth();
        else
            suffixText:Hide();
        end
    end

    frame:SetWidth(width);
end