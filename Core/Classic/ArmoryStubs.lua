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

-- Stubs that only Classic has (Era and TBC); the shared ones are in Core\ArmoryStubs.lua

function Armory:GetArenaCurrency()
	local arenaCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID);
    return self:SetGetCharacterValue("ArenaCurrency", arenaCurrencyInfo.quantity);
end

function Armory:GetArmorPenetration()
    return self:SetGetCharacterValue("ArmorPenetration", _G.GetArmorPenetration());
end

function Armory:GetCritChanceFromAgility(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("CritChanceFromAgility", _G.GetCritChanceFromAgility(unit));
    end
    return self:SetGetCharacterValue("CritChanceFromAgility", _G.GetCritChanceFromAgility(unit));
end

function Armory:GetDodgeBlockParryChanceFromDefense()
    local base, modifier = Armory:UnitDefense("player");
    local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (Armory:UnitLevel("player")*5));
    defensePercent = max(defensePercent, 0);
    return defensePercent;
end

function Armory:GetExpertisePercent()
    return self:SetGetCharacterValue("ExpertisePercent", _G.GetExpertisePercent());
end

function Armory:GetHonorCurrency()
    local honorCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID);
    return self:SetGetCharacterValue("HonorCurrency", honorCurrencyInfo.quantity);
end

function Armory:GetPetHappiness()
    return self:SetGetPetValue("Happiness", _G.GetPetHappiness());
end

function Armory:GetPetLoyalty()
    return self:SetGetPetValue("Loyalty", _G.GetPetLoyalty());
end

function Armory:GetPetTrainingPoints()
    return self:SetGetPetValue("TrainingPoints", _G.GetPetTrainingPoints());
end

function Armory:GetPVPRankProgress()
    return self:SetGetCharacterValue("PVPRankProgress", _G.GetPVPRankProgress());
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

function Armory:GetSpellCritChanceFromIntellect(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("SpellCritChanceFromIntellect", _G.GetSpellCritChanceFromIntellect(unit));
    end
    return self:SetGetCharacterValue("SpellCritChanceFromIntellect", _G.GetSpellCritChanceFromIntellect(unit));
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

function Armory:GetWeeklyResetTime()
	local day = self:GetWeeklyResetDay();
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

function Armory:IsInWeek(timestamp, weekOffset)
    local eow = self:GetWeeklyResetTime() + (weekOffset or 0) * 7 * 24 * 60 * 60;
    local bow = eow - 7 * 24 * 60 * 60;
    return timestamp > bow and timestamp < eow;
end

function Armory:HasWandEquipped()
    return self:SetGetCharacterValue("HasWandEquipped", _G.HasWandEquipped());
end

-- Classic has no currency module
function Armory:CountCurrency(link)
    return 0;
end

-- Classic has no quest history (dailies and weeklies)
function Armory:GetNumQuestHistoryEntries()
    return 0, 0;
end

-- Classic has no Raid Finder, and its world bosses have no lockout (GetNumSavedWorldBosses is always 0)
function Armory:ClearRaidFinder()
end

function Armory:UpdateRaidFinderInfo()
end

function Armory:UpdateRaidFinderInProgress()
    return false;
end

function Armory:GetNumRaidFinderDungeons()
    return 0;
end

function Armory:ClearWorldBosses()
end

function Armory:UpdateWorldBosses()
end

function Armory:UpdateWorldBossesInProgress()
    return false;
end

function Armory:GetNumSavedWorldBosses()
    return 0;
end

function Armory:SetTalent(index, id, inspect)
    local tooltipLines = self:GetTalentTooltip(index, id);
    if ( tooltipLines ) then
        self:Table2Tooltip(GameTooltip, tooltipLines);
        GameTooltip:Show();
    end
end

function Armory:UnitAttackBothHands(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("AttackBothHands", _G.UnitAttackBothHands(unit));
    end
    return self:SetGetCharacterValue("AttackBothHands", _G.UnitAttackBothHands(unit));
end

function Armory:UnitCharacterPoints(unit)
    return self:SetGetCharacterValue("CharacterPoints", _G.UnitCharacterPoints("player"));
end

function Armory:UnitDefense(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Defense", _G.UnitDefense(unit));
    end
    return self:SetGetCharacterValue("Defense", _G.UnitDefense(unit));
end

function Armory:UnitHealth(unit)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Health", _G.UnitHealth(unit));
    end
    return self:SetGetCharacterValue("Health", _G.UnitHealth(unit));
end

function Armory:UnitPower(unit, powerType)
    if ( strlower(unit) == "pet" ) then
        return self:SetGetPetValue("Power", _G.UnitPower(unit, powerType));
    end
    return self:SetGetCharacterValue("Power", _G.UnitPower(unit, powerType));
end

function Armory:UnitPVPRank(unit)
    return self:SetGetCharacterValue("PVPRank", _G.UnitPVPRank("player"));
end

function Armory:UnitResistance(unit, index)
    if ( index ) then
        if ( strlower(unit) == "pet" ) then
            return self:SetGetPetValue("Resistance"..index, _G.UnitResistance(unit, index));
        end
        return self:SetGetCharacterValue("Resistance"..index, _G.UnitResistance(unit, index));
    end
end

function Armory:IsCharacterBankSlot(index)
    if ( index ) then
        return index >= C_Container.ContainerIDToInventoryID(NUM_BAG_SLOTS + 1) and index <= C_Container.ContainerIDToInventoryID(NUM_BAG_SLOTS + NUM_BANKBAGSLOTS);
    end
end

function Armory:IsPersistentPet()
    return (_G.UnitName("pet") or UNKNOWN) ~= UNKNOWN and _G.UnitCreatureFamily("pet");
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

function Armory:SetPortraitTexture(frame, unit)
    self:SetPortraitToTexture(frame, self:GetPortraitTexture(unit));
    return "Portrait1";
end

function Armory:SetSpell(id, bookType)
    local tooltipLines = self:GetSpellTooltip(id, bookType);
    if ( tooltipLines ) then
        self:Table2Tooltip(GameTooltip, tooltipLines, 2);
        GameTooltip:Show();
    end
end
