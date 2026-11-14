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

-- Resistance bonus of the pet: only TBC (Blizzard's WARLOCK_PET_BONUS and HUNTER_PET_BONUS)
local hasPetBonus = Armory.isTBC;

ARMORY_SLOTINFO = {
	INVTYPE_2HWEAPON = "MainHandSlot",
	INVTYPE_BODY = "ShirtSlot",
	INVTYPE_CHEST = "ChestSlot",
	INVTYPE_CLOAK = "BackSlot",
	INVTYPE_CROSSBOW = "RangedSlot",
	INVTYPE_FEET = "FeetSlot",
	INVTYPE_FINGER = "Finger0Slot",
	INVTYPE_FINGER_OTHER = "Finger1Slot",
	INVTYPE_GUN = "RangedSlot",
	INVTYPE_HAND = "HandsSlot",
	INVTYPE_HEAD = "HeadSlot",
	INVTYPE_HOLDABLE = "SecondaryHandSlot",
	INVTYPE_LEGS = "LegsSlot",
	INVTYPE_NECK = "NeckSlot",
	INVTYPE_RANGED = "RangedSlot",
	INVTYPE_RANGEDRIGHT = "RangedSlot",
	INVTYPE_RELIC = "RangedSlot",
	INVTYPE_ROBE = "ChestSlot",
	INVTYPE_SHIELD = "SecondaryHandSlot",
	INVTYPE_SHOULDER = "ShoulderSlot",
	INVTYPE_TABARD = "TabardSlot",
	INVTYPE_THROWN = "RangedSlot",
	INVTYPE_TRINKET = "Trinket0Slot",
	INVTYPE_TRINKET_OTHER = "Trinket1Slot",
	INVTYPE_WAIST = "WaistSlot",
	INVTYPE_WEAPON = "MainHandSlot",
	INVTYPE_WEAPON_OTHER = "SecondaryHandSlot",
	INVTYPE_WEAPONMAINHAND = "MainHandSlot",
	INVTYPE_WEAPONOFFHAND = "SecondaryHandSlot",
	INVTYPE_WRIST = "WristSlot",
	INVTYPE_WAND = "RangedSlot"
};

ARMORY_SLOTID = {
    HeadSlot = 1,
    NeckSlot = 2,
    ShoulderSlot = 3,
    ShirtSlot = 4,
    ChestSlot = 5,
    WaistSlot = 6,
    LegsSlot = 7,
    FeetSlot = 8,
    WristSlot = 9,
    HandsSlot = 10,
    Finger0Slot = 11,
    Finger1Slot = 12,
    Trinket0Slot = 13,
    Trinket1Slot = 14,
    BackSlot = 15,
    MainHandSlot = 16,
    SecondaryHandSlot = 17,
    RangedSlot = 18,
    TabardSlot = 19
};

ARMORY_SLOT = {
    HEADSLOT, -- 1
    NECKSLOT, -- 2
    SHOULDERSLOT, -- 3
    SHIRTSLOT, -- 4
    CHESTSLOT, -- 5
    WAISTSLOT, -- 6
    LEGSSLOT, -- 7
    FEETSLOT, -- 8
    WRISTSLOT, -- 9
    HANDSSLOT, -- 10
    FINGER0SLOT, -- 11
    FINGER1SLOT, -- 12
    TRINKET0SLOT, -- 13
    TRINKET1SLOT, -- 14
    BACKSLOT, -- 15
    MAINHANDSLOT, -- 16
    SECONDARYHANDSLOT, -- 17
    RANGEDSLOT, -- 18
    TABARDSLOT  -- 19
};

ARMORY_ANCHOR_SLOTINFO = {
    RIGHT = {point="TOPLEFT",    relativeTo="TOPRIGHT",   xFactor= 1, yFactor=-1, x= 0, y=6},
    LEFT  = {point="TOPRIGHT",   relativeTo="TOPLEFT",    xFactor=-1, yFactor=-1, x= 0, y=6},
    DOWN  = {point="TOPLEFT",    relativeTo="BOTTOMLEFT", xFactor= 1, yFactor=-1, x=-6, y=0},
    UP    = {point="BOTTOMLEFT", relativeTo="TOPLEFT",    xFactor= 1, yFactor= 1, x=-6, y=0}
};

ARMORY_MAX_ALTERNATE_SLOTS = 3;
ARMORY_ALTERNATE_SLOT_SIZE = 40;

function ArmoryPaperDollTalentFrame_OnLoad(self)
    self:RegisterEvent("CHARACTER_POINTS_CHANGED");
    self:RegisterEvent("SPELLS_CHANGED");
end

function ArmoryPaperDollTalentFrame_OnEvent(self, event, ...)
    if ( Armory:CanHandleEvents() ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateTalent);
    end
end

function ArmoryPaperDollTradeSkillFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("TRADE_SKILL_UPDATE");
    self:RegisterEvent("CRAFT_UPDATE");
	self:RegisterEvent("UPDATE_TRADESKILL_RECAST");
end

function ArmoryPaperDollTradeSkillFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:ProfessionsExists() ) then
            Armory:Execute(ArmoryPaperDollTradeSkillFrame_UpdateSkills);
        end
    else
        Armory:Execute(ArmoryPaperDollTradeSkillFrame_UpdateSkills);
    end
end

function ArmoryPaperDollTradeSkillFrame_UpdateSkills()
    Armory:UpdateProfessions();
    ArmoryPaperDollFrame_UpdateSkills();
end

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
    if ( not Armory:CanHandleEvents() and unit == "player" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateManaBar);
    end
end

function ArmoryPaperDollItemSlotButton_Update(button, itemId)
    local unit = "player";
    local count = 0;
    local link, quality, texture;

    if ( itemId ~= nil ) then
        if ( itemId ~= 0 ) then
            _, link, quality, _, _, _, _, _, _, texture = _G.GetItemInfo(itemId);
        end
        button.itemId = itemId;
    else
        link = Armory:GetInventoryItemLink(unit, button:GetID());
        quality = Armory:GetInventoryItemQuality(unit, button:GetID());
        texture = Armory:GetInventoryItemTexture(unit, button:GetID());
        count = Armory:GetInventoryItemCount(unit, button:GetID());
        button.itemId = nil;
    end

    if ( texture ) then
        SetItemButtonTexture(button, texture);
        SetItemButtonCount(button, count);
        button.hasItem = 1;
    else
        texture = button.backgroundTextureName;
        if ( button.checkRelic and Armory:UnitHasRelicSlot(unit) ) then
            texture = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp";
        end
        SetItemButtonTexture(button, texture);
        SetItemButtonCount(button, 0);
        button.hasItem = nil;
    end

    SetItemButtonQuality(button, quality, button.itemId or link);

    Armory:SetInventoryItem("player", button:GetID(), true);
    button.link = link;
end

function ArmoryPaperDollItemSlotButton_OnLoad(self)
    local slotName = self:GetName();
    local id, textureName, checkRelic = GetInventorySlotInfo(strsub(slotName,7));
    self:SetID(id);
    local texture = _G[slotName.."IconTexture"];
    texture:SetTexture(textureName);
    self.backgroundTextureName = textureName;
    self.checkRelic = checkRelic;

    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
end

function ArmoryPaperDollItemSlotButton_OnEnter(self)
    local hasItem;
    self.anchor = "ANCHOR_RIGHT";
    GameTooltip:SetOwner(self, self.anchor);
    if ( self.itemId == nil ) then
        if ( self:GetID() == 0 or (self:GetID() >= 16 and self:GetID() <= 18) ) then
            ArmoryAlternateSlotFrame_Show(self, "VERTICAL", "DOWN");
        elseif ( self:GetID() ~= 9 and self:GetID() >= 6 and self:GetID() <= 14 ) then
            self.anchor = "ANCHOR_LEFT";
            ArmoryAlternateSlotFrame_Show(self, "HORIZONTAL", "RIGHT");
            if ( ArmoryAlternateSlotFrame:IsShown() ) then
                GameTooltip:SetOwner(ArmoryAlternateSlotFrame, "ANCHOR_RIGHT", -6, -6);
            end
        else
            ArmoryAlternateSlotFrame_Show(self, "HORIZONTAL", "LEFT");
        end
        hasItem = Armory:SetInventoryItem("player", self:GetID());
    elseif ( self.itemId ~= 0 ) then
        local _, link = _G.GetItemInfo(self.itemId);
        Armory:SetInventoryItem("player", self:GetID(), nil, nil, link);
        hasItem = true;
    end
    if ( not hasItem ) then
        local text = _G[strupper(strsub(self:GetName(), 7))];
        if ( self.checkRelic and Armory:UnitHasRelicSlot("player") ) then
            text = RELICSLOT;
        end
        GameTooltip:SetText(text);
    end
