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

local MAX_SPELLS = 1024;
local MAX_SKILLLINE_TABS = 8;
local SPELLS_PER_PAGE = 12;
local SPELLBOOK_PAGENUMBERS = {};
SPELLBOOK_PAGENUMBERS["pet"] = {};

local SPELLFLYOUT_DEFAULT_SPACING = 4;
local SPELLFLYOUT_INITIAL_SPACING = 7;
local SPELLFLYOUT_FINAL_SPACING = 9;

-- Classic's spellbook API still takes a book type
local BANK_PLAYER, BANK_PET, GetPetSpec;
if ( Armory.isClassic ) then
    BANK_PLAYER = BOOKTYPE_SPELL;
    BANK_PET = BOOKTYPE_PET;
    GetPetSpec = function() end;
else
    BANK_PLAYER = Enum.SpellBookSpellBank.Player;
    BANK_PET = Enum.SpellBookSpellBank.Pet;
    GetPetSpec = function() return Armory:GetSpecialization(false, true) or 1; end;
end

function ArmoryToggleSpellBook(spellBank)
    if ( spellBank == BANK_PET and (not Armory:PetsEnabled() or not Armory:HasPetSpells() or not Armory:PetHasSpellbook()) ) then
        return;
    end

    local isShown = ArmorySpellBookFrame:IsShown();
    if ( isShown ) then
        ArmorySpellBookFrame.suppressCloseSound = true;
    end

    ArmorySpellBookFrame:Hide();
    if ( (not isShown or (ArmorySpellBookFrame.spellBank ~= spellBank)) ) then
        ArmorySpellBookFrame.spellBank = spellBank;
        ArmoryCloseChildWindows();
        ArmorySpellBookFrame:Show();
    end
    ArmorySpellBookFrame_UpdatePages();

    ArmorySpellBookFrame.suppressCloseSound = nil;
end

function ArmorySpellBookFrame_OnLoad(self)
    if ( Armory.isClassic ) then
        -- Blizzard's frame template in Classic has a button bar
        ButtonFrameTemplate_HideButtonBar(self);
        Armory:SetPortraitToTexture(ArmorySpellBookFramePortrait, "Interface\\Spellbook\\Spellbook-Icon");

        self:RegisterEvent("PET_BAR_UPDATE");
        self:RegisterEvent("TRADE_SKILL_CLOSE");
    else
        self:SetPortraitToAsset("Interface\\Spellbook\\Spellbook-Icon");

        self:RegisterEvent("PLAYER_GUILD_UPDATE");
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    end
    self:SetTitle(SPELLBOOK);

    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", PANEL_DEFAULT_WIDTH + PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_BOTTOM_OFFSET);

    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("SPELLS_CHANGED");
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM");

    self.spellBank = BANK_PLAYER;

    ArmoryPanelTemplates_SetNumTabs(self, 2);
    ArmoryPanelTemplates_SetTab(self, 1);
end

function ArmorySpellBookFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD") then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:SpellsExists() ) then
            Armory:Execute(ArmorySpellBookFrame_UpdateSpells);
        end
    else
        Armory:Execute(ArmorySpellBookFrame_UpdateSpells);
    end
end

function ArmorySpellBookFrame_UpdateSpells()
    Armory:SetSpells();
    ArmorySpellBookFrame_Update();
end

function ArmorySpellBookFrame_OnShow(self)
    ArmorySpellBookFrame.selectedPetSpec = GetPetSpec();

    -- Init page nums
    SPELLBOOK_PAGENUMBERS[1] = 1;
    SPELLBOOK_PAGENUMBERS[2] = 1;
    SPELLBOOK_PAGENUMBERS[3] = 1;
    SPELLBOOK_PAGENUMBERS[4] = 1;
    SPELLBOOK_PAGENUMBERS[5] = 1;
    SPELLBOOK_PAGENUMBERS[6] = 1;
    SPELLBOOK_PAGENUMBERS[7] = 1;
    SPELLBOOK_PAGENUMBERS[8] = 1;
    SPELLBOOK_PAGENUMBERS["pet"][1] = 1;
    SPELLBOOK_PAGENUMBERS["pet"][2] = 1;

    -- Set to the class tab by default
    ArmorySpellBookFrame.selectedSkillLine = 2;

    -- Set to first tab by default
    ArmorySpellBookFrame.selectedPetSkillLine = 1;

    ArmorySpellBookFrame_PlayOpenSound();
    ArmorySpellBookFrame_Update(true);
