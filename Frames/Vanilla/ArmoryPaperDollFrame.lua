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

function ArmoryPaperDollFrame_UpdateStats()
    ArmoryPaperDollFrame_SetPrimaryStats();
	ArmoryPaperDollFrame_SetResistances();
	ArmoryPaperDollFrame_SetArmor();
	ArmoryPaperDollFrame_SetAttackBothHands();
	ArmoryPaperDollFrame_SetDamage();
	ArmoryPaperDollFrame_SetAttackPower();
	ArmoryPaperDollFrame_SetRangedAttack();
	ArmoryPaperDollFrame_SetRangedDamage();
	ArmoryPaperDollFrame_SetRangedAttackPower();
end

-- Update our primary stats (Strength, Agility, etc.).
function ArmoryPaperDollFrame_SetPrimaryStats()
	for i = 1, NUM_STATS, 1 do
		local text = _G["ArmoryStatFrame"..i.."StatText"];
		local frame = _G["ArmoryStatFrame"..i];
		local stat;
		local effectiveStat;
		local posBuff;
		local negBuff;
		stat, effectiveStat, posBuff, negBuff = Armory:UnitStat("player", i);

		-- Set the tooltip text
		local tooltipText = HIGHLIGHT_FONT_COLOR_CODE.._G["SPELL_STAT"..i.."_NAME"].." ";

		-- Get class specific tooltip for that stat
		local temp, classFileName = Armory:UnitClass("player");
		local classStatText = _G[strupper(classFileName).."_"..frame.stat.."_".."TOOLTIP"];
		-- If can't find one use the default
		if ( not classStatText ) then
			classStatText = _G["DEFAULT".."_"..frame.stat.."_".."TOOLTIP"];
		end

		if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
			text:SetText(effectiveStat);
			frame.tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE;
			frame.tooltip2 = classStatText;
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
			frame.tooltip2= classStatText;

			-- If there are any negative buffs then show the main number in red even if there are
			-- positive buffs. Otherwise show in green.
			if ( negBuff < 0 ) then
				text:SetText(RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
			else
				text:SetText(GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE);
			end
		end
	end
end

function ArmoryPaperDollFrame_SetArmor(unit, prefix)
	if ( not unit ) then
		unit = "player";
	end
	if ( not prefix ) then
		prefix = "";
	end

	local base, effectiveArmor, armor, posBuff, negBuff = Armory:UnitArmor(unit);

	if (unit ~= "player") then
		--[[ In 1.12.0, UnitArmor didn't report positive / negative buffs for units that weren't the active player.
			 This hack replicates that behavior for the UI. ]]
		base = effectiveArmor;
		armor = effectiveArmor;
		posBuff = 0;
		negBuff = 0;
    end
    if ( not base ) then
        return;
    end

	local totalBufs = posBuff + negBuff;

	local frame = _G["Armory"..prefix.."ArmorFrame"];
	local text = _G["Armory"..prefix.."ArmorFrameStatText"];

	PaperDollFormatStat(ARMOR, base, posBuff, negBuff, frame, text);
	local playerLevel = Armory:UnitLevel(unit);
	local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, playerLevel);

	frame.tooltip2 = format(ARMOR_TOOLTIP, playerLevel, armorReduction);
end

-- Note: while this function was historically named "BothHands",
-- it looks like it only ever displayed attack rating for the main hand.
function ArmoryPaperDollFrame_SetAttackBothHands(unit, prefix)
	if ( not unit ) then
		unit = "player";
	end
	if ( not prefix ) then
		prefix = "";
	end

    local mainHandAttackBase, mainHandAttackMod = Armory:UnitAttackBothHands(unit);
    if ( not mainHandAttackBase ) then
        return;
    end

	local frame = _G["Armory"..prefix.."AttackFrame"];
	local text = _G["Armory"..prefix.."AttackFrameStatText"];

	if( mainHandAttackMod == 0 ) then
		text:SetText(mainHandAttackBase);
	else
		local color = RED_FONT_COLOR_CODE;
		if( mainHandAttackMod > 0 ) then
			color = GREEN_FONT_COLOR_CODE;
		end
		text:SetText(color..(mainHandAttackBase + mainHandAttackMod)..FONT_COLOR_CODE_CLOSE);
	end

	frame.tooltip = ATTACK_TOOLTIP;
	frame.tooltip2 = ATTACK_TOOLTIP_SUBTEXT;
end

function ArmoryPaperDollFrame_SetAttackPower(unit, prefix)
	if ( not unit ) then
		unit = "player";
	end
	if ( not prefix ) then
		prefix = "";
	end

    local base, posBuff, negBuff = Armory:UnitAttackPower(unit);
    if ( not base ) then
        return;
    end

	local frame = _G["Armory"..prefix.."AttackPowerFrame"];
	local text = _G["Armory"..prefix.."AttackPowerFrameStatText"];

	PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff, frame, text);
	frame.tooltip2 = format(MELEE_ATTACK_POWER_TOOLTIP, max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER);
end

function ArmoryPaperDollFrame_SetDamage(unit, prefix)
	if ( not unit ) then
		unit = "player";
	end
	if ( not prefix ) then
		prefix = "";
	end

	local damageText = _G["Armory"..prefix.."DamageFrameStatText"];
	local damageFrame = _G["Armory"..prefix.."DamageFrame"];

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
    local damagePerSecond;
    if ( speed == 0 ) then
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
			damageText:SetText(displayMin.." - "..displayMax);
		else
			damageText:SetText(displayMin.."-"..displayMax);
		end
	else

		local color;
		if ( totalBonus > 0 ) then
			color = colorPos;
		else
			color = colorNeg;
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			damageText:SetText(color..displayMin.." - "..displayMax.."|r");
		else
			damageText:SetText(color..displayMin.."-"..displayMax.."|r");
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
	damageFrame.damage = damageTooltip;
	damageFrame.attackSpeed = speed;
	damageFrame.dps = damagePerSecond;

	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
        local offhandDamagePerSecond;
        if ( offhandSpeed == 0 ) then
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
		damageFrame.offhandDamage = offhandDamageTooltip;
		damageFrame.offhandAttackSpeed = offhandSpeed;
		damageFrame.offhandDps = offhandDamagePerSecond;
	else
		damageFrame.offhandAttackSpeed = nil;
	end
end

function ArmoryPaperDollFrame_SetRangedAttack(unit, prefix)
	if ( not unit ) then
		unit = "player";
	elseif ( unit == "pet" ) then
		return;
	end
	if ( not prefix ) then
		prefix = "";
	end

	local hasRelic = Armory:UnitHasRelicSlot(unit);

    local rangedAttackBase, rangedAttackMod = Armory:UnitRangedAttack(unit);
    if ( not rangedAttackBase ) then
        return;
    end

	local frame = _G["Armory"..prefix.."RangedAttackFrame"];
	local text = _G["Armory"..prefix.."RangedAttackFrameStatText"];

	-- If no ranged texture then set stats to n/a
	local rangedTexture = Armory:GetInventoryItemTexture("player", 18);
	local oldValue = ArmoryPaperDollFrame.noRanged;
	if ( rangedTexture and not hasRelic ) then
		ArmoryPaperDollFrame.noRanged = nil;
	else
		text:SetText(NOT_APPLICABLE);
		ArmoryPaperDollFrame.noRanged = 1;
		frame.tooltip = nil;
	end
	if ( not rangedTexture or hasRelic ) then
		return;
	end

	if( rangedAttackMod == 0 ) then
		text:SetText(rangedAttackBase);
	else
		local color = RED_FONT_COLOR_CODE;
		if( rangedAttackMod > 0 ) then
			color = GREEN_FONT_COLOR_CODE;
		end
		text:SetText(color..(rangedAttackBase + rangedAttackMod)..FONT_COLOR_CODE_CLOSE);
	end

	frame.tooltip = RANGED_ATTACK_TOOLTIP;
	frame.tooltip2 = ATTACK_TOOLTIP_SUBTEXT;
end

function ArmoryPaperDollFrame_SetRangedAttackPower(unit, prefix)
	if ( not unit ) then
		unit = "player";
	elseif ( unit == "pet" ) then
		return;
	end
	if ( not prefix ) then
		prefix = "";
	end
	local frame = _G["Armory"..prefix.."RangedAttackPowerFrame"];
	local text = _G["Armory"..prefix.."RangedAttackPowerFrameStatText"];

	-- If no ranged attack then set to n/a
	if ( ArmoryPaperDollFrame.noRanged ) then
		text:SetText(NOT_APPLICABLE);
		frame.tooltip = nil;
		return;
	end
	if ( Armory:HasWandEquipped() ) then
		text:SetText("--");
		frame.tooltip = nil;
		return;
	end

	local base, posBuff, negBuff = Armory:UnitRangedAttackPower(unit);
	PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff, frame, text);
	frame.tooltip2 = format(RANGED_ATTACK_POWER_TOOLTIP, base/ATTACK_POWER_MAGIC_NUMBER);
end

function ArmoryPaperDollFrame_SetRangedDamage(unit, prefix)
	if ( not unit ) then
		unit = "player";
	elseif ( unit == "pet" ) then
		return;
	end
	if ( not prefix ) then
		prefix = "";
	end

	local damageText = _G["Armory"..prefix.."RangedDamageFrameStatText"];
	local damageFrame = _G["Armory"..prefix.."RangedDamageFrame"];

	-- If no ranged attack then set to n/a
	if ( ArmoryPaperDollFrame.noRanged ) then
		damageText:SetText(NOT_APPLICABLE);
		damageFrame.damage = nil;
		return;
	end

    local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = Armory:UnitRangedDamage(unit);
    if ( not rangedAttackSpeed ) then
        return;
    end
	local displayMin = max(floor(minDamage),1);
	local displayMax = max(ceil(maxDamage),1);

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
		damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed);
	end

	local tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);

	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then
			damageText:SetText(displayMin.." - "..displayMax);
		else
			damageText:SetText(displayMin.."-"..displayMax);
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
			damageText:SetText(color..displayMin.." - "..displayMax.."|r");
		else
			damageText:SetText(color..displayMin.."-"..displayMax.."|r");
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
		damageFrame.tooltip = tooltip.." "..format(DPS_TEMPLATE, damagePerSecond);
	end
	damageFrame.attackSpeed = rangedAttackSpeed;
	damageFrame.damage = tooltip;
	damageFrame.dps = damagePerSecond;
end

function ArmoryPaperDollFrame_SetDefense(unit, prefix)
	if ( not unit ) then
		unit = "player";
	end
	if ( not prefix ) then
		prefix = "";
	end
    local base, modifier = Armory:UnitDefense(unit);
    if ( not base ) then
        return;
    end

	local frame = _G["Armory"..prefix.."DefenseFrame"];
	local text = _G["Armory"..prefix.."DefenseFrameStatText"];

	local posBuff = 0;
	local negBuff = 0;
	if ( modifier > 0 ) then
		posBuff = modifier;
	elseif ( modifier < 0 ) then
		negBuff = modifier;
	end
	PaperDollFormatStat(DEFENSE_COLON, base, posBuff, negBuff, frame, text);
end
