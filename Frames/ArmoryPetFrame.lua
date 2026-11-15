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

local NUM_PET_SLOTS = 5;
local NUM_PET_ABILITIES = 6;

local PETPAPERDOLL_STATCATEGORY_DEFAULTORDER = {
    "GENERAL",
    "ATTACK",
    "SPELL",
    "DEFENSE",
};

local function BuildListString(...)
    local list = "";
    for i = 1, select("#", ...) do
        local item = select(i, ...);
        if ( item ) then
            list = (list == "" and item) or (list..", "..item);
        end
    end
    return list;
end

local STRIPE_COLOR = {r=0.9, g=0.9, b=1};
local STATCATEGORY_PADDING = 4;

function ArmoryPetSlot_OnClick(self, button)
    local pets = Armory:GetPets();
    if ( pets[self:GetID()] ) then
        for i = 1, NUM_PET_SLOTS do
            _G["ArmoryPetFramePet"..i]:SetChecked(false);
        end

        self:SetChecked(true);
        Armory.selectedPet = pets[self:GetID()];

        if ( button == "RightButton" ) then
            ArmoryStaticPopup_Show("ARMORY_DELETE_PET", Armory:GetCurrentPet());
        else
            ArmoryPetFrame_Update(1);
        end
    end
end

function ArmoryPetFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PET_UI_UPDATE");
    self:RegisterEvent("PET_BAR_UPDATE");
    self:RegisterEvent("PET_UI_CLOSE");
    self:RegisterUnitEvent("UNIT_PET", "player");
    self:RegisterEvent("UNIT_MODEL_CHANGED");
    self:RegisterEvent("UNIT_LEVEL");
    self:RegisterEvent("UNIT_RESISTANCES");
    self:RegisterEvent("UNIT_STATS");
    self:RegisterEvent("UNIT_DAMAGE");
    self:RegisterEvent("UNIT_RANGEDDAMAGE");
    self:RegisterEvent("UNIT_ATTACK_SPEED");
    self:RegisterEvent("UNIT_ATTACK_POWER");
    self:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
    self:RegisterEvent("UNIT_DEFENSE");
    self:RegisterEvent("UNIT_ATTACK");
    -- Forever has no PET_SPELL_POWER_UPDATE
    if ( C_EventUtils.IsEventValid("PET_SPELL_POWER_UPDATE") ) then
        self:RegisterEvent("PET_SPELL_POWER_UPDATE");
    end
    -- Forever has the happiness of Classic
    if ( Armory.isForever ) then
        self:RegisterUnitEvent("UNIT_HAPPINESS", "pet");
    end

    ArmoryPetFrame_InitStatCategories();

    self.page = 1;
end

function ArmoryPetFrame_OnEvent(self, event, ...)
    local arg1 = ...;

    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        local _, class = UnitClass("player");
        if ( class == "HUNTER" ) then
            ArmoryPetFrame_InitPets();
        end
        if ( HasPetUI() ) then
            Armory:ExecuteConditional(ArmoryPetFrame_HasPetData, ArmoryPetFrame_Update);
        end
    elseif ( event == "PET_UI_UPDATE" or event == "PET_BAR_UPDATE" or event == "UNIT_PET" ) then
        ArmoryFrameTab_Update();
        Armory:ExecuteConditional(ArmoryPetFrame_HasPetData, ArmoryPetFrame_Update);
    elseif ( event == "PET_UI_CLOSE" ) then
        ArmoryFrameTab_Update();
    elseif ( event == "UNIT_HAPPINESS" ) then
        Armory:Execute(ArmoryPetFrame_Update);
    elseif( event == "PET_SPELL_POWER_UPDATE" ) then
        Armory:Execute(ArmoryPetFrame_UpdateStats);
    elseif ( arg1 == "pet" ) then
        Armory:Execute(ArmoryPetFrame_UpdateStats);
    end
end

function ArmoryPetFrame_HasPetData()
    local stat, effectiveStat = UnitStat("pet", 3);
    return stat and effectiveStat;
end

function ArmoryPetFrame_OnShow(self)
    Armory.selectedPet = Armory:UnitName("pet");
    ArmoryFrameInset:SetPoint("TOPLEFT", ArmoryFrame, "TOPLEFT", 4, -70);
    ArmoryFrameInset:SetPoint("BOTTOMRIGHT", ArmoryFrame, "BOTTOMRIGHT", -6, 114);
    ArmoryPetFrame_Update();
