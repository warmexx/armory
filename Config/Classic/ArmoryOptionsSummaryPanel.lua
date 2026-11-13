
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

ArmoryOptionsSummaryPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsSummaryPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_SUMMARY_TITLE);
    self.SubText:SetText(ARMORY_SUMMARY_SUBTEXT1);
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