end

function ArmorySpellBookFrame_Update(showing)
    local hasPetSpells, petToken;
    if ( Armory:PetsEnabled() ) then
        hasPetSpells, petToken = Armory:HasPetSpells(ArmorySpellBookFrame.selectedPetSpec);
        hasPetSpells = hasPetSpells and Armory:PetHasSpellbook(ArmorySpellBookFrame.selectedPetSpec);
    end
    if ( ArmorySpellBookFrame.spellBank == BANK_PET and not hasPetSpells ) then
        ArmorySpellBookFrame.spellBank = BANK_PLAYER;
    end

    -- Hide all tabs
    ArmorySpellBookFrameTabButton1:Hide();
    ArmorySpellBookFrameTabButton2:Hide();

    -- Setup skillline tabs
    if ( showing ) then
        if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
            ArmorySpellBookSkillLineTab_OnClick(nil, ArmorySpellBookFrame.selectedPetSkillLine, ArmorySpellBookFrame.selectedPetSpec);
        else
            ArmorySpellBookSkillLineTab_OnClick(nil, ArmorySpellBookFrame.selectedSkillLine);
        end
    end

    ArmorySpellBookFrame_UpdateSkillLineTabs();

    -- Setup tabs
    ArmorySpellBookFrame.petTitle = nil;
    if ( hasPetSpells ) then
        ArmorySpellBookFrame_SetTabType(ArmorySpellBookFrameTabButton1, BANK_PLAYER);
        ArmorySpellBookFrame_SetTabType(ArmorySpellBookFrameTabButton2, BANK_PET, petToken);
    else
        ArmorySpellBookFrame_SetTabType(ArmorySpellBookFrameTabButton1, BANK_PLAYER);
        if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
            -- if has no pet spells but trying to show the pet spellbook close the window;
            ArmorySpellBookFrame:Hide();
            ArmorySpellBookFrame.spellBank = BANK_PLAYER;
        end
    end
    -- The selected tab follows the book that is shown, also when the book changes without a click on the tab
    ArmoryPanelTemplates_SetTab(ArmorySpellBookFrame, ArmorySpellBookFrame.spellBank == BANK_PET and 2 or 1);

    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        ArmorySpellBookFrame:SetTitle(ArmorySpellBookFrame.petTitle);
        ArmorySpellBookFrame_SetSelectedPetInfo();
        ArmorySpellBookPetInfo:Show();
        ArmorySpellBookFrame_ShowSpells();
        ArmorySpellBookFrame_UpdatePages();
    else
        ArmorySpellBookFrame:SetTitle(SPELLBOOK);
        ArmorySpellBookPetInfo:Hide();
        ArmorySpellBookFrame_ShowSpells();
        ArmorySpellBookFrame_UpdatePages();
    end
end

function ArmorySpellBookFrame_SetSelectedPetInfo()
    local icon = Armory:GetPetIcon();
    local name = Armory.selectedPet;
    local level = Armory:UnitLevel("pet");
    local family = Armory:UnitCreatureFamily("pet");
    local text = "";

    ArmorySpellBookPetInfo.icon:SetTexture(icon);

    if ( name ) then
          local petName, realName = Armory:UnitName("pet");
        if ( realName and petName == name ) then
            ArmorySpellBookPetInfo.name:SetText(realName);
        else
            ArmorySpellBookPetInfo.name:SetText(name);
        end
    else
        ArmorySpellBookPetInfo.name:SetText("");
    end

    if ( level and family ) then
        ArmorySpellBookPetInfo.text:SetFormattedText(UNIT_TYPE_LEVEL_TEMPLATE, level, family);
    elseif ( level ) then
        ArmorySpellBookPetInfo.text:SetFormattedText(UNIT_LEVEL_TEMPLATE, level);
    elseif ( family ) then
        ArmorySpellBookPetInfo.text:SetText(family);
    else
        ArmorySpellBookPetInfo.text:SetText("");
    end
