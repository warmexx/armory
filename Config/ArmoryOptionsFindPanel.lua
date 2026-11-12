
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

ArmoryOptionsFindPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsFindPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_FIND_TITLE);
    self.SubText:SetText(ARMORY_FIND_SUBTEXT);
end

function ArmoryOptionsFindPanelMixin:GetID()
    return ARMORY_FIND_LABEL;
end


ArmoryOptionsSearchWindowMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSearchWindowMixin:GetKey()
    return "ARMORY_CMD_SET_WINDOWSEARCH";
end


ArmoryOptionsSearchRealmsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSearchRealmsMixin:GetKey()
    return "ARMORY_CMD_SET_GLOBALSEARCH";
end


ArmoryOptionsSearchExtendedMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSearchExtendedMixin:GetKey()
    return "ARMORY_CMD_SET_EXTENDEDSEARCH";
end


ArmoryOptionsSearchRestrictiveMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSearchRestrictiveMixin:GetKey()
    return "ARMORY_CMD_SET_RESTRICTIVESEARCH";
end


ArmoryOptionsSearchAltClickMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSearchAltClickMixin:GetKey()
    return "ARMORY_CMD_SET_ALTCLICKSEARCH";
end


ArmoryOptionsDefaultSearchTypeMixin = CreateFromMixins(ArmoryOptionsDropDownTemplateMixin);

function ArmoryOptionsDefaultSearchTypeMixin:SetValue(value)
    ArmoryOptionsDropDownTemplateMixin.SetValue(self, value);
    Armory:SetConfigDefaultSearch(value);
end

function ArmoryOptionsDefaultSearchTypeMixin:OnLoad()
    ArmoryOptionsDropDownTemplateMixin.OnLoad(self);
    self:SetLabel(Armory:Proper(ARMORY_CMD_SET_DEFAULTSEARCH_TEXT));
    self:SetTooltipText(ARMORY_CMD_SET_DEFAULTSEARCH_TOOLTIP);
    self:SetDefaultValue(ARMORY_CMD_FIND_ITEM);
end

function ArmoryOptionsDefaultSearchTypeMixin:Initialize()
    ArmoryOptionsDropDownTemplateMixin.Initialize(self);
    self:SetValue(Armory:GetConfigDefaultSearch());
end

function ArmoryOptionsDefaultSearchTypeMixin:AddButtons(info)
    for _, value in ipairs({ARMORY_CMD_FIND_ALL, ARMORY_CMD_FIND_INVENTORY, ARMORY_CMD_FIND_ITEM, ARMORY_CMD_FIND_QUEST, ARMORY_CMD_FIND_SPELL, ARMORY_CMD_FIND_SKILL}) do
        info.text =  Armory:Proper(value);
        info.value = value;
        info.checked = nil;
        ArmoryDropDownMenu_AddButton(info);
    end
end