end

function ArmoryPaperDollItemSlotButton_OnClick(self, button)
    if ( self.link and IsModifiedClick("CHATLINK") ) then
        HandleModifiedItemClick(self.link);
    end
end

function ArmoryPaperDollFrame_SetLevel()
    local unit = "player";
    local class, classEn = Armory:UnitClass(unit);
    local level = Armory:UnitLevel(unit);
    local race = Armory:UnitRace(unit);
    local text = format(PLAYER_LEVEL, level, race, "|c"..Armory:ClassColor(classEn, true)..class..FONT_COLOR_CODE_CLOSE);
    local xp = Armory:GetXP();
    if ( xp ) then
        text = text.." ("..XP.." "..xp..")";
    end
    ArmoryLevelText:SetText(text);
end

function ArmoryPaperDollFrame_SetGuild()
    local guildName, title = Armory:GetGuildInfo("player");
    if ( guildName ) then
        ArmoryGuildText:Show();
        ArmoryGuildText:SetFormattedText(GUILD_TITLE_TEMPLATE, title, guildName);
    else
        ArmoryGuildText:Hide();
    end
end

function ArmoryPaperDollFrame_SetZone()
    local zoneName = Armory:GetZoneText();
    local subzoneName = Armory:GetSubZoneText();
    if ( subzoneName == zoneName ) then
        subzoneName = "";
    end

    if ( zoneName ) then
        if ( subzoneName ~= "" ) then
            zoneName = zoneName..", "..subzoneName;
        end
        ArmoryZoneText:Show();
        ArmoryZoneText:SetText(zoneName);
    else
        ArmoryZoneText:Hide();
    end
end

function ArmoryPaperDollFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("UNIT_LEVEL");
    self:RegisterEvent("UNIT_RESISTANCES");
    self:RegisterEvent("UNIT_STATS");
    self:RegisterEvent("UNIT_DAMAGE");
	self:RegisterEvent("UNIT_RANGEDDAMAGE");
	self:RegisterEvent("PLAYER_DAMAGE_DONE_MODS");
	self:RegisterEvent("UNIT_ATTACK_SPEED");
	self:RegisterEvent("UNIT_ATTACK_POWER");
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER");
	self:RegisterEvent("UNIT_ATTACK");
	self:RegisterEvent("PLAYER_GUILD_UPDATE");
	self:RegisterEvent("SKILL_LINES_CHANGED");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    self:RegisterEvent("ZONE_CHANGED");
    self:RegisterEvent("ZONE_CHANGED_INDOORS");
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    self:RegisterEvent("PLAYER_CONTROL_LOST");
    self:RegisterEvent("PLAYER_CONTROL_GAINED");
    self:RegisterEvent("PLAYER_XP_UPDATE");
    self:RegisterEvent("UPDATE_EXHAUSTION");
    self:RegisterEvent("TRIAL_STATUS_UPDATE");
    self:RegisterEvent("UPDATE_FACTION");
    self:RegisterUnitEvent("UNIT_MAXHEALTH", "player");
    self:RegisterUnitEvent("UNIT_AURA", "player");
    if ( Armory.isTBC ) then
        self:RegisterEvent("COMBAT_RATING_UPDATE");
    end

    ArmoryPaperDollFrame_UpdateVersion();
end