end

function ArmoryPetFrame_OnHide(self)
    ArmoryFrameInset:SetPoint("TOPLEFT", ArmoryFrame, "TOPLEFT", 4, -60);
    ArmoryFrameInset:SetPoint("BOTTOMRIGHT", ArmoryFrame, "BOTTOMRIGHT", -6, 4);
end

function ArmoryPetFrame_InitPets()
    for i = 1, C_StableInfo.GetNumStablePets() do
        local petInfo = C_StableInfo.GetStablePetInfo(i);
        if ( petInfo and not Armory:PetExists(petInfo.name) ) then
            Armory:SetPetValue(petInfo.name, "Name", petInfo.name);
            Armory:SetPetValue(petInfo.name, "Icon", petInfo.icon);
            Armory:SetPetValue(petInfo.name, "Level", petInfo.level);
            Armory:SetPetValue(petInfo.name, "Family", petInfo.familyName);
            Armory:SetPetValue(petInfo.name, "FoodTypes", C_StableInfo.GetStablePetFoodTypes(i));
        end
    end
end

function ArmoryPetFrame_Update(petChanged)
    if ( (not Armory:PetsEnabled() or petChanged) and ArmorySpellBookFrame:IsShown() and ArmorySpellBookFrame.spellBank == Enum.SpellBookSpellBank.Pet ) then
        ArmorySpellBookFrame:Hide();
        ArmorySpellBookFrame:Show();
    end

    local currentPet = Armory:GetCurrentPet();
    if ( not Armory:PetsEnabled() or (currentPet == UNKNOWN and not Armory:HasPetUI()) ) then
        ArmoryFrameTab_Update();
        return;
    end

    local pets = Armory:GetPets();
    ArmoryPetFrame.maxPages = ceil(#pets / NUM_PET_SLOTS);

    local button, background, icon, index;
    for i = 1, NUM_PET_SLOTS do
        button = _G["ArmoryPetFramePet"..i];
        background = _G["ArmoryPetFramePet"..i.."Background"];
        index = (ArmoryPetFrame.page - 1) * NUM_PET_SLOTS + i;
        button:SetID(index);
        if ( index <= #pets ) then
            Armory.selectedPet = pets[index];
            button.PetName:SetText(Armory:GetPetRealName());
            background:SetVertexColor(1.0, 1.0, 1.0);
            button:Enable();
            icon = Armory:GetPetIcon();
            SetItemButtonTexture(button, icon);
            if ( icon ) then
                button.tooltip = button.PetName:GetText();
                button.tooltipSubtext = format(UNIT_TYPE_LEVEL_TEMPLATE, Armory:UnitEffectiveLevel("pet"), Armory:UnitCreatureFamily("pet"));
                button.hint = ARMORY_DELETE_UNIT_HINT;
            else
                button.tooltip = nil;
                button.tooltipSubtext = "";
                button.hint = nil;
            end
            button:SetChecked(Armory.selectedPet == currentPet and icon);
        else
            button.PetName:SetText("");
            SetItemButtonTexture(button, "");
            background:SetVertexColor(1.0,0.1,0.1);
            button:SetChecked(false);
            button:Disable();
        end
    end
    Armory.selectedPet = currentPet;
    ArmoryPetFrame.selectedPet = currentPet;

    local _, canGainXP = Armory:HasPetUI();
    local foodTypes = Armory:GetPetFoodTypes();
    if ( Armory.isForever and canGainXP and ArmoryPetFrame_SetHappiness(foodTypes) ) then
        ArmoryPetFrameDiet:Show();
    elseif ( canGainXP and Armory:GetPetFoodTypes() ) then
        if ( Armory.isForever ) then
            ArmoryPetFrame_SetDietIcon();
        end
        ArmoryPetFrameDiet.tooltip = format(PET_DIET_TEMPLATE, BuildListString(unpack(type(foodTypes) == "table" and foodTypes or {foodTypes})));
        ArmoryPetFrameDiet:Show();
    else
        ArmoryPetFrameDiet:Hide();
    end

    ArmoryPetFrame_SetSelectedPetInfo();
    ArmoryPetFrame_UpdateSpec();
    ArmoryPetFrame_UpdateStats();

    -- Select correct page
    if ( ArmoryPetFrame.page == 1 ) then
        ArmoryPetFramePrevPageButton:Disable();
    else
        ArmoryPetFramePrevPageButton:Enable();
    end
    if ( ArmoryPetFrame.maxPages == 0 or ArmoryPetFrame.page == ArmoryPetFrame.maxPages ) then
        ArmoryPetFrameNextPageButton:Disable();
    else
        ArmoryPetFrameNextPageButton:Enable();
    end
    ArmoryPetFrameCurrentPage:SetFormattedText(MERCHANT_PAGE_NUMBER, ArmoryPetFrame.page, ArmoryPetFrame.maxPages);
end

-- Forever: the diet icon shows the happiness instead, with the loyalty and the diet in its tooltip,
-- as Blizzard's PetHappinessIndicatorMixin (PetHappiness.lua) does
local PET_HAPPINESS_ATLAS = { "UI-PetMad", "UI-PetNeutral", "UI-PetHappiness" };

function ArmoryPetFrame_SetHappiness(foodTypes)
    local happiness, damagePercentage, loyaltyRate = Armory:GetPetHappiness();
    local atlas = happiness and PET_HAPPINESS_ATLAS[happiness];
    if ( not atlas ) then
        return false;
    end

    ArmoryPetFrameDietTexture:SetAtlas(atlas);

    local lines = {};
    local loyalty = Armory:GetPetLoyalty();
    if ( loyalty and loyalty ~= "" ) then
        table.insert(lines, loyalty);
    end
    if ( damagePercentage ) then
        table.insert(lines, format(PET_DAMAGE_PERCENTAGE, damagePercentage));
    end
    if ( (loyaltyRate or 0) < 0 ) then
        table.insert(lines, LOSING_LOYALTY);
    elseif ( (loyaltyRate or 0) > 0 ) then
        table.insert(lines, GAINING_LOYALTY);
    end
    if ( foodTypes ) then
        table.insert(lines, format(PET_DIET_TEMPLATE, BuildListString(unpack(type(foodTypes) == "table" and foodTypes or {foodTypes}))));
    end

    ArmoryPetFrameDiet.tooltip = _G["PET_HAPPINESS"..happiness] or NONE;
    ArmoryPetFrameDiet.tooltipLines = lines;
    return true;
end

-- Forever: back to the diet icon of the XML when the happiness is not known
function ArmoryPetFrame_SetDietIcon()
    ArmoryPetFrameDietTexture:SetTexture("Interface\\PetStableFrame\\PetStable-Parts");
    ArmoryPetFrameDietTexture:SetTexCoord(0.08593750, 0.13476563, 0.73437500, 0.77929688);
    ArmoryPetFrameDiet.tooltipLines = nil;
end

function ArmoryPetFrameDiet_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(self.tooltip);
    if ( self.tooltipLines ) then
        for _, line in ipairs(self.tooltipLines) do
            GameTooltip:AddLine(line, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        end
        GameTooltip:Show();
    end
end

function ArmoryPetFrame_SetSelectedPetInfo()
    local icon = Armory:GetPetIcon();
    local name = Armory.selectedPet;
    local level = Armory:UnitLevel("pet");
    local family = Armory:UnitCreatureFamily("pet");

    if ( family ) then
        ArmoryPetFrameTypeText:SetText(family);
    else
        ArmoryPetFrameTypeText:SetText("");
    end

    if ( level ) then
        ArmoryPetFrameLevelText:SetFormattedText(UNIT_LEVEL_TEMPLATE, level);
    else
        ArmoryPetFrameLevelText:SetText("");
    end

    if ( name ) then
        ArmoryPetFrameNameText:SetText(Armory:GetPetRealName());
    else
        ArmoryPetFrameNameText:SetText("");
    end

    ArmoryPetFrameSelectedPetIcon:SetTexture(icon);
end

function ArmoryPetFrame_NextPage()
    local page = ArmoryPetFrame.page + 1;
    if ( page ~= ArmoryPetFrame.page and page > 0 and page <= ArmoryPetFrame.maxPages ) then
        ArmoryPetFrame.page = page;
        ArmoryPetFrame_Update(false);
    end
end

function ArmoryPetFrame_PrevPage()
    local page = ArmoryPetFrame.page - 1;
    if ( page ~= ArmoryPetFrame.page and page > 0 and page <= ArmoryPetFrame.maxPages ) then
        ArmoryPetFrame.page = page;
        ArmoryPetFrame_Update(false);
    end
end


----------------------------------------------------------
-- Stats Functions
----------------------------------------------------------

local StatCategoryFrames = {};

function ArmoryPetFrame_InitStatCategories()
    local order = PETPAPERDOLL_STATCATEGORY_DEFAULTORDER;

    -- Initialize stat frames
    table.wipe(StatCategoryFrames);
    for index=1, #order do
        local frame = _G["ArmoryPetStatsPaneCategory"..index];
        assert(frame);
        table.insert(StatCategoryFrames, frame);
        frame.Category = order[index];
        frame:Show();

        ArmoryPetFrame_ExpandStatCategory(frame);
    end

    -- Hide unused stat frames
    local index = #order + 1;
    while ( _G["ArmoryPetStatsPaneCategory"..index] ) do
        _G["ArmoryPetStatsPaneCategory"..index]:Hide();
        _G["ArmoryPetStatsPaneCategory"..index].Category = nil;
        index = index + 1;
    end

    ArmoryPetFrame_UpdateCategoryPositions();
end

function ArmoryPetFrame_UpdateCategoryPositions()
    local prevFrame = nil;
    for index = 1, #StatCategoryFrames do
        local frame = StatCategoryFrames[index];
        frame:ClearAllPoints();
    end

    for index = 1, #StatCategoryFrames do
        local frame = StatCategoryFrames[index];
        if (prevFrame) then
            frame:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", 0, -STATCATEGORY_PADDING);
        else
            frame:SetPoint("TOPLEFT", 1, -STATCATEGORY_PADDING);
        end
        prevFrame = frame;
    end
end

function ArmoryPetFrame_CollapseStatCategory(categoryFrame)
    if ( not categoryFrame.collapsed ) then
        categoryFrame.collapsed = true;
        local index = 1;
        while (_G[categoryFrame:GetName().."Stat"..index]) do
            _G[categoryFrame:GetName().."Stat"..index]:Hide();
            index = index + 1;
        end
        categoryFrame.CollapsedIcon:Show();
        categoryFrame.ExpandedIcon:Hide();
        categoryFrame:SetHeight(18);
        categoryFrame.BgMinimized:Show();
        categoryFrame.BgTop:Hide();
        categoryFrame.BgMiddle:Hide();
        categoryFrame.BgBottom:Hide();
    end
end

function ArmoryPetFrame_ExpandStatCategory(categoryFrame)
    if ( categoryFrame.collapsed ) then
        categoryFrame.collapsed = false;
        categoryFrame.CollapsedIcon:Hide();
        categoryFrame.ExpandedIcon:Show();
        ArmoryPetFrame_UpdateStatCategory(categoryFrame);
        categoryFrame.BgMinimized:Hide();
        categoryFrame.BgTop:Show();
        categoryFrame.BgMiddle:Show();
        categoryFrame.BgBottom:Show();
    end
end

function ArmoryPetFrame_UpdateStatCategory(categoryFrame)
    if ( not categoryFrame.Category ) then
        categoryFrame:Hide();
        return;
    end

    local categoryInfo = ARMORY_PAPERDOLL_STATCATEGORIES[categoryFrame.Category];

    categoryFrame.NameText:SetText(_G["STAT_CATEGORY_"..categoryFrame.Category]);

    if ( categoryFrame.collapsed ) then
        return;
    end

    local stat;
    local totalHeight = categoryFrame.NameText:GetHeight() + 10;
    local numVisible = 0;
    if ( categoryInfo ) then
        local prevStatFrame = nil;
        for index, stat in next, categoryInfo.stats do
            local statInfo = ARMORY_PAPERDOLL_STATINFO[stat];
            if ( statInfo ) then
                local statFrame = _G[categoryFrame:GetName().."Stat"..numVisible + 1];
                if ( not statFrame ) then
                    statFrame = CreateFrame("Frame", categoryFrame:GetName().."Stat"..numVisible + 1, categoryFrame, "ArmoryStatTemplate");
                    if ( prevStatFrame ) then
                        statFrame:SetPoint("TOPLEFT", prevStatFrame, "BOTTOMLEFT", 0, 0);
                        statFrame:SetPoint("TOPRIGHT", prevStatFrame, "BOTTOMRIGHT", 0, 0);
                    end
                end
                statFrame:Show();
                -- Reset tooltip script in case it's been changed
                statFrame:SetScript("OnEnter", PaperDollStatTooltip);
                statFrame.tooltip = nil;
                statFrame.tooltip2 = nil;
                statFrame.UpdateTooltip = nil;
                statFrame:SetScript("OnUpdate", nil);
                statInfo.updateFunc(statFrame, "pet");
                if ( statFrame:IsShown() ) then
                    numVisible = numVisible + 1;
                    totalHeight = totalHeight + statFrame:GetHeight();
                    prevStatFrame = statFrame;
                    -- Update Tooltip
                    if ( GameTooltip:GetOwner() == statFrame ) then
                        statFrame:GetScript("OnEnter")(statFrame);
                    end
                end
            end
        end
    end

    local i;
    for index = 1, numVisible do
        if ( index % 2 == 0 ) then
            local statFrame = _G[categoryFrame:GetName().."Stat"..index];
            if ( not statFrame.Bg ) then
                statFrame.Bg = statFrame:CreateTexture(statFrame:GetName().."Bg", "BACKGROUND");
                statFrame.Bg:SetPoint("LEFT", categoryFrame, "LEFT", 1, 0);
                statFrame.Bg:SetPoint("RIGHT", categoryFrame, "RIGHT", 0, 0);
                statFrame.Bg:SetPoint("TOP");
                statFrame.Bg:SetPoint("BOTTOM");
                statFrame.Bg:SetTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b);
                statFrame.Bg:SetAlpha(0.1);
            end
        end
    end

    -- Hide all other stats
    local index = numVisible + 1;
    while (_G[categoryFrame:GetName().."Stat"..index]) do
        _G[categoryFrame:GetName().."Stat"..index]:Hide();
        index = index + 1;
    end

    -- Hack to fix category frames that only have 1 item in them
    if ( totalHeight < 44 ) then
        categoryFrame.BgBottom:SetHeight(totalHeight - 2);
    else
        categoryFrame.BgBottom:SetHeight(46);
    end

    categoryFrame:SetHeight(totalHeight);
end

function ArmoryPetFrame_UpdateStats()
    local index = 1;
    while( _G["ArmoryPetStatsPaneCategory"..index] ) do
        ArmoryPetFrame_UpdateStatCategory(_G["ArmoryPetStatsPaneCategory"..index]);
        index = index + 1;
    end
    ArmoryBuffFrame_Update("pet");

    if ( Armory:UnitHealthMax("pet") ) then
        ArmoryPetFrameWarning:Hide();
        ArmoryPetStatsPane:Show();
    else
        ArmoryPetFrameWarning:Show();
        ArmoryPetStatsPane:Hide();
    end
end


----------------------------------------------------------
-- Specialization Functions
----------------------------------------------------------

function ArmoryPetFrame_UpdateSpec()
    ArmoryPetSpecFrame:Hide();
    local spec = Armory:GetSpecialization(false, true);
    if ( spec ) then
        local _, name, description, icon = Armory:GetSpecializationInfo(spec, false, true, nil, Armory:UnitSex("pet"));
        if ( name ) then
            Armory:SetPortraitToTexture(ArmoryPetSpecFrame.specIcon, icon);
            ArmoryPetSpecFrame.specName:SetText(name);
            local role = Armory:GetSpecializationRole(spec, false, true);
            ArmoryPetSpecFrame.roleIcon:SetTexCoord(Armory:GetTexCoordsForRole(role));
            ArmoryPetSpecFrame.roleName:SetText(_G[role]);
            local spells = Armory:GetPetSpecializationSpells(spec);
            if ( spells ) then
                for i = 1, NUM_PET_ABILITIES do
                    local button = _G["ArmoryPetAbility"..i];
                    if ( i <= #spells ) then
                        local _, icon = C_Spell.GetSpellTexture(spells[i]);
                        Armory:SetPortraitToTexture(button.icon, icon);
                        button.spellID = spells[i];
                        button.extraTooltip = nil;
                        local level = C_Spell.GetSpellLevelLearned(spells[i]);
                        if ( level and level > Armory:UnitLevel("player") ) then
                            button.extraTooltip =  format(SPELLBOOK_AVAILABLE_AT, level);
                        end
                        button:Show();
                    else
                        button.spellID = nil;
                        button:Hide();
                    end
                end
                ArmoryPetSpecFrame:Show();
            end
        end
    end
end