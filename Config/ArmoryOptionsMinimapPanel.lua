
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

ArmoryOptionsMinimapPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsMinimapPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_MINIMAP_TITLE);
    self.SubText:SetText(ARMORY_MINIMAP_SUBTEXT);
end

function ArmoryOptionsMinimapPanelMixin:GetID()
    return ARMORY_MINIMAP_LABEL;
end


ArmoryOptionsMinimapButtonMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsMinimapButtonMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWMINIMAP";
end

function ArmoryOptionsMinimapButtonMixin:SetValue(value)
    ArmoryOptionsCheckButtonTemplateMixin.SetValue(self, value);
    Armory:ShowIcon();
end


ArmoryOptionsGlobalMinimapButtonMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGlobalMinimapButtonMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWMMGLOBAL";
end


ArmoryOptionsSetHideMinimapIfToolbarMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsSetHideMinimapIfToolbarMixin:GetKey()
    return "ARMORY_CMD_SET_HIDEMMTOOLBAR";
end

function ArmoryOptionsSetHideMinimapIfToolbarMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().MinimapButton);
end


ArmoryOptionsSetMinimapAngleMixin = CreateFromMixins(ArmoryOptionsSliderTemplateMixin);

function ArmoryOptionsSetMinimapAngleMixin:GetKey()
    return "ARMORY_CMD_SET_MMB_ANGLE";
end

function ArmoryOptionsSetMinimapAngleMixin:OnLoad()
    ArmoryOptionsSliderTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().MinimapButton);
end

function ArmoryOptionsSetMinimapAngleMixin:OnShow()
    self.Low:SetText("");
    self.High:SetText("");
end

function ArmoryOptionsSetMinimapAngleMixin:OnValueChanged(value)
    ArmoryOptionsSliderTemplateMixin.OnValueChanged(self, value);
    Armory:MoveIconToPosition();
end


ArmoryOptionsGlobalPositionButtonMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsGlobalPositionButtonMixin:GetKey()
    return "ARMORY_CMD_SET_MMB_GLOBAL";
end

function ArmoryOptionsGlobalPositionButtonMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().MinimapButton);
end
