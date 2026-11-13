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

local ipairs = ipairs;
local PlaySound = PlaySound;

ArmoryOptionsMiscPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsMiscPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_MISC_TITLE);
    self.SubText:SetText(ARMORY_MISC_SUBTEXT);
end

function ArmoryOptionsMiscPanelMixin:GetID()
    return ARMORY_MISC_LABEL;
end


ArmoryOptionsMiscLDBLabelMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsMiscLDBLabelMixin:GetKey()
    return "ARMORY_CMD_SET_LDBLABEL";
end


ArmoryOptionsMiscEncodingMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsMiscEncodingMixin:GetKey()
    return "ARMORY_CMD_SET_USEENCODING";
end

function ArmoryOptionsMiscEncodingMixin:OnCommit()
    if ( self:IsDirty() ) then
        Armory:ConvertDb();
    end
end


ArmoryOptionsMiscEnhancedTipsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsMiscEnhancedTipsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWENHANCEDTIPS";
end


ArmoryOptionsMiscExtendedTradeSkillsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsMiscExtendedTradeSkillsMixin:GetKey()
    return "ARMORY_CMD_SET_EXTENDEDTRADE";
end


ArmoryOptionsMiscSystemWarningsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsMiscSystemWarningsMixin:GetKey()
    return "ARMORY_CMD_SET_SYSTEMWARNINGS";
end


ArmoryMiscWarningSoundMixin = CreateFromMixins(ArmoryOptionsDropDownTemplateMixin);

function ArmoryMiscWarningSoundMixin:SetValue(value)
    ArmoryOptionsDropDownTemplateMixin.SetValue(self, value or "");
    Armory:SetConfigWarningSound(value);
end

function ArmoryMiscWarningSoundMixin:SetSelectedValue(value)
    ArmoryOptionsDropDownTemplateMixin.SetSelectedValue(self, value);
    if ( (value or "") ~= "" ) then
        PlaySound(value);
    end
end

function ArmoryMiscWarningSoundMixin:OnLoad()
    ArmoryOptionsDropDownTemplateMixin.OnLoad(self);
    self:SetLabel(Armory:Proper(ARMORY_CMD_SET_WARNINGSOUND_TEXT));
    self:SetTooltipText(ARMORY_CMD_SET_WARNINGSOUND_TOOLTIP);
    self:SetDefaultValue("");
end

function ArmoryMiscWarningSoundMixin:Initialize()
    ArmoryOptionsDropDownTemplateMixin.Initialize(self);
    self:SetValue(Armory:GetConfigWarningSound());
end

function ArmoryMiscWarningSoundMixin:AddButtons(info)
    info.text = NONE;
    info.value = "";
    info.checked = nil;
    ArmoryDropDownMenu_AddButton(info);

    for k, v in ipairs(Armory.sounds) do
        info.text = ARMORY_SOUND.." "..k;

        info.value = v;
        info.checked = nil;
        ArmoryDropDownMenu_AddButton(info);
    end
end
