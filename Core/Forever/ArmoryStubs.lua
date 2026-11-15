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

-- Stubs that only Forever has, in addition to Core\Mainline\ArmoryStubs.lua; mostly for the paper doll

-- Forever has the pet happiness and loyalty of Classic, in C_PetInfo
function Armory:GetPetHappiness()
    return self:SetGetPetValue("Happiness", C_PetInfo.GetPetHappiness());
end

function Armory:GetPetLoyalty()
    return self:SetGetPetValue("Loyalty", C_PetInfo.GetPetLoyalty());
end

-- Forever returns base, real, effective and bonus (Classic: base, total, bonus and minus)
function Armory:UnitResistance(unit, index)
    if ( index ) then
        if ( strlower(unit) == "pet" ) then
            return self:SetGetPetValue("Resistance"..index, _G.UnitResistance(unit, index));
        end
        return self:SetGetCharacterValue("Resistance"..index, _G.UnitResistance(unit, index));
    end
end

----------------------------------------------------------
-- Forever: weapon skills and wands
----------------------------------------------------------

-- Same mapping as Blizzard's damage tooltip (Blizzard_UIPanels_Game\Camelot\PaperDollFrameStats.lua)
local WEAPON_SUBCLASS_TO_SKILL_ID = {
    [Enum.ItemWeaponSubclass.Sword1H]  = 43,  -- Swords
    [Enum.ItemWeaponSubclass.Axe1H]    = 44,  -- Axes
    [Enum.ItemWeaponSubclass.Bows]     = 45,  -- Bows
    [Enum.ItemWeaponSubclass.Guns]     = 46,  -- Guns
    [Enum.ItemWeaponSubclass.Mace1H]   = 54,  -- Maces
    [Enum.ItemWeaponSubclass.Sword2H]  = 55,  -- Two-Handed Swords
    [Enum.ItemWeaponSubclass.Staff]    = 136, -- Staves
    [Enum.ItemWeaponSubclass.Mace2H]   = 160, -- Two-Handed Maces
    [Enum.ItemWeaponSubclass.Axe2H]    = 172, -- Two-Handed Axes
    [Enum.ItemWeaponSubclass.Dagger]   = 173, -- Daggers
    [Enum.ItemWeaponSubclass.Thrown]   = 176, -- Thrown
    [Enum.ItemWeaponSubclass.Crossbow] = 226, -- Crossbows
    [Enum.ItemWeaponSubclass.Wand]     = 228, -- Wands
    [Enum.ItemWeaponSubclass.Polearm]  = 229, -- Polearms
    [Enum.ItemWeaponSubclass.Unarmed]  = 162, -- Fist Weapons
};
local UNARMED_SKILL = 162;
local FERAL_WEAPON_SKILL = 3014;

local function GetEquippedWeaponSkillID(slot)
    if ( _G.GetShapeshiftForm() ~= 0 and select(2, _G.UnitClass("player")) == "DRUID" ) then
        return FERAL_WEAPON_SKILL;
    end

    local itemID = _G.GetInventoryItemID("player", slot);
    if ( not itemID ) then
        return UNARMED_SKILL;
    end

    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID);
    if ( classID ~= Enum.ItemClass.Weapon ) then
        return;
    end
    return WEAPON_SUBCLASS_TO_SKILL_ID[subclassID];
end

-- Forever replaces UnitAttackBothHands and UnitRangedAttack by the weapon skill of the slot
-- Returns name, rank, modifier, maxRank
function Armory:GetWeaponSkill(slot)
    local name, rank, modifier, maxRank;
    local skillLineID = GetEquippedWeaponSkillID(slot);
    local skillInfo = skillLineID and C_SkillInfo.GetSkillLineInfoByID(skillLineID);
    if ( skillInfo ) then
        name, rank, modifier, maxRank = skillInfo.name, skillInfo.rank, skillInfo.modifier, skillInfo.maxRank;
    end
    return self:SetGetCharacterValue("WeaponSkill"..slot, name, rank, modifier, maxRank);
end

-- Forever has no HasWandEquipped; look at the ranged slot instead
function Armory:HasWandEquipped()
    local isWand = false;
    local itemID = _G.GetInventoryItemID("player", INVSLOT_RANGED);
    if ( itemID ) then
        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID);
        isWand = classID == Enum.ItemClass.Weapon and subclassID == Enum.ItemWeaponSubclass.Wand;
    end
    return self:SetGetCharacterValue("HasWandEquipped", isWand);
end

----------------------------------------------------------
-- Forever: stats of the paperdoll
----------------------------------------------------------

-- The "ForStat" functions are computed with the player's own stat, never with the stat of a character that is being viewed
local function PlayerStat(index)
    local _, effectiveStat = _G.UnitStat("player", index);
    return effectiveStat or 0;
end

function Armory:GetCritChanceFromStat(index)
    return self:SetGetCharacterValue("CritChanceFromStat"..index, _G.GetCritChanceFromStat(index, PlayerStat(index)));
end

function Armory:GetSpellCritChanceFromStat(index)
    return self:SetGetCharacterValue("SpellCritChanceFromStat"..index, _G.GetSpellCritChanceFromStat(index, PlayerStat(index)));
end

function Armory:GetAttackPowerForPlayerStat(index)
    return self:GetAttackPowerForStat(index, PlayerStat(index));
end

function Armory:GetRangedAttackPowerForStat(index)
    return self:SetGetCharacterValue("RangedAttackPowerForStat"..index, _G.GetRangedAttackPowerForStat(index, PlayerStat(index)));
end

function Armory:GetArmorPenetration()
    return self:SetGetCharacterValue("ArmorPenetration", _G.GetArmorPenetration());
end

function Armory:GetHealthRegen()
    return self:SetGetCharacterValue("HealthRegen", _G.GetHealthRegen());
end

function Armory:GetHealthRegenFromSpirit()
    return self:SetGetCharacterValue("HealthRegenFromSpirit", _G.GetHealthRegenFromSpirit());
end

function Armory:GetManaRegenFromSpirit()
    return self:SetGetCharacterValue("ManaRegenFromSpirit", _G.GetManaRegenFromSpirit());
end

function Armory:GetOffhandHitModifier()
    return self:SetGetCharacterValue("OffhandHitModifier", _G.GetOffhandHitModifier());
end

function Armory:GetRangedHitModifier()
    return self:SetGetCharacterValue("RangedHitModifier", _G.GetRangedHitModifier());
end

-- Returns the haste and the haste from the quiver
function Armory:GetRangedHaste()
    return self:SetGetCharacterValue("RangedHaste", _G.GetRangedHaste());
end

function Armory:UnitSpellHaste(unit)
    return self:SetGetCharacterValue("SpellHaste", _G.UnitSpellHaste("player"));
end

-- Returns base and modifier
function Armory:UnitDefenseSkill(unit)
    return self:SetGetCharacterValue("DefenseSkill", _G.UnitDefenseSkill("player"));
end

function Armory:IsDualWielding()
    return self:SetGetCharacterValue("IsDualWielding", _G.IsDualWielding());
end