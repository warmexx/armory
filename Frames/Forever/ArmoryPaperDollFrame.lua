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

local function format(fmt, ...)
    return string.format(fmt or "", ...);
end

for _, invType in ipairs({ "INVTYPE_CROSSBOW", "INVTYPE_GUN", "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_RELIC", "INVTYPE_THROWN", "INVTYPE_WAND" }) do
    ARMORY_SLOTINFO[invType] = "RangedSlot";
end
ARMORY_SLOTID.RangedSlot = 18;

function ArmoryHealth_OnLoad(self)
    self:RegisterUnitEvent("UNIT_HEALTH", "player");
    self:RegisterUnitEvent("UNIT_MAXHEALTH", "player");

    ArmoryHealthTextFrameLabel:SetText(strupper(HEALTH)..":");
    ArmoryHealth.tooltipTitle = HEALTH;
    ArmoryHealth.tooltipText = NEWBIE_TOOLTIP_HEALTHBAR;
end

function ArmoryHealth_OnEvent(self, event, ...)
    if ( Armory:CanHandleEvents() ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateHealthBar);
    end
end

function ArmoryMana_OnLoad(self)
    self:RegisterEvent("UNIT_DISPLAYPOWER");
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", "player");
    self:RegisterUnitEvent("UNIT_MAXPOWER", "player");
end

function ArmoryMana_OnEvent(self, event, unit)
    if ( Armory:CanHandleEvents() and unit == "player" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateManaBar);
    end
end

function ArmoryPaperDollFrame_SetStatDropDown()
    -- Forever: left and right dropdown as in Armory TBC
    local _, classFileName = Armory:UnitClass("player");
    classFileName = strupper(classFileName or "");
    ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION = "PLAYERSTAT_BASE_STATS";
    if ( classFileName == "MAGE" or classFileName == "PRIEST" or classFileName == "WARLOCK" or classFileName == "DRUID" ) then
        ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = "PLAYERSTAT_SPELL_COMBAT";
    elseif ( classFileName == "HUNTER" ) then
        ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = "PLAYERSTAT_RANGED_COMBAT";
    else
        ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = "PLAYERSTAT_MELEE_COMBAT";
    end
end

----------------------------------------------------------
-- Forever: stats as in Armory TBC, two dropdowns of six rows
-- Values and tooltips follow Blizzard_UIPanels_Game\Camelot\PaperDollFrame.lua and PaperDollFrameStats.lua
----------------------------------------------------------

local ARMOR_PER_AGILITY = 2;
local BLOCK_VALUE_PER_STRENGTH = 20;
local SKILL_RANKS_PER_SKILL_LEVEL = 5;
local STAT_PER_DEFENSE = 0.04;
local SPIRIT_STANDING_PENALTY = 0.75;
local HOLY_SCHOOL = 2;
local PRIMARY_STATS = { "STRENGTH", "AGILITY", "STAMINA", "INTELLECT", "SPIRIT" };

local PLAYERSTAT_OPTIONS = {
    "PLAYERSTAT_BASE_STATS",
    "PLAYERSTAT_MELEE_COMBAT",
    "PLAYERSTAT_RANGED_COMBAT",
    "PLAYERSTAT_SPELL_COMBAT",
    "PLAYERSTAT_DEFENSES",
};

-- Forever's own code does not use the PLAYERSTAT_ strings
local PLAYERSTAT_NAMES = {
    PLAYERSTAT_BASE_STATS = PLAYERSTAT_BASE_STATS or STAT_CATEGORY_ATTRIBUTES or "Base Stats",
    PLAYERSTAT_MELEE_COMBAT = PLAYERSTAT_MELEE_COMBAT or MELEE or "Melee",
    PLAYERSTAT_RANGED_COMBAT = PLAYERSTAT_RANGED_COMBAT or RANGED or "Ranged",
    PLAYERSTAT_SPELL_COMBAT = PLAYERSTAT_SPELL_COMBAT or SPELLS or "Spell",
    PLAYERSTAT_DEFENSES = PLAYERSTAT_DEFENSES or DEFENSE or "Defenses",
};

-- Forever's tooltip strings are not in the Lua export; a mismatch in arguments should not break the frame
local function SafeFormat(fmt, ...)
    if ( fmt ) then
        local ok, text = pcall(format, fmt, ...);
        if ( ok ) then
            return text;
        end
    end
end

local function AddLine(text, line)
    if ( not line ) then
        return text;
    elseif ( not text ) then
        return line;
    end
    return text.."\n"..line;
end

local function GetClassFileName()
    local _, classFileName = Armory:UnitClass("player");
    return strupper(classFileName or "");
end

local function SetLabelAndText(statFrame, label, text)
    _G[statFrame:GetName().."Label"]:SetText(format(STAT_FORMAT, label));
    _G[statFrame:GetName().."StatText"]:SetText(text);
end

local function TooltipTitle(label, text)
    return HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, label).." "..text..FONT_COLOR_CODE_CLOSE;
end

local function FormatPercentage(value)
    return format("%.1F%%", value or 0);
end

local function FormatStat(statFrame, label, name, base, posBuff, negBuff)
    local valueText, tooltipText = PaperDollFormatStat(name, base, posBuff, negBuff);
    SetLabelAndText(statFrame, label, valueText);
    statFrame.tooltip = tooltipText;
end

local function FormatSkill(rank, modifier, maxRank)
    if ( (modifier or 0) == 0 ) then
        return rank.."/"..maxRank;
    end
    return rank.." ("..modifier..")/"..maxRank;
end

local function HasRanged()
    local rangedTexture = Armory:GetInventoryItemTexture("player", INVSLOT_RANGED);
    return rangedTexture and not Armory:UnitHasRelicSlot("player");
end

-- Primary stats

local function GetStatTooltip2(statIndex, effectiveStat)
    local classFileName = GetClassFileName();
    local stat = PRIMARY_STATS[statIndex];
    local text = _G[classFileName.."_"..stat.."_TOOLTIP"] or _G["DEFAULT_"..stat.."_TOOLTIP"];
    local noMana = classFileName == "WARRIOR" or classFileName == "ROGUE";

    if ( statIndex == 1 ) then
        return SafeFormat(text, Armory:GetAttackPowerForPlayerStat(statIndex) or 0, floor(effectiveStat / BLOCK_VALUE_PER_STRENGTH));

    elseif ( statIndex == 2 ) then
        local dodge = (Armory:GetDodgeChanceFromAttribute() or 0) * 100;
        local armor = effectiveStat * ARMOR_PER_AGILITY;
        local crit = (Armory:GetCritChanceFromStat(statIndex) or 0) * 100;
        local attackPower = Armory:GetAttackPowerForPlayerStat(statIndex) or 0;
        local rangedAttackPower = Armory:GetRangedAttackPowerForStat(statIndex) or 0;
        if ( classFileName == "ROGUE" or classFileName == "HUNTER" ) then
            return SafeFormat(text, crit, attackPower, rangedAttackPower, armor, dodge);
        elseif ( classFileName == "DRUID" ) then
            return SafeFormat(text, crit, effectiveStat, armor, dodge);
        elseif ( classFileName == "WARRIOR" ) then
            return SafeFormat(text, crit, rangedAttackPower, armor, dodge);
        end
        return SafeFormat(text, crit, armor, dodge);

    elseif ( statIndex == 3 ) then
        local bonus = min(STAMINA_BREAK, effectiveStat) + (max(STAMINA_BREAK, effectiveStat) - STAMINA_BREAK) * (Armory:UnitHPPerStamina("player") or 0);
        return SafeFormat(text, tostring(bonus));

    elseif ( statIndex == 4 ) then
        local spellCrit = (Armory:GetSpellCritChanceFromStat(statIndex) or 0) * 100;
        if ( noMana ) then
            return SafeFormat(text, spellCrit);
        end
        local manaBonus = min(INTELLECT_BREAK, effectiveStat) + (max(INTELLECT_BREAK, effectiveStat) - INTELLECT_BREAK) * MANA_PER_INTELLECT;
        return SafeFormat(text, tostring(manaBonus), spellCrit);

    elseif ( statIndex == 5 ) then
        local healthRegenFromSpirit = (Armory:GetHealthRegenFromSpirit() or 0) * SPIRIT_STANDING_PENALTY;
        local manaRegenFromSpirit = Armory:GetManaRegenFromSpirit() or 0;
        local healthRegen = Armory:GetHealthRegen() or 0;
        local manaRegen = Armory:GetManaRegen() or 0;
        if ( noMana ) then
            text = SafeFormat(text, healthRegenFromSpirit * 5, healthRegen * 5);
        else
            text = SafeFormat(text, healthRegenFromSpirit * 5, manaRegenFromSpirit * 5, healthRegen * 5, manaRegen * 5);
        end
        if ( text and SPIRIT_STANDING_WARNING ) then
            text = text.."\n\n"..SPIRIT_STANDING_WARNING;
        end
        return text;
    end
end

local function SetStat(statFrame, statIndex)
    local stat, effectiveStat, posBuff, negBuff = Armory:UnitStat("player", statIndex);
    local statName = _G["SPELL_STAT"..statIndex.."_NAME"];
    if ( not stat ) then
        SetLabelAndText(statFrame, statName, NOT_APPLICABLE);
        return;
    end

    local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..statName.." ";
    if ( posBuff == 0 and negBuff == 0 ) then
        SetLabelAndText(statFrame, statName, effectiveStat);
        statFrame.tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE;
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
        statFrame.tooltip = tooltipText;

        -- If there are any negative buffs then show the main number in red even if there are
        -- positive buffs. Otherwise show in green.
        if ( negBuff < 0 ) then
            SetLabelAndText(statFrame, statName, RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
        else
            SetLabelAndText(statFrame, statName, GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
        end
    end

    local ok, tooltip2 = pcall(GetStatTooltip2, statIndex, effectiveStat);
    statFrame.tooltip2 = ok and tooltip2 or nil;
end

-- Forever: UnitArmor returns baseline, effective, armor and bonus
local function SetArmor(statFrame)
    local _, effectiveArmor, _, bonusArmor = Armory:UnitArmor("player");
    if ( not effectiveArmor ) then
        SetLabelAndText(statFrame, ARMOR, NOT_APPLICABLE);
        return;
    end

    SetLabelAndText(statFrame, ARMOR, PaperDollFrame_FormatBonusValue(BreakUpLargeNumbers(effectiveArmor), bonusArmor or 0));
    statFrame.tooltip = TooltipTitle(ARMOR, BreakUpLargeNumbers(effectiveArmor));
    statFrame.tooltip2 = SafeFormat(STAT_ARMOR_TOOLTIP, PaperDollFrame_GetArmorReduction(effectiveArmor, Armory:UnitLevel("player")));
end

-- Resistances, the column next to the talents
-- Forever: UnitResistance returns base, real, effective and bonus
local function SetResistances()
    local unitLevel = max(Armory:UnitLevel("player") or 1, 1);
    for i = 1, 5 do
        local text = _G["ArmoryMagicResText"..i];
        local frame = _G["ArmoryMagicResFrame"..i];
        local damageClass = frame:GetID();
        local _, _, effectiveResistance, bonusResistance = Armory:UnitResistance("player", damageClass);
        effectiveResistance = effectiveResistance or 0;

        text:SetText(PaperDollFrame_FormatBonusValue(BreakUpLargeNumbers(effectiveResistance), bonusResistance or 0));

        local resistanceName = _G["DAMAGE_SCHOOL"..(damageClass + 1)] or "";
        frame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..resistanceName.." "..effectiveResistance..FONT_COLOR_CODE_CLOSE;
        frame.tooltip2 = SafeFormat(RESISTANCE_TOOLTIP_SUBTEXT, _G["RESISTANCE_TYPE"..damageClass], unitLevel, floor(ExpectedSpellResistance(unitLevel, effectiveResistance) * 100));
    end
end

-- Melee and ranged

local colorPos = "|cff20ff20";
local colorNeg = "|cffff2020";

local function FormatDamageText(displayMin, displayMax, color)
    local text;
    if ( displayMin < 100 and displayMax < 100 ) then
        text = displayMin.." - "..displayMax;
    else
        text = displayMin.."-"..displayMax;
    end
    if ( color ) then
        text = color..text.."|r";
    end
    return text;
end

local function FormatDamageTooltip(minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent)
    local tooltip = max(floor(minDamage), 1).." - "..max(ceil(maxDamage), 1);
    if ( physicalBonusPos > 0 ) then
        tooltip = tooltip..colorPos.." +"..physicalBonusPos.."|r";
    end
    if ( physicalBonusNeg < 0 ) then
        tooltip = tooltip..colorNeg.." "..physicalBonusNeg.."|r";
    end
    if ( percent > 1 ) then
        tooltip = tooltip..colorPos.." x"..floor(percent * 100 + 0.5).."%|r";
    elseif ( percent < 1 ) then
        tooltip = tooltip..colorNeg.." x"..floor(percent * 100 + 0.5).."%|r";
    end
    return tooltip;
end

local function AddWeaponSkillLine(slot)
    local name, rank, modifier, maxRank = Armory:GetWeaponSkill(slot);
    if ( rank ) then
        GameTooltip:AddDoubleLine(format(WEAPON_SKILL_PAPERDOLLFRAME_FORMAT, name), FormatSkill(rank, modifier, maxRank), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    end
end

local function AddDamageLines(attackSpeed, damage, dps)
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, ATTACK_SPEED_SECONDS), format("%.2F", attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, DAMAGE), damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:AddDoubleLine(format(STAT_FORMAT, STAT_DPS_SHORT or DAMAGE_PER_SECOND), format("%.1F", dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
end

-- Forever: Blizzard's CharacterDamageFrame_OnEnter reads the weapon skill of the logged in character
function ArmoryPaperDollDamageFrame_OnEnter(self)
    if ( not self.damage ) then
        return;
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(self.tooltipLabel or INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    AddDamageLines(self.attackSpeed or 0, self.damage, self.dps or 0);
    AddWeaponSkillLine(self.slot or INVSLOT_MAINHAND);

    -- Check for offhand weapon
    if ( self.offhandAttackSpeed ) then
        GameTooltip:AddLine("\n");
        GameTooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        AddDamageLines(self.offhandAttackSpeed, self.offhandDamage, self.offhandDps or 0);
        AddWeaponSkillLine(INVSLOT_OFFHAND);
    end
    GameTooltip:Show();
end

local function SetDamage(statFrame)
    statFrame:SetScript("OnEnter", ArmoryPaperDollDamageFrame_OnEnter);
    statFrame.damage = nil;

    local speed, offhandSpeed = Armory:UnitAttackSpeed("player");
    local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = Armory:UnitDamage("player");
    if ( not minDamage ) then
        SetLabelAndText(statFrame, DAMAGE, NOT_APPLICABLE);
        return;
    end
    local displayMin = max(floor(minDamage), 1);
    local displayMax = max(ceil(maxDamage), 1);

    if ( percent == 0 ) then
        minDamage = 0;
        maxDamage = 0;
    else
        minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
    end

    local baseDamage = (minDamage + maxDamage) * 0.5;
    local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
    local totalBonus = (fullDamage - baseDamage);
    local damagePerSecond = 0;
    if ( (speed or 0) > 0 ) then
        damagePerSecond = (max(fullDamage, 1) / speed);
    end

    -- epsilon check
    if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
        totalBonus = 0.0;
    end

    if ( totalBonus == 0 ) then
        SetLabelAndText(statFrame, DAMAGE, FormatDamageText(displayMin, displayMax));
        statFrame.damage = max(floor(minDamage), 1).." - "..max(ceil(maxDamage), 1);
    else
        SetLabelAndText(statFrame, DAMAGE, FormatDamageText(displayMin, displayMax, totalBonus > 0 and colorPos or colorNeg));
        statFrame.damage = FormatDamageTooltip(minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent);
    end
    statFrame.tooltipLabel = INVTYPE_WEAPONMAINHAND;
    statFrame.slot = INVSLOT_MAINHAND;
    statFrame.attackSpeed = speed;
    statFrame.dps = damagePerSecond;

    -- If there's an offhand speed then add the offhand info to the tooltip
    if ( offhandSpeed and percent ~= 0 ) then
        minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

        local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
        local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        local offhandDamagePerSecond = 0;
        if ( offhandSpeed > 0 ) then
            offhandDamagePerSecond = (max(offhandFullDamage, 1) / offhandSpeed);
        end
        statFrame.offhandDamage = FormatDamageTooltip(minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent);
        statFrame.offhandAttackSpeed = offhandSpeed;
        statFrame.offhandDps = offhandDamagePerSecond;
    else
        statFrame.offhandAttackSpeed = nil;
    end
end

local function SetRangedDamage(statFrame)
    statFrame:SetScript("OnEnter", ArmoryPaperDollDamageFrame_OnEnter);
    statFrame.damage = nil;
    statFrame.offhandAttackSpeed = nil;

    -- If no ranged attack then set to n/a
    if ( not HasRanged() ) then
        SetLabelAndText(statFrame, DAMAGE, NOT_APPLICABLE);
        return;
    end

    local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = Armory:UnitRangedDamage("player");
    if ( not rangedAttackSpeed or (percent or 0) == 0 ) then
        SetLabelAndText(statFrame, DAMAGE, NOT_APPLICABLE);
        return;
    end
    local displayMin = max(floor(minDamage), 1);
    local displayMax = max(ceil(maxDamage), 1);

    minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
    maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

    local baseDamage = (minDamage + maxDamage) * 0.5;
    local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
    local totalBonus = (fullDamage - baseDamage);
    local damagePerSecond;
    if ( rangedAttackSpeed == 0 ) then
        -- Egan's Blaster!!!
        damagePerSecond = math.huge;
    else
        damagePerSecond = (max(fullDamage, 1) / rangedAttackSpeed);
    end

    if ( totalBonus == 0 ) then
        SetLabelAndText(statFrame, DAMAGE, FormatDamageText(displayMin, displayMax));
        statFrame.damage = max(floor(minDamage), 1).." - "..max(ceil(maxDamage), 1);
    else
        SetLabelAndText(statFrame, DAMAGE, FormatDamageText(displayMin, displayMax, totalBonus > 0 and colorPos or colorNeg));
        statFrame.damage = FormatDamageTooltip(minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent);
    end
    statFrame.tooltipLabel = INVTYPE_RANGED;
    statFrame.slot = INVSLOT_RANGED;
    statFrame.attackSpeed = rangedAttackSpeed;
    statFrame.dps = damagePerSecond;
end

local function SetAttackSpeed(statFrame)
    local speed, offhandSpeed = Armory:UnitAttackSpeed("player");
    if ( not speed ) then
        SetLabelAndText(statFrame, WEAPON_SPEED, NOT_APPLICABLE);
        return;
    end
    local text = format("%.2F", speed);
    if ( offhandSpeed ) then
        text = text.." / "..format("%.2F", offhandSpeed);
    end
    SetLabelAndText(statFrame, WEAPON_SPEED, text);
    statFrame.tooltip = TooltipTitle(ATTACK_SPEED, text);
    statFrame.tooltip2 = SafeFormat(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(Armory:GetMeleeHaste() or 0));
end

local function SetRangedAttackSpeed(statFrame)
    local speed = HasRanged() and Armory:UnitRangedDamage("player");
    if ( not speed ) then
        SetLabelAndText(statFrame, WEAPON_SPEED, NOT_APPLICABLE);
        return;
    end
    local text = format("%.2F", speed);
    local haste, quiverHaste = Armory:GetRangedHaste();
    SetLabelAndText(statFrame, WEAPON_SPEED, text);
    statFrame.tooltip = TooltipTitle(ATTACK_SPEED, text);
    statFrame.tooltip2 = SafeFormat(CR_HASTE_RANGED_TOOLTIP, (haste or 0) + (quiverHaste or 0));
end

local function SetAttackPower(statFrame)
    local base, posBuff, negBuff = Armory:UnitAttackPower("player");
    if ( not base ) then
        SetLabelAndText(statFrame, STAT_ATTACK_POWER, NOT_APPLICABLE);
        return;
    end
    local tooltip = _G[GetClassFileName().."_MELEE_ATTACK_POWER_TOOLTIP"] or MELEE_ATTACK_POWER_TOOLTIP;
    FormatStat(statFrame, STAT_ATTACK_POWER, MELEE_ATTACK_POWER, base, posBuff, negBuff);
    statFrame.tooltip2 = SafeFormat(tooltip, BreakUpLargeNumbers(max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER));
end

local function SetRangedAttackPower(statFrame)
    local base, posBuff, negBuff = Armory:UnitRangedAttackPower("player");
    if ( not base ) then
        SetLabelAndText(statFrame, STAT_ATTACK_POWER, NOT_APPLICABLE);
        return;
    end
    FormatStat(statFrame, STAT_ATTACK_POWER, RANGED_ATTACK_POWER, base, posBuff, negBuff);
    statFrame.tooltip2 = SafeFormat(RANGED_ATTACK_POWER_TOOLTIP, BreakUpLargeNumbers(max((base + posBuff + negBuff), 0) / ATTACK_POWER_MAGIC_NUMBER));
end

local function GetHitCapTooltip()
    return SafeFormat(_G["CR_"..GetClassFileName().."_HIT_CAP_TOOLTIP"] or CR_DEFAULT_HIT_CAP_TOOLTIP, Armory:UnitLevel("player"));
end

-- As in TBC, armor penetration is part of the tooltip of hit
local function GetArmorPenetrationLine()
    local armorPenetration = Armory:GetArmorPenetration() or 0;
    if ( armorPenetration > 0 ) then
        return SafeFormat(ARMOR_PENETRATION_TOOLTIP, armorPenetration);
    end
end

local function SetMeleeHit(statFrame)
    local ratingBonus = Armory:GetCombatRatingBonus(CR_HIT_MELEE);
    local meleeHit = ratingBonus + (Armory:GetHitModifier() or 0);
    local offhandHit = ratingBonus + (Armory:GetOffhandHitModifier() or 0);
    local text = FormatPercentage(meleeHit);

    SetLabelAndText(statFrame, STAT_HIT_CHANCE, text);
    statFrame.tooltip = TooltipTitle(STAT_HIT_CHANCE, text);
    statFrame.tooltip2 = SafeFormat(CR_HIT_MELEE_TOOLTIP, meleeHit);
    if ( offhandHit ~= meleeHit and Armory:IsDualWielding() ) then
        statFrame.tooltip2 = AddLine(statFrame.tooltip2, SafeFormat(CR_HIT_OFFHAND_TOOLTIP, offhandHit));
    end
    statFrame.tooltip2 = AddLine(statFrame.tooltip2, GetArmorPenetrationLine());
    statFrame.tooltip3 = GetHitCapTooltip();
end

local function SetRangedHit(statFrame)
    local rangedHit = Armory:GetCombatRatingBonus(CR_HIT_RANGED) + (Armory:GetRangedHitModifier() or 0);
    local text = FormatPercentage(rangedHit);

    SetLabelAndText(statFrame, STAT_HIT_CHANCE, text);
    statFrame.tooltip = TooltipTitle(STAT_HIT_CHANCE, text);
    statFrame.tooltip2 = AddLine(SafeFormat(CR_HIT_RANGED_TOOLTIP, rangedHit), GetArmorPenetrationLine());
    statFrame.tooltip3 = GetHitCapTooltip();
end

-- As in TBC, spell penetration is part of the tooltip of spell hit
local function SetSpellHit(statFrame)
    local spellHit = Armory:GetCombatRatingBonus(CR_HIT_SPELL) + (Armory:GetSpellHitModifier() or 0);
    local text = FormatPercentage(spellHit);

    SetLabelAndText(statFrame, STAT_HIT_CHANCE, text);
    statFrame.tooltip = TooltipTitle(STAT_HIT_CHANCE, text);
    statFrame.tooltip2 = SafeFormat(CR_HIT_SPELL_TOOLTIP, spellHit);

    local spellPenetration = Armory:GetSpellPenetration() or 0;
    if ( spellPenetration > 0 ) then
        local resistanceAverage = spellPenetration * 0.75 / (max(Armory:UnitLevel("player") or 1, 1) * 5);
        statFrame.tooltip2 = AddLine(statFrame.tooltip2, TooltipTitle(STAT_SPELL_PENETRATION, spellPenetration));
        statFrame.tooltip2 = AddLine(statFrame.tooltip2, SafeFormat(SPELL_PENETRATION_TOOLTIP, spellPenetration, resistanceAverage, resistanceAverage / 2));
    end
    statFrame.tooltip3 = GetHitCapTooltip();
end

local function GetCritBonusTooltip()
    return _G["STAT_"..GetClassFileName().."_CRIT_BONUS"] or STAT_CRIT_BONUS;
end

local function SetCrit(statFrame, critChance, tooltip)
    local text = FormatPercentage(critChance);
    SetLabelAndText(statFrame, STAT_CRITICAL_STRIKE, text);
    statFrame.tooltip = TooltipTitle(STAT_CRITICAL_STRIKE, text);
    statFrame.tooltip2 = SafeFormat(tooltip, critChance or 0);
    statFrame.tooltip3 = GetCritBonusTooltip();
end

local function SetMeleeCrit(statFrame)
    SetCrit(statFrame, Armory:GetCritChance(), STAT_CRIT_MELEE);
end

local function SetRangedCrit(statFrame)
    SetCrit(statFrame, Armory:GetRangedCritChance(), STAT_CRIT_RANGED);
end

-- Forever: GetSpellCritChance has no school argument
local function SetSpellCrit(statFrame)
    SetCrit(statFrame, Armory:GetSpellCritChance(HOLY_SCHOOL), STAT_CRIT_SPELL);
end

-- Forever: GetExpertise returns percentages for main hand, off hand and ranged
local function SetExpertise(statFrame)
    local expertise, offhandExpertise = Armory:GetExpertise();
    local _, offhandSpeed = Armory:UnitAttackSpeed("player");
    local text = FormatPercentage(expertise);
    if ( offhandSpeed ) then
        text = text.." / "..FormatPercentage(offhandExpertise);
    end
    SetLabelAndText(statFrame, STAT_EXPERTISE, text);
    statFrame.tooltip = TooltipTitle(_G["COMBAT_RATING_NAME"..CR_EXPERTISE] or STAT_EXPERTISE, text);
    statFrame.tooltip2 = SafeFormat(CR_EXPERTISE_TOOLTIP or CR_RANGED_EXPERTISE_TOOLTIP, text);
end

-- Spell

local function SetSpellBonusDamage(statFrame)
    local minModifier = Armory:GetSpellBonusDamage(HOLY_SCHOOL) or 0;
    local maxModifier = minModifier;
    statFrame.bonusDamage = {};
    statFrame.bonusDamage[HOLY_SCHOOL] = minModifier;
    -- Start at 2 to skip physical damage
    for i = HOLY_SCHOOL + 1, MAX_SPELL_SCHOOLS do
        local bonusDamage = Armory:GetSpellBonusDamage(i) or 0;
        minModifier = min(minModifier, bonusDamage);
        maxModifier = max(maxModifier, bonusDamage);
        statFrame.bonusDamage[i] = bonusDamage;
    end
    SetLabelAndText(statFrame, STAT_SPELLPOWER, BreakUpLargeNumbers(minModifier));
    statFrame.minModifier = minModifier;
    statFrame.tooltip = STAT_SPELLPOWER;
    statFrame.tooltip2 = SafeFormat(STAT_SPELLPOWER_TOOLTIP, maxModifier);
    statFrame:SetScript("OnEnter", ArmoryCharacterSpellBonusDamage_OnEnter);
end

local function SetSpellBonusHealing(statFrame)
    local bonusHealing = Armory:GetSpellBonusHealing() or 0;
    SetLabelAndText(statFrame, STAT_SPELLHEALING, BreakUpLargeNumbers(bonusHealing));
    statFrame.tooltip = TooltipTitle(STAT_SPELLHEALING, BreakUpLargeNumbers(bonusHealing));
    statFrame.tooltip2 = SafeFormat(STAT_SPELLHEALING_TOOLTIP, bonusHealing);
end

local function SetSpellHaste(statFrame)
    local spellHaste = Armory:UnitSpellHaste("player") or 0;
    local text = FormatPercentage(spellHaste);
    SetLabelAndText(statFrame, STAT_HASTE, text);
    statFrame.tooltip = TooltipTitle(STAT_HASTE, text);
    statFrame.tooltip2 = SafeFormat(CR_HASTE_SPELL_TOOLTIP, spellHaste);
end

local function SetManaRegen(statFrame)
    if ( not Armory:UnitHasMana("player") ) then
        SetLabelAndText(statFrame, MANA_REGEN, NOT_APPLICABLE);
        return;
    end

    local base, combat = Armory:GetManaRegen();
    -- All mana regen stats are displayed as mana/5 sec.
    base = floor((base or 0) * 5.0);
    combat = floor((combat or 0) * 5.0);
    -- Combat mana regen is most important to the player, so we display it as the main value
    SetLabelAndText(statFrame, MANA_REGEN, BreakUpLargeNumbers(combat));
    statFrame.tooltip = TooltipTitle(MANA_REGEN, BreakUpLargeNumbers(combat));
    statFrame.tooltip2 = SafeFormat(MANA_REGEN_TOOLTIP, BreakUpLargeNumbers(base));
end

-- Defenses

local function SetDefense(statFrame)
    local baseDefenseSkill, defenseModifier = Armory:UnitDefenseSkill("player");
    if ( not baseDefenseSkill ) then
        SetLabelAndText(statFrame, DEFENSE, NOT_APPLICABLE);
        return;
    end
    defenseModifier = defenseModifier or 0;

    local maxDefense = (Armory:UnitLevel("player") or 0) * SKILL_RANKS_PER_SKILL_LEVEL;
    local effectiveDefenseSkill = max(0, baseDefenseSkill + defenseModifier);
    local effectiveDefense = max(effectiveDefenseSkill - maxDefense, 0);
    local posBuff = max(defenseModifier, 0);
    local negBuff = min(defenseModifier, 0);

    local valueText, tooltipText = PaperDollFormatStat(DEFENSE, baseDefenseSkill, posBuff, negBuff);
    SetLabelAndText(statFrame, DEFENSE, valueText);
    statFrame.tooltip = tooltipText;
    statFrame.tooltip2 = AddLine(SafeFormat(DEFAULT_STATDEFENSE_TOOLTIP, effectiveDefense * STAT_PER_DEFENSE, effectiveDefense * STAT_PER_DEFENSE), "("..effectiveDefenseSkill.." / "..maxDefense..")");
end

local function SetDodge(statFrame)
    local chance = Armory:GetDodgeChance() or 0;
    SetLabelAndText(statFrame, STAT_DODGE, FormatPercentage(chance));
    statFrame.tooltip = TooltipTitle(DODGE_CHANCE, FormatPercentage(chance));
    statFrame.tooltip2 = SafeFormat(CR_DODGE_BASE_STAT_TOOLTIP, chance);
end

local function SetParry(statFrame)
    local chance = Armory:GetParryChance() or 0;
    SetLabelAndText(statFrame, STAT_PARRY, FormatPercentage(chance));
    statFrame.tooltip = TooltipTitle(PARRY_CHANCE, FormatPercentage(chance));
    statFrame.tooltip2 = SafeFormat(CR_PARRY_BASE_STAT_TOOLTIP, chance);
end

local function SetBlock(statFrame)
    local chance = Armory:GetBlockChance() or 0;
    SetLabelAndText(statFrame, STAT_BLOCK, FormatPercentage(chance));
    statFrame.tooltip = TooltipTitle(BLOCK_CHANCE, FormatPercentage(chance));
    statFrame.tooltip2 = SafeFormat(STAT_BLOCK_VALUE_FLAT_TOOLTIP, chance, Armory:GetShieldBlock() or 0);
end

-- The two dropdowns (Armory TBC)

function ArmoryUpdatePaperDollStats(prefix, index)
    local stats = {};
    for i = 1, 6 do
        local statFrame = _G[prefix..i];
        statFrame:SetScript("OnEnter", PaperDollStatTooltip);
        statFrame.tooltip = nil;
        statFrame.tooltip2 = nil;
        statFrame.tooltip3 = nil;
        statFrame:Show();
        stats[i] = statFrame;
    end

    if ( index == "PLAYERSTAT_BASE_STATS" ) then
        SetStat(stats[1], 1);
        SetStat(stats[2], 2);
        SetStat(stats[3], 3);
        SetStat(stats[4], 4);
        SetStat(stats[5], 5);
        SetArmor(stats[6]);
    elseif ( index == "PLAYERSTAT_MELEE_COMBAT" ) then
        SetDamage(stats[1]);
        SetAttackSpeed(stats[2]);
        SetAttackPower(stats[3]);
        SetMeleeHit(stats[4]);
        SetMeleeCrit(stats[5]);
        SetExpertise(stats[6]);
    elseif ( index == "PLAYERSTAT_RANGED_COMBAT" ) then
        SetRangedDamage(stats[1]);
        SetRangedAttackSpeed(stats[2]);
        SetRangedAttackPower(stats[3]);
        SetRangedHit(stats[4]);
        SetRangedCrit(stats[5]);
        stats[6]:Hide();
    elseif ( index == "PLAYERSTAT_SPELL_COMBAT" ) then
        SetSpellBonusDamage(stats[1]);
        SetSpellBonusHealing(stats[2]);
        SetSpellHit(stats[3]);
        SetSpellCrit(stats[4]);
        SetSpellHaste(stats[5]);
        SetManaRegen(stats[6]);
    elseif ( index == "PLAYERSTAT_DEFENSES" ) then
        SetArmor(stats[1]);
        SetDefense(stats[2]);
        SetDodge(stats[3]);
        SetParry(stats[4]);
        SetBlock(stats[5]);
        stats[6]:Hide();
    end

    ArmoryDropDownMenu_SetText(_G[prefix.."DropDown"], PLAYERSTAT_NAMES[index]);
end

local function InitializeStatDropDown(selected, func)
    local info = ArmoryDropDownMenu_CreateInfo();
    for _, option in ipairs(PLAYERSTAT_OPTIONS) do
        info.text = PLAYERSTAT_NAMES[option];
        info.func = func;
        info.value = option;
        info.checked = (option == selected) and 1 or nil;
        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        ArmoryDropDownMenu_AddButton(info);
    end
end

function ArmoryPlayerStatFrameLeftDropDown_OnLoad(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryPlayerStatFrameLeftDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION);
    ArmoryDropDownMenu_SetWidth(self, 99);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryPlayerStatFrameLeftDropDown_Initialize(self)
    InitializeStatDropDown(ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION, ArmoryPlayerStatFrameLeftDropDown_OnClick);
end

function ArmoryPlayerStatFrameLeftDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION = self.value;
    ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameLeft", self.value);
end

function ArmoryPlayerStatFrameRightDropDown_OnLoad(self)
    ArmoryDropDownMenu_Initialize(self, ArmoryPlayerStatFrameRightDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(self, ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION);
    ArmoryDropDownMenu_SetWidth(self, 99);
    ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryPlayerStatFrameRightDropDown_Initialize(self)
    InitializeStatDropDown(ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION, ArmoryPlayerStatFrameRightDropDown_OnClick);
end

function ArmoryPlayerStatFrameRightDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(_G[self.owner], self.value);
    ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = self.value;
    ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameRight", self.value);
end

-- Health and mana bars (Era)

function ArmoryPaperDollFrame_UpdateHealthBar()
    local currValue = Armory:UnitHealth("player") or 0;
    local maxValue = Armory:UnitHealthMax("player") or 0;
    if ( maxValue == 0 ) then
        maxValue = 1;
    end

    ArmoryHealthBar:SetMinMaxValues(0, maxValue);
    ArmoryHealthBar:SetStatusBarColor(0.0, 1.0, 0.0);
    ArmoryHealthBar:SetValue(currValue);
    ArmoryHealthBarText:SetText(currValue.." / "..maxValue);
end

function ArmoryPaperDollFrame_UpdateManaBar()
    local powerType, powerToken, altR, altG, altB = Armory:UnitPowerType("player");
    local info = powerToken and PowerBarColor[powerToken];
    local prefix = (powerToken and _G[powerToken]) or MANA;
    if ( info ) then
        ArmoryManaBar:SetStatusBarColor(info.r, info.g, info.b);
    elseif ( altR ) then
        ArmoryManaBar:SetStatusBarColor(altR, altG, altB);
    end
    ArmoryManaTextFrameLabel:SetText(strupper(prefix)..":");
    ArmoryMana.tooltipTitle = prefix;
    ArmoryMana.tooltipText = _G["NEWBIE_TOOLTIP_MANABAR"..(powerType or 0)];

    local currValue = Armory:UnitPower("player", powerType) or 0;
    local maxValue = Armory:UnitPowerMax("player") or 0;
    if ( maxValue == 0 ) then
        maxValue = 1;
    end

    ArmoryManaBar:SetMinMaxValues(0, maxValue);
    ArmoryManaBar:SetValue(currValue);
    ArmoryManaBarText:SetText(currValue.." / "..maxValue);
end

function ArmoryPaperDollFrame_UpdateStats()
    -- keeps storing every stat of the character
    ArmoryInitializePaperDollStats();

    if ( not ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION or not ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION ) then
        ArmoryPaperDollFrame_SetStatDropDown();
    end
    ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameLeft", ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION);
    ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameRight", ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION);
    SetResistances();
end