function ArmoryPaperDollFrame_OnEvent(self, event, unit)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        -- Wait for data...
        Armory:ExecuteConditional(ArmoryPaperDollFrame_HasData, ArmoryPaperDollFrame_Update);
    end

    if ( unit == "player" ) then
        if ( event == "UNIT_LEVEL" or event == "PLAYER_XP_UPDATE" or event == "UPDATE_EXHAUSTION" ) then
            Armory:Execute(ArmoryPaperDollFrame_SetLevel);
        elseif ( event == "UNIT_DAMAGE" or
                 event == "UNIT_ATTACK_SPEED" or
                 event == "UNIT_RANGEDDAMAGE" or
                 event == "UNIT_ATTACK" or
                 event == "UNIT_STATS" or
                 event == "UNIT_RANGED_ATTACK_POWER" or
                 event == "UNIT_MAXHEALTH" or
                 event == "UNIT_AURA" or
                 event == "UNIT_RESISTANCES" ) then
            Armory:Execute(ArmoryPaperDollFrame_UpdateStats);
        elseif ( event == "PLAYER_GUILD_UPDATE" ) then
            Armory:Execute(ArmoryPaperDollFrame_SetGuild);
        end
    end

    if ( event == "COMBAT_RATING_UPDATE" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateStats);
    elseif ( event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" ) then
        Armory:Execute(ArmoryPaperDollFrame_SetZone);
    elseif ( event == "PLAYER_CONTROL_LOST" ) then
        self:UnregisterEvent("ZONE_CHANGED");
        self:UnregisterEvent("ZONE_CHANGED_INDOORS");
    elseif ( event == "PLAYER_CONTROL_GAINED" ) then
        self:RegisterEvent("ZONE_CHANGED");
        self:RegisterEvent("ZONE_CHANGED_INDOORS");
        Armory:Execute(ArmoryPaperDollFrame_SetZone);
    elseif ( (event == "UNIT_LEVEL" and unit == "player") or event == "SKILL_LINES_CHANGED" or event == "TRIAL_STATUS_UPDATE" or event == "UPDATE_FACTION" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateEquippable);
    elseif ( event == "PLAYER_EQUIPMENT_CHANGED" ) then
        Armory:Execute(ArmoryPaperDollFrame_UpdateInventory);
    end
end

function ArmoryPaperDollFrame_HasData()
    local unit = "player";
    return UnitLevel(unit) and UnitRace(unit) and UnitClass(unit);
end

function ArmoryPaperDollFrame_OnShow(self)
    ArmoryPaperDollFrame_Update();
end

function ArmoryPaperDollFrame_SetResistances()
	for i = 1, NUM_RESISTANCE_TYPES, 1 do
		local resistance;
		local positive;
		local negative;
		local resistanceLevel;
		local base;
		local text = _G["ArmoryMagicResText"..i];
		local frame = _G["ArmoryMagicResFrame"..i];

		base, resistance, positive, negative = Armory:UnitResistance("player", frame:GetID());

		-- resistances can now be negative. Show Red if negative, Green if positive, white otherwise
		if( abs(negative) > positive ) then
			text:SetText(RED_FONT_COLOR_CODE..resistance..FONT_COLOR_CODE_CLOSE);
		elseif( abs(negative) == positive ) then
			text:SetText(resistance);
		else
			text:SetText(GREEN_FONT_COLOR_CODE..resistance..FONT_COLOR_CODE_CLOSE);
		end

		local resistanceName = _G["RESISTANCE"..(frame:GetID()).."_NAME"];
		frame.tooltip = resistanceName.." "..resistance;
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

		local unitLevel = Armory:UnitLevel("player");
		unitLevel = max(unitLevel, 20);
		local magicResistanceNumber = resistance / unitLevel;
		if ( magicResistanceNumber > 5 ) then
			resistanceLevel = RESISTANCE_EXCELLENT;
		elseif ( magicResistanceNumber > 3.75 ) then
			resistanceLevel = RESISTANCE_VERYGOOD;
		elseif ( magicResistanceNumber > 2.5 ) then
			resistanceLevel = RESISTANCE_GOOD;
		elseif ( magicResistanceNumber > 1.25 ) then
			resistanceLevel = RESISTANCE_FAIR;
		elseif ( magicResistanceNumber > 0 ) then
			resistanceLevel = RESISTANCE_POOR;
		else
			resistanceLevel = RESISTANCE_NONE;
		end
		frame.tooltip2 = format(RESISTANCE_TOOLTIP_SUBTEXT, _G["RESISTANCE_TYPE"..frame:GetID()], unitLevel, resistanceLevel);
		if ( hasPetBonus ) then
			local petBonus = Armory:ComputePetBonus("PET_BONUS_RES", resistance);
			if ( petBonus > 0 ) then
				frame.tooltip2 = frame.tooltip2.."\n"..format(PET_BONUS_TOOLTIP_RESISTANCE, petBonus);
			end
		end
	end
end

function ArmoryPaperDollFrame_UpdateSlot(frame)
    Armory:SetInventoryItemInfo(frame:GetID());
    ArmoryPaperDollItemSlotButton_Update(frame);
end

function ArmoryPaperDollFrame_UpdateInventory()
    ArmoryPaperDollFrame_UpdateSlot(ArmoryHeadSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryNeckSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryShoulderSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryBackSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryChestSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryShirtSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryTabardSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryWristSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryHandsSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryWaistSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryLegsSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryFeetSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryFinger0Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryFinger1Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryTrinket0Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryTrinket1Slot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryMainHandSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmorySecondaryHandSlot);
    ArmoryPaperDollFrame_UpdateSlot(ArmoryRangedSlot);

    Armory.hasEquipment = true;
    Armory_EQC_Refresh();
end

function ArmoryPaperDollFrame_UpdateHealthBar()
	local currValue = Armory:UnitHealth("player");
	local maxValue = Armory:UnitHealthMax("player");
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
    local info = PowerBarColor[powerToken];
    local prefix = _G[powerToken];
    if ( info ) then
        ArmoryManaBar:SetStatusBarColor(info.r, info.g, info.b);
    elseif ( altR) then
        ArmoryManaBar:SetStatusBarColor(altR, altG, altB);
    end
    ArmoryManaTextFrameLabel:SetText(strupper(prefix)..":");
    ArmoryMana.tooltipTitle = prefix;
    ArmoryMana.tooltipText = _G["NEWBIE_TOOLTIP_MANABAR"..powerType];

    local currValue = Armory:UnitPower("player", powerType);
    local maxValue = Armory:UnitPowerMax("player");
	if ( maxValue == 0 ) then
		maxValue = 1;
	end

    ArmoryManaBar:SetMinMaxValues(0, maxValue);
	ArmoryManaBar:SetValue(currValue);
    ArmoryManaBarText:SetText(currValue.." / "..maxValue);
end

function ArmoryPaperDollFrame_UpdateTalent()
    local inspect = false;
	local talents = {};
    local maxPointsSpent = 0;
    local specialism = NONE;
    local iconTexture;

	for i = 1, Armory:GetNumTalentTabs(inspect) do
        local name, texture, pointsSpent = Armory:GetTalentTabInfo(i, inspect);
        talents[i] = pointsSpent;
        if ( pointsSpent > maxPointsSpent ) then
            specialism = name;
            iconTexture = texture;
            maxPointsSpent = pointsSpent;
        end
    end

    if ( iconTexture ) then
        Armory:SetPortraitToTexture(ArmoryPaperDollTalentButtonIcon, iconTexture);
    else
        ArmoryPaperDollTalentButtonIcon:SetTexture("");
    end
    ArmoryPaperDollTalentText:SetText(strupper(specialism));
    ArmoryPaperDollTalentPoints:SetText(strjoin(" / ", unpack(talents)));
end

local function UpdateSkillFrame(skillFrame, values)
    local label = _G[skillFrame:GetName().."Label"];
    local statusbar = _G[skillFrame:GetName().."Bar"];
    local bartext = _G[skillFrame:GetName().."BarText"];
    local icon = _G[skillFrame:GetName().."ButtonIcon"];

    if ( not values ) then
        skillFrame:Hide();
    else
        local skillName, skillRank, skillMaxRank = unpack(values);
        if ( not (skillName and skillRank and skillMaxRank) ) then
            skillFrame:Hide();
            return;
        end

        Armory:SetPortraitToTexture(icon, Armory:GetProfessionTexture(skillName));
        label:SetText(strupper(skillName));
        statusbar:SetMinMaxValues(0, skillMaxRank);
        statusbar:SetValue(skillRank);
        bartext:SetText(skillRank.." / "..skillMaxRank);
        skillFrame:Show();
    end
end

function ArmoryPaperDollFrame_UpdateSkills()
    local skills = Armory:GetPrimaryTradeSkills();
    if ( #skills == 0 ) then
        UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame1, nil);
        UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame2, nil);
    elseif ( #skills == 1 ) then
        UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame1, skills[1]);
        UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame2, nil);
    else
        UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame1, skills[1]);
        UpdateSkillFrame(ArmoryPaperDollTradeSkillFrame2, skills[2]);
    end
