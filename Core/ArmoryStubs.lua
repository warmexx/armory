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
local BCT = LibStub("LibBabble-CreatureType-3.0"):GetReverseLookupTable();

function Armory:GetAverageItemLevel()
    return self:SetGetCharacterValue("AverageItemLevel", _G.GetAverageItemLevel());
end

function Armory:GetBlockChance()
    return self:SetGetCharacterValue("BlockChance", _G.GetBlockChance());
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

function Armory:GetCurrentPet()
    local pets = self:GetPets();
    local pet = self:UnitName("pet") or UNKNOWN;
    if ( not self.selectedPet ) then
        self.selectedPet = pet;
    end
    if ( not self:PetExists(self.selectedPet) ) then
        -- A summoned pet stays selected
        if ( pet == UNKNOWN and #pets > 0 ) then
            self.selectedPet = pets[1];
        else
            self.selectedPet = pet;
        end
    end
    return self.selectedPet;
end

function Armory:GetDodgeChance()
    return self:SetGetCharacterValue("DodgeChance", _G.GetDodgeChance());
end

function Armory:GetExpertise()
    return self:SetGetCharacterValue("Expertise", _G.GetExpertise());
end

function Armory:GetGuildInfo(unit)
    return self:SetGetCharacterValue("Guild", _G.GetGuildInfo("player"));
end

function Armory:GetInventoryItemCount(unit, index)
    if ( index ) then
        return self:SetGetCharacterValue("InventoryItemCount"..index, _G.GetInventoryItemCount("player", index));
    end
end

function Armory:GetInventoryItemLink(unit, index)
    if ( index ) then
        if ( index >= INVSLOT_FIRST_EQUIPPED and index <= INVSLOT_LAST_EQUIPPED ) then
            return self:GetCharacterValue("InventoryItemLink"..index);
        elseif ( not ArmoryInventoryFrame.bankOpen and self:IsCharacterBankSlot(index) ) then
            return self:GetCharacterValue("InventoryItemLink"..index);
        else
            return self:SetGetCharacterValue("InventoryItemLink"..index, _G.GetInventoryItemLink(unit, index));
        end
    end
end

function Armory:GetInventoryItemTexture(unit, index)
    if ( index ) then
        if ( not ArmoryInventoryFrame.bankOpen and self:IsCharacterBankSlot(index) ) then
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
    local getFoodTypes = _G.GetPetFoodTypes or (C_PetInfo and C_PetInfo.GetPetFoodTypes);
    if ( getFoodTypes ) then
        return self:SetGetPetValue("FoodTypes", getFoodTypes());
    elseif ( self:PetExists(self:GetCurrentPet()) ) then
        -- no live API (Retail): use the value stored from the stable
        return self:GetPetValue(self:GetCurrentPet(), "FoodTypes");
    end
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
            return C_Spell.GetSpellTexture(112866);
        elseif ( creatureFamily == "Voidlord" ) then
            return C_Spell.GetSpellTexture(112867);
        elseif ( creatureFamily == "Observer" ) then
            return C_Spell.GetSpellTexture(112868);
        elseif ( creatureFamily == "Shivarra" ) then
            return C_Spell.GetSpellTexture(112869);
        elseif ( creatureFamily == "Wrathguard" ) then
            return C_Spell.GetSpellTexture(030146);
        end
        return "Interface\\Icons\\Spell_Shadow_Summon"..creatureFamily;
    else
        return "Interface\\Icons\\INV_Misc_QuestionMark";
    end
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

-- Not every race has a portrait in the game. Armory brings its own for these races (cut from
-- Interface\Glues\CharacterCreate\CharacterCreateIcons); any other race without one gets the generic portrait.
local OWN_PORTRAITS = { EarthenDwarf = true, Harronir = true };
local portraitExists = {};
local function PortraitExists(portrait)
    if ( portraitExists[portrait] == nil ) then
        portraitExists[portrait] = not _G.GetFileIDFromPath or _G.GetFileIDFromPath(portrait) ~= nil;
    end
    return portraitExists[portrait];
end

function Armory:GetPortraitTexture(unit)
    local portrait = "Interface\\CharacterFrame\\TemporaryPortrait";

    if ( strlower(unit) == "pet" ) then
        portrait = portrait .. "-Pet";
    else
        local sex = self:UnitSex(unit);
        local _, raceEn = self:UnitRace(unit);
        local suffix;
        if ( raceEn and sex == 2 ) then
            suffix = "-Male-" .. raceEn;
        elseif ( raceEn and sex == 3 ) then
            suffix = "-Female-" .. raceEn;
        end
        if ( suffix ) then
            if ( PortraitExists(portrait .. suffix) ) then
                portrait = portrait .. suffix;
            elseif ( OWN_PORTRAITS[raceEn] ) then
                portrait = "Interface\\AddOns\\Armory\\Artwork\\TemporaryPortrait" .. suffix;
            end
        end
    end

    return portrait;
end

function Armory:GetPVPLifetimeStats()
    return self:SetGetCharacterValue("PVPLifetimeStats", _G.GetPVPLifetimeStats());
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

function Armory:GetWeeklyQuestResetTime()
    return time() + C_DateAndTime.GetSecondsUntilWeeklyReset();
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

function Armory:IsCharacterNewlyBoosted()
    return self:SetGetCharacterValue("IsNewlyBoosted", _G.IsCharacterNewlyBoosted());
end

function Armory:IsResting()
   return self:SetGetCharacterValue("IsResting", _G.IsResting());
end

function Armory:IsXPUserDisabled()
   return self:SetGetCharacterValue("IsXPUserDisabled", _G.IsXPUserDisabled());
end

function Armory:PetExists(pet, unit)
    local dbEntry = self.selectedDbBaseEntry;

    if ( unit == "player" ) then
        dbEntry = self.playerDbBaseEntry;
    end

    return dbEntry and dbEntry:Contains("Pets", pet);
end

----------------------------------------------------------

local HAS_GEAR_SETS = Armory.isMainline;

-- Time left of an owned auction: Mainline knows the duration, Classic only a category (short, medium, long, very long)
local FormatAuctionTimeLeft;
if ( Armory.isClassic ) then
    FormatAuctionTimeLeft = function(timeLeft, remaining)
        local timeLeftScanned = SecondsToTime(remaining, true);
        if ( timeLeftScanned ~= "" ) then
            timeLeftScanned = " "..string.format(GUILD_BANK_LOG_TIME, timeLeftScanned);
        end
        return (_G["AUCTION_TIME_LEFT"..timeLeft] or "?")..timeLeftScanned;
    end;
else
    FormatAuctionTimeLeft = function(timeLeft, remaining)
        return SecondsToTime(timeLeft - remaining, true);
    end;
end

function Armory:SetBagItem(id, index)
    local link, tinker, anchor = self:GetContainerItemLink(id, index);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link, tinker, anchor);

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
                local tooltipLines = self:Tooltip2Table(GameTooltip);
                table.insert(tooltipLines, 2, self:Text2String(FormatAuctionTimeLeft(timeLeft, remaining), 1.0, 1.0, 0.6));
                self:Table2Tooltip(GameTooltip, tooltipLines);
                GameTooltip:Show();
            end

        elseif ( HAS_GEAR_SETS and not self:IsDummyContainer(id) ) then
            self:AddEquipmentSet(GameTooltip);

        end
    end
end

function Armory:SetInventoryItem(unit, index, dontShow, tooltip, link)
    if ( index ) then
        local hasItem, hasCooldown, repairCost, tinker, anchor;
        if ( link ) then
            hasItem = true;
        else
            hasItem, hasCooldown, repairCost = self:GetInventoryItem(index);
            link, tinker, anchor = self:GetInventoryItemLink("player", index);
        end
        if ( link and hasItem and not dontShow ) then
            if ( not tooltip ) then
                self:SetHyperlink(GameTooltip, link, tinker, anchor);
                if ( HAS_GEAR_SETS ) then
                    self:AddEquipmentSet(GameTooltip);
                end
            else
                self:SetHyperlink(tooltip, link, tinker, anchor);
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

function Armory:IsMetaActive(unit)
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        if ( self:GetCharacterValue("IsMetaActive"..slot, unit) ) then
            return true;
        end
    end
end

function Armory:GetInventoryItemInfo(index, unit)
    local hasItem, hasCooldown, repairCost = self:GetCharacterValue("InventoryItem"..index, unit);
    local link, tinker, anchor, emptySockets = self:GetCharacterValue("InventoryItemLink"..index, unit);
    return hasItem, hasCooldown, repairCost, link, tinker, anchor, emptySockets;
end

function Armory:SetItemLink(button, link)
    -- stub to enable hooks
    button.link = link;
end

-- Replaces Blizzard's removed SetPortraitToTexture: shows the texture as a circle.
-- The mask has to be set before the texture, as Blizzard does.
function Armory:SetPortraitToTexture(texture, file)
    texture:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask");
    texture:SetTexture(file);
end

function Armory:SetQuestLogItem(itemType, id)
    local link = self:GetQuestLogItemLink(itemType, id);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);
    end
end

function Armory:SetQuestLogRewardSpell(id)
    local link = self:GetQuestLogSpellLink(id);
    if ( link ) then
        self:SetHyperlink(GameTooltip, link);
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

function Armory:UnitFactionGroup(unit)
    return self:SetGetCharacterValue("FactionGroup", _G.UnitFactionGroup("player"));
end

-- Mainline has no UnitHasMana
local UnitHasMana = Armory.isClassic and _G.UnitHasMana or function(unit)
    if ( _G.UnitPowerMax(unit, Enum.PowerType.Mana) > 0 ) then
        return 1;
    end
    return nil;
end;

function Armory:UnitHasMana(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("HasMana", UnitHasMana(unit));
    end
    return self:SetGetCharacterValue("HasMana", UnitHasMana(unit));
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

----------------------------------------------------------
-- Miscellaneous stubs
----------------------------------------------------------

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
