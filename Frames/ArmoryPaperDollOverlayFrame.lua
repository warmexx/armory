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

----------------------------------------------------------
-- Paper doll overlay
----------------------------------------------------------

hooksecurefunc("PaperDollFrame_QueuedUpdate", function(self)
    if ( Armory:GetConfigUseOverlay() ) then
        ArmoryPaperDollOverlayFrame_UpdateStats();
    end
end)

hooksecurefunc(CharacterFrame, "Expand", function(self)
    if ( Armory:GetConfigUseOverlay() ) then
        ArmoryPaperDollOverlayFrame:Show();

        if ( Armory:GetConfigCollapseCharacterFrame() ) then
            -- Collapse it back after Blizzard expanded it
            CharacterFrame:Collapse();
        end
    end
end)

function ArmoryPaperDollOverlayFrame_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
    if ( PlayerTitlePickerFrame ) then -- Removed in Patch 4.1.0
        PlayerTitlePickerFrame:SetFrameLevel(self:GetFrameLevel() + 4);
    end
end

local function ArmoryPaperDollOverlayFrame_Initialize()
    ArmoryPaperDollOverlayTopFrame_SetStatDropDown();
    ArmoryPaperDollOverlayBottomFrame_SetStatDropDown();
    ArmoryPaperDollCheckButton_Enable(not Armory:GetConfigHideCheckButton());
end

function ArmoryPaperDollOverlayFrame_OnEvent(self, event, ...)
    -- VARIABLES_LOADED can reach this frame before ArmoryFrame has loaded the database;
    -- on a new character ArmoryLocalSettings doesn't exist yet until then
    Armory:ExecuteConditional(function() return Armory.dbLoaded end, ArmoryPaperDollOverlayFrame_Initialize);
end

function ArmoryPaperDollOverlayFrame_OnShow(self)
    CharacterModelScene:Hide();
    if ( PawnUI_InventoryPawnButton ) then
        PawnUI_InventoryPawnButton:SetFrameLevel(self:GetFrameLevel() + 1);
    end

    if ( Armory:GetConfigUseMaziel() ) then
        ArmoryPaperDollTalentOverlay:Hide();
        ArmoryPaperDollTradeSkillOverlay:Hide();
        ArmoryAttributesOverlayTopFrame:Show();
        ArmoryAttributesOverlayBottomFrame:ClearAllPoints()
        ArmoryAttributesOverlayBottomFrame:SetPoint("TOPLEFT", ArmoryAttributesOverlayTopFrame, "BOTTOMLEFT", 0, -24);
    else
        ArmoryPaperDollTalentOverlay:Show();
        ArmoryPaperDollTradeSkillOverlay:Show();
        ArmoryAttributesOverlayTopFrame:Hide();
        ArmoryAttributesOverlayBottomFrame:ClearAllPoints()
        ArmoryAttributesOverlayBottomFrame:SetPoint("TOPLEFT", ArmoryPaperDollTradeSkillOverlay, "BOTTOMLEFT", 1, -25);

        ArmoryPaperDollFrame_UpdateTalent(1);
        ArmoryPaperDollFrame_UpdateSkills(1);
    end
    ArmoryPaperDollOverlayFrame_UpdateStats();

    ArmoryPaperDoll_UpdateSockets(1);

    if ( Armory:GetConfigCollapseCharacterFrame() ) then
        CharacterFrame:Collapse();
        CharacterFrame:RefreshDisplay();
    end
end

function ArmoryPaperDollOverlayFrame_OnHide(self)
    CharacterModelScene:Show();
    CharacterFrame:Expand();
    CharacterFrame:RefreshDisplay();
end

