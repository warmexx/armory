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

local strlen = strlen;

ArmoryOptionsSharePanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsSharePanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.Title:SetText(ARMORY_SHARE_TITLE);
    self.SubText:SetText(ARMORY_SHARE_SUBTEXT1);
end

function ArmoryOptionsSharePanelMixin:GetID()
    return ARMORY_SHARE_LABEL;
end


ArmoryOptionsShareProfessionsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareProfessionsMixin:GetKey()
    return "ARMORY_CMD_SET_SHARESKILLS";
end


ArmoryOptionsShareQuestsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareQuestsMixin:GetKey()
    return "ARMORY_CMD_SET_SHAREQUESTS";
end


ArmoryOptionsShareCharacterMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareCharacterMixin:GetKey()
    return "ARMORY_CMD_SET_SHARECHARACTER";
end


ArmoryOptionsShareItemsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareItemsMixin:GetKey()
    return "ARMORY_CMD_SET_SHAREITEMS";
end


ArmoryOptionsShareAsAltMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareAsAltMixin:GetKey()
    return "ARMORY_CMD_SET_SHAREALT";
end


ArmoryOptionsShareChannelEnableMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareChannelEnableMixin:GetKey()
    return "ARMORY_CMD_SET_SHARECHANNEL";
end

function ArmoryOptionsShareChannelEnableMixin:OnLoad()
    self:Register(self:GetParent():GetParent());
end


ArmoryOptionsShareChannelNameMixin = CreateFromMixins(ArmoryOptionControlBaseMixin);

function ArmoryOptionsShareChannelNameMixin:GetKey()
    return nil;
end

function ArmoryOptionsShareChannelNameMixin:GetDefaultValue()
    local _, name = Armory:GetConfigChannelName();
    return name;
end

function ArmoryOptionsShareChannelNameMixin:OnLoad()
    self.Text = self;
    self:SetMaxLetters(31 - strlen(ARMORY_ID));

    self:Register(self:GetParent():GetParent());
    self:SetupDependency(self:GetParent().Check);
end

function ArmoryOptionsShareChannelNameMixin:OnShow()
    self:SetText(self:GetValue() or ADD_CHANNEL);
    self:SetCursorPosition(0);
    self:ClearFocus();
end

function ArmoryOptionsShareChannelNameMixin:OnTextChanged()
    if ( self:GetText() == "" ) then
        self:SetValue(nil);
    elseif ( self:GetText() ~= ADD_CHANNEL ) then
        self:SetValue(self:GetText():gsub(" ", ""));
    end
end

function ArmoryOptionsShareChannelNameMixin:OnEditFocusLost()
    self:HighlightText(0, 0);
    if ( self:GetText() == "" ) then
        self:SetText(ADD_CHANNEL);
    end
end

function ArmoryOptionsShareChannelNameMixin:OnEditFocusGained()
    self:HighlightText();
    if ( self:GetText() == ADD_CHANNEL ) then
        self:SetText("");
    end
end

function ArmoryOptionsShareChannelNameMixin:OnCommit()
    if ( self:IsInitialized() and self:IsDirty() ) then
        if ( self:GetOriginalValue() ) then
            Armory:SetConfigChannelName(self:GetOriginalValue());
            ArmoryAddonMessageFrame_UpdateChannel(true);
        end
        Armory:SetConfigChannelName(self:GetValue());
        ArmoryAddonMessageFrame_UpdateChannel();
    end
end


ArmoryOptionsShareInInstanceMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareInInstanceMixin:GetKey()
    return "ARMORY_CMD_SET_SHAREININSTANCE";
end


ArmoryOptionsShareInCombatMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareInCombatMixin:GetKey()
    return "ARMORY_CMD_SET_SHAREINCOMBAT";
end


ArmoryOptionsShareMessagesMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareMessagesMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWSHAREMSG";
end


ArmoryOptionsShareAllMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsShareAllMixin:GetKey()
    return "ARMORY_CMD_SET_SHAREALL";
end
