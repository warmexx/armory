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

ArmoryOptionsPanelMixin = CreateFromMixins(ArmoryOptionsPanelTemplateMixin);

function ArmoryOptionsPanelMixin:Open()
    Settings.OpenToCategory(self:GetCategoryID());
end

function ArmoryOptionsPanelMixin:OnLoad()
    ArmoryOptionsPanelTemplateMixin.OnLoad(self);

    self.DefaultsButton:SetText(SETTINGS_DEFAULTS);
    self.DefaultsButton:SetScript("OnClick", function()
        StaticPopup_Show("GAME_SETTINGS_APPLY_DEFAULTS");
    end);

    self.Title:SetText(ARMORY_TITLE);
    self.SubText:SetText(ARMORY_SUBTEXT);
end

function ArmoryOptionsPanelMixin:GetID()
    return ARMORY_TITLE;
end

function ArmoryOptionsPanelTemplateMixin:OnCommit(...)
    self:ForEachControl(function(control)
        control:OnCommit();
        control:Reset();
    end);
end

function ArmoryOptionsPanelMixin:OnDefault(...)
    self:ForAllControls(function(control)
        control:SetToDefault();
    end);

    self:OnRefresh();
end

function ArmoryOptionsPanelTemplateMixin:OnRefresh(...)
    self:ForEachControl(function(control)
        if ( control:IsInitialized() ) then
            control:Refresh();
        else
            control:Initialize();
        end
    end);
end


ArmoryOptionsPanelSetEnabledMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetEnabledMixin:GetKey()
    return "ARMORY_CMD_SET_ENABLED";
end

function ArmoryOptionsPanelSetEnabledMixin:OnCommit()
    if ( self:IsDirty() ) then
        if ( not self:GetChecked() ) then
            Armory:DeleteProfile(Armory.playerRealm, Armory.player, true);
        end
        ReloadUI();
    end
end


ArmoryOptionsPanelSetSearchAllMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetSearchAllMixin:GetKey()
    return "ARMORY_CMD_SET_SEARCHALL";
end


ArmoryOptionsPanelSetLastViewedMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetLastViewedMixin:GetKey()
    return "ARMORY_CMD_SET_LASTVIEWED";
end


ArmoryOptionsPanelSetPerCharacterMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetPerCharacterMixin:GetKey()
    return "ARMORY_CMD_SET_PERCHARACTER";
end


ArmoryOptionsPanelSetShowAltEquipMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetShowAltEquipMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWALTEQUIP";
end


ArmoryOptionsPanelSetShowUnequipMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetShowUnequipMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWUNEQUIP";
end

function ArmoryOptionsPanelSetShowUnequipMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().ShowAltEquip);
end


ArmoryOptionsPanelSetShowEqcTooltipsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetShowEqcTooltipsMixin:GetKey()
    return "ARMORY_CMD_SET_SHOWEQCTOOLTIPS";
end


ArmoryOptionsPanelSetPauseInCombatMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetPauseInCombatMixin:GetKey()
    return "ARMORY_CMD_SET_PAUSEINCOMBAT";
end


ArmoryOptionsPanelSetPauseInInstanceMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetPauseInInstanceMixin:GetKey()
    return "ARMORY_CMD_SET_PAUSEININSTANCE";
end

function ArmoryOptionsPanelSetPauseInInstanceMixin:OnLoad()
    ArmoryOptionsCheckButtonTemplateMixin.OnLoad(self);
    self:SetupDependency(self:GetPanel().PauseInCombat);
end


ArmoryOptionsPanelSetScanOnEnterMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetScanOnEnterMixin:GetKey()
    return "ARMORY_CMD_SET_SCANONENTER";
end


ArmoryOptionsPanelSetFactionFilterMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetFactionFilterMixin:GetKey()
    return "ARMORY_CMD_SET_USEFACTIONFILTER";
end


ArmoryOptionsPanelSetClassColorsMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetClassColorsMixin:GetKey()
    return "ARMORY_CMD_SET_USECLASSCOLORS";
end

ArmoryOptionsPanelResetScreenMixin = CreateFromMixins(ArmoryOptionsPanelButtonTemplateMixin);

function ArmoryOptionsPanelResetScreenMixin:OnLoad()
    self:SetTooltipText(Armory:Proper(ARMORY_CMD_RESET_FRAME_TEXT));
end

function ArmoryOptionsPanelResetScreenMixin:OnClick()
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
    Armory:Reset(ARMORY_CMD_RESET_FRAME, true);
end


ArmoryOptionsPanelSetUIScaleMixin = CreateFromMixins(ArmoryOptionsSliderTemplateMixin);

function ArmoryOptionsPanelSetUIScaleMixin:GetKey()
    return "ARMORY_CMD_SET_UISCALE";
end

function ArmoryOptionsPanelSetUIScaleMixin:OnLoad()
    ArmoryOptionsSliderTemplateMixin.OnLoad(self);
    self:SetLabel(UI_SCALE);
end


ArmoryOptionsPanelSetScaleOnMouseWheelMixin = CreateFromMixins(ArmoryOptionsCheckButtonTemplateMixin);

function ArmoryOptionsPanelSetScaleOnMouseWheelMixin:GetKey()
    return "ARMORY_CMD_SET_SCALEONMOUSEWHEEL";
end
