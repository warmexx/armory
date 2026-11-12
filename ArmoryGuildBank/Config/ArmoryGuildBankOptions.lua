
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

local AGB = AGB;
local Armory, _ = Armory, nil;

do
    ArmoryGuildBankFrame_RegisterOptions();
end

ArmoryOptionsGuildBankPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsGuildBankPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_GUILDBANK_SUBTEXT);
    self.SubText:SetText(ARMORY_GUILDBANK_SUBTEXT);
end

function ArmoryOptionsGuildBankPanelMixin:GetID()
    return ARMORY_GUILDBANK_TITLE;
end


ArmoryOptionsGuildBankShowItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankShowItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_AGBITEMCOUNT";
end

function ArmoryOptionsGuildBankShowItemCountMixin:OnShow()
    if ( AGB:GetConfigUniItemCountColor() ) then
        self:GetPanel().ShowItemCountColor:Hide();
        self:GetPanel().ShowItemCountNumberColor:Hide();
    else
        self:GetPanel().ShowItemCountColor:Show();
        self:GetPanel().ShowItemCountNumberColor:Show();
    end
end

ArmoryOptionsGuildBankShowItemCountColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin)

function ArmoryOptionsGuildBankShowItemCountColorMixin:OnLoad()
    self:ColorSetter(function(r, g, b) AGB:SetConfigItemCountColor(r, g, b); end);
    self:ColorGetter(function(default) return AGB:GetConfigItemCountColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end

ArmoryOptionsGuildBankShowItemCountNumberColorMixin = CreateFromMixins(ArmoryOptionsColorTemplateMixin)

function ArmoryOptionsGuildBankShowItemCountNumberColorMixin:OnLoad()
    self:SetLabel(STATUS_TEXT_VALUE);

    self:ColorSetter(function(r, g, b) AGB:SetConfigItemCountNumberColor(r, g, b); end);
    self:ColorGetter(function(default) return AGB:GetConfigItemCountNumberColor(default); end);

    ArmoryOptionsColorTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end


ArmoryOptionsGuildBankUniItemCountColorMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankUniItemCountColorMixin:GetKey()
    return "ARMORY_CMD_SET_AGBUNICOLOR";
end

function ArmoryOptionsGuildBankUniItemCountColorMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end

function ArmoryOptionsGuildBankUniItemCountColorMixin:OnClick()
    if ( self:GetChecked() ) then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
        self:GetPanel().ShowItemCountColor:Hide();
        self:GetPanel().ShowItemCountNumberColor:Hide();
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
        self:GetPanel().ShowItemCountColor:Show();
        self:GetPanel().ShowItemCountNumberColor:Show();
    end
end


ArmoryOptionsGuildBankMyGuildItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankMyGuildItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_AGBCOUNTMYGUILD";
end

function ArmoryOptionsGuildBankMyGuildItemCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end


ArmoryOptionsGuildBankPersonalGuildItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankPersonalGuildItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_AGBCOUNTPGB";
end

function ArmoryOptionsGuildBankPersonalGuildItemCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowItemCount);
end


ArmoryOptionsGuildBankGlobalItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankGlobalItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_AGBCOUNTALL";
end

function ArmoryOptionsGuildBankGlobalItemCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().MyGuildItemCount);
end


ArmoryOptionsGuildBankCrossFactionItemCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankCrossFactionItemCountMixin:GetKey()
    return "ARMORY_CMD_SET_AGBCOUNTXFACTION";
end

function ArmoryOptionsGuildBankCrossFactionItemCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().MyGuildItemCount);
end


ArmoryOptionsGuildBankIncludeInFindMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankIncludeInFindMixin:GetKey()
    return "ARMORY_CMD_SET_AGBFIND";
end


ArmoryOptionsGuildBankIntegrateMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGuildBankIntegrateMixin:GetKey()
    return "ARMORY_CMD_SET_AGBINTEGRATE";
end
