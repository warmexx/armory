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

ArmoryOptionsTooltipPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsTooltipPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_TOOLTIP_TITLE);
    self.SubText:SetText(ARMORY_TOOLTIP_SUBTEXT);
end

function ArmoryOptionsTooltipPanelMixin:GetID()
    return ARMORY_TOOLTIP_LABEL;
end


ArmoryOptionsTooltipShowItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWITEMCOUNT";
end


ArmoryOptionsTooltipShowItemCountColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin)

function ArmoryOptionsTooltipShowItemCountColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigItemCountColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigItemCountColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end

ArmoryOptionsTooltipShowItemCountNumberColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowItemCountNumberColorMixin:OnLoad()
    self:SetLabel(STATUS_TEXT_VALUE);

    self:ColorSetter(function(r, g, b) Armory:SetConfigItemCountNumberColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigItemCountNumberColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end


ArmoryOptionsTooltipShowItemCountTotalsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowItemCountTotalsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWCOUNTTOTAL";
end

function ArmoryOptionsTooltipShowItemCountTotalsMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end

ArmoryOptionsTooltipShowItemCountTotalsColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowItemCountTotalsColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigItemCountTotalsColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigItemCountTotalsColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCountTotals);
end

ArmoryOptionsTooltipShowItemCountTotalsNumberColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowItemCountTotalsNumberColorMixin:OnLoad()
    self:SetLabel(STATUS_TEXT_VALUE);

    self:ColorSetter(function(r, g, b) Armory:SetConfigItemCountTotalsNumberColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigItemCountTotalsNumberColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetParent().ShowItemCountTotals);
end


ArmoryOptionsTooltipItemCountPerSlotMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipItemCountPerSlotMixin:GetKey()
    return "ARMORY_CMD_SET_COUNTPERSLOT";
end

function ArmoryOptionsTooltipItemCountPerSlotMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end


ArmoryOptionsTooltipGlobalItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipGlobalItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_COUNTALL";
end

function ArmoryOptionsTooltipGlobalItemCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end


ArmoryOptionsTooltipCrossFactionItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipCrossFactionItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_COUNTXFACTION";
end

function ArmoryOptionsTooltipCrossFactionItemCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end

ArmoryOptionsTooltipShowKnownByMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowKnownByMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWKNOWNBY";
end

ArmoryOptionsTooltipShowKnownByColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowKnownByColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigKnownColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigKnownColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowKnownBy);
end


ArmoryOptionsTooltipShowHasSkillMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowHasSkillMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWHASSKILL";
end

ArmoryOptionsTooltipShowHasSkillColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowHasSkillColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigHasSkillColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigHasSkillColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowHasSkill);
end

ArmoryOptionsTooltipShowCanLearnMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowCanLearnMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWCANLEARN";
end

ArmoryOptionsTooltipShowCanLearnColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowCanLearnColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigCanLearnColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigCanLearnColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowCanLearn);
end


ArmoryOptionsTooltipShowCraftersMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowCraftersMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWCRAFTERS";
end

ArmoryOptionsTooltipShowCraftersColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowCraftersColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigCraftersColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigCraftersColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowCrafters);
end


ArmoryOptionsTooltipShowSkillRankMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowSkillRankMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWSKILLRANK";
end

ArmoryOptionsTooltipShowSkillRankColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowSkillRankColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigTradeSkillRankColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigTradeSkillRankColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowSkillRank);
end


ArmoryOptionsTooltipShowSecondarySkillRankMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowSecondarySkillRankMixin:GetKey()
    return "ARMORY_CMD_SET_SHOW2NDSKILLRANK";
end

function ArmoryOptionsTooltipShowSecondarySkillRankMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowSkillRank);
end


-- A color has no option of its own; it goes with the option it depends on, which Classic
-- does not have for quests and achievements
local function OptionAvailable(key)
    return function()
        return Armory.options[key] ~= nil;
    end;
end

ArmoryOptionsTooltipShowQuestAltsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowQuestAltsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWQUESTALTS";
end

ArmoryOptionsTooltipShowQuestAltsColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

ArmoryOptionsTooltipShowQuestAltsColorMixin.IsAvailable = OptionAvailable("ARMORY_CMD_SET_SHOWQUESTALTS");

function ArmoryOptionsTooltipShowQuestAltsColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigQuestAltsColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigQuestAltsColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowQuestAlts);
end


ArmoryOptionsTooltipShowAchievementsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

local HasAchievements = OptionAvailable("ARMORY_CMD_SET_SHOWACHIEVEMENTS");

function ArmoryOptionsTooltipShowAchievementsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWACHIEVEMENTS";
end

ArmoryOptionsTooltipShowAchievementsColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

ArmoryOptionsTooltipShowAchievementsColorMixin.IsAvailable = HasAchievements;

function ArmoryOptionsTooltipShowAchievementsColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigAchievementsColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigAchievementsColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowAchievements);
end


ArmoryOptionsTooltipAchievementInProgressMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipAchievementInProgressMixin:GetKey()
    return "ARMORY_CMD_SET_USEINPROGRESSCOLOR";
end

function ArmoryOptionsTooltipAchievementInProgressMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowAchievements);
end

ArmoryOptionsTooltipAchievementInProgressColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

ArmoryOptionsTooltipAchievementInProgressColorMixin.IsAvailable = HasAchievements;

function ArmoryOptionsTooltipAchievementInProgressColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) Armory:SetConfigAchievementInProgressColor(r, g, b); end);
    self:ColorGetter(function(default) return Armory:GetConfigAchievementInProgressColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().AchievementInProgress);
end


ArmoryOptionsTooltipShowGearSetsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowGearSetsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWGEARSETS";
end

ArmoryOptionsTooltipShowGemsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowGemsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWGEMS";
end