end

function ArmorySpellBookFrame_HideSpells()
    for i = 1, SPELLS_PER_PAGE do
        _G["ArmorySpellButton" .. i]:Hide();
    end

    for i = 1, MAX_SKILLLINE_TABS do
        _G["ArmorySpellBookSkillLineTab" .. i]:Hide();
    end

    ArmorySpellBookPrevPageButton:Hide();
    ArmorySpellBookNextPageButton:Hide();
    ArmorySpellBookPageText:Hide();
end

function ArmorySpellBookFrame_ShowSpells()
    for i = 1, SPELLS_PER_PAGE do
        _G["ArmorySpellButton" .. i]:Show();
    end

    ArmorySpellBookPrevPageButton:Show();
    ArmorySpellBookNextPageButton:Show();
    ArmorySpellBookPageText:Show();
end

function ArmorySpellBookFrame_UpdatePages()
    local currentPage, maxPages = ArmorySpellBook_GetCurrentPage();
    if ( maxPages == 0 ) then
        ArmorySpellBookPrevPageButton:Disable();
        ArmorySpellBookNextPageButton:Disable();
        ArmorySpellBookPageText:SetText("");
        return;
    end
    if ( currentPage > maxPages ) then
        if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
            SPELLBOOK_PAGENUMBERS["pet"][ArmorySpellBookFrame.selectedPetSkillLine] = maxPages;
        else
            SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] = maxPages;
        end
        currentPage = maxPages;
        ArmorySpellBook_UpdateSpells();
        if ( currentPage == 1 ) then
            ArmorySpellBookPrevPageButton:Disable();
        else
            ArmorySpellBookPrevPageButton:Enable();
        end
        if ( currentPage == maxPages ) then
            ArmorySpellBookNextPageButton:Disable();
        else
            ArmorySpellBookNextPageButton:Enable();
        end
    end
    if ( currentPage == 1 ) then
        ArmorySpellBookPrevPageButton:Disable();
    else
        ArmorySpellBookPrevPageButton:Enable();
    end
    if ( currentPage == maxPages ) then
        ArmorySpellBookNextPageButton:Disable();
    else
        ArmorySpellBookNextPageButton:Enable();
    end
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, currentPage);
end

function ArmorySpellBookFrame_SetTabType(tabButton, spellBank, token)
    if ( spellBank == BANK_PET ) then
        tabButton.spellBank = BANK_PET;
        tabButton:SetText(_G["PET_TYPE_"..token]);
        ArmorySpellBookFrame.petTitle = _G["PET_TYPE_"..token];
    else
        tabButton.spellBank = BANK_PLAYER;
        tabButton:SetText(SPELLBOOK);
    end
    tabButton:Show();
end

function ArmorySpellBookFrame_PlayOpenSound()
    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        -- Need to change to pet book open sound
        PlaySound(SOUNDKIT.IG_ABILITY_OPEN);
    else
        PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN);
    end
end

function ArmorySpellBookFrame_PlayCloseSound()
    if ( not ArmorySpellBookFrame.suppressCloseSound ) then
        if ( ArmorySpellBookFrame.spellBank == BANK_PLAYER ) then
            PlaySound(SOUNDKIT.IG_SPELLBOOK_CLOSE);
        else
            -- Need to change to pet book close sound
            PlaySound(SOUNDKIT.IG_ABILITY_CLOSE);
        end
    end
end

function ArmorySpellBookFrame_OnHide(self)
    ArmorySpellBookFrame_PlayCloseSound();
end

function ArmorySpellButton_OnEnter(self)
    local slot = ArmorySpellBook_GetSpellBookSlot(self);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if ( slot and Armory:SetSpell(slot, ArmorySpellBookFrame.spellBank) ) then
        self.UpdateTooltip = ArmorySpellButton_OnEnter;
    else
        self.UpdateTooltip = nil;
    end
end

function ArmorySpellButton_OnClick(self)
    if ( IsModifiedClick("CHATLINK") and self.link ) then
        HandleModifiedItemClick(self.link);
    end
    local slot, slotType = ArmorySpellBook_GetSpellBookSlot(self);
    if ( slot > MAX_SPELLS or slotType ~= "FLYOUT") then
        return;
    end
    local _, spellID = Armory:GetSpellBookItemInfo(slot, ArmorySpellBookFrame.spellBank);
    ArmorySpellFlyout_Toggle(ArmorySpellFlyout, self, slot, spellID, self.offSpecID);
    ArmorySpellFlyout_SetBorderColor(ArmorySpellFlyout, 181/256, 162/256, 90/256);
    ArmorySpellFlyout_SetBorderSize(ArmorySpellFlyout, 42);
end

function ArmorySpellButton_UpdateButton(self)
    local offset, numSlots, offSpecID;
    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        if ( not ArmorySpellBookFrame.selectedPetSkillLine ) then
            ArmorySpellBookFrame.selectedPetSkillLine = 1;
        end
        _, _, offset, numSlots, _, offSpecID = Armory:GetSpellTabInfo(ArmorySpellBookFrame.selectedPetSkillLine);
    else
        if ( not ArmorySpellBookFrame.selectedSkillLine ) then
            ArmorySpellBookFrame.selectedSkillLine = 2;
        end
        _, _, offset, numSlots, _, offSpecID = Armory:GetSpellTabInfo(ArmorySpellBookFrame.selectedSkillLine);
    end
    ArmorySpellBookFrame.selectedSkillLineNumSlots = numSlots;
    ArmorySpellBookFrame.selectedSkillLineOffset = offset;
    local isOffSpec = (offSpecID ~= 0) and (ArmorySpellBookFrame.spellBank == BANK_PLAYER);
    self.offSpecID = offSpecID;

    local slot, slotType, attachedGlyph, isDisabled, isLocked = ArmorySpellBook_GetSpellBookSlot(self);
    local name = self:GetName();
    local iconTexture = _G[name.."IconTexture"];
    local levelLinkLockTexture = _G[name.."LevelLinkLockTexture"];
    local levelLinkLockBg = _G[name.."LevelLinkLockBg"];
    local spellString = _G[name.."SpellName"];
    local subSpellString = _G[name.."SubSpellName"];
    local autoCastableTexture = _G[name.."AutoCastable"];

    -- Hide flyout if it's currently open
    if ( ArmorySpellFlyout:IsShown() and ArmorySpellFlyout:GetParent() == self )  then
        ArmorySpellFlyout:Hide();
    end

    if ( (ArmorySpellBookFrame.spellBank ~= BANK_PET) and not slot ) then
        self:Disable();
        iconTexture:Hide();
        levelLinkLockTexture:Hide();
        levelLinkLockBg:Hide();
        spellString:Hide();
        subSpellString:Hide();
        autoCastableTexture:Hide();
        self.SeeTrainerString:Hide();
        self.RequiredLevelString:Hide();
        self.FlyoutArrow:Hide();
        self.GlyphIcon:Hide();
        self.EmptySlot:SetDesaturated(isOffSpec);
        return;
    else
        self:Enable();
    end

    local texture = slot and Armory:GetSpellBookItemTexture(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec);

    -- If no spell, hide everything and return
    if ( not texture or (strlen(texture) == 0) ) then
        iconTexture:Hide();
        spellString:Hide();
        subSpellString:Hide();
        autoCastableTexture:Hide();
        self.SeeTrainerString:Hide();
        self.RequiredLevelString:Hide();
        self.FlyoutArrow:Hide();
        self.GlyphIcon:Hide();
        return;
    end
    self.link = Armory:GetSpellLink(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec);

    local autoCastAllowed = Armory:GetSpellAutocast(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec);
    if ( autoCastAllowed ) then
        autoCastableTexture:Show();
    else
        autoCastableTexture:Hide();
    end

    local spellName, subSpellName, spellID = Armory:GetSpellBookItemName(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec);
    local isPassive = Armory:IsPassiveSpell(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec);
    if ( isPassive ) then
        spellString:SetTextColor(PASSIVE_SPELL_FONT_COLOR.r, PASSIVE_SPELL_FONT_COLOR.g, PASSIVE_SPELL_FONT_COLOR.b);
    else
        spellString:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    end

    if ( slotType == "FLYOUT" ) then
        SetClampedTextureRotation(self.FlyoutArrow, 90);
        self.FlyoutArrow:Show();
    else
        self.FlyoutArrow:Hide();
    end

    iconTexture:SetTexture(texture);
    spellString:SetText(spellName);
    subSpellString:SetText(subSpellName);

    -- If there is no spell sub-name, move the bottom row of text up
    if ( subSpellName == "" ) then
        self.SpellSubName:SetHeight(6);
    else
        self.SpellSubName:SetHeight(18);
    end

    iconTexture:Show();
    spellString:Show();
    subSpellString:Show();

    local iconTextureAlpha;
    local iconTextureDesaturated;
    isDisabled = spellID and isDisabled;
    if ( not (slotType == "FUTURESPELL") and not isDisabled ) then
        iconTextureAlpha = 1;
        iconTextureDesaturated = false;
        self.RequiredLevelString:Hide();
        self.SeeTrainerString:Hide();
        self.SpellName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        if ( attachedGlyph ) then
            self.GlyphIcon:Show();
        else
            self.GlyphIcon:Hide();
        end
    else
        local level = Armory:GetSpellAvailableLevel(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec);
        iconTextureAlpha = .5;
        iconTextureDesaturated = true;
        self.GlyphIcon:Hide();
        if ( level and level > Armory:UnitLevel("player") or isDisabled ) then
            self.SeeTrainerString:Hide();

            local displayedLevel = isDisabled and Armory:GetSpellLevelLearned(slot, ArmorySpellBookFrame.spellBank, ArmorySpellBookFrame.selectedPetSpec) or level;
            if ( displayedLevel > 0 ) then
                self.RequiredLevelString:SetFormattedText(SPELLBOOK_AVAILABLE_AT, displayedLevel);
                self.RequiredLevelString:SetTextColor(0.25, 0.12, 0);
                self.RequiredLevelString:Show();
            end

            self.SpellName:SetTextColor(0.25, 0.12, 0);
        else
            self.SeeTrainerString:Show();
            self.RequiredLevelString:Hide();
            self.SpellName:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
         end
    end

    local isLevelLinkLocked = spellID and isLocked or false;
    levelLinkLockTexture:SetShown(isLevelLinkLocked);
    levelLinkLockBg:SetShown(isLevelLinkLocked);
    if ( isLevelLinkLocked ) then
        iconTexture:SetAlpha(1.0);
        iconTexture:SetDesaturated(true);
    else
        iconTexture:SetAlpha(iconTextureAlpha);
        iconTexture:SetDesaturated(iconTextureDesaturated);
    end

    self.EmptySlot:SetDesaturated(isOffSpec);
    self.FlyoutArrow:SetDesaturated(isOffSpec);
    if ( isOffSpec ) then
        iconTexture:SetDesaturated(isOffSpec);
        self.SpellName:SetTextColor(0.75, 0.75, 0.75);
        self.RequiredLevelString:SetTextColor(0.1, 0.1, 0.1);
    end