end

function ArmoryPaperDollFrame_Update()
    ArmoryBuffFrame_Update("player");
    ArmoryPaperDollFrame_SetGuild();
    ArmoryPaperDollFrame_SetZone();
    ArmoryPaperDollFrame_SetLevel();
    ArmoryPaperDollFrame_UpdateStats();
    ArmoryPaperDollFrame_UpdateHealthBar();
    ArmoryPaperDollFrame_UpdateManaBar();
    ArmoryPaperDollFrame_UpdateTalent();
    ArmoryPaperDollFrame_UpdateSkills();
    ArmoryPaperDollFrame_UpdateInventory();
end

local alternatives = {};
function ArmoryAlternateSlotFrame_Show(parent, orientation, direction)
    if ( not Armory:GetConfigShowAltEquipment() ) then
        return;
    end

    local frame = ArmoryAlternateSlotFrame;
    local slotName = strsub(parent:GetName(), 7);
    local parentId = Armory:GetUniqueItemId(parent.link)
    local id, link, equipLoc, texture, itemId;
    local numItems = 0;

    table.wipe(alternatives);

    for i = 1, #ArmoryInventoryContainers do
        id = ArmoryInventoryContainers[i];
        if ( id > ARMORY_MAIL_CONTAINER ) then
            for index = 1, Armory:GetContainerNumSlots(id) do
                link = Armory:GetContainerItemLink(id, index);
                if ( link and IsEquippableItem(link) and (Armory:GetContainerItemCanEquip(id, index) or Armory:GetConfigShowUnequippable()) ) then
                    _, _, _, _, _, _, _, _, equipLoc, texture = GetItemInfo(link);
                    if ( ARMORY_SLOTINFO[equipLoc] and ARMORY_SLOTINFO[equipLoc] == slotName ) then
                        itemId = Armory:GetUniqueItemId(link);
                        if ( not alternatives[itemId] and itemId ~= parentId ) then
                            alternatives[itemId] = {link=link, texture=texture};
                            numItems = numItems + 1;
                        end
                    end
                end
            end
        end
    end

    if ( numItems == 0 ) then
        frame:Hide();
        return;
    end

    local length = min(numItems, ARMORY_MAX_ALTERNATE_SLOTS) * ARMORY_ALTERNATE_SLOT_SIZE;
    local xOffset = 12;
    local yOffset = 14;
    if ( direction == "LEFT" and parent:GetLeft() - length + xOffset < 0 ) then
        direction = "RIGHT";
    elseif ( direction == "RIGHT" and parent:GetRight() + length - xOffset > GetScreenWidth() ) then
        direction = "LEFT";
    elseif ( parent:GetBottom() - length + yOffset < 0 ) then
        direction = "UP";
    end
    local anchor = ARMORY_ANCHOR_SLOTINFO[direction];
    local row, column, x, y, button;
    local i = 0;
    for _, item in pairs(alternatives) do
        row = floor(i / ARMORY_MAX_ALTERNATE_SLOTS);
        column = i % ARMORY_MAX_ALTERNATE_SLOTS;
        if ( orientation == "VERTICAL" ) then
            x = row;
            y = column;
        else
            x = column;
            y = row;
        end
        i = i + 1;
        x = (8 + x * ARMORY_ALTERNATE_SLOT_SIZE) * anchor.xFactor;
        y = (8 + y * ARMORY_ALTERNATE_SLOT_SIZE) * anchor.yFactor;

        -- "^Armory.*Slot" pattern used by EQC
        button = _G["ArmoryAlternate"..i.."Slot"];
        if ( not button ) then
            button = CreateFrame("CheckButton", "ArmoryAlternate"..i.."Slot", frame, "ArmoryItemButtonTemplate");
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
            button:SetScript("OnClick", ArmoryAlternateSlotButton_OnClick);
            button:SetScript("OnEnter", ArmoryAlternateSlotButton_OnEnter);
            button:SetScript("OnLeave", ArmoryAlternateSlotButton_OnLeave);
        end
        SetItemButtonTexture(button, item.texture);
        Armory:SetItemLink(button, item.link);
        button.anchor = parent.anchor;
        button:SetID(parent:GetID());
        button:ClearAllPoints();
        button:SetPoint(anchor.point, frame, anchor.point, x, y);
        button:SetFrameLevel(frame:GetFrameLevel() + 1);
        button:Show();
    end
    table.wipe(alternatives);

    ArmoryAlternateSlotFrame_HideSlots(numItems + 1);

    frame:ClearAllPoints();
    frame:SetParent(parent);
    frame:SetFrameLevel(parent:GetFrameLevel() + 4);
    frame:SetScale(.85);
    frame:SetPoint(anchor.point, parent, anchor.relativeTo, anchor.x, anchor.y);
    if ( orientation == "VERTICAL" ) then
        frame:SetWidth((row + 1) * ARMORY_ALTERNATE_SLOT_SIZE + xOffset);
        frame:SetHeight(length + yOffset);
    else
        frame:SetWidth(length + xOffset);
        frame:SetHeight((row + 1) * ARMORY_ALTERNATE_SLOT_SIZE + yOffset);
    end
    frame.delay = 0;
    frame:Show();
