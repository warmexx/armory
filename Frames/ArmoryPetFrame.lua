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

ARMORY_NUM_PET_SLOTS = 4;

function ArmoryPetSlot_OnClick(self, button)
    local pets = Armory:GetPets();
    if ( pets[self:GetID()] ) then
        for i = 1, ARMORY_NUM_PET_SLOTS do
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
    self:RegisterEvent("UNIT_PET");
    self:RegisterEvent("UNIT_PET_EXPERIENCE");
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
    self:RegisterEvent("UNIT_PET_TRAINING_POINTS");
    self:RegisterEvent("UNIT_HAPPINESS");
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
    elseif ( event == "UNIT_PET_EXPERIENCE" ) then
        Armory:Execute(ArmoryPetFrame_SetLevel);
    elseif ( event == "UNIT_HAPPINESS" ) then
        Armory:Execute(ArmoryPetFrame_SetHappiness);
    elseif ( event == "UNIT_PET_TRAINING_POINTS" ) then
        Armory:Execute(ArmoryPetFrame_UpdateStats);
    elseif ( arg1 == "pet" ) then
        Armory:Execute(ArmoryPetFrame_UpdateStats);
    end
end

function ArmoryPetFrame_HasPetData()
    for i = 1, NUM_PET_STATS do
        local stat, effectiveStat = UnitStat("pet", i);
        if ( not (stat and effectiveStat) ) then
            return false;
        end
    end
    return GetCritChanceFromAgility("pet") and GetUnitHealthModifier("pet") and GetUnitPowerModifier("pet") and GetUnitHealthRegenRateFromSpirit("pet");
end

function ArmoryPetFrame_OnShow(self)
    self.TitleText:SetText(Armory:UnitPVPName("player"));
    Armory.selectedPet = Armory:UnitName("pet");
    ArmoryPetFrame_Update();
end

function ArmoryPetFrame_OnHide(self)
    ArmoryFrameInset:SetPoint("TOPLEFT", ArmoryFrame, "TOPLEFT", 4, -60);
    ArmoryFrameInset:SetPoint("BOTTOMRIGHT", ArmoryFrame, "BOTTOMRIGHT", -6, 4);
end

function ArmoryPetFrame_InitPets()
    for i = 1, NUM_PET_STABLE_SLOTS do
        local icon, name, level, family, loyalty = GetStablePetInfo(i);
        if ( name and not Armory:PetExists(name) ) then
            Armory:SetPetValue(name, "Name", name);
            Armory:SetPetValue(name, "Icon", icon);
            Armory:SetPetValue(name, "Level", level);
            Armory:SetPetValue(name, "Family", family);
            Armory:SetPetValue(name, "Loyalty", loyalty);
            Armory:SetPetValue(name, "FoodTypes", GetStablePetFoodTypes(i));
        end
    end
end