end

function ArmorySpellBookPrevPageButton_OnClick(self)
    local pageNum = ArmorySpellBook_GetCurrentPage() - 1;
    if ( ArmorySpellBookFrame.spellBank == BANK_PLAYER ) then
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] = pageNum;
    else
        ArmorySpellBookFrame:SetTitle(ArmorySpellBookFrame.petTitle);
        -- Need to change to pet book pageturn sound
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        SPELLBOOK_PAGENUMBERS["pet"][ArmorySpellBookFrame.selectedPetSkillLine] = pageNum;
    end
    ArmorySpellBook_UpdatePageArrows();
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, pageNum);
    ArmorySpellBook_UpdateSpells();
end

function ArmorySpellBookNextPageButton_OnClick(self)
    local pageNum = ArmorySpellBook_GetCurrentPage() + 1;
    if ( ArmorySpellBookFrame.spellBank == BANK_PLAYER ) then
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] = pageNum;
    else
        ArmorySpellBookFrame:SetTitle(ArmorySpellBookFrame.petTitle);
        -- Need to change to pet book pageturn sound
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        SPELLBOOK_PAGENUMBERS["pet"][ArmorySpellBookFrame.selectedPetSkillLine] = pageNum;
    end
    ArmorySpellBook_UpdatePageArrows();
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, pageNum);
    ArmorySpellBook_UpdateSpells();
end

function ArmorySpellBook_GetSpellBookSlot(spellButton)
    local id = spellButton:GetID();
    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        return id + (SPELLS_PER_PAGE * (SPELLBOOK_PAGENUMBERS["pet"][ArmorySpellBookFrame.selectedPetSkillLine] - 1));
    else
        local relativeSlot = id + ( SPELLS_PER_PAGE * (SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] - 1));
        if ( ArmorySpellBookFrame.selectedSkillLineNumSlots and relativeSlot <= ArmorySpellBookFrame.selectedSkillLineNumSlots ) then
            local slot = ArmorySpellBookFrame.selectedSkillLineOffset + relativeSlot;
            local slotType, slotID, attachedGlyph, isDisabled, isLocked = Armory:GetSpellBookItemInfo(slot, ArmorySpellBookFrame.spellBank);
            return slot, slotType, attachedGlyph, isDisabled, isLocked;
        else
            return nil, nil, nil, nil, nil;
        end
    end
end

function ArmorySpellBook_UpdatePageArrows()
    local currentPage, maxPages = ArmorySpellBook_GetCurrentPage();
    if ( currentPage == 1 ) then
        ArmorySpellBookPrevPageButton:Disable();
    else
        ArmorySpellBookPrevPageButton:Enable();
    end
    if ( maxPages == 0 or currentPage == maxPages ) then
        ArmorySpellBookNextPageButton:Disable();
    else
        ArmorySpellBookNextPageButton:Enable();
    end
end

function ArmorySpellBook_GetCurrentPage()
    local currentPage, maxPages;
    local numPetSpells = Armory:HasPetSpells(ArmorySpellBookFrame.selectedPetSpec);
    if ( numPetSpells and Armory:HasPetUI() and ArmorySpellBookFrame.spellBank == BANK_PET ) then
        currentPage = SPELLBOOK_PAGENUMBERS["pet"][ArmorySpellBookFrame.selectedPetSkillLine];
        maxPages = ceil(numPetSpells / SPELLS_PER_PAGE);
    elseif ( ArmorySpellBookFrame.spellBank ==  BANK_PLAYER) then
        currentPage = SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine];
        local name, texture, offset, numSpells = Armory:GetSpellTabInfo(ArmorySpellBookFrame.selectedSkillLine);
        if ( numSpells ) then
            maxPages = ceil(numSpells / SPELLS_PER_PAGE);
        else
            maxPages = 0;
        end
    else
        currentPage = 1;
        maxPages = 1;
    end
    return currentPage, maxPages;
end

function ArmorySpellBook_UpdateSpells()
    for i = 1, SPELLS_PER_PAGE do
       ArmorySpellButton_UpdateButton(_G["ArmorySpellButton"..i]);
    end
    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        ArmorySpellBook_DesaturateBackground(_G["ArmorySpellBookSkillLineTab"..ArmorySpellBookFrame.selectedPetSkillLine].isOffSpec);
    else
        ArmorySpellBook_DesaturateBackground(_G["ArmorySpellBookSkillLineTab"..ArmorySpellBookFrame.selectedSkillLine].isOffSpec);
    end
end

function ArmorySpellBook_DesaturateBackground(desaturate)
    ArmorySpellBookFrame.Page1:SetDesaturated(desaturate);
    ArmorySpellBookFrame.Page2:SetDesaturated(desaturate);
end

----------------------------------------------------------
-- Update functions for tabs
----------------------------------------------------------