end

function ArmoryAlternateSlotButton_OnClick(self, button)
    if ( self.link and IsModifiedClick("CHATLINK") ) then
        HandleModifiedItemClick(self.link);
    end
end

function ArmoryAlternateSlotButton_OnEnter(self)
    GameTooltip:SetOwner(self, self.anchor);
    Armory:SetInventoryItem("player", self:GetID(), false, false, self.link);
end

function ArmoryAlternateSlotButton_OnLeave(self)
    GameTooltip:Hide();
end

function ArmoryAlternateSlotFrame_OnUpdate(self, elapsed)
    local now = time();
    if ( self:IsVisible() and now >= self.delay ) then
        if ( self:IsMouseOver() or self:GetParent():IsMouseOver() ) then
            return;
        end
        self:Hide();
    end
    self.delay = now + 0.5;
end

function ArmoryAlternateSlotFrame_HideSlots(start)
    local i = start or 1;
    while ( _G["ArmoryAlternate"..i.."Slot"] ) do
        _G["ArmoryAlternate"..i.."Slot"]:Hide();
        i = i + 1;
    end
end

function ArmoryPaperDollFrame_UpdateEquippable()
    Armory:UpdateInventoryEquippable();
end

function ArmoryPaperDollFrame_UpdateVersion(version)
    local major, minor, rel, lastVersion;
    local myVersion = Armory.version:match("^v?([%d%.]+)")

    if ( myVersion ) then
        ArmoryVersionText:SetText("v"..Armory.version:match("^v?(.+)"));

        if ( not ArmoryPaperDollFrame.lastVersion ) then
            major, minor, rel = strsplit(".", myVersion);
            ArmoryPaperDollFrame.lastVersion = major * 100 + (minor or 0) + (rel or 0) / 100;
        end

        if ( version ) then
            major, minor, rel = strsplit(".", version);
            if ( tonumber(major) ) then
                lastVersion = major * 100 + (minor or 0) + (rel or 0) / 100;
                if ( lastVersion > ArmoryPaperDollFrame.lastVersion ) then
                    ArmoryPaperDollFrame.lastVersion = lastVersion;
                    ArmoryNewVersionText:SetFormattedText("|cffff0000new!|r v|cffffffff%s", version);
                    ArmoryNewVersionText:Show();
                end
            end
        end
    else
        ArmoryVersionText:SetText(RED_FONT_COLOR_CODE..Armory.version..FONT_COLOR_CODE_CLOSE);
    end
end
