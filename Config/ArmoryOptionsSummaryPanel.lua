
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

local table = table;
local pairs = pairs;
local ipairs = ipairs;

local ARMORY_SUMMARY_CURRENCIES_HEIGHT = 16;
local SUMMARY_CURRENCIES_DISPLAYED = 8;

-- Classic has no currency module
local function HasCurrency()
    return not Armory.isClassic;
end

ArmoryOptionsSummaryPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsSummaryPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    if ( not HasCurrency() ) then
        self.CurrencyContainer:Hide();
    end

    self.Title:SetText(ARMORY_SUMMARY_TITLE);
    self.SubText:SetText(ARMORY_SUMMARY_SUBTEXT1);
end

function ArmoryOptionsSummaryPanelMixin:OnCommit()
    self.CurrencyContainer:OnCommit();
end

function ArmoryOptionsSummaryPanelMixin:GetID()
    return ARMORY_SUMMARY_LABEL;
end


ArmoryOptionsSummaryEnableMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSummaryEnableMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWSUMMARY";
end


ArmoryOptionsSummaryDelayMixin = CreateFromMixins(ArmoryOptionsSliderTemplateMixin);

function ArmoryOptionsSummaryDelayMixin:GetKey()
    return "ARMORY_CMD_SET_SUMMARYDELAY";
end

function ArmoryOptionsSummaryDelayMixin:OnLoad()
    ArmoryOptionsSliderTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().Summary);
end

function ArmoryOptionsSummaryDelayMixin:OnShow()
    -- Show standard labels
end


ArmoryOptionsSummaryColumnTemplateMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSummaryColumnTemplateMixin:GetKey()
    return nil;
end

function ArmoryOptionsSummaryColumnTemplateMixin:GetDefaultValue()
    return true;
end

function ArmoryOptionsSummaryColumnTemplateMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().Summary);
end


ArmoryOptionsSummaryClassMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryClassMixin:GetValue()
    return Armory:GetConfigSummaryClass();
end

function ArmoryOptionsSummaryClassMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryClass(value);
end

function ArmoryOptionsSummaryClassMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(CLASS);
end

ArmoryOptionsSummaryLevelMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryLevelMixin:GetValue()
    return Armory:GetConfigSummaryLevel();
end

function ArmoryOptionsSummaryLevelMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryLevel(value);
end

function ArmoryOptionsSummaryLevelMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(LEVEL);
end


ArmoryOptionsSummaryItemLevelMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryItemLevelMixin:GetValue()
    return Armory:GetConfigSummaryItemLevel();
end

function ArmoryOptionsSummaryItemLevelMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryItemLevel(value);
end

function ArmoryOptionsSummaryItemLevelMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(ITEM_LEVEL_ABBR);
end


ArmoryOptionsSummaryZoneMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryZoneMixin:GetValue()
    return Armory:GetConfigSummaryZone();
end

function ArmoryOptionsSummaryZoneMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryZone(value);
end

function ArmoryOptionsSummaryZoneMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(ZONE);
end


ArmoryOptionsSummaryXPMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryXPMixin:GetValue()
    return Armory:GetConfigSummaryXP();
end

function ArmoryOptionsSummaryXPMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryXP(value);
end

function ArmoryOptionsSummaryXPMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(XP);
end


ArmoryOptionsSummaryPlayedMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryPlayedMixin:GetValue()
    return Armory:GetConfigSummaryPlayed();
end

function ArmoryOptionsSummaryPlayedMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryPlayed(value);
end

function ArmoryOptionsSummaryPlayedMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(PLAYED);
end


ArmoryOptionsSummaryOnlineMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryOnlineMixin:GetValue()
    return Armory:GetConfigSummaryOnline();
end

function ArmoryOptionsSummaryOnlineMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryOnline(value);
end

function ArmoryOptionsSummaryOnlineMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(LASTONLINE);
end


ArmoryOptionsSummaryMoneyMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryMoneyMixin:GetValue()
    return Armory:GetConfigSummaryMoney();
end

function ArmoryOptionsSummaryMoneyMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryMoney(value);
end

function ArmoryOptionsSummaryMoneyMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(MONEY);
end


ArmoryOptionsSummaryBagsMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryBagsMixin:GetValue()
    return Armory:GetConfigSummaryBags();
end

function ArmoryOptionsSummaryBagsMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryBags(value);
end

function ArmoryOptionsSummaryBagsMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(BAGSLOTTEXT);
end


ArmoryOptionsSummaryCurrencyMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);
ArmoryOptionsSummaryCurrencyMixin.IsAvailable = HasCurrency;

function ArmoryOptionsSummaryCurrencyMixin:GetValue()
    return Armory:GetConfigSummaryCurrency();
end

function ArmoryOptionsSummaryCurrencyMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryCurrency(value);
end

function ArmoryOptionsSummaryCurrencyMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(CURRENCY);
end


ArmoryOptionsSummaryRaidInfoMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryRaidInfoMixin:GetValue()
    return Armory:GetConfigSummaryRaidInfo();
end

function ArmoryOptionsSummaryRaidInfoMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryRaidInfo(value);
end

function ArmoryOptionsSummaryRaidInfoMixin:ShouldDisable()
    return not Armory:RaidEnabled();
end

function ArmoryOptionsSummaryRaidInfoMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(RAID_INFO);
end


ArmoryOptionsSummaryQuestMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryQuestMixin:GetValue()
    return Armory:GetConfigSummaryQuest();
end

function ArmoryOptionsSummaryQuestMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryQuest(value);
end

function ArmoryOptionsSummaryQuestMixin:ShouldDisable()
    return not Armory:HasQuestLog();
end

function ArmoryOptionsSummaryQuestMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(QUESTS_LABEL);
end


ArmoryOptionsSummaryExpirationMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryExpirationMixin:GetValue()
    return Armory:GetConfigSummaryExpiration();
end

function ArmoryOptionsSummaryExpirationMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryExpiration(value);
end

function ArmoryOptionsSummaryExpirationMixin:ShouldDisable()
    return not (Armory:GetConfigExpirationDays() > 0 and Armory:HasInventory());
end

function ArmoryOptionsSummaryExpirationMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(ARMORY_EXPIRATION_TITLE);
end


ArmoryOptionsSummaryEventsMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryEventsMixin:GetValue()
    return Armory:GetConfigSummaryEvents();
end

function ArmoryOptionsSummaryEventsMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryEvents(value);
end

function ArmoryOptionsSummaryEventsMixin:ShouldDisable()
    return not Armory:HasSocial();
end

function ArmoryOptionsSummaryEventsMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(EVENTS_LABEL);
end


ArmoryOptionsSummaryTradeSkillsMixin = CreateFromMixins(ArmoryOptionsSummaryColumnTemplateMixin);

function ArmoryOptionsSummaryTradeSkillsMixin:GetValue()
    return Armory:GetConfigSummaryTradeSkills();
end

function ArmoryOptionsSummaryTradeSkillsMixin:SetValue(value)
    ArmoryOptionsSummaryColumnTemplateMixin.SetValue(self, value);
    Armory:SetConfigSummaryTradeSkills(value);
end

function ArmoryOptionsSummaryTradeSkillsMixin:ShouldDisable()
    return not Armory:HasTradeSkills();
end

function ArmoryOptionsSummaryTradeSkillsMixin:OnLoad()
    ArmoryOptionsSummaryColumnTemplateMixin.OnLoad(self);
    self:SetLabel(TRADESKILLS);
end


ArmoryOptionsCurrencyCheckButtonTemplateMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsCurrencyCheckButtonTemplateMixin:Register(parent)
    self.panel = parent:GetParent();
    if ( HasCurrency() ) then
        self.panel:RegisterControl(self);
    end
end

function ArmoryOptionsCurrencyCheckButtonTemplateMixin:GetValue()
    return self:GetPanel().CurrencyContainer.currencies[self.currency];
end

function ArmoryOptionsCurrencyCheckButtonTemplateMixin:SetValue(value)
    self:SetChecked(value);
    self:GetPanel().CurrencyContainer.currencies[self.currency] = value or false;
end

function ArmoryOptionsCurrencyCheckButtonTemplateMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().Currency);
end


ArmoryOptionsSummaryCurrencyContainerMixin = { currencies = {} };

function ArmoryOptionsSummaryCurrencyContainerMixin:Initialize()
    for name in pairs(Armory:GetConfigSummaryEnabledCurrencies()) do
        self.currencies[name] = true;
    end
    self:Update();
end

local currencies = {};
local currencyInfo = {};
local function GetCurrencies()
	local getVirtualCurrencies = function()
		local name, isHeader;
		for i = 1, Armory:GetVirtualNumCurrencies() do
			name, isHeader = Armory:GetVirtualCurrencyInfo(i);
			if ( (name or "") ~= "" and not isHeader and not currencyInfo[name] ) then
				table.insert(currencies, name);
				currencyInfo[name] = true;
			end
		end
	end;

	table.wipe(currencyInfo);

	local hasCurrency = Armory:CurrencyEnabled();
	if ( hasCurrency ) then
		local currentProfile = Armory:CurrentProfile();
		currencies = Armory:GetConfigSummaryCurrencies();
		for i = 1, #currencies do
			currencyInfo[currencies[i]] = true;
		end
		for _, profile in ipairs(Armory:Profiles()) do
			Armory:SelectProfile(profile);
			getVirtualCurrencies();
		end
		Armory:SelectProfile(currentProfile);
	else
		table.wipe(currencies);
	end

	-- add default currencies
	Armory:CurrencyEnabled(false);
	getVirtualCurrencies();
	Armory:CurrencyEnabled(hasCurrency);

	table.sort(currencies);

	return currencies;
end

function ArmoryOptionsSummaryCurrencyContainerMixin:Update()
    local currencies = GetCurrencies();
    local numCurrencies = #currencies;
    local showScrollBar = (numCurrencies > SUMMARY_CURRENCIES_DISPLAYED);
    local offset = FauxScrollFrame_GetOffset(self.ScrollFrame);
    local button, index;
    local width = self.ScrollFrame:GetWidth() - 16;

    for i = 1, SUMMARY_CURRENCIES_DISPLAYED do
        index = offset + i;

        button = _G[self:GetName().."Button"..i];

        if ( index > numCurrencies ) then
            button:Hide();
        else
            button.currency = currencies[index];
            button.Text:SetText(button.currency);

            -- If need scrollbar resize columns
            if ( showScrollBar ) then
                button.Text:SetWidth(width - 16);
            else
                button.Text:SetWidth(width);
            end

            button:Show();
        end
    end

    self:GetParent():OnRefresh();

    FauxScrollFrame_Update(self.ScrollFrame, numCurrencies, SUMMARY_CURRENCIES_DISPLAYED, ARMORY_SUMMARY_CURRENCIES_HEIGHT);
end

function ArmoryOptionsSummaryCurrencyContainerMixin:OnVerticalScroll(offset)
    FauxScrollFrame_OnVerticalScroll(self.ScrollFrame, offset, ARMORY_SUMMARY_CURRENCIES_HEIGHT, function() self:Update() end);
end

function ArmoryOptionsSummaryCurrencyContainerMixin:OnCommit()
    for name in pairs(self.currencies) do
        Armory:SetConfigSummaryCurrencyEnabled(name, self.currencies[name]);
    end
end
