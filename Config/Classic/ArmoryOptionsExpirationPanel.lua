
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

local format = format;
local floor = floor;

ArmoryOptionsExpirationPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsExpirationPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_EXPIRATION_TITLE);
    self.SubText:SetText(ARMORY_EXPIRATION_SUBTEXT);
end

function ArmoryOptionsExpirationPanelMixin:GetID()
    return ARMORY_EXPIRATION_LABEL;
end


ArmoryOptionsExpirationDaysMixin = CreateFromMixins(ArmoryOptionsSliderTemplateMixin);

function ArmoryOptionsExpirationDaysMixin:GetKey()
    return "ARMORY_CMD_SET_EXPDAYS";
end

function ArmoryOptionsExpirationDaysMixin:OnValueChanged(value)
    ArmoryOptionsSliderTemplateMixin.OnValueChanged(self, value);
    local expiration;
    if ( floor(value) == 0 ) then
        expiration = "(" .. OFF .. ")";
    else
        expiration = format(DAYS_ABBR, floor(value));
    end
    self:SetLabel(Armory:Proper(ARMORY_CMD_SET_EXPDAYS_TEXT) .. ": " .. expiration);
end


ArmoryOptionsExpirationIgnoreAltsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationIgnoreAltsMixin:GetKey()
    return "ARMORY_CMD_SET_IGNOREALTS";
end


ArmoryOptionsExpirationCheckVisitMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationCheckVisitMixin:GetKey()
    return "ARMORY_CMD_SET_MAILCHECKVISIT";
end


ArmoryOptionsExpirationExcludeVisitMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationExcludeVisitMixin:GetKey()
    return "ARMORY_CMD_SET_MAILEXCLUDEVISIT";
end

function ArmoryOptionsExpirationExcludeVisitMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().CheckVisit);
end


ArmoryOptionsExpirationLogonVisitMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationLogonVisitMixin:GetKey()
    return "ARMORY_CMD_SET_MAILHIDELOGONVISIT";
end

function ArmoryOptionsExpirationLogonVisitMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().CheckVisit);
end


ArmoryOptionsExpirationCheckCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationCheckCountMixin:GetKey()
    return "ARMORY_CMD_SET_MAILCHECKCOUNT";
end


ArmoryOptionsExpirationHideCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationHideCountMixin:GetKey()
    return "ARMORY_CMD_SET_MAILHIDECOUNT";
end

function ArmoryOptionsExpirationHideCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().CheckCount);
end


ArmoryOptionsExpirationLogonCountMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsExpirationLogonCountMixin:GetKey()
    return "ARMORY_CMD_SET_MAILHIDELOGONCOUNT";
end

function ArmoryOptionsExpirationLogonCountMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().CheckCount);
end


ArmoryOptionsExpirationCheckMixin = CreateFromMixins(ArmoryOptionsPanelButtonTemplateMixin);

function ArmoryOptionsExpirationCheckMixin:OnLoad()
    self:SetTooltipText(Armory:Proper(ARMORY_CMD_CHECK_TEXT));
end

function ArmoryOptionsExpirationCheckMixin:OnClick()
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
    Armory:CheckMailItems();
end
