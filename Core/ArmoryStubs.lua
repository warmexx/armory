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
local BCT = LibStub("LibBabble-CreatureType-3.0"):GetReverseLookupTable();

function Armory:GetArenaCurrency()
	local arenaCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID);
    return self:SetGetCharacterValue("ArenaCurrency", arenaCurrencyInfo.quantity);
end

function Armory:GetArmorPenetration()
    return self:SetGetCharacterValue("ArmorPenetration", _G.GetArmorPenetration());
end

function Armory:GetBlockChance()
    return self:SetGetCharacterValue("BlockChance", _G.GetBlockChance());
end

function Armory:ComputePetBonus(stat, value)
    local _, unitClass = Armory:UnitClass("player");
    unitClass = strupper(unitClass);
    if( unitClass == "WARLOCK" ) then
        if( WARLOCK_PET_BONUS[stat] ) then
            return value * WARLOCK_PET_BONUS[stat];
        else
            return 0;
        end
    elseif( unitClass == "HUNTER" ) then
        if( HUNTER_PET_BONUS[stat] ) then
            return value * HUNTER_PET_BONUS[stat];
        else
            return 0;
        end
    end

    return 0;
end

function Armory:GetCombatRating(index)
    if ( index ) then
        return self:SetGetCharacterValue("CombatRating"..index, _G.GetCombatRating(index)) or 0;
    end
end

function Armory:GetCombatRatingBonus(index)
    if ( index ) then
        return self:SetGetCharacterValue("CombatRatingBonus"..index, _G.GetCombatRatingBonus(index)) or 0;
    end
end

function Armory:GetCritChance()
    return self:SetGetCharacterValue("CritChance", _G.GetCritChance());
end

function Armory:GetCritChanceFromAgility(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("CritChanceFromAgility", _G.GetCritChanceFromAgility(unit));
    end
    return self:SetGetCharacterValue("CritChanceFromAgility", _G.GetCritChanceFromAgility(unit));
end

function Armory:GetCurrentPet()
    local pets = self:GetPets();
    local pet = self:UnitName("pet") or UNKNOWN;
    if ( not self.selectedPet ) then
        self.selectedPet = pet;
    end
    if ( not self:PetExists(self.selectedPet) ) then
        if ( pet == UNKNOWN and #pets > 0 ) then
            self.selectedPet = pets[1];
        else
            self.selectedPet = pet;
        end
    end
    return self.selectedPet;
end

function Armory:GetDodgeBlockParryChanceFromDefense()
    local base, modifier = Armory:UnitDefense("player");
    local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (Armory:UnitLevel("player")*5));
    defensePercent = max(defensePercent, 0);
    return defensePercent;
end

function Armory:GetDodgeChance()
    return self:SetGetCharacterValue("DodgeChance", _G.GetDodgeChance());
end

function Armory:GetExpertise()
    return self:SetGetCharacterValue("Expertise", _G.GetExpertise());
end

function Armory:GetExpertisePercent()
    return self:SetGetCharacterValue("ExpertisePercent", _G.GetExpertisePercent());
end

function Armory:GetGuildInfo(unit)
    return self:SetGetCharacterValue("Guild", _G.GetGuildInfo("player"));
end

function Armory:GetHonorCurrency()
    local honorCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID);
    return self:SetGetCharacterValue("HonorCurrency", honorCurrencyInfo.quantity);
end

