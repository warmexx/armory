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

-- Stubs that only Mainline has (Retail and Forever); the shared ones are in Core\ArmoryStubs.lua

function Armory:GetActiveSpecGroup(inspect)
    return self:SetGetCharacterValue("ActiveSpecGroup", C_SpecializationInfo.GetActiveSpecGroup()) or 1;
end

function Armory:GetAttackPowerForStat(index, effectiveStat)
    return self:SetGetCharacterValue("AttackPowerForStat"..index, _G.GetAttackPowerForStat(index, effectiveStat));
end

function Armory:GetAvoidance()
    return self:SetGetCharacterValue("Avoidance", _G.GetAvoidance());
end

function Armory:GetBladedArmorEffect()
    return self:SetGetCharacterValue("BladedArmorEffect", _G.GetBladedArmorEffect());
end

function Armory:GetCombatRatingBonusForCombatRatingValue(index, value)
    if ( index ) then
        return self:SetGetCharacterValue("CombatRatingBonusForCombatRatingValue"..index, _G.GetCombatRatingBonusForCombatRatingValue(index, value)) or 0;
    end
end

function Armory:GetCorruption()
    return self:SetGetCharacterValue("Corruption", _G.GetCorruption());
end

function Armory:GetCorruptionResistance()
    return self:SetGetCharacterValue("CorruptionResistance", _G.GetCorruptionResistance());
end

function Armory:GetCritChanceProvidesParryEffect()
    return self:SetGetCharacterValue("CritChanceProvidesParryEffect", _G.GetCritChanceProvidesParryEffect());
end

function Armory:GetCurrencyInfo(id)
    --  61 Dalaran Jewelcrafter's Token
    --  81 Dalarn Cooking Award
    -- 241 Champion's Seal
    -- 361 Illustrious Jewelcrafter's Token
    -- 390 Conquest Points
    -- 391 Tol Barad Commendation
    -- 392 Honor Points
    -- 395 Justice Points
    -- 396 Valor Points
    -- 402 Chef's Award
    -- 1191 WoD Valor

    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(id);

    if ( currencyInfo ) then
        local name, quantity, icon, earnedThisWeek, earnablePerWeek = currencyInfo.name, currencyInfo.quantity, currencyInfo.iconFileID, currencyInfo.quantityEarnedThisWeek, currencyInfo.maxWeeklyQuantity;
        name, quantity, icon, earnedThisWeek, earnablePerWeek = self:SetGetCharacterValue("CurrencyInfo"..id, name, quantity, icon, earnedThisWeek, earnablePerWeek);

        if ( time() >= self:GetWeeklyQuestResetTime() ) then
            earnedThisWeek = 0;
        end

        return name, quantity, icon, earnedThisWeek, earnablePerWeek;
    end
end

function Armory:GetDodgeChanceFromAttribute()
    return self:SetGetCharacterValue("DodgeChanceFromAttribute", _G.GetDodgeChanceFromAttribute());
end

function Armory:GetEquippedArtifactInfo()
    return self:SetGetCharacterValue("EquippedArtifactInfo", C_ArtifactUI.GetEquippedArtifactInfo());
end

function Armory:GetHaste()
    return self:SetGetCharacterValue("Haste", _G.GetHaste());
end

function Armory:GetHitModifier()
    return self:SetGetCharacterValue("HitModifier", _G.GetHitModifier());
end