function ArmoryPetFrame_Update(petChanged)
    if ( (not Armory:PetsEnabled() or petChanged) and ArmorySpellBookFrame:IsShown() and ArmorySpellBookFrame.bookType == BOOKTYPE_PET ) then
        ArmorySpellBookFrame:Hide();
        ArmorySpellBookFrame:Show();
    end

    local currentPet = Armory:GetCurrentPet();
    if ( not Armory:PetsEnabled() or (currentPet == UNKNOWN and not Armory:HasPetUI()) ) then
        ArmoryFrameTab_Update();
        return;
    end

    local setButton = function(button, pet)
        if ( pet ) then
            button.PetName:SetText(Armory:GetPetRealName());
            button.Background:SetVertexColor(1.0, 1.0, 1.0);
            button:Enable();
            button:SetChecked(pet == currentPet);
            local icon = Armory:GetPetIcon();
            SetItemButtonTexture(button, icon);
            if ( icon ) then
                button.tooltip = button.PetName:GetText();
                button.tooltipSubtext = format(UNIT_LEVEL_TEMPLATE, Armory:UnitLevel("pet"), Armory:UnitCreatureFamily("pet"));
                button.hint = ARMORY_DELETE_UNIT_HINT;
            else
                button.tooltip = nil;
                button.tooltipSubtext = "";
                button.hint = nil;
            end
        else
            button.PetName:SetText("");
            SetItemButtonTexture(button, "");
            button.Background:SetVertexColor(1.0, 0.1, 0.1);
            button:Disable();
            button:SetChecked(false);
        end
    end

    local pets = Armory:GetPets();
    for i = 1, ARMORY_NUM_PET_SLOTS do
        local button = _G["ArmoryPetFramePet"..i];
        if ( i <= #pets ) then
            Armory.selectedPet = pets[i];
            button:SetID(i);
            setButton(button, Armory.selectedPet);
        else
            setButton(button, nil);
        end
    end
    Armory.selectedPet = currentPet;
    ArmoryPetFrame.selectedPet = currentPet;

    ArmoryPetFrame_SetSelectedPetInfo();
    ArmoryPetFrame_UpdateStats();

    ArmoryBuffFrame_Update("pet");

    if ( Armory:UnitHealthMax("pet") ) then
        ArmoryPetFrameWarning:Hide();
        ArmoryPetFramePetInfo:Show();
        ArmoryPetAttributesFrame:Show();
        ArmoryPetResistanceFrame:Show();
    else
        ArmoryPetFrameWarning:Show();
        ArmoryPetFramePetInfo:Hide();
        ArmoryPetAttributesFrame:Hide();
        ArmoryPetResistanceFrame:Hide();
    end
end

function ArmoryPetFrame_SetSelectedPetInfo()
    ArmoryPetFrame_SetLevel();
    ArmoryPetFrame_SetHappiness();
    ArmoryPetFrameLoyaltyText:SetText(Armory:GetPetLoyalty());

    local _, canGainXP = Armory:HasPetUI();
    if ( canGainXP ) then
        local totalPoints, spent = Armory:GetPetTrainingPoints();
        if ( totalPoints ) then
            ArmoryPetFrameTrainingPointText:SetText(totalPoints - spent);
            ArmoryPetFrameTrainingPointText:Show();
            ArmoryPetFrameTrainingPointLabel:Show();
        else
            ArmoryPetFrameTrainingPointText:Hide();
            ArmoryPetFrameTrainingPointLabel:Hide();
        end
    else
        ArmoryPetFrameTrainingPointText:Hide();
        ArmoryPetFrameTrainingPointLabel:Hide();
    end
end


----------------------------------------------------------
-- Stats Functions
----------------------------------------------------------

function ArmoryPetFrame_SetLevel()
    local currXP, nextXP = Armory:GetPetExperience();
    local text = Armory.selectedPet and Armory:GetPetRealName() or "";
    if ( Armory:UnitCreatureFamily("pet") ) then
        text = text.." "..format(UNIT_LEVEL_TEMPLATE, Armory:UnitLevel("pet")).." "..Armory:UnitCreatureFamily("pet");
    end
    if ( (nextXP or 0) > 0 ) then
        local percentXP = floor((currXP * 100) / nextXP);
        if ( percentXP > 0 ) then
            text = text.." ("..XP.." "..percentXP.."%)";
        end
    end
    ArmoryPetFrameLevelText:SetText(text);
end

function ArmoryPetFrame_SetHappiness()
    local happiness, damagePercentage, loyaltyRate = Armory:GetPetHappiness();
    local hasPetUI, isHunterPet = Armory:HasPetUI();
    if ( not happiness or not isHunterPet ) then
        ArmoryPetFrameDiet:Hide();
        return;
    end
    ArmoryPetFrameDiet:Show();
    if ( happiness == 1 ) then
        ArmoryPetFrameHappinessTexture:SetTexCoord(0.375, 0.5625, 0, 0.359375);
    elseif ( happiness == 2 ) then
        ArmoryPetFrameHappinessTexture:SetTexCoord(0.1875, 0.375, 0, 0.359375);
    elseif ( happiness == 3 ) then
        ArmoryPetFrameHappinessTexture:SetTexCoord(0, 0.1875, 0, 0.359375);
    end
    ArmoryPetFrameDiet.tooltip = _G["PET_HAPPINESS"..happiness];
    ArmoryPetFrameDiet.tooltipDamage = format(PET_DAMAGE_PERCENTAGE, damagePercentage);
    if ( loyaltyRate < 0 ) then
        ArmoryPetFrameDiet.tooltipLoyalty = _G["LOSING_LOYALTY"];
    elseif ( loyaltyRate > 0 ) then
        ArmoryPetFrameDiet.tooltipLoyalty = _G["GAINING_LOYALTY"];
    else
        ArmoryPetFrameDiet.tooltipLoyalty = nil;
    end
    ArmoryPetDietText:SetFormattedText(PET_DIET_TEMPLATE, BuildListString(Armory:GetPetFoodTypes()));
end

function ArmoryPetFrame_SetResistances()
    local resistance;
    local positive;
    local negative;
    local base;
    local index;
    local text;
    local frame;
    for i = 1, NUM_PET_RESISTANCE_TYPES, 1 do
        index = i + 1;
        if ( i == NUM_PET_RESISTANCE_TYPES ) then
            index = 1;
        end
        text = _G["ArmoryPetMagicResText"..i];
        frame = _G["ArmoryPetMagicResFrame"..i];

        base, resistance, positive, negative = Armory:UnitResistance("pet", frame:GetID());
        resistance = resistance or 0;
        positive = positive or 0;
        negative = negative or 0;

        frame.tooltip = _G["RESISTANCE"..frame:GetID().."_NAME"];

        -- resistances can now be negative. Show Red if negative, Green if positive, white otherwise
        if( resistance < 0 ) then
            text:SetText(RED_FONT_COLOR_CODE..resistance..FONT_COLOR_CODE_CLOSE);
        elseif( resistance == 0 ) then
            text:SetText(resistance);
        else
            text:SetText(GREEN_FONT_COLOR_CODE..resistance..FONT_COLOR_CODE_CLOSE);
        end

        if ( positive ~= 0 or negative ~= 0 ) then
            -- Otherwise build up the formula
            frame.tooltip = frame.tooltip.. " ( "..HIGHLIGHT_FONT_COLOR_CODE..base;
            if( positive > 0 ) then
                frame.tooltip = frame.tooltip..GREEN_FONT_COLOR_CODE.." +"..positive;
            end
            if( negative < 0 ) then
                frame.tooltip = frame.tooltip.." "..RED_FONT_COLOR_CODE..negative;
            end
            frame.tooltip = frame.tooltip..FONT_COLOR_CODE_CLOSE.." )";
        end
    end
end

function ArmoryPetFrame_SetStats()
    for i = 1, NUM_PET_STATS do
        local label = getglobal("ArmoryPetStatFrame"..i.."Label");
        local text = getglobal("ArmoryPetStatFrame"..i.."StatText");
        local frame = getglobal("ArmoryPetStatFrame"..i);
        local stat, effectiveStat, posBuff, negBuff;
        label:SetText(getglobal("SPELL_STAT"..i.."_NAME")..":");
        stat, effectiveStat, posBuff, negBuff = Armory:UnitStat("pet", i);
        -- Set the tooltip text
        local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..getglobal("SPELL_STAT"..i.."_NAME").." ";

        if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
            text:SetText(effectiveStat);
            frame.tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE;
        else
            tooltipText = tooltipText..effectiveStat;
            if ( posBuff > 0 or negBuff < 0 ) then
                tooltipText = tooltipText.." ("..(stat - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE;
            end
            if ( posBuff > 0 ) then
                tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..posBuff..FONT_COLOR_CODE_CLOSE;
            end
            if ( negBuff < 0 ) then
                tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE;
            end
            if ( posBuff > 0 or negBuff < 0 ) then
                tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE;
            end
            frame.tooltip = tooltipText;

            -- If there are any negative buffs then show the main number in red even if there are
            -- positive buffs. Otherwise show in green.
            if ( negBuff < 0 ) then
                text:SetText(RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
            else
                text:SetText(GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
            end
        end

        -- Second tooltip line
        frame.tooltip2 = getglobal("DEFAULT_STAT"..i.."_TOOLTIP");
        if ( i == 1 ) then
            local attackPower = 2 * effectiveStat - 20;
            frame.tooltip2 = format(frame.tooltip2, attackPower);
        elseif ( i == 2 ) then
            --local newLineIndex = strfind(frame.tooltip2, "\n");
            local newLineIndex = strfind(frame.tooltip2, "|n");
            frame.tooltip2 = strsub(frame.tooltip2, 1, newLineIndex - 1);
            frame.tooltip2 = format(frame.tooltip2, Armory:GetCritChanceFromAgility("pet"));
        elseif ( i == 3 ) then
               local expectedHealthGain = (((stat - posBuff - negBuff) - 20) * 10 + 20) * Armory:GetUnitHealthModifier("pet");
            local realHealthGain = ((effectiveStat - 20) * 10 + 20) * Armory:GetUnitHealthModifier("pet");
            local healthGain = (realHealthGain - expectedHealthGain) * Armory:GetUnitMaxHealthModifier("pet");
            frame.tooltip2 = format(frame.tooltip2, healthGain);
        elseif ( i == 4 ) then
            if ( Armory:UnitHasMana("pet") ) then
                local manaGain = ((effectiveStat - 20) * 15 + 20) * Armory:GetUnitPowerModifier("pet");
                frame.tooltip2 = format(frame.tooltip2, manaGain, Armory:GetSpellCritChanceFromIntellect("pet"));
            else
                local newLineIndex = strfind(frame.tooltip2, "|n") + 2;
                frame.tooltip2 = strsub(frame.tooltip2, newLineIndex);
                frame.tooltip2 = format(frame.tooltip2, Armory:GetSpellCritChanceFromIntellect("pet"));
            end
        elseif ( i == 5 ) then
            frame.tooltip2 = format(frame.tooltip2, Armory:GetUnitHealthRegenRateFromSpirit("pet"));
            if ( Armory:UnitHasMana("pet") ) then
                frame.tooltip2 = frame.tooltip2.."\n"..format(MANA_REGEN_FROM_SPIRIT, Armory:GetUnitManaRegenRateFromSpirit("pet"));
            end
        end
    end
end

function ArmoryPetPaperDollFrame_SetSpellBonusDamage()
    local _, unitClass = Armory:UnitClass("player");
    unitClass = strupper(unitClass);
    local spellDamageBonus = 0;
    if( unitClass == "WARLOCK" ) then
        local bonusFireDamage = Armory:GetSpellBonusDamage(3);
        local bonusShadowDamage = Armory:GetSpellBonusDamage(6);
        if ( bonusShadowDamage > bonusFireDamage ) then
            spellDamageBonus = Armory:ComputePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", bonusShadowDamage);
        else
            spellDamageBonus = Armory:ComputePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", bonusFireDamage);
        end
    elseif( unitClass == "HUNTER" ) then
        local base, posBuff, negBuff = Armory:UnitRangedAttackPower("player");
        local totalAP = base + posBuff + negBuff;
        spellDamageBonus = Armory:ComputePetBonus("PET_BONUS_RAP_TO_SPELLDMG", totalAP);
    end
    local spellDamageBonusText = format("%d", spellDamageBonus);

    ArmoryPetSpellDamageFrameLabel:SetText(SPELL_BONUS_COLON);
    if ( spellDamageBonus > 0 ) then
        spellDamageBonusText = GREEN_FONT_COLOR_CODE.."+"..spellDamageBonusText..FONT_COLOR_CODE_CLOSE;
    elseif( spellDamageBonus < 0 ) then
        spellDamageBonusText = RED_FONT_COLOR_CODE..spellDamageBonusText..FONT_COLOR_CODE_CLOSE;
    end

    ArmoryPetSpellDamageFrameStatText:SetText(spellDamageBonusText);
    ArmoryPetSpellDamageFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..SPELL_BONUS..FONT_COLOR_CODE_CLOSE.." "..spellDamageBonusText;
    ArmoryPetSpellDamageFrame.tooltip2 = DEFAULT_STATSPELLBONUS_TOOLTIP;

    ArmoryPetSpellDamageFrame:Show();
end

function ArmoryPetFrame_UpdateStats()
    ArmoryPetFrame_SetResistances();
    ArmoryPetFrame_SetStats();
    ArmoryPaperDollFrame_SetDamage(ArmoryPetDamageFrame, "Pet");
    ArmoryPaperDollFrame_SetArmor(ArmoryPetArmorFrame, "Pet");
    ArmoryPaperDollFrame_SetAttackPower(ArmoryPetAttackPowerFrame, "Pet");
    ArmoryPetPaperDollFrame_SetSpellBonusDamage();
end