function ArmorySpellBookFrame_UpdateSkillLineTabs()
    local numSkillLineTabs = Armory:GetNumSpellTabs(ArmorySpellBookFrame.spellBank);
    local name, texture, numSpells, isGuild, offSpecID;
    local skillLineTab, prevTab;
    local selectedTab;

    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        selectedTab = ArmorySpellBookFrame.selectedPetSkillLine;
    else
        selectedTab = ArmorySpellBookFrame.selectedSkillLine;
    end

    for i = 1, MAX_SKILLLINE_TABS do
        skillLineTab = _G["ArmorySpellBookSkillLineTab"..i];
        prevTab = _G["ArmorySpellBookSkillLineTab"..i-1];
        --if ( i <= numSkillLineTabs and ArmorySpellBookFrame.spellBank == BANK_PLAYER ) then
        if ( i <= numSkillLineTabs ) then
            name, texture, _, _, isGuild, offSpecID = Armory:GetSpellTabInfo(i, ArmorySpellBookFrame.spellBank);
            local isOffSpec = (offSpecID ~= 0);
            skillLineTab.tooltip = name;
            skillLineTab:Show();
            skillLineTab.isOffSpec = isOffSpec;
            if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
                skillLineTab.petSpec = isOffSpec and offSpecID or GetPetSpec();
            end
            if ( texture ) then
                skillLineTab:SetNormalTexture(texture);
                skillLineTab:GetNormalTexture():SetDesaturated(isOffSpec);
            else
                skillLineTab:ClearNormalTexture();
            end

            -- Guild tab gets additional space
            if ( prevTab ) then
                if ( isGuild ) then
                    skillLineTab:SetPoint("TOPLEFT", prevTab, "BOTTOMLEFT", 0, -46);
                elseif ( isOffSpec and not prevTab.isOffSpec ) then
                    skillLineTab:SetPoint("TOPLEFT", prevTab, "BOTTOMLEFT", 0, -40);
                else
                    skillLineTab:SetPoint("TOPLEFT", prevTab, "BOTTOMLEFT", 0, -17);
                end
            end

            -- Guild tab must show the Guild Banner
            if ( isGuild ) then
                skillLineTab:SetNormalTexture("Interface\\SpellBook\\GuildSpellbooktabBG");
                skillLineTab.TabardEmblem:Show();
                skillLineTab.TabardIconFrame:Show();
                Armory:SetLargeGuildTabardTextures("player", skillLineTab.TabardEmblem, skillLineTab:GetNormalTexture(), skillLineTab.TabardIconFrame);
            else
                skillLineTab.TabardEmblem:Hide();
                skillLineTab.TabardIconFrame:Hide();
            end

            -- Set the selected tab
            skillLineTab:SetChecked(selectedTab == i);
        else
            skillLineTab:Hide();
        end
    end
end

function ArmorySpellBookSkillLineTab_OnClick(self, id, spec)
    local selectedTab;
    if ( ArmorySpellBookFrame.spellBank == BANK_PET ) then
        ArmorySpellBookFrame.selectedPetSkillLine = id or self:GetID();
        selectedTab = ArmorySpellBookFrame.selectedPetSkillLine;

        if ( not spec ) then
            local skillLineTab = self or _G["ArmorySpellBookSkillLineTab"..selectedTab];
            ArmorySpellBookFrame.selectedPetSpec = skillLineTab.petSpec;
        end
    else
        ArmorySpellBookFrame.selectedSkillLine = id or self:GetID();
        selectedTab = ArmorySpellBookFrame.selectedSkillLine;

        local name, texture, offset, numSpells = Armory:GetSpellTabInfo(selectedTab);
        ArmorySpellBookFrame.selectedSkillLineOffset = offset;
        ArmorySpellBookFrame.selectedSkillLineNumSpells = numSpells;
    end
    ArmorySpellBook_UpdatePageArrows();
    ArmorySpellBookFrame_Update();
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, ArmorySpellBook_GetCurrentPage());
    ArmorySpellBook_UpdateSpells();
end

function ArmorySpellFlyout_Toggle(self, parent, slot, spellID, specID)
    if ( self:IsShown() and self:GetParent() == parent ) then
        self:Hide();
        return;
    end

    local offSpec = specID and (specID ~= 0);

    -- Save previous parent to update at the end
    local oldParent = self:GetParent();
    self:SetParent(parent);

    local numSlots = Armory:GetSpellFlyoutNumSlots(slot);

    -- Update all spell buttons for this flyout
    local prevButton = nil;
    local numButtons = 0;
    for i = 1, numSlots do
        local spellID, overrideSpellID, isKnown, spellName, slotSpecID = Armory:GetSpellFlyoutSlotInfo(slot, i);
        local visible = true;

        if ( ((not offSpec or slotSpecID == 0) and visible and isKnown) or (offSpec and slotSpecID == specID) ) then
            local button = _G["ArmorySpellFlyoutButton"..numButtons + 1];
            if ( not button ) then
                button = CreateFrame("CHECKBUTTON", "ArmorySpellFlyoutButton"..numButtons + 1, ArmorySpellFlyout, "ArmorySpellFlyoutButtonTemplate");
            end

            button:ClearAllPoints();
            if ( prevButton ) then
                button:SetPoint("LEFT", prevButton, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0);
            else
                button:SetPoint("LEFT", SPELLFLYOUT_INITIAL_SPACING, 0);
            end

            button:Show();

            _G[button:GetName().."Icon"]:SetTexture(C_Spell.GetSpellTexture(overrideSpellID));
            _G[button:GetName().."Icon"]:SetDesaturated(offSpec);
            button.offSpec = offSpec;
            button.spellID = spellID;
            button.spellName = spellName;
            if ( offSpec ) then
                button:Disable();
            else
                button:Enable();
            end

            prevButton = button;
            numButtons = numButtons + 1;
        end
    end

    -- Hide unused buttons
    local unusedButtonIndex = numButtons + 1;
    while ( _G["ArmorySpellFlyoutButton"..unusedButtonIndex] ) do
        _G["ArmorySpellFlyoutButton"..unusedButtonIndex]:Hide();
        unusedButtonIndex = unusedButtonIndex+1;
    end

    if ( numButtons == 0 ) then
        self:Hide();
        return;
    end

    -- Show the flyout
    self:SetFrameStrata("DIALOG");
    self:ClearAllPoints();

    self.Background.End:ClearAllPoints();
    self.Background.Start:ClearAllPoints();

    self:SetPoint("LEFT", parent, "RIGHT");
    self.Background.End:SetPoint("RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0);
    SetClampedTextureRotation(self.Background.End, 90);
    SetClampedTextureRotation(self.Background.HorizontalMiddle, 0);
    self.Background.Start:SetPoint("RIGHT", self.Background.HorizontalMiddle, "LEFT");
    SetClampedTextureRotation(self.Background.Start, 90);
    self.Background.VerticalMiddle:Hide();
    self.Background.HorizontalMiddle:Show();
    self.Background.HorizontalMiddle:ClearAllPoints();
    self.Background.HorizontalMiddle:SetPoint("RIGHT", self.Background.End, "LEFT");
    self.Background.HorizontalMiddle:SetPoint("LEFT", 1, 0);

    self:Layout();

    ArmorySpellFlyout_SetBorderColor(self, 0.7, 0.7, 0.7);
    ArmorySpellFlyout_SetBorderSize(self, 47);

    self:Show();
end

function ArmorySpellFlyout_SetBorderColor(self, r, g, b)
    self.Background.Start:SetVertexColor(r, g, b);
    self.Background.HorizontalMiddle:SetVertexColor(r, g, b);
    self.Background.VerticalMiddle:SetVertexColor(r, g, b);
    self.Background.End:SetVertexColor(r, g, b);
end

function ArmorySpellFlyout_SetBorderSize(self, size)
    self.Background.Start:SetHeight(size);
    self.Background.HorizontalMiddle:SetHeight(size);
    self.Background.VerticalMiddle:SetHeight(size);
    self.Background.End:SetHeight(size);
end

function ArmorySpellFlyoutButton_SetTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 4);
    if ( GameTooltip:SetSpellByID(self.spellID) ) then
        self.UpdateTooltip = ArmorySpellFlyoutButton_SetTooltip;
    else
        self.UpdateTooltip = nil;
    end
end