function Armory:GetInventoryAlertStatus(index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryAlertStatus"..index, _G.GetInventoryAlertStatus(index));
    end
end

function Armory:GetInventoryItemBroken(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemBroken"..index, _G.GetInventoryItemBroken("player", index));
    end
end

function Armory:GetLifesteal()
    return self:SetGetCharacterValue("Lifesteal", _G.GetLifesteal());
end

function Armory:GetMasteryEffect()
    return self:SetGetCharacterValue("MasteryEffect", _G.GetMasteryEffect());
end

function Armory:GetMeleeHaste()
    return self:SetGetCharacterValue("MeleeHaste", _G.GetMeleeHaste());
end

function Armory:GetMinItemLevel()
    return self:SetGetCharacterValue("MinItemLevel", C_PaperDollInfo.GetMinItemLevel());
end

function Armory:GetNegativeCorruptionEffectInfo()
    return self:SetGetCharacterValue("NegativeCorruptionEffectInfo", _G.GetNegativeCorruptionEffectInfo());
end

function Armory:GetOverrideAPBySpellPower()
    return self:SetGetCharacterValue("OverrideAPBySpellPower", _G.GetOverrideAPBySpellPower());
end

function Armory:GetOverrideSpellPowerByAP()
    return self:SetGetCharacterValue("OverrideSpellPowerByAP", _G.GetOverrideSpellPowerByAP());
end

function Armory:GetParryChanceFromAttribute()
    return self:SetGetCharacterValue("ParryChanceFromAttribute", _G.GetParryChanceFromAttribute());
end

function Armory:GetPersonalRatedInfo(id)
    local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon, lastWeeksBest, hasWon, pvpTier, ranking,
        roundsSeasonPlayed, roundsSeasonWon, roundsWeeklyPlayed, roundsWeeklyWon = self:SetGetCharacterValue("PersonalRatedInfo"..id, _G.GetPersonalRatedInfo(id));
    if ( time() >= self:GetWeeklyQuestResetTime() ) then
        weeklyBest = 0;
        weeklyPlayed = 0;
        weeklyWon = 0;
        roundsWeeklyPlayed = 0;
        roundsWeeklyWon = 0;
    end
    return rating or 0, seasonBest or 0, weeklyBest or 0, seasonPlayed or 0, seasonWon or 0, weeklyPlayed or 0, weeklyWon or 0,
        roundsSeasonPlayed or 0, roundsSeasonWon or 0, roundsWeeklyPlayed or 0, roundsWeeklyWon or 0;
end

function Armory:GetPetSpellBonusDamage()
    return self:SetGetPetValue("SpellBonusDamage", _G.GetPetSpellBonusDamage());
end

function Armory:GetPowerRegen()
    return self:SetGetCharacterValue("PowerRegen", _G.GetPowerRegen());
end

function Armory:GetPVPGearStatRules()
    return self:SetGetCharacterValue("PVPGearStatRules", _G.GetPVPGearStatRules());
end

function Armory:GetQuestResetTime()
    return self:SetGetCharacterValue("QuestResetTime", time() + _G.GetQuestResetTime()) or 0;
end

function Armory:GetRuneCooldown(index)
    return self:SetGetCharacterValue("RuneCooldown"..index, _G.GetRuneCooldown(index));
end

function Armory:GetSpecialization(inspect, pet, talentGroup)
    local activeTalentGroup = C_SpecializationInfo.GetActiveSpecGroup() or 1;
    local numTalentGroups = _G.GetNumSpecGroups();
    for i = 1, numTalentGroups do
        if ( pet ) then
            if ( i == activeTalentGroup ) then
                local _, isHunterPet = _G.HasPetUI();
                if ( isHunterPet and self:IsPersistentPet() ) then
                    local name = self:GetPetName();
                    self:SetPetValue(name, "Specialization"..i, C_SpecializationInfo.GetSpecialization(false, true));
                end
            end
        else
            self:SetCharacterValue("Specialization"..i, C_SpecializationInfo.GetSpecialization(false, false, i));
        end
    end

    talentGroup = talentGroup or self:GetActiveSpecGroup();
    if ( not pet ) then
        return self:GetCharacterValue("Specialization"..talentGroup);
    elseif ( self:PetExists(self:GetCurrentPet()) ) then
        return self:GetPetValue(self:GetCurrentPet(), "Specialization"..talentGroup);
    end
end

function Armory:GetSpecializationMasterySpells()
    local primaryTree = C_SpecializationInfo.GetSpecialization();
    if ( not primaryTree ) then
        return self:SetGetCharacterValue("MaterySpells", nil);
    end

    local masterySpells = C_SpecializationInfo.GetSpecializationMasterySpells(primaryTree);
    local masterySpell1 = nil;
    local masterySpell2 = nil;
    if ( masterySpells[1] ) then
        masterySpell1 = masterySpells[1];
    end
    if ( masterySpells[2] ) then
        masterySpell2 = masterySpells[2];
    end
    return self:SetGetCharacterValue("MaterySpells", masterySpell1, masterySpell2);
end

function Armory:GetSpeed()
    return self:SetGetCharacterValue("Speed", _G.GetSpeed());
end

function Armory:GetSpellHitModifier()
    return self:SetGetCharacterValue("SpellHitModifier", _G.GetSpellHitModifier());
end

function Armory:GetStaggerPercentage(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("StaggerPercentage", C_PaperDollInfo.GetStaggerPercentage(unit));
    end
    return self:SetGetCharacterValue("StaggerPercentage", C_PaperDollInfo.GetStaggerPercentage(unit));
end

function Armory:GetTexCoordsForRole(role)
    local textureHeight, textureWidth = 256, 256;
    local roleHeight, roleWidth = 67, 67;

    if ( role == "GUIDE" ) then
        return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight);
    elseif ( role == "TANK" ) then
        return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight);
    elseif ( role == "HEALER" ) then
        return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight);
    elseif ( role == "DAMAGER" ) then
        return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight);
    else
        error("Unknown role: "..tostring(role));
    end