function Armory:GetInventoryItemCount(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemCount"..index, _G.GetInventoryItemCount("player", index));
    end
end

function Armory:GetInventoryItemLink(unit, index)
    if ( index ) then
        if ( index >= EQUIPPED_FIRST and index <= EQUIPPED_LAST ) then
            return self:GetCharacterValue("InventoryItemLink"..index);
        elseif ( not ArmoryInventoryFrame.bankOpen and self:IsBankBagSlot(index) ) then
            return self:GetCharacterValue("InventoryItemLink"..index);
        else
            return self:SetGetCharacterValue("InventoryItemLink"..index, _G.GetInventoryItemLink(unit, index));
        end
    end
end

function Armory:GetInventoryItemTexture(unit, index)
    if ( index ) then
        if ( not ArmoryInventoryFrame.bankOpen and self:IsBankBagSlot(index) ) then
            return self:GetCharacterValue("InventoryItemTexture"..index);
        else
            return self:SetGetCharacterValue("InventoryItemTexture"..index, _G.GetInventoryItemTexture("player", index));
        end
    end
end

function Armory:GetInventoryItemQuality(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemQuality"..index, _G.GetInventoryItemQuality("player", index));
    end
end

function Armory:GetLatestThreeSenders()
    return self:SetGetCharacterValue("LatestThreeSenders", _G.GetLatestThreeSenders());
end

function Armory:GetManaRegen()
    return self:SetGetCharacterValue("ManaRegen", _G.GetManaRegen());
end

function Armory:GetMoney()
    return self:SetGetCharacterValue("Money", _G.GetMoney()) or 0;
end

function Armory:GetParryChance()
    return self:SetGetCharacterValue("ParryChance", _G.GetParryChance());
end

function Armory:GetPetExperience()
    return self:SetGetPetValue("Experience", _G.GetPetExperience());
end

function Armory:GetPetFoodTypes()
    return self:SetGetPetValue("FoodTypes", _G.GetPetFoodTypes());
end

function Armory:GetPetHappiness()
    return self:SetGetPetValue("Happiness", _G.GetPetHappiness());
end

function Armory:GetPetIcon()
    local _, isHunterPet = self:HasPetUI();
    if ( isHunterPet ) then
        return self:SetGetPetValue("Icon", _G.GetPetIcon());
    end

    local _, className = self:UnitClass("player");
    local creatureFamily = BCT[self:UnitCreatureFamily("pet")];
    if ( className == "DEATHKNIGHT" ) then
        return "Interface\\Icons\\Spell_Shadow_RaiseDead"; --Spell_Shadow_AnimateDead";
    elseif ( className == "MAGE" ) then
        return "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2";
    elseif ( creatureFamily ) then
        if ( creatureFamily == "Fel Imp" ) then
            return GetSpellTexture(112866);
        elseif ( creatureFamily == "Voidlord" ) then
            return GetSpellTexture(112867);
        elseif ( creatureFamily == "Observer" ) then
            return GetSpellTexture(112868);
        elseif ( creatureFamily == "Shivarra" ) then
            return GetSpellTexture(112869);
        elseif ( creatureFamily == "Wrathguard" ) then
            return GetSpellTexture(030146);
        end
        return "Interface\\Icons\\Spell_Shadow_Summon"..creatureFamily;
    else
        return "Interface\\Icons\\INV_Misc_QuestionMark";
    end
end

function Armory:GetPetLoyalty()
    return self:SetGetPetValue("Loyalty", _G.GetPetLoyalty());
end

function Armory:GetPetRealName()
    local name, realName = self:GetPetName();
    return self:SetGetPetValue("Name", realName or name);
end

local pets = {};
local oldPets = {};
function Armory:GetPets(unit)
    table.wipe(pets);
    table.wipe(oldPets);

    if ( self:PetsEnabled() ) then
        local dbEntry = self.selectedDbBaseEntry;
        if ( unit == "player" ) then
            dbEntry = self.playerDbBaseEntry;
        end
        if ( dbEntry and dbEntry:Contains("Pets") ) then
            for pet in pairs(dbEntry:GetValue("Pets")) do
                -- sanity check
                if ( pet == UNKNOWN or not dbEntry:GetValue("Pets", pet, "Family") ) then
                    table.insert(oldPets, pet);
                else
                    table.insert(pets, pet);
                end
            end
            table.sort(pets);

            -- should never happen, but better save than sorry
            for _, pet in ipairs(oldPets) do
                self:DeletePet(pet, unit);
                self:PrintDebug("Pet", pet, "removed");
            end
        end
    end

    return pets;
end

function Armory:GetPetTrainingPoints()
    return self:SetGetPetValue("TrainingPoints", _G.GetPetTrainingPoints());
end

function Armory:GetPortraitTexture(unit)
    local portrait = "Interface\\CharacterFrame\\TemporaryPortrait";

    if ( strlower(unit) == "pet" ) then
        portrait = portrait .. "-Pet";
    else
        local sex = self:UnitSex(unit);
        local _, raceEn = self:UnitRace(unit);
        if ( sex == 2 ) then
            portrait = portrait .. "-Male-" .. raceEn;
        elseif ( sex == 3 ) then
            portrait = portrait .. "-Female-" .. raceEn;
        end
    end

    return portrait;
end

function Armory:GetPVPLifetimeStats()
    return self:SetGetCharacterValue("PVPLifetimeStats", _G.GetPVPLifetimeStats());
end

function Armory:GetPVPRankProgress()
    return self:SetGetCharacterValue("PVPRankProgress", _G.GetPVPRankProgress());
end

function Armory:GetPVPSessionStats()
    local timestamp, hk, cp = self:SetGetCharacterValue("PVPSessionStats", time(), _G.GetPVPSessionStats());

    if ( not (hk and self:IsToday(timestamp)) ) then
        hk = 0;
        cp = 0;
    end

    return hk, cp;
end

function Armory:GetPVPYesterdayStats(update)
    local timestamp, hk, cp;
    if ( update ) then
        timestamp, hk, cp = self:SetGetCharacterValue("PVPYesterdayStats", time(), _G.GetPVPYesterdayStats());
    else
        timestamp, hk, cp = self:GetCharacterValue("PVPYesterdayStats");
    end

    if ( not (hk and self:IsToday(timestamp)) ) then
        hk = 0;
        cp = 0;
    end

    return hk, cp;
end

function Armory:GetPVPThisWeekStats(update)
    local timestamp, hk, cp;
    if ( update ) then
        timestamp, hk, cp = self:SetGetCharacterValue("PVPThisWeekStats", time(), _G.GetPVPThisWeekStats());
    else
        timestamp, hk, cp = self:GetCharacterValue("PVPThisWeekStats");
    end

    if ( not (hk and self:IsInWeek(timestamp)) ) then
        hk = 0;
        cp = 0;
    end

    return hk, cp;
end

function Armory:GetPVPLastWeekStats(update)
    local timestamp, hk, cp;
    if ( update ) then
        timestamp, hk, cp = self:SetGetCharacterValue("PVPLastWeekStats", time(), _G.GetPVPLastWeekStats());
    else
        timestamp, hk, cp = self:GetCharacterValue("PVPLastWeekStats");
    end

    if ( not (hk and self:IsInWeek(timestamp, -1)) ) then
        hk = 0;
        cp = 0;
    end

    return hk, cp;
end

function Armory:GetRangedCritChance()
    return self:SetGetCharacterValue("RangedCritChance", _G.GetRangedCritChance());
end

function Armory:GetRestState()
    return self:SetGetCharacterValue("RestState", _G.GetRestState());
end

function Armory:GetShieldBlock()
    return self:SetGetCharacterValue("ShieldBlock", _G.GetShieldBlock());
end

function Armory:GetSpellBonusDamage(holySchool)
    if ( holySchool ) then
        return self:SetGetCharacterValue("SpellBonusDamage"..holySchool, _G.GetSpellBonusDamage(holySchool));
    end
end

function Armory:GetSpellBonusHealing()
    return self:SetGetCharacterValue("SpellBonusHealing", _G.GetSpellBonusHealing());
end

function Armory:GetSpellCritChance(holySchool)
    if ( holySchool ) then
        return self:SetGetCharacterValue("SpellCritChance"..holySchool, _G.GetSpellCritChance(holySchool));
    end
end

function Armory:GetSpellCritChanceFromIntellect(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("SpellCritChanceFromIntellect", _G.GetSpellCritChanceFromIntellect(unit));
    end
    return self:SetGetCharacterValue("SpellCritChanceFromIntellect", _G.GetSpellCritChanceFromIntellect(unit));
end

function Armory:GetSpellPenetration()
    return self:SetGetCharacterValue("SpellPenetration", _G.GetSpellPenetration());
end

function Armory:GetSubZoneText()
    return self:SetGetCharacterValue("SubZone", _G.GetSubZoneText());
end

function Armory:GetUnitHealthModifier(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HealthModifier", _G.GetUnitHealthModifier(unit));
    end
    return self:SetGetCharacterValue("HealthModifier", _G.GetUnitHealthModifier(unit));
end

function Armory:GetUnitHealthRegenRateFromSpirit(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HealthRegenRateFromSpirit", _G.GetUnitHealthRegenRateFromSpirit(unit));
    end
    return self:SetGetCharacterValue("HealthRegenRateFromSpirit", _G.GetUnitHealthRegenRateFromSpirit(unit));
end

function Armory:GetUnitManaRegenRateFromSpirit(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("ManaRegenRateFromSpirit", _G.GetUnitManaRegenRateFromSpirit(unit));
    end
    return self:SetGetCharacterValue("ManaRegenRateFromSpirit", _G.GetUnitManaRegenRateFromSpirit(unit));
end

function Armory:GetUnitMaxHealthModifier(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("MaxHealthModifier", _G.GetUnitMaxHealthModifier(unit));
    end
    return self:SetGetCharacterValue("MaxHealthModifier", _G.GetUnitMaxHealthModifier(unit));
end

function Armory:GetUnitPowerModifier(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("PowerModifier", _G.GetUnitPowerModifier(unit));
    end
    return self:SetGetCharacterValue("PowerModifier", _G.GetUnitPowerModifier(unit));
end

function Armory:GetWeeklyResetTime()
	local day = self:GetConfigWeeklyReset();
	local offset = (6 + day - date("%w", time())) % 7;
	return self:GetServerTimeAsLocalTime(self:GetServerTime() + offset * 24 * 60 * 60);
end

function Armory:GetWeeklyResetDay()
    local day = 4;
	--local region = strupper(GetCVar("realmList"):match("^[%a.]-(%a+).%a+.%a+.%a+$"));
	local region = GetCVar("portal");
	if ( region == "US" ) then
		day = 2;
	elseif ( region == "EU" ) then
		day = 3;
	end
    return day;
end

function Armory:GetXPExhaustion()
    return self:SetGetCharacterValue("XPExhaustion", _G.GetXPExhaustion(), time());
end

function Armory:GetZoneText()
    return self:SetGetCharacterValue("Zone", _G.GetZoneText());
end

function Armory:HasNewMail()
    return self:SetGetCharacterValue("HasMail", _G.HasNewMail());
end

function Armory:HasPetUI()
    if ( self:PetsEnabled() ) then
        local pets = self:GetPets();
        if ( #pets == 0 and self.character == self.player ) then
            return _G.HasPetUI();
        end
        local _, unitClass = self:UnitClass("player");
        return #pets > 0, strupper(unitClass) == "HUNTER";
    end
end

function Armory:HasWandEquipped()
    return self:SetGetCharacterValue("HasWandEquipped", _G.HasWandEquipped());
end

function Armory:IsBankBagSlot(index)
    if ( index ) then
        return index >= _G.ContainerIDToInventoryID(NUM_BAG_SLOTS + 1) and index <= _G.ContainerIDToInventoryID(NUM_BAG_SLOTS + NUM_BANKBAGSLOTS);
    end
end

function Armory:IsPersistentPet()
    return (_G.UnitName("pet") or UNKNOWN) ~= UNKNOWN and _G.UnitCreatureFamily("pet");
end

function Armory:IsResting()
   return self:SetGetCharacterValue("IsResting", _G.IsResting());
end

function Armory:PetExists(pet, unit)
    local dbEntry = self.selectedDbBaseEntry;

    if ( unit == "player" ) then
        dbEntry = self.playerDbBaseEntry;
    end

    return dbEntry and dbEntry:Contains("Pets", pet);
end

----------------------------------------------------------

function Armory:SetBagItem(id, index)
    local link = self:GetContainerItemLink(id, index);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);

        if ( id == ARMORY_MAIL_CONTAINER ) then
            local daysLeft = self:GetContainerItemExpiration(ARMORY_MAIL_CONTAINER, index);
            --local daysLeft = Armory:GetContainerInboxItemDaysLeft(id, index);
            if ( daysLeft ) then
                if ( daysLeft >= 1 ) then
                    daysLeft = LIGHTYELLOW_FONT_COLOR_CODE.."  "..format(DAYS_ABBR, floor(daysLeft)).." "..FONT_COLOR_CODE_CLOSE;
                else
                    daysLeft = RED_FONT_COLOR_CODE.."  "..SecondsToTime(floor(daysLeft * 24 * 60 * 60))..FONT_COLOR_CODE_CLOSE;
                end
                GameTooltip:AppendText(daysLeft);
                GameTooltip:Show();
            end

        elseif ( id == ARMORY_AUCTIONS_CONTAINER or id == ARMORY_NEUTRAL_AUCTIONS_CONTAINER ) then
            local timeLeft, _, remaining = self:GetContainerItemExpiration(id, index);
            if ( timeLeft ) then
                local timeLeftScanned = SecondsToTime(remaining, true);
                if ( timeLeftScanned ~= "" ) then
                    timeLeftScanned = " "..string.format(GUILD_BANK_LOG_TIME, timeLeftScanned);
                end

            --local timeLeft, timestamp = self:GetInventoryContainerValue(id, "TimeLeft"..index);
            --if ( timeLeft ) then
                --local timeLeftScanned = SecondsToTime(time() - timestamp, true);
                --if ( timeLeftScanned ~= "" ) then
                    --timeLeftScanned = " "..string.format(GUILD_BANK_LOG_TIME, timeLeftScanned);
                --end

                local tooltipLines = self:Tooltip2Table(GameTooltip);
                local remaining = "?";
                if ( _G["AUCTION_TIME_LEFT"..timeLeft] ) then
                    remaining = _G["AUCTION_TIME_LEFT"..timeLeft];
                end
                table.insert(tooltipLines, 2, self:Text2String(remaining..timeLeftScanned, 1.0, 1.0, 0.6));
                self:Table2Tooltip(GameTooltip, tooltipLines);
                GameTooltip:Show();
            end

        end
    end
end

function Armory:SetInventoryItem(unit, index, dontShow, tooltip, link)
    if ( index ) then
        local hasItem, hasCooldown, repairCost;
        if ( link ) then
            hasItem = true;
        else
            hasItem, hasCooldown, repairCost = self:GetInventoryItem(index);
            link = self:GetInventoryItemLink("player", index);
        end
        if ( link and hasItem and not dontShow ) then
            if ( not tooltip ) then
                self:SetHyperlink(GameTooltip, link);
            else
                self:SetHyperlink(tooltip, link);
                if ( PawnUpdateTooltip ) then
                     PawnUpdateTooltip(tooltip:GetName(), "SetHyperlink", link);
                     if ( PawnAttachIconToTooltip ) then
                        PawnAttachIconToTooltip(tooltip, true, link);
                     end
                end

                local tooltipLines = self:Tooltip2Table(tooltip, true);
                local realm, character = self:GetPaperDollLastViewed();
                table.insert(tooltipLines, 1, self:Text2String(character.." "..realm, 0.5, 0.5, 0.5));
                self:Table2Tooltip(tooltip, tooltipLines, 4);
                tooltip:Show();
            end
        end
        return hasItem, hasCooldown, repairCost;
    end
end

function Armory:GetInventoryItem(index)
    if ( index ) then
        return self:GetCharacterValue("InventoryItem"..index);
    end
end

function Armory:SetInventoryItemInfo(index)
    local link = _G.GetInventoryItemLink("player", index);
    local hasItem, hasCooldown, repairCost;
    local invalid;

    if ( link ) then
        local tooltip1 = self:AllocateTooltip();
        hasItem, hasCooldown, repairCost = tooltip1:SetInventoryItem("player", index);
        if ( not self:IsValidTooltip(tooltip1) ) then
            invalid = true;
        end
        self:ReleaseTooltip(tooltip1);
    end

    if ( not invalid ) then
        self:SetCharacterValue("InventoryItem"..index, hasItem, hasCooldown, repairCost);
        self:SetCharacterValue("InventoryItemLink"..index, link);
    else
        self:PrintDebug("No data for", ARMORY_SLOT[index], "slot; skipping update")
    end
end

function Armory:GetInventoryItemInfo(index, unit)
    local hasItem, hasCooldown, repairCost = self:GetCharacterValue("InventoryItem"..index, unit);
    local link = self:GetCharacterValue("InventoryItemLink"..index, unit);
    return hasItem, hasCooldown, repairCost, link;
end

function Armory:SetItemLink(button, link)
    -- stub to enable hooks
    button.link = link;
end

function Armory:SetPortraitTexture(frame, unit)
    SetPortraitToTexture(frame, self:GetPortraitTexture(unit));
    return "Portrait1";
end

function Armory:SetQuestLogItem(itemType, id)
    local link = self:GetQuestLogItemLink(itemType, id);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);
    end
end

function Armory:SetQuestLogRewardSpell()
    local link = self:GetQuestLogSpellLink();
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);
    end
end

function Armory:SetSpell(id, bookType)
    local tooltipLines = self:GetSpellTooltip(id, bookType);
    if ( tooltipLines ) then
        self:Table2Tooltip(GameTooltip, tooltipLines, 2);
        GameTooltip:Show();
    end
end

function Armory:SetTalent(index, id, inspect)
    local tooltipLines = self:GetTalentTooltip(index, id);
    if ( tooltipLines ) then
        self:Table2Tooltip(GameTooltip, tooltipLines);
        GameTooltip:Show();
    end
end

function Armory:SetTradeSkillItem(index, reagent)
    if ( index ) then
        local link;
        if ( reagent ) then
            link = self:GetTradeSkillReagentItemLink(index, reagent);
        else
            link = self:GetTradeSkillItemLink(index);
        end
        if ( link ) then
            self:SetHyperlink(GameTooltip, link);
        end
    end
end

function Armory:SetUnitAura(unit, index, filter)
    local tooltipLines = self:GetBuffTooltip(unit, index, filter);
    if ( tooltipLines ) then
        self:Table2Tooltip(GameTooltip, tooltipLines, 1);
    else
        local name = self:UnitAura(unit, index, filter);
        GameTooltip:SetText(name);
    end
    GameTooltip:Show();
end

----------------------------------------------------------

function Armory:UnitArmor(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Armor", _G.UnitArmor(unit));
    end
    return self:SetGetCharacterValue("Armor", _G.UnitArmor(unit));
end

function Armory:UnitAttackBothHands(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("AttackBothHands", _G.UnitAttackBothHands(unit));
    end
    return self:SetGetCharacterValue("AttackBothHands", _G.UnitAttackBothHands(unit));
end

function Armory:UnitAttackPower(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("AttackPower", _G.UnitAttackPower(unit));
    end
    return self:SetGetCharacterValue("AttackPower", _G.UnitAttackPower(unit));
end

function Armory:UnitAttackSpeed(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("AttackSpeed", _G.UnitAttackSpeed(unit));
    end
    return self:SetGetCharacterValue("AttackSpeed", _G.UnitAttackSpeed(unit));
end

function Armory:UnitAura(unit, index, filter)
    return self:GetBuff(unit, index, filter);
end

function Armory:UnitCharacterPoints(unit)
    return self:SetGetCharacterValue("CharacterPoints", _G.UnitCharacterPoints("player"));
end

function Armory:UnitClass(unit)
    return self:SetGetCharacterValue("Class", _G.UnitClass("player"));
end

function Armory:UnitCreatureFamily(unit)
    return self:SetGetPetValue("Family", _G.UnitCreatureFamily("pet"));
end

function Armory:UnitDamage(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Damage", _G.UnitDamage(unit));
    end
    return self:SetGetCharacterValue("Damage", _G.UnitDamage(unit));
end

function Armory:UnitDefense(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Defense", _G.UnitDefense(unit));
    end
    return self:SetGetCharacterValue("Defense", _G.UnitDefense(unit));
end

function Armory:UnitFactionGroup(unit)
    return self:SetGetCharacterValue("FactionGroup", _G.UnitFactionGroup("player"));
end

function Armory:UnitHasMana(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HasMana", _G.UnitHasMana(unit));
    end
    return self:SetGetCharacterValue("HasMana", _G.UnitHasMana(unit));
end

function Armory:UnitHasRelicSlot(unit)
    return self:SetGetCharacterValue("HasRelicSlot", _G.UnitHasRelicSlot("player"));
end

function Armory:UnitHealth(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Health", _G.UnitHealth(unit));
    end
    return self:SetGetCharacterValue("Health", _G.UnitHealth(unit));
end

function Armory:UnitHealthMax(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HealthMax", _G.UnitHealthMax(unit));
    end
    return self:SetGetCharacterValue("HealthMax", _G.UnitHealthMax(unit));
end

function Armory:UnitLevel(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Level", _G.UnitLevel(unit)) or self:UnitLevel("player");
    end
    return self:SetGetCharacterValue("Level", _G.UnitLevel(unit));
end

function Armory:UnitName(unit)
    if ( strlower(unit) == "pet" ) then
        if ( self:GetPetName() ) then
            self:SetCharacterValue("Pet", self:GetPetName());
        else
            self:SetCharacterValue("Pet", nil);
        end
        return self:GetCharacterValue("Pet");
    end
    return self.character; --:SetGetCharacterValue("Name", _G.UnitName(unit));
end

function Armory:UnitPower(unit, powerType)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Power", _G.UnitPower(unit, powerType));
    end
    return self:SetGetCharacterValue("Power", _G.UnitPower(unit, powerType));
end

function Armory:UnitPowerMax(unit, powerType)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("PowerMax", _G.UnitPowerMax(unit, powerType));
    end
    return self:SetGetCharacterValue("PowerMax", _G.UnitPowerMax(unit, powerType));
end

function Armory:UnitPowerType(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("PowerType", _G.UnitPowerType(unit));
    end
    return self:SetGetCharacterValue("PowerType", _G.UnitPowerType(unit));
end

function Armory:UnitPVPName(unit)
    return self:SetGetCharacterValue("PVPName", _G.UnitPVPName("player"));
end

function Armory:UnitPVPRank(unit)
    return self:SetGetCharacterValue("PVPRank", _G.UnitPVPRank("player"));
end

function Armory:UnitRace(unit)
    return self:SetGetCharacterValue("Race", _G.UnitRace("player"));
end

function Armory:UnitRangedAttack(unit)
    return self:SetGetCharacterValue("RangedAttack", _G.UnitRangedAttack("player"));
end

function Armory:UnitRangedAttackPower(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("RangedAttackPower", _G.UnitRangedAttackPower(unit));
    end
    return self:SetGetCharacterValue("RangedAttackPower", _G.UnitRangedAttackPower(unit));
end

function Armory:UnitRangedDamage(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("RangedDamage", _G.UnitRangedDamage(unit));
    end
    return self:SetGetCharacterValue("RangedDamage", _G.UnitRangedDamage(unit));
end

function Armory:UnitResistance(unit, index)
    if ( index ) then
        if ( strlower(unit) == "pet" ) then
            return self:SetGetPetValue("Resistance"..index, _G.UnitResistance(unit, index));
        end
        return self:SetGetCharacterValue("Resistance"..index, _G.UnitResistance(unit, index));
    end
end

function Armory:UnitSex(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Sex", _G.UnitSex(unit));
    end
    return self:SetGetCharacterValue("Sex", _G.UnitSex(unit));
end

function Armory:UnitStat(unit, index)
    if ( index ) then
        if ( strlower(unit) == "pet" ) then
            return self:SetGetPetValue("Stat"..index, _G.UnitStat(unit, index));
        end
        return self:SetGetCharacterValue("Stat"..index, _G.UnitStat(unit, index));
    end
end

function Armory:UnitXP(unit)
    return self:SetGetCharacterValue("XP", _G.UnitXP("player"));
end

function Armory:UnitXPMax(unit)
    return self:SetGetCharacterValue("XPMax", _G.UnitXPMax("player"));
end
