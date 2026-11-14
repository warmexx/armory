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

function ArmoryPlayerStatFrameLeftDropDown_OnLoad(self)
	ArmoryDropDownMenu_Initialize(self, ArmoryPlayerStatFrameLeftDropDown_Initialize);
	ArmoryDropDownMenu_SetSelectedValue(self, ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION);
	ArmoryDropDownMenu_SetWidth(self, 99);
	ArmoryDropDownMenu_JustifyText(self, "LEFT");
end

function ArmoryPlayerStatFrameLeftDropDown_Initialize(self)
	-- Setup buttons
	local info = ArmoryDropDownMenu_CreateInfo();
	local checked;
	for i=1, getn(PLAYERSTAT_DROPDOWN_OPTIONS) do
		if ( PLAYERSTAT_DROPDOWN_OPTIONS[i] == ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION ) then
			checked = 1;
		else
			checked = nil;
		end
		info.text = getglobal(PLAYERSTAT_DROPDOWN_OPTIONS[i]);
		info.func = ArmoryPlayerStatFrameLeftDropDown_OnClick;
		info.value = PLAYERSTAT_DROPDOWN_OPTIONS[i];
		info.checked = checked;
		info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
		ArmoryDropDownMenu_AddButton(info);
	end
end

function ArmoryPlayerStatFrameLeftDropDown_OnClick(self)
	ArmoryDropDownMenu_SetSelectedValue(getglobal(self.owner), self.value);
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
	-- Setup buttons
	local info = ArmoryDropDownMenu_CreateInfo();
	local checked;
	for i=1, getn(PLAYERSTAT_DROPDOWN_OPTIONS) do
		if ( PLAYERSTAT_DROPDOWN_OPTIONS[i] == ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION ) then
			checked = 1;
		else
			checked = nil;
		end
		info.text = getglobal(PLAYERSTAT_DROPDOWN_OPTIONS[i]);
		info.func = ArmoryPlayerStatFrameRightDropDown_OnClick;
		info.value = PLAYERSTAT_DROPDOWN_OPTIONS[i];
		info.checked = checked;
		info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
		ArmoryDropDownMenu_AddButton(info);
	end
end

function ArmoryPlayerStatFrameRightDropDown_OnClick(self)
	ArmoryDropDownMenu_SetSelectedValue(getglobal(self.owner), self.value);
	ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = self.value;
	ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameRight", self.value);
end

function ArmoryPaperDollFrame_SetStatDropDown()
    local _, classFileName = Armory:UnitClass("player");
    classFileName = strupper(classFileName);
    ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION = "PLAYERSTAT_BASE_STATS";
    if ( classFileName == "MAGE" or classFileName == "PRIEST" or classFileName == "WARLOCK" or classFileName == "DRUID" ) then
        ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = "PLAYERSTAT_SPELL_COMBAT";
    elseif ( classFileName == "HUNTER" ) then
        ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = "PLAYERSTAT_RANGED_COMBAT";
    else
        ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION = "PLAYERSTAT_MELEE_COMBAT";
    end
end

function ArmoryPaperDollFrame_ResetStatDropDown()
    ArmoryPaperDollFrame_SetStatDropDown();
    ArmoryDropDownMenu_SetSelectedValue(ArmoryPlayerStatFrameLeftDropDown, ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION);
    ArmoryDropDownMenu_SetSelectedValue(ArmoryPlayerStatFrameRightDropDown, ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION);
    ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameLeft", ARMORY_PLAYERSTAT_LEFTDROPDOWN_SELECTION);
    ArmoryUpdatePaperDollStats("ArmoryPlayerStatFrameRight", ARMORY_PLAYERSTAT_RIGHTDROPDOWN_SELECTION);
end

function ArmoryPaperDollFrame_UpdateStats()
    ArmoryPaperDollFrame_ResetStatDropDown();
	ArmoryPaperDollFrame_SetResistances();
end