end;

function Armory:GetUnitSpeed(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("UnitSpeed", _G.GetUnitSpeed(unit));
    end
    return self:SetGetCharacterValue("UnitSpeed", _G.GetUnitSpeed(unit));
end

function Armory:GetVersatilityBonus(index)
    if ( index ) then
        return self:SetGetCharacterValue("VersatilityBonus"..index, _G.GetVersatilityBonus(index)) or 0;
    end
end

function Armory:HasAPEffectsSpellPower()
    return self:SetGetCharacterValue("HasAPEffectsSP", _G.HasAPEffectsSpellPower());
end

function Armory:HasSPEffectsAttackPower()
    return self:SetGetCharacterValue("HasSPEffectsAP", _G.HasSPEffectsAttackPower());
end

function Armory:IsCharacterBankSlot(index)
    if ( index ) then
        return index >= C_Container.ContainerIDToInventoryID(Enum.BagIndex.CharacterBankTab_1) and index <= C_Container.ContainerIDToInventoryID(Enum.BagIndex.CharacterBankTab_6);
    end
end

function Armory:IsFalling(unit)
    if ( self:IsPlayerSelected() ) then
        return _G.IsFalling(unit);
    end
    return false;
end

function Armory:IsFlying(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("IsFlying", _G.IsFlying(unit));
    end
    return self:SetGetCharacterValue("IsFlying", _G.IsFlying(unit));
end

function Armory:InRepairMode()
   return self:SetGetCharacterValue("InRepairMode", _G.InRepairMode());
end

function Armory:IsMetaActive(unit)
    return self:GetCharacterValue("IsMetaActive", unit);
end

function Armory:IsPersistentPet()
    return _G.UnitExists("pet") and _G.UnitCreatureFamily("pet");
end

function Armory:IsRangedWeapon()
    return self:SetGetCharacterValue("IsRangedWeapon", _G.IsRangedWeapon());
end

function Armory:IsSwimming(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("IsSwimming", _G.IsSwimming(unit));
    end
    return self:SetGetCharacterValue("IsSwimming", _G.IsSwimming(unit));
end

function Armory:IsWarModeDesired()
    return self:SetGetCharacterValue("IsWarModeDesired", C_PvP.IsWarModeDesired());
end

function Armory:SetInventoryItemInfo(index)
    local link = _G.GetInventoryItemLink("player", index);
    local hasItem, hasCooldown, repairCost;
    local tinker, anchor;
    local emptySockets, activeMeta;
    local invalid;

    if ( link and issecretvalue(link) ) then
        link = nil;
    end

    if ( link ) then
        local tooltip1 = self:AllocateTooltip();
        hasItem, hasCooldown, repairCost = tooltip1:SetInventoryItem("player", index);
        if ( not self:IsValidTooltip(tooltip1) ) then
            invalid = true;
        elseif ( index ~= ARMORY_SLOTID.ShirtSlot and index ~= ARMORY_SLOTID.TabardSlot ) then
            local tooltip2 = self:AllocateTooltip();
            tooltip2:SetHyperlink(link);
            if ( self:IsValidTooltip(tooltip2) ) then
                -- Tinkers (engineering) only go on gloves, belt and cloak; elsewhere a difference is
                -- something else (e.g. the stats of a scaling item) that doesn't belong in the stored tooltip
                if ( index == ARMORY_SLOTID.HandsSlot or index == ARMORY_SLOTID.WaistSlot or index == ARMORY_SLOTID.BackSlot ) then
                    tinker, anchor = self:GetTinkerFromTooltip(tooltip1, tooltip2);
                end
                emptySockets, activeMeta = self:GetInventoryItemSocketInfo(tooltip1);
            else
                invalid = true;
            end
            self:ReleaseTooltip(tooltip2);
        end
        self:ReleaseTooltip(tooltip1);
    end

    if ( not invalid ) then
        self:SetCharacterValue("InventoryItem"..index, hasItem, hasCooldown, repairCost);
        self:SetCharacterValue("InventoryItemLink"..index, link, tinker, anchor, emptySockets);

        if ( index == ARMORY_SLOTID.HeadSlot ) then
            self:SetCharacterValue("IsMetaActive", activeMeta);
        end
        -- not really needed but may be useful for others
        self:SetCharacterValue("InventoryItemGems"..index, self:GetItemGemString(link));
    else
        self:PrintDebug("No data for", ARMORY_SLOT[index], "slot; skipping update")
    end
end

function Armory:SetPortraitTexture(frame, unit)
    frame:SetTexture(self:GetPortraitTexture(unit));
    return "Portrait1";
end

function Armory:SetPvpTalent(id)
    local link = _G.GetPvpTalentLink(id);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);
    end
end

function Armory:SetQuestLogCurrency(itemType, id)
    -- TODO
end

function Armory:SetSpell(id, spellBank, specialization)
    local link = self:GetSpellLink(id, spellBank, specialization);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);
    end
end

function Armory:UnitBonusArmor(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("BonusArmor", _G.UnitBonusArmor(unit));
    end
    return self:SetGetCharacterValue("BonusArmor", _G.UnitBonusArmor(unit));
end

function Armory:UnitEffectiveLevel(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("EffectiveLevel", _G.UnitEffectiveLevel(unit)) or self:UnitLevel(unit);
    end
    return self:SetGetCharacterValue("EffectiveLevel", _G.UnitEffectiveLevel(unit)) or self:UnitLevel(unit);
end

local function UnitDebuff(unitToken, index, filter)
    local ok, auraData = pcall(C_UnitAuras.GetDebuffDataByIndex, unitToken, index, filter);
    if ( not ok or not auraData or issecrettable(auraData) ) then
        return nil;
    end
    return AuraUtil.UnpackAuraData(auraData);
 end

function Armory:UnitHasResSickness(unit)
    local hasResSickness = false;
    local texture;
    local index = 1;

    unit = "player";

    if ( UnitDebuff(unit, index) ) then
        while ( UnitDebuff(unit, index) ) do
            texture = UnitDebuff(unit, index);
            if ( texture == "Interface\\Icons\\Spell_Shadow_DeathScream" ) then
                hasResSickness = true;
                break;
            end
            index = index + 1;
        end
    end

    return self:SetGetCharacterValue("HasResSickness", hasResSickness);
end

function Armory:UnitHonor(unit)
    return self:SetGetCharacterValue("Honor", _G.UnitHonor("player")) or 0;
end

function Armory:UnitHonorLevel(unit)
    return self:SetGetCharacterValue("HonorLevel", _G.UnitHonorLevel("player")) or 0;
end

function Armory:UnitHonorMax(unit)
    return self:SetGetCharacterValue("HonorMax", _G.UnitHonorMax("player")) or 0;
end

function Armory:UnitHPPerStamina(unit)
    return self:SetGetCharacterValue("HPPerStamina", _G.UnitHPPerStamina("player"));
end

function Armory:UnitIsDeadOrGhost(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("IsDead", _G.UnitIsDeadOrGhost(unit));
    end
    return self:SetGetCharacterValue("IsDead", _G.UnitIsDeadOrGhost(unit));
end

function Armory:GetGuildLogoInfo(unit)
    return self:SetGetCharacterValue("GuildLogo", _G.GetGuildLogoInfo("player"));
end

function Armory:PlayerIsTimerunning()
    return self:SetGetCharacterValue("Timerunning", _G.PlayerIsTimerunning());
end

function Armory:SetLargeGuildTabardTextures(unit, emblemTexture, backgroundTexture, borderTexture, tabardData)
    -- texure dimensions are 1024x1024, icon dimensions are 64x64
    local emblemSize, columns, offset;
    if ( emblemTexture ) then
        emblemSize = 64 / 1024;
        columns = 16
        offset = 0;
        emblemTexture:SetTexture("Interface\\GuildFrame\\GuildEmblemsLG_01");
    end
    self:SetGuildTabardTextures(emblemSize, columns, offset, unit, emblemTexture, backgroundTexture, borderTexture, tabardData);
end

function Armory:SetGuildTabardTextures(emblemSize, columns, offset, unit, emblemTexture, backgroundTexture, borderTexture, tabardData)
    local bkgR, bkgG, bkgB, borderR, borderG, borderB, emblemR, emblemG, emblemB, emblemFilename;
    if ( tabardData ) then
        bkgR = tabardData[1];
        bkgG = tabardData[2];
        bkgB = tabardData[3];
        borderR = tabardData[4];
        borderG = tabardData[5];
        borderB = tabardData[6];
        emblemR = tabardData[7];
        emblemG = tabardData[8];
        emblemB = tabardData[9];
        emblemFilename = tabardData[10];
    else
        bkgR, bkgG, bkgB, borderR, borderG, borderB, emblemR, emblemG, emblemB, emblemFilename = self:GetGuildLogoInfo(unit);
    end
    if ( emblemFilename ) then
        if ( backgroundTexture ) then
            backgroundTexture:SetVertexColor(bkgR / 255, bkgG / 255, bkgB / 255);
        end
        if ( borderTexture ) then
            borderTexture:SetVertexColor(borderR / 255, borderG / 255, borderB / 255);
        end
        if ( emblemSize ) then
            local index = emblemFilename:match("([%d]+)");
            if ( index) then
                index = tonumber(index);
                local xCoord = mod(index, columns) * emblemSize;
                local yCoord = floor(index / columns) * emblemSize;
                emblemTexture:SetTexCoord(xCoord + offset, xCoord + emblemSize - offset, yCoord + offset, yCoord + emblemSize - offset);
            end
            emblemTexture:SetVertexColor(emblemR / 255, emblemG / 255, emblemB / 255);
        elseif ( emblemTexture ) then
            emblemTexture:SetTexture(emblemFilename);
            emblemTexture:SetVertexColor(emblemR / 255, emblemG / 255, emblemB / 255);
        end
    else
        -- tabard lacks design
        if ( backgroundTexture ) then
            backgroundTexture:SetVertexColor(0.2245, 0.2088, 0.1794);
        end
        if ( borderTexture ) then
            borderTexture:SetVertexColor(0.2, 0.2, 0.2);
        end
        if ( emblemTexture ) then
            if ( emblemSize ) then
                if ( emblemSize == 18 / 256 ) then
                    emblemTexture:SetTexture("Interface\\GuildFrame\\GuildLogo-NoLogoSm");
                else
                    emblemTexture:SetTexture("Interface\\GuildFrame\\GuildLogo-NoLogo");
                end
                emblemTexture:SetTexCoord(0, 1, 0, 1);
                emblemTexture:SetVertexColor(1, 1, 1, 1);
            else
                emblemTexture:SetTexture("");
            end
        end
    end
end
