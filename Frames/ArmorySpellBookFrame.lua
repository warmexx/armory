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

local Armory, _ = Armory;

ARMORY_SPELLBOOK_PAGENUMBERS = {};
ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET] = {};

function ArmoryToggleSpellBook(bookType)
    if ( bookType == BOOKTYPE_PET and (not Armory:PetsEnabled() or not Armory:HasPetSpells() or not Armory:PetHasSpellbook()) ) then
	    return;
    end

    local isShown = ArmorySpellBookFrame:IsShown();
    if ( isShown ) then
        ArmorySpellBookFrame.suppressCloseSound = true;
    end
    
    HideUIPanel(ArmorySpellBookFrame);
    if ( (not isShown or (ArmorySpellBookFrame.bookType ~= bookType)) ) then
        ArmorySpellBookFrame.bookType = bookType;
        ArmoryCloseChildWindows();
        ShowUIPanel(ArmorySpellBookFrame);
    end
    ArmorySpellBookFrame_UpdatePages();
    
    ArmorySpellBookFrame.suppressCloseSound = nil;
end

function ArmorySpellBookFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("SPELLS_CHANGED");
    self:RegisterEvent("LEARNED_SPELL_IN_TAB");
    self:RegisterEvent("PET_BAR_UPDATE");
    self:RegisterEvent("TRADE_SKILL_CLOSE");

    self.bookType = BOOKTYPE_SPELL;
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
    -- Init page nums
    ARMORY_SPELLBOOK_PAGENUMBERS[1] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[2] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[3] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[4] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[5] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[6] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[7] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[8] = 1;
    ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET] = 1;

    -- Set to the class tab by default
    ArmorySpellBookFrame.selectedSkillLine = 2;

    ArmorySpellBookFrame_PlayOpenSound();
    ArmorySpellBookFrame_Update(true);
end

function ArmorySpellBookFrame_Update(showing)
    local hasPetSpells, petToken;
    if ( Armory:PetsEnabled() ) then
        hasPetSpells, petToken = Armory:HasPetSpells();
        hasPetSpells = hasPetSpells and Armory:PetHasSpellbook();
    end
    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_PET and not hasPetSpells ) then
        ArmorySpellBookFrame.bookType = BOOKTYPE_SPELL;
    end

    -- Hide all tabs
    ArmorySpellBookFrameTabButton1:Hide();
    ArmorySpellBookFrameTabButton2:Hide();
    ArmorySpellBookFrameTabButton3:Hide();

    -- Setup skillline tabs
    if ( showing ) then
        ArmorySpellBookSkillLineTab_OnClick(nil, ArmorySpellBookFrame.selectedSkillLine);
    end

    ArmorySpellBookFrame_UpdateSkillLineTabs();
    
    -- Setup tabs
    ArmorySpellBookFrame.petTitle = nil;
    if ( hasPetSpells ) then
        ArmorySpellBookFrame_SetTabType(ArmorySpellBookFrameTabButton1, BOOKTYPE_SPELL);
        ArmorySpellBookFrame_SetTabType(ArmorySpellBookFrameTabButton2, BOOKTYPE_PET, petToken);
    else
        ArmorySpellBookFrame_SetTabType(ArmorySpellBookFrameTabButton1, BOOKTYPE_SPELL);
        if ( ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
            -- if has no pet spells but trying to show the pet spellbook close the window;
            HideUIPanel(ArmorySpellBookFrame);
            ArmorySpellBookFrame.bookType = BOOKTYPE_SPELL;
        end
    end
    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
        ArmorySpellBookTitleText:SetText(ArmorySpellBookFrame.petTitle);
        ArmorySpellBookFrame_SetSelectedPetInfo();
        ArmorySpellBookPetInfo:Show();
        ArmorySpellBookFrame_ShowSpells();
        ArmorySpellBookFrame_UpdatePages();
    else
        ArmorySpellBookTitleText:SetText(SPELLBOOK);
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
        if ( ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
            ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET] = maxPages;
        else
            ARMORY_SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] = maxPages;
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

function ArmorySpellBookFrame_SetTabType(tabButton, bookType, token)
    if ( bookType == BOOKTYPE_PET ) then
        tabButton.bookType = BOOKTYPE_PET;
        tabButton:SetText(_G["PET_TYPE_"..token]);
        ArmorySpellBookFrame.petTitle = _G["PET_TYPE_"..token];
    else
        tabButton.bookType = BOOKTYPE_SPELL;
        tabButton:SetText(SPELLBOOK);
    end
    if ( ArmorySpellBookFrame.bookType == bookType ) then
        tabButton:Disable();
    else
        tabButton:Enable();
    end
    tabButton:Show();
end

function ArmorySpellBookFrame_PlayOpenSound()
    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
        -- Need to change to pet book open sound
        PlaySound(SOUNDKIT.IG_ABILITY_OPEN);
    else
        PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN);
    end
end

function ArmorySpellBookFrame_PlayCloseSound()
    if ( not ArmorySpellBookFrame.suppressCloseSound ) then
        if ( ArmorySpellBookFrame.bookType == BOOKTYPE_SPELL ) then
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
    if ( slot and Armory:SetSpell(slot, ArmorySpellBookFrame.bookType) ) then
        self.UpdateTooltip = ArmorySpellButton_OnEnter;
    else
        self.UpdateTooltip = nil;
    end
end

function ArmorySpellButton_UpdateButton(self)
    local texture, offset, numSlots, isGuild, offSpecID;

    if ( not ArmorySpellBookFrame.selectedSkillLine ) then
        ArmorySpellBookFrame.selectedSkillLine = 2;
    end
    _, texture, offset, numSlots, isGuild, offSpecID = Armory:GetSpellTabInfo(ArmorySpellBookFrame.selectedSkillLine);

    ArmorySpellBookFrame.selectedSkillLineNumSlots = numSlots;
    ArmorySpellBookFrame.selectedSkillLineOffset = offset;
	local isOffSpec = (offSpecID ~= 0) and (ArmorySpellBookFrame.bookType == BOOKTYPE_SPELL);
    local slot = ArmorySpellBook_GetSpellBookSlot(self);
    local name = self:GetName();
    local iconTexture = _G[name.."IconTexture"];
    local spellString = _G[name.."SpellName"];
    local subSpellString = _G[name.."SubSpellName"];
    local autoCastableTexture = _G[name.."AutoCastable"];

    if ( (ArmorySpellBookFrame.bookType ~= BOOKTYPE_PET) and not slot ) then
        self:Disable();
        iconTexture:Hide();
        spellString:Hide();
        subSpellString:Hide();
        autoCastableTexture:Hide();
        _G[name.."NormalTexture"]:SetVertexColor(1.0, 1.0, 1.0);
        return;
    else
        self:Enable();
    end
    local texture = Armory:GetSpellBookItemTexture(slot, ArmorySpellBookFrame.bookType);
    local normalTexture = _G[name.."NormalTexture"];

    -- If no spell, hide everything and return
    if ( not texture or (strlen(texture) == 0) ) then
        iconTexture:Hide();
        spellString:Hide();
        subSpellString:Hide();
        autoCastableTexture:Hide();
        normalTexture:SetVertexColor(1.0, 1.0, 1.0);
        return;
    end
    local spellLink, tradeSkillLink = Armory:GetSpellLink(slot, ArmorySpellBookFrame.bookType);
    if ( tradeSkillLink ) then
        self.link = tradeSkillLink;
    else
        self.link = spellLink;
    end

    local autoCastAllowed = Armory:GetSpellAutocast(slot, ArmorySpellBookFrame.bookType);
    if ( autoCastAllowed ) then
        autoCastableTexture:Show();
    else
        autoCastableTexture:Hide();
    end

    local spellName, subSpellName = Armory:GetSpellBookItemName(slot, ArmorySpellBookFrame.bookType);
    local isPassive = Armory:IsPassiveSpell(slot, ArmorySpellBookFrame.bookType);
    if ( isPassive ) then
        normalTexture:SetVertexColor(0, 0, 0);
        spellString:SetTextColor(PASSIVE_SPELL_FONT_COLOR.r, PASSIVE_SPELL_FONT_COLOR.g, PASSIVE_SPELL_FONT_COLOR.b);
    else
        normalTexture:SetVertexColor(1.0, 1.0, 1.0);
        spellString:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
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
end

function ArmorySpellBookPrevPageButton_OnClick(self)
    local pageNum = ArmorySpellBook_GetCurrentPage() - 1;
    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_SPELL ) then
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        ARMORY_SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] = pageNum;
    else
        ArmorySpellBookTitleText:SetText(ArmorySpellBookFrame.petTitle);
        -- Need to change to pet book pageturn sound
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET] = pageNum;
    end
    ArmorySpellBook_UpdatePageArrows();
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, pageNum);
    ArmorySpellBook_UpdateSpells();
end

function ArmorySpellBookNextPageButton_OnClick(self)
    local pageNum = ArmorySpellBook_GetCurrentPage() + 1;
    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_SPELL ) then
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        ARMORY_SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] = pageNum;
    else
        ArmorySpellBookTitleText:SetText(ArmorySpellBookFrame.petTitle);
        -- Need to change to pet book pageturn sound
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);
        ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET] = pageNum;
    end
    ArmorySpellBook_UpdatePageArrows();
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, pageNum);
    ArmorySpellBook_UpdateSpells();
end

function ArmorySpellBook_GetSpellBookSlot(spellButton)
    local id = spellButton:GetID();
    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
        return id + (SPELLS_PER_PAGE * (ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET] - 1));
    else
        local relativeSlot = id + ( SPELLS_PER_PAGE * (ARMORY_SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine] - 1));
        if ( ArmorySpellBookFrame.selectedSkillLineNumSlots and relativeSlot <= ArmorySpellBookFrame.selectedSkillLineNumSlots ) then
            local slot = ArmorySpellBookFrame.selectedSkillLineOffset + relativeSlot;
            return slot;
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
    local numPetSpells = Armory:HasPetSpells();
    if ( numPetSpells and Armory:HasPetUI() and ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
        currentPage = ARMORY_SPELLBOOK_PAGENUMBERS[BOOKTYPE_PET];
        maxPages = ceil(numPetSpells / SPELLS_PER_PAGE);
    elseif ( ArmorySpellBookFrame.bookType ==  BOOKTYPE_SPELL) then
        currentPage = ARMORY_SPELLBOOK_PAGENUMBERS[ArmorySpellBookFrame.selectedSkillLine];
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
    ArmorySpellBook_DesaturateBackground(_G["ArmorySpellBookSkillLineTab"..ArmorySpellBookFrame.selectedSkillLine].isOffSpec);
end

function ArmorySpellBook_DesaturateBackground(desaturate)
    ArmorySpellBookFrameTopLeft:SetDesaturated(desaturate);
    ArmorySpellBookFrameTopRight:SetDesaturated(desaturate);
    ArmorySpellBookFrameBotLeft:SetDesaturated(desaturate);
    ArmorySpellBookFrameBotRight:SetDesaturated(desaturate);
end

----------------------------------------------------------
-- Update functions for tabs
----------------------------------------------------------

function ArmorySpellBookFrame_UpdateSkillLineTabs()
    local numSkillLineTabs = Armory:GetNumSpellTabs();
    local name, texture, numSpells, isGuild;
    local skillLineTab, prevTab;
    local selectedTab = ArmorySpellBookFrame.selectedSkillLine;

    for i = 1, MAX_SKILLLINE_TABS do
        skillLineTab = _G["ArmorySpellBookSkillLineTab"..i];
        prevTab = _G["ArmorySpellBookSkillLineTab"..i-1];
        if ( i <= numSkillLineTabs and ArmorySpellBookFrame.bookType == BOOKTYPE_SPELL ) then
            name, texture, _, _, isGuild, offSpecID = Armory:GetSpellTabInfo(i, ArmorySpellBookFrame.bookType);
   			local isOffSpec = (offSpecID ~= 0);
            skillLineTab:SetNormalTexture(texture);
            skillLineTab.tooltip = name;
            skillLineTab:Show();
			skillLineTab.isOffSpec = isOffSpec;
			if ( texture ) then
				skillLineTab:GetNormalTexture():SetDesaturated(isOffSpec);
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

            -- Set the selected tab
            skillLineTab:SetChecked(selectedTab == i);
        else
            skillLineTab:Hide();
        end
    end
end

function ArmorySpellBookSkillLineTab_OnClick(self, id)
    ArmorySpellBookFrame.selectedSkillLine = id or self:GetID();

    if ( ArmorySpellBookFrame.bookType == BOOKTYPE_SPELL ) then
        local name, texture, offset, numSpells = Armory:GetSpellTabInfo(ArmorySpellBookFrame.selectedSkillLine);
        ArmorySpellBookFrame.selectedSkillLineOffset = offset;
        ArmorySpellBookFrame.selectedSkillLineNumSpells = numSpells;
    end

    ArmorySpellBook_UpdatePageArrows();
    ArmorySpellBookFrame_Update();
    ArmorySpellBookPageText:SetFormattedText(PAGE_NUMBER, ArmorySpellBook_GetCurrentPage());
    ArmorySpellBook_UpdateSpells();
end