function ArmoryPaperDollFrame_SetStat(statFrame, statIndex)
	local label = getglobal(statFrame:GetName().."Label");
	local text = getglobal(statFrame:GetName().."StatText");
	local stat;
	local effectiveStat;
	local posBuff;
	local negBuff;
	stat, effectiveStat, posBuff, negBuff = Armory:UnitStat("player", statIndex);
	local statName = getglobal("SPELL_STAT"..statIndex.."_NAME");
	label:SetText(statName..":");

	-- Set the tooltip text
	local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..statName.." ";

	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		text:SetText(effectiveStat);
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
			text:SetText(RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
		else
			text:SetText(GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
		end
	end
	statFrame.tooltip2 = getglobal("DEFAULT_STAT"..statIndex.."_TOOLTIP");
	local _, unitClass = Armory:UnitClass("player");
	unitClass = strupper(unitClass);

	if ( statIndex == 1 ) then
		local attackPower = GetAttackPowerForStat(statIndex,effectiveStat);
		statFrame.tooltip2 = format(statFrame.tooltip2, attackPower);
		if ( unitClass == "WARRIOR" or unitClass == "SHAMAN" or unitClass == "PALADIN" ) then
			statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format( STAT_BLOCK_TOOLTIP, effectiveStat*BLOCK_PER_STRENGTH );
		end
	elseif ( statIndex == 3 ) then
		local baseStam = min(20, effectiveStat);
		local moreStam = effectiveStat - baseStam;
		statFrame.tooltip2 = format(statFrame.tooltip2, (baseStam + (moreStam*HEALTH_PER_STAMINA))*Armory:GetUnitMaxHealthModifier("player"));
		local petStam = Armory:ComputePetBonus("PET_BONUS_STAM", effectiveStat );
		if( petStam > 0 ) then
			statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_STAMINA,petStam);
		end
	elseif ( statIndex == 2 ) then
		local attackPower = GetAttackPowerForStat(statIndex,effectiveStat);
		if ( attackPower > 0 ) then
			statFrame.tooltip2 = format(STAT_ATTACK_POWER, attackPower) .. format(statFrame.tooltip2, Armory:GetCritChanceFromAgility("player"), effectiveStat*ARMOR_PER_AGILITY);
		else
			statFrame.tooltip2 = format(statFrame.tooltip2, Armory:GetCritChanceFromAgility("player"), effectiveStat*ARMOR_PER_AGILITY);
		end
	elseif ( statIndex == 4 ) then
		local baseInt = min(20, effectiveStat);
		local moreInt = effectiveStat - baseInt
		if ( Armory:UnitHasMana("player") ) then
			statFrame.tooltip2 = format(statFrame.tooltip2, baseInt + moreInt*MANA_PER_INTELLECT, Armory:GetSpellCritChanceFromIntellect("player"));
		else
			statFrame.tooltip2 = nil;
		end
		local petInt = Armory:ComputePetBonus("PET_BONUS_INT", effectiveStat );
		if( petInt > 0 ) then
			if ( not statFrame.tooltip2 ) then
				statFrame.tooltip2 = "";
			end
			statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_INTELLECT,petInt);
		end
	elseif ( statIndex == 5 ) then
		-- All mana regen stats are displayed as mana/5 sec.
		statFrame.tooltip2 = format(statFrame.tooltip2, Armory:GetUnitHealthRegenRateFromSpirit("player"));
		if ( Armory:UnitHasMana("player") ) then
			local regen = Armory:GetUnitManaRegenRateFromSpirit("player");
			regen = floor( regen * 5.0 );
			statFrame.tooltip2 = statFrame.tooltip2.."\n"..format(MANA_REGEN_FROM_SPIRIT, regen);
		end
	end
end

function ArmoryPaperDollFrame_SetRating(statFrame, ratingIndex)
    local label = getglobal(statFrame:GetName().."Label");
    local text = getglobal(statFrame:GetName().."StatText");
    local statName = getglobal("COMBAT_RATING_NAME"..ratingIndex);
    label:SetText(statName..":");
    local rating = Armory:GetCombatRating(ratingIndex);
    local ratingBonus = Armory:GetCombatRatingBonus(ratingIndex);
    text:SetText(rating);

    -- Set the tooltip text
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..statName.." "..rating..FONT_COLOR_CODE_CLOSE;
    -- Can probably axe this if else tree if all rating tooltips follow the same format
    if ( ratingIndex == CR_HIT_MELEE ) then
        statFrame.tooltip2 = format(CR_HIT_MELEE_TOOLTIP, Armory:UnitLevel("player"), ratingBonus, Armory:GetArmorPenetration());
    elseif ( ratingIndex == CR_HIT_RANGED ) then
        statFrame.tooltip2 = format(CR_HIT_RANGED_TOOLTIP, Armory:UnitLevel("player"), ratingBonus, Armory:GetArmorPenetration());
    elseif ( ratingIndex == CR_DODGE ) then
        statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, ratingBonus);
    elseif ( ratingIndex == CR_PARRY ) then
        statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, ratingBonus);
    elseif ( ratingIndex == CR_BLOCK ) then
        statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, ratingBonus);
    elseif ( ratingIndex == CR_HIT_SPELL ) then
        statFrame.tooltip2 = format(CR_HIT_SPELL_TOOLTIP, Armory:UnitLevel("player"), ratingBonus, Armory:GetSpellPenetration(), Armory:GetSpellPenetration());
    elseif ( ratingIndex == CR_CRIT_SPELL ) then
        local holySchool = 2;
        local minCrit = Armory:GetSpellCritChance(holySchool);
        statFrame.spellCrit = {};
        statFrame.spellCrit[holySchool] = minCrit;
        local spellCrit;
        for i=(holySchool+1), MAX_SPELL_SCHOOLS do
            spellCrit = Armory:GetSpellCritChance(i);
            minCrit = min(minCrit, spellCrit);
            statFrame.spellCrit[i] = spellCrit;
        end
        minCrit = format("%.2f%%", minCrit);
        statFrame.minCrit = minCrit;
    elseif ( ratingIndex == CR_EXPERTISE ) then
        statFrame.tooltip2 = format(CR_EXPERTISE_TOOLTIP, ratingBonus);
    else
        statFrame.tooltip2 = HIGHLIGHT_FONT_COLOR_CODE..getglobal("COMBAT_RATING_NAME"..ratingIndex).." "..rating;
    end
end

function ArmoryPaperDollFrame_SetArmor(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    end
    local base, effectiveArmor, armor, posBuff, negBuff = Armory:UnitArmor(unit);
    getglobal(statFrame:GetName().."Label"):SetText(ARMOR_COLON);
    local text = getglobal(statFrame:GetName().."StatText");

    PaperDollFormatStat(ARMOR, base, posBuff, negBuff, statFrame, text);
    local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, Armory:UnitLevel(unit));
    statFrame.tooltip2 = format(DEFAULT_STATARMOR_TOOLTIP, armorReduction);

    if ( unit == "player" ) then
        local petBonus = Armory:ComputePetBonus( "PET_BONUS_ARMOR", effectiveArmor );
        if( petBonus > 0 ) then
            statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_ARMOR, petBonus);
        end
    end
end

function ArmoryPaperDollFrame_SetDefense(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    end
    local base, modifier = Armory:UnitDefense(unit);
    local posBuff = 0;
    local negBuff = 0;
    if ( modifier > 0 ) then
        posBuff = modifier;
    elseif ( modifier < 0 ) then
        negBuff = modifier;
    end
    getglobal(statFrame:GetName().."Label"):SetText(DEFENSE_COLON);
    local text = getglobal(statFrame:GetName().."StatText");

    PaperDollFormatStat(DEFENSE, base, posBuff, negBuff, statFrame, text);
    local defensePercent = Armory:GetDodgeBlockParryChanceFromDefense();
    statFrame.tooltip2 = format(DEFAULT_STATDEFENSE_TOOLTIP, Armory:GetCombatRating(CR_DEFENSE_SKILL), Armory:GetCombatRatingBonus(CR_DEFENSE_SKILL), defensePercent, defensePercent);
end

function ArmoryPaperDollFrame_SetDodge(statFrame)
    local chance = Armory:GetDodgeChance();

    PaperDollFrame_SetLabelAndText(statFrame, STAT_DODGE, chance, 1);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("DODGE_CHANCE").." "..string.format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_DODGE_TOOLTIP, Armory:GetCombatRating(CR_DODGE), Armory:GetCombatRatingBonus(CR_DODGE));
end

function ArmoryPaperDollFrame_SetBlock(statFrame)
    local chance = Armory:GetBlockChance();

    PaperDollFrame_SetLabelAndText(statFrame, STAT_BLOCK, chance, 1);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("BLOCK_CHANCE").." "..string.format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_BLOCK_TOOLTIP, Armory:GetCombatRating(CR_BLOCK), Armory:GetCombatRatingBonus(CR_BLOCK), Armory:GetShieldBlock());
end

function ArmoryPaperDollFrame_SetParry(statFrame)
    local chance = Armory:GetParryChance();
    PaperDollFrame_SetLabelAndText(statFrame, STAT_PARRY, chance, 1);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("PARRY_CHANCE").." "..string.format("%.02f", chance).."%"..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_PARRY_TOOLTIP, Armory:GetCombatRating(CR_PARRY), Armory:GetCombatRatingBonus(CR_PARRY));
end

function ArmoryPaperDollFrame_SetResilience(statFrame)
	local resilience = Armory:GetCombatRating(CR_RESILIENCE_CRIT_TAKEN);
	local bonus = Armory:GetCombatRatingBonus(CR_RESILIENCE_CRIT_TAKEN);

	PaperDollFrame_SetLabelAndText(statFrame, STAT_RESILIENCE, resilience);
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..STAT_RESILIENCE.." "..resilience..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(RESILIENCE_TOOLTIP, bonus, min(bonus * 2, 25.00), bonus);
end

function ArmoryPaperDollFrame_SetDamage(statFrame, unit)
	if ( not unit ) then
		unit = "player";
	end
	getglobal(statFrame:GetName().."Label"):SetText(DAMAGE_COLON);
	local text = getglobal(statFrame:GetName().."StatText");

    local speed, offhandSpeed = Armory:UnitAttackSpeed(unit);
	local minDamage;
	local maxDamage;
	local minOffHandDamage;
	local maxOffHandDamage;
	local physicalBonusPos;
	local physicalBonusNeg;
	local percent;
    minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = Armory:UnitDamage(unit);
    if ( not minDamage ) then
        return;
    end
	local displayMin = max(floor(minDamage),1);
	local displayMax = max(ceil(maxDamage),1);

    if (percent == 0) then
		minDamage = 0;
		maxDamage = 0;
	else
        minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
    end

	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
    local damagePerSecond;
	if speed == 0 then
		damagePerSecond = 0;
	else
		damagePerSecond = (max(fullDamage,1) / speed);
	end
	local damageTooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);

	local colorPos = "|cff20ff20";
	local colorNeg = "|cffff2020";

	-- epsilon check
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
	end

	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			text:SetText(displayMin.." - "..displayMax);
		else
			text:SetText(displayMin.."-"..displayMax);
		end
	else

		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			text:SetText(color..displayMin.." - "..displayMax.."|r");
		else
			text:SetText(color..displayMin.."-"..displayMax.."|r");
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end

	end
	statFrame.damage = damageTooltip;
	statFrame.attackSpeed = speed;
	statFrame.dps = damagePerSecond;

	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
		local offhandDamagePerSecond;
		if offhandSpeed == 0 then
			offhandDamagePerSecond = 0;
		else
			offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed);
		end
		local offhandDamageTooltip = max(floor(minOffHandDamage),1).." - "..max(ceil(maxOffHandDamage),1);
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r";
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r";
		end
		if ( percent > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
		elseif ( percent < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
		end
		statFrame.offhandDamage = offhandDamageTooltip;
		statFrame.offhandAttackSpeed = offhandSpeed;
		statFrame.offhandDps = offhandDamagePerSecond;
	else
		statFrame.offhandAttackSpeed = nil;
	end
end

function ArmoryPaperDollFrame_SetAttackSpeed(statFrame, unit)
	if ( not unit ) then
		unit = "player";
	end
	local speed, offhandSpeed = Armory:UnitAttackSpeed(unit);
	speed = format("%.2f", speed);
	if ( offhandSpeed ) then
		offhandSpeed = format("%.2f", offhandSpeed);
	end
	local text;
	if ( offhandSpeed ) then
		text = speed.." / "..offhandSpeed;
	else
		text = speed;
	end
	PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, text);

	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..ATTACK_SPEED.." "..text..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, Armory:GetCombatRating(CR_HASTE_MELEE), Armory:GetCombatRatingBonus(CR_HASTE_MELEE));
end

function ArmoryPaperDollFrame_SetAttackPower(statFrame, unit)
	if ( not unit ) then
		unit = "player";
	end
    getglobal(statFrame:GetName().."Label"):SetText(ATTACK_POWER_COLON);
	local text = getglobal(statFrame:GetName().."StatText");
	local base, posBuff, negBuff = Armory:UnitAttackPower(unit);

	PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff, statFrame, text);
	statFrame.tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
end

function ArmoryPaperDollFrame_SetAttackBothHands(statFrame, unit)
	if ( not unit ) then
		unit = "player";
	end
	local mainHandAttackBase, mainHandAttackMod, offHandAttackBase, offHandAttackMod = Armory:UnitAttackBothHands(unit);

	getglobal(statFrame:GetName().."Label"):SetText(COMBAT_RATING_NAME1..":");
	local text = getglobal(statFrame:GetName().."StatText");

	if( mainHandAttackMod == 0 ) then
		text:SetText(mainHandAttackBase);
	else
		local color = RED_FONT_COLOR_CODE;
		if( mainHandAttackMod > 0 ) then
			color = GREEN_FONT_COLOR_CODE;
		end
		text:SetText(color..(mainHandAttackBase + mainHandAttackMod)..FONT_COLOR_CODE_CLOSE);
	end

	if( mainHandAttackMod == 0 ) then
		statFrame.weaponSkill = COMBAT_RATING_NAME1.." "..mainHandAttackBase;
	else
		local color = RED_FONT_COLOR_CODE;
		statFrame.weaponSkill = COMBAT_RATING_NAME1.." "..(mainHandAttackBase + mainHandAttackMod).." ("..mainHandAttackBase..color.." "..mainHandAttackMod..")";
		if( mainHandAttackMod > 0 ) then
			color = GREEN_FONT_COLOR_CODE;
			statFrame.weaponSkill = COMBAT_RATING_NAME1.." "..(mainHandAttackBase + mainHandAttackMod).." ("..mainHandAttackBase..color.." +"..mainHandAttackMod..FONT_COLOR_CODE_CLOSE..")";
		end
	end

	local total = Armory:GetCombatRating(CR_WEAPON_SKILL) + Armory:GetCombatRating(CR_WEAPON_SKILL_MAINHAND);
	statFrame.weaponRating = format(WEAPON_SKILL_RATING, total);
	if ( total > 0 ) then
		statFrame.weaponRating = statFrame.weaponRating..format(WEAPON_SKILL_RATING_BONUS, Armory:GetCombatRatingBonus(CR_WEAPON_SKILL) + Armory:GetCombatRatingBonus(CR_WEAPON_SKILL_MAINHAND));
	end

	local speed, offhandSpeed = Armory:UnitAttackSpeed(unit);
	if ( offhandSpeed ) then
		if( offHandAttackMod == 0 ) then
			statFrame.offhandSkill = COMBAT_RATING_NAME1.." "..offHandAttackBase;
		else
			local color = RED_FONT_COLOR_CODE;
			statFrame.offhandSkill = COMBAT_RATING_NAME1.." "..(offHandAttackBase + offHandAttackMod).." ("..offHandAttackBase..color.." "..offHandAttackMod..")";
			if( offHandAttackMod > 0 ) then
				color = GREEN_FONT_COLOR_CODE;
				statFrame.offhandSkill = COMBAT_RATING_NAME1.." "..(offHandAttackBase + offHandAttackMod).." ("..offHandAttackBase..color.." +"..offHandAttackMod..FONT_COLOR_CODE_CLOSE..")";
			end
		end

		total = Armory:GetCombatRating(CR_WEAPON_SKILL) + Armory:GetCombatRating(CR_WEAPON_SKILL_OFFHAND);
		statFrame.offhandRating = format(WEAPON_SKILL_RATING, total);
		if ( total > 0 ) then
			statFrame.offhandRating = statFrame.offhandRating..format(WEAPON_SKILL_RATING_BONUS, Armory:GetCombatRatingBonus(CR_WEAPON_SKILL) + Armory:GetCombatRatingBonus(CR_WEAPON_SKILL_OFFHAND));
		end
	else
		statFrame.offhandSkill = nil;
	end
end

function ArmoryPaperDollFrame_SetRangedAttack(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    elseif ( unit == "pet" ) then
        return;
    end

    local hasRelic = Armory:UnitHasRelicSlot(unit);
    local rangedAttackBase, rangedAttackMod = Armory:UnitRangedAttack(unit);
    getglobal(statFrame:GetName().."Label"):SetText(COMBAT_RATING_NAME1..":");
    local text = getglobal(statFrame:GetName().."StatText");

    -- If no ranged texture then set stats to n/a
    local rangedTexture = Armory:GetInventoryItemTexture("player", 18);
    if ( rangedTexture and not hasRelic ) then
        ArmoryPaperDollFrame.noRanged = nil;
    else
        text:SetText(NOT_APPLICABLE);
        ArmoryPaperDollFrame.noRanged = 1;
        statFrame.tooltip = nil;
    end
    if ( not rangedTexture or hasRelic ) then
        return;
    end

    if( rangedAttackMod == 0 ) then
        text:SetText(rangedAttackBase);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..COMBAT_RATING_NAME1.." "..rangedAttackBase..FONT_COLOR_CODE_CLOSE;
    else
        local color = RED_FONT_COLOR_CODE;
        if( rangedAttackMod > 0 ) then
              color = GREEN_FONT_COLOR_CODE;
            statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..COMBAT_RATING_NAME1.." "..(rangedAttackBase + rangedAttackMod).." ("..rangedAttackBase..color.." +"..rangedAttackMod..FONT_COLOR_CODE_CLOSE..HIGHLIGHT_FONT_COLOR_CODE..")";
        else
            statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..COMBAT_RATING_NAME1.." "..(rangedAttackBase + rangedAttackMod).." ("..rangedAttackBase..color.." "..rangedAttackMod..FONT_COLOR_CODE_CLOSE..HIGHLIGHT_FONT_COLOR_CODE..")";
        end
        text:SetText(color..(rangedAttackBase + rangedAttackMod)..FONT_COLOR_CODE_CLOSE);
    end
    local total = Armory:GetCombatRating(CR_WEAPON_SKILL) + Armory:GetCombatRating(CR_WEAPON_SKILL_RANGED);
    statFrame.tooltip2 = format(WEAPON_SKILL_RATING, total);
    if ( total > 0 ) then
        statFrame.tooltip2 = statFrame.tooltip2..format(WEAPON_SKILL_RATING_BONUS, Armory:GetCombatRatingBonus(CR_WEAPON_SKILL) + Armory:GetCombatRatingBonus(CR_WEAPON_SKILL_RANGED));
    end
end

function ArmoryPaperDollFrame_SetRangedDamage(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    elseif ( unit == "pet" ) then
        return;
    end
    getglobal(statFrame:GetName().."Label"):SetText(DAMAGE_COLON);
    local text = getglobal(statFrame:GetName().."StatText");

    -- If no ranged attack then set to n/a
    local hasRelic = Armory:UnitHasRelicSlot(unit);
    local rangedTexture = Armory:GetInventoryItemTexture("player", 18);
    if ( rangedTexture and not hasRelic ) then
        ArmoryPaperDollFrame.noRanged = nil;
    else
        text:SetText(NOT_APPLICABLE);
        ArmoryPaperDollFrame.noRanged = 1;
        statFrame.damage = nil;
        return;
    end

    local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = Armory:UnitRangedDamage(unit);
    local displayMin = max(floor(minDamage),1);
    local displayMax = max(ceil(maxDamage),1);

    local baseDamage;
    local fullDamage;
    local totalBonus;
    local damagePerSecond;
    local tooltip;

    if ( Armory:HasWandEquipped() ) then
        baseDamage = (minDamage + maxDamage) * 0.5;
        fullDamage = baseDamage * percent;
        totalBonus = 0;
        damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed);
        tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
    else
        minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
        maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

        baseDamage = (minDamage + maxDamage) * 0.5;
        fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        totalBonus = (fullDamage - baseDamage);
		if (rangedAttackSpeed == 0) then
            -- Egan's Blaster!!!
            damagePerSecond = math.huge;
        else
            damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed);
        end
        tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
    end

    if ( totalBonus == 0 ) then
        if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
            text:SetText(displayMin.." - "..displayMax);
        else
            text:SetText(displayMin.."-"..displayMax);
        end
    else
        local colorPos = "|cff20ff20";
        local colorNeg = "|cffff2020";
        local color;
        if ( totalBonus > 0 ) then
            color = colorPos;
        else
            color = colorNeg;
        end
        if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
            text:SetText(color..displayMin.." - "..displayMax.."|r");
        else
            text:SetText(color..displayMin.."-"..displayMax.."|r");
        end
        if ( physicalBonusPos > 0 ) then
            tooltip = tooltip..colorPos.." +"..physicalBonusPos.."|r";
        end
        if ( physicalBonusNeg < 0 ) then
            tooltip = tooltip..colorNeg.." "..physicalBonusNeg.."|r";
        end
        if ( percent > 1 ) then
            tooltip = tooltip..colorPos.." x"..floor(percent*100+0.5).."%|r";
        elseif ( percent < 1 ) then
            tooltip = tooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r";
        end
        statFrame.tooltip = tooltip.." "..format(DPS_TEMPLATE, damagePerSecond);
    end
    statFrame.attackSpeed = rangedAttackSpeed;
    statFrame.damage = tooltip;
    statFrame.dps = damagePerSecond;
end

function ArmoryPaperDollFrame_SetRangedAttackSpeed(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    elseif ( unit == "pet" ) then
        return;
    end
    local text;
    -- If no ranged attack then set to n/a
    if ( ArmoryPaperDollFrame.noRanged ) then
        text = NOT_APPLICABLE;
        statFrame.tooltip = nil;
    else
        text = Armory:UnitRangedDamage(unit);
        text = format("%.2f", text);
        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..ATTACK_SPEED.." "..text..FONT_COLOR_CODE_CLOSE;
    end
    PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, text);
    statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, Armory:GetCombatRating(CR_HASTE_RANGED), Armory:GetCombatRatingBonus(CR_HASTE_RANGED));
end

function ArmoryPaperDollFrame_SetRangedAttackPower(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    end
    getglobal(statFrame:GetName().."Label"):SetText(ATTACK_POWER_COLON);
    local text = getglobal(statFrame:GetName().."StatText");
    local base, posBuff, negBuff = Armory:UnitRangedAttackPower(unit);

    PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff, statFrame, text);
    local totalAP = base+posBuff+negBuff;
    statFrame.tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, max((totalAP), 0)/ATTACK_POWER_MAGIC_NUMBER);
    local petAPBonus = Armory:ComputePetBonus( "PET_BONUS_RAP_TO_AP", totalAP );
    if( petAPBonus > 0 ) then
        statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_RANGED_ATTACK_POWER, petAPBonus);
    end

    local petSpellDmgBonus = Armory:ComputePetBonus( "PET_BONUS_RAP_TO_SPELLDMG", totalAP );
    if( petSpellDmgBonus > 0 ) then
        statFrame.tooltip2 = statFrame.tooltip2 .. "\n" .. format(PET_BONUS_TOOLTIP_SPELLDAMAGE, petSpellDmgBonus);
    end
end

function ArmoryPaperDollFrame_SetSpellBonusDamage(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(BONUS_DAMAGE..":");
    local text = getglobal(statFrame:GetName().."StatText");
    local holySchool = 2;
    -- Start at 2 to skip physical damage
    local minModifier = Armory:GetSpellBonusDamage(holySchool);
    statFrame.bonusDamage = {};
    statFrame.bonusDamage[holySchool] = minModifier;
    local bonusDamage;
    for i=(holySchool+1), MAX_SPELL_SCHOOLS do
        bonusDamage = Armory:GetSpellBonusDamage(i);
        minModifier = min(minModifier, bonusDamage);
        statFrame.bonusDamage[i] = bonusDamage;
    end
    text:SetText(minModifier);
    statFrame.minModifier = minModifier;
end

function ArmoryPaperDollFrame_SetSpellCritChance(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(SPELL_CRIT_CHANCE..":");
    local text = getglobal(statFrame:GetName().."StatText");
    local holySchool = 2;
    -- Start at 2 to skip physical damage
    local minCrit = Armory:GetSpellCritChance(holySchool);
    statFrame.spellCrit = {};
    statFrame.spellCrit[holySchool] = minCrit;
    local spellCrit;
    for i=(holySchool+1), MAX_SPELL_SCHOOLS do
        spellCrit = Armory:GetSpellCritChance(i);
        minCrit = min(minCrit, spellCrit);
        statFrame.spellCrit[i] = spellCrit;
    end
    -- Add agility contribution
    --minCrit = minCrit + Armory:GetSpellCritChanceFromIntellect();
    minCrit = format("%.2f%%", minCrit);
    text:SetText(minCrit);
    statFrame.minCrit = minCrit;
end

function ArmoryPaperDollFrame_SetMeleeCritChance(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(MELEE_CRIT_CHANCE..":");
    local text = getglobal(statFrame:GetName().."StatText");
    local critChance = Armory:GetCritChance();
    critChance = format("%.2f%%", critChance);
    text:SetText(critChance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..MELEE_CRIT_CHANCE.." "..critChance..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_CRIT_MELEE_TOOLTIP, Armory:GetCombatRating(CR_CRIT_MELEE), Armory:GetCombatRatingBonus(CR_CRIT_MELEE));
end

function ArmoryPaperDollFrame_SetRangedCritChance(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(RANGED_CRIT_CHANCE..":");
    local text = getglobal(statFrame:GetName().."StatText");
    local critChance = Armory:GetRangedCritChance();-- + Armory:GetCritChanceFromAgility();
    critChance = format("%.2f%%", critChance);
    text:SetText(critChance);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..RANGED_CRIT_CHANCE.." "..critChance..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(CR_CRIT_RANGED_TOOLTIP, Armory:GetCombatRating(CR_CRIT_RANGED), Armory:GetCombatRatingBonus(CR_CRIT_RANGED));
end

function ArmoryPaperDollFrame_SetSpellBonusHealing(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(BONUS_HEALING..":");
    local text = getglobal(statFrame:GetName().."StatText");
    local bonusHealing = Armory:GetSpellBonusHealing();
    text:SetText(bonusHealing);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. BONUS_HEALING .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 =format(BONUS_HEALING_TOOLTIP, bonusHealing);
end

function ArmoryPaperDollFrame_SetSpellPenetration(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(SPELL_PENETRATION..":");
    local text = getglobal(statFrame:GetName().."StatText");
    text:SetText(Armory:GetSpellPenetration());

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. SPELL_PENETRATION .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = SPELL_PENETRATION_TOOLTIP;
end

function ArmoryPaperDollFrame_SetSpellHaste(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(SPELL_HASTE..":");
    local text = getglobal(statFrame:GetName().."StatText");
    text:SetText(Armory:GetCombatRating(CR_HASTE_SPELL));

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. SPELL_HASTE .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(SPELL_HASTE_TOOLTIP, Armory:GetCombatRatingBonus(CR_HASTE_SPELL));
end

function ArmoryPaperDollFrame_SetManaRegen(statFrame)
    getglobal(statFrame:GetName().."Label"):SetText(MANA_REGEN..":");
    local text = getglobal(statFrame:GetName().."StatText");
    if ( not Armory:UnitHasMana("player") ) then
        text:SetText(NOT_APPLICABLE);
        statFrame.tooltip = nil;
        return;
    end

    local base, casting = Armory:GetManaRegen();
    -- All mana regen stats are displayed as mana/5 sec.
    base = floor( base * 5.0 );
    casting = floor( casting * 5.0 );
    text:SetText(base);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. MANA_REGEN .. FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = format(MANA_REGEN_TOOLTIP, base, casting);
end

function ArmoryPaperDollFrame_SetExpertise(statFrame, unit)
    if ( not unit ) then
        unit = "player";
    end
    local expertise, offhandExpertise = Armory:GetExpertise();
    local speed, offhandSpeed = Armory:UnitAttackSpeed(unit);
    local text;
    if( offhandSpeed ) then
        text = expertise.." / "..offhandExpertise;
    else
        text = expertise;
    end
    PaperDollFrame_SetLabelAndText(statFrame, STAT_EXPERTISE, text);

    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..getglobal("COMBAT_RATING_NAME"..CR_EXPERTISE).." "..text..FONT_COLOR_CODE_CLOSE;

    local expertisePercent, offhandExpertisePercent = Armory:GetExpertisePercent();
    expertisePercent = format("%.2f", expertisePercent);
    if( offhandSpeed ) then
        offhandExpertisePercent = format("%.2f", offhandExpertisePercent);
        text = expertisePercent.."% / "..offhandExpertisePercent.."%";
    else
        text = expertisePercent.."%";
    end
    statFrame.tooltip2 = format(CR_EXPERTISE_TOOLTIP, text, Armory:GetCombatRating(CR_EXPERTISE), Armory:GetCombatRatingBonus(CR_EXPERTISE));
end

function ArmoryCharacterSpellBonusDamage_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..BONUS_DAMAGE.." "..self.minModifier..FONT_COLOR_CODE_CLOSE);
	for i=2, MAX_SPELL_SCHOOLS do
		GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..i), self.bonusDamage[i], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..i);
	end

	local petStr, damage;
	if( self.bonusDamage[6] > self.bonusDamage[3] ) then
		petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_SHADOW;
		damage = self.bonusDamage[6];
	else
		petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_FIRE;
		damage = self.bonusDamage[3];
	end

	local petBonusAP = Armory:ComputePetBonus("PET_BONUS_SPELLDMG_TO_AP", damage );
	local petBonusDmg = Armory:ComputePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", damage );
	if( petBonusAP > 0 or petBonusDmg > 0 ) then
		GameTooltip:AddLine("\n" .. format(petStr, petBonusAP, petBonusDmg), nil, nil, nil, 1 );
	end
	GameTooltip:Show();
end

function ArmoryCharacterSpellCritChance_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(HIGHLIGHT_FONT_COLOR_CODE..COMBAT_RATING_NAME11.." "..Armory:GetCombatRating(11)..FONT_COLOR_CODE_CLOSE);
	local spellCrit;
	for i=2, MAX_SPELL_SCHOOLS do
		spellCrit = format("%.2f", self.spellCrit[i]);
		spellCrit = spellCrit.."%";
		GameTooltip:AddDoubleLine(getglobal("DAMAGE_SCHOOL"..i), spellCrit, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		GameTooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..i);
	end
	GameTooltip:Show();
end

function ArmoryUpdatePaperDollStats(prefix, index)
	local stat1 = _G[prefix..1];
	local stat2 = _G[prefix..2];
	local stat3 = _G[prefix..3];
	local stat4 = _G[prefix..4];
	local stat5 = _G[prefix..5];
	local stat6 = _G[prefix..6];

	-- reset any OnEnter scripts that may have been changed
	stat1:SetScript("OnEnter", PaperDollStatTooltip);
	stat2:SetScript("OnEnter", PaperDollStatTooltip);
	stat4:SetScript("OnEnter", PaperDollStatTooltip);

	stat6:Show();

	if ( index == "PLAYERSTAT_BASE_STATS" ) then
		ArmoryPaperDollFrame_SetStat(stat1, 1);
		ArmoryPaperDollFrame_SetStat(stat2, 2);
		ArmoryPaperDollFrame_SetStat(stat3, 3);
		ArmoryPaperDollFrame_SetStat(stat4, 4);
		ArmoryPaperDollFrame_SetStat(stat5, 5);
		ArmoryPaperDollFrame_SetArmor(stat6);
	elseif ( index == "PLAYERSTAT_MELEE_COMBAT" ) then
		ArmoryPaperDollFrame_SetDamage(stat1);
		stat1:SetScript("OnEnter", CharacterDamageFrame_OnEnter);
		ArmoryPaperDollFrame_SetAttackSpeed(stat2);
		ArmoryPaperDollFrame_SetAttackPower(stat3);
		ArmoryPaperDollFrame_SetRating(stat4, CR_HIT_MELEE);
		ArmoryPaperDollFrame_SetMeleeCritChance(stat5);
		ArmoryPaperDollFrame_SetExpertise(stat6);
	elseif ( index == "PLAYERSTAT_RANGED_COMBAT" ) then
		ArmoryPaperDollFrame_SetRangedDamage(stat1);
		stat1:SetScript("OnEnter", CharacterRangedDamageFrame_OnEnter);
		ArmoryPaperDollFrame_SetRangedAttackSpeed(stat2);
		ArmoryPaperDollFrame_SetRangedAttackPower(stat3);
		ArmoryPaperDollFrame_SetRating(stat4, CR_HIT_RANGED);
		ArmoryPaperDollFrame_SetRangedCritChance(stat5);
		stat6:Hide();
	elseif ( index == "PLAYERSTAT_SPELL_COMBAT" ) then
		ArmoryPaperDollFrame_SetSpellBonusDamage(stat1);
		stat1:SetScript("OnEnter", ArmoryCharacterSpellBonusDamage_OnEnter);
		ArmoryPaperDollFrame_SetSpellBonusHealing(stat2);
		ArmoryPaperDollFrame_SetRating(stat3, CR_HIT_SPELL);
		ArmoryPaperDollFrame_SetSpellCritChance(stat4);
		stat4:SetScript("OnEnter", ArmoryCharacterSpellCritChance_OnEnter);
		ArmoryPaperDollFrame_SetSpellHaste(stat5);
		ArmoryPaperDollFrame_SetManaRegen(stat6);
	elseif ( index == "PLAYERSTAT_DEFENSES" ) then
		ArmoryPaperDollFrame_SetArmor(stat1);
		ArmoryPaperDollFrame_SetDefense(stat2);
		ArmoryPaperDollFrame_SetDodge(stat3);
		ArmoryPaperDollFrame_SetParry(stat4);
		ArmoryPaperDollFrame_SetBlock(stat5);
		ArmoryPaperDollFrame_SetResilience(stat6);
	end

	-- Shouldn't really be necessary, since the VARIABLES_LOADED should take care of this on startup and the OnClick should handle it from there.
	-- But this covers us to be safe.
	ArmoryDropDownMenu_SetText(_G[prefix.."DropDown"], _G[index]);
end