function ArmoryPaperDollOverlayTopFrame_SetStatDropDown()
    if ( not ArmoryLocalSettings.playerStatTopDropdown ) then
        ArmoryLocalSettings.playerStatTopDropdown = "ATTRIBUTES";
    end
    ArmoryDropDownMenu_SetSelectedValue(ArmoryAttributesOverlayTopFramePlayerStatDropDown, ArmoryLocalSettings.playerStatTopDropdown);
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnLoad(self)
    ArmoryDropDownMenu_SetWidth(self, 182);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnShow(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryAttributesOverlayTopFramePlayerStatDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ArmoryLocalSettings.playerStatTopDropdown);
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_Initialize()
    -- Setup buttons
    local info = ArmoryDropDownMenu_CreateInfo();
    local checked;
    for i = 1, getn(ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS) do
        if ( ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i] == ArmoryLocalSettings.playerStatTopDropdown ) then
            info.checked = 1;
            checked = 1;
        else
            info.checked = nil;
        end
        info.text = _G["STAT_CATEGORY_"..ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i]];
        info.func = ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnClick;
        info.value = ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i];
        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        ArmoryDropDownMenu_AddButton(info);
    end
    if ( not checked ) then
        ArmoryLocalSettings.playerStatTopDropdown = nil;
        ArmoryPaperDollOverlayTopFrame_SetStatDropDown();
    end
end

function ArmoryAttributesOverlayTopFramePlayerStatDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ArmoryLocalSettings.playerStatTopDropdown = self.value;
    ArmoryPaperDollFrame_UpdateStatCategory(self.value, "OverlayTop");
end

function ArmoryPaperDollOverlayBottomFrame_SetStatDropDown()
    local _, classFileName = UnitClass("player");
    classFileName = strupper(classFileName);
    if ( not ArmoryLocalSettings.playerStatBottomDropdown ) then
        ArmoryLocalSettings.playerStatBottomDropdown = "ATTRIBUTES";
        if ( classFileName == "MAGE" or classFileName == "PRIEST" or classFileName == "WARLOCK" or classFileName == "DRUID" ) then
            ArmoryLocalSettings.playerStatBottomDropdown = "SPELL";
        else
            ArmoryLocalSettings.playerStatBottomDropdown = "ENHANCEMENTS";
        end
    end
    ArmoryDropDownMenu_SetSelectedValue(ArmoryAttributesOverlayBottomFramePlayerStatDropDown, ArmoryLocalSettings.playerStatBottomDropdown);
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnLoad(self)
    ArmoryDropDownMenu_SetWidth(self, 212);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnShow(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryAttributesOverlayBottomFramePlayerStatDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ArmoryLocalSettings.playerStatBottomDropdown);
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_Initialize()
    -- Setup buttons
    local info = ArmoryDropDownMenu_CreateInfo();
    local checked;
    for i = 1, getn(ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS) do
        if ( ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i] == ArmoryLocalSettings.playerStatBottomDropdown ) then
            info.checked = 1;
            checked = 1;
        else
            info.checked = nil;
        end
        info.text = _G["STAT_CATEGORY_"..ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i]];
        info.func = ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnClick;
        info.value = ARMORY_PLAYERSTAT_DROPDOWN_OPTIONS[i];
        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        ArmoryDropDownMenu_AddButton(info);
    end
    if ( not checked ) then
        ArmoryLocalSettings.playerStatBottomDropdown = nil;
        ArmoryPaperDollOverlayBottomFrame_SetStatDropDown();
    end
end

function ArmoryAttributesOverlayBottomFramePlayerStatDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ArmoryLocalSettings.playerStatBottomDropdown = self.value;
    ArmoryPaperDollFrame_UpdateStatCategory(self.value, "OverlayBottom");
end

function ArmoryPaperDollOverlayFrame_UpdateStats()
    if ( Armory.inCombat or Armory.onHateList ) then
        return;
    end
    ArmoryPaperDollFrame_UpdateStatCategory(ArmoryLocalSettings.playerStatTopDropdown, "OverlayTop");
    ArmoryPaperDollFrame_UpdateStatCategory(ArmoryLocalSettings.playerStatBottomDropdown, "OverlayBottom");
end

function ArmoryPaperDollCheckButton_Enable(enable)
    if ( enable ) then
        ArmoryPaperDollOverlayFrameCheckButton:Show();
    else
        ArmoryPaperDollOverlayFrameCheckButton:Hide();
    end
end