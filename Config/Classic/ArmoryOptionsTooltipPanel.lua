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


ArmoryOptionsTooltipShowItemCountNumberColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowItemCountNumberColorMixin:OnLoad()
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

ArmoryOptionsTooltipShowItemCountTotalsNumberColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin);

function ArmoryOptionsTooltipShowItemCountTotalsNumberColorMixin:OnLoad()
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


ArmoryOptionsTooltipShowHasSkillMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowHasSkillMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWHASSKILL";
end


ArmoryOptionsTooltipShowCanLearnMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowCanLearnMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWCANLEARN";
end


ArmoryOptionsTooltipShowCraftersMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsTooltipShowCraftersMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWCRAFTERS";
end
