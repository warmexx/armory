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

ARMORY_CONQUEST_SIZE_STRINGS = { ARENA_2V2, ARENA_3V3, BATTLEGROUND_10V10 };
ARMORY_CONQUEST_BUTTONS = {};
local RATED_BG_ID = 3;

function ArmoryPVPFrame_OnLoad(self)
	ARMORY_CONQUEST_BUTTONS = {ArmoryConquestFrame.Arena2v2, ArmoryConquestFrame.Arena3v3, ArmoryConquestFrame.RatedBG};

    ArmoryPVPFrameLine1:SetAlpha(0.3);
    ArmoryPVPHonorKillsLabel:SetVertexColor(0.6, 0.6, 0.6);
    ArmoryPVPHonorHonorLabel:SetVertexColor(0.6, 0.6, 0.6);
    ArmoryPVPHonorTodayLabel:SetVertexColor(0.6, 0.6, 0.6);
    ArmoryPVPHonorYesterdayLabel:SetVertexColor(0.6, 0.6, 0.6);
    ArmoryPVPHonorLifetimeLabel:SetVertexColor(0.6, 0.6, 0.6);
    ArmoryConquestFrameLabel:SetText(strupper(PVP_CONQUEST)..":");

    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PLAYER_PVP_KILLS_CHANGED");
    self:RegisterEvent("PLAYER_PVP_RANK_CHANGED");
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    self:RegisterEvent("PVP_RATED_STATS_UPDATE");
    self:RegisterEvent("PVP_REWARDS_UPDATE");
    self:RegisterEvent("HONOR_XP_UPDATE");
    self:RegisterEvent("UPDATE_EXHAUSTION");
    self:RegisterEvent("HONOR_LEVEL_UPDATE");
    self:RegisterEvent("PLAYER_UPDATE_RESTING");
    self:RegisterEvent("HONOR_PRESTIGE_UPDATE");
    self:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");

    RequestRatedInfo();
    RequestPVPRewards();
    
    -- update the tabs
    PanelTemplates_SetNumTabs(self, 2);
    PanelTemplates_UpdateTabs(self);
    PanelTemplates_SetTab(self, 1);
end

function ArmoryPVPFrame_OnEvent(self, event, ...)
    local arg1 = ...;
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        ArmoryPVPFrame_SetFaction();
        ArmoryPVPHonor_Update(true);
        ArmoryPVPHonorXPBar_Update();
        if ( Armory.forceScan or not Armory:HonorTalentsExists() ) then
			Armory:Execute(ArmoryPVPFrame_UpdateTalents);
        end
    elseif ( event == "HONOR_XP_UPDATE" or event == "HONOR_LEVEL_UPDATE" or event == "HONOR_PRESTIGE_UPDATE" ) then
        ArmoryPVPHonorXPBar_Update();
		Armory:Execute(ArmoryPVPFrame_UpdateTalents);
    elseif ( event == "UPDATE_EXHAUSTION" or event == "PLAYER_UPDATE_RESTING" ) then
        ArmoryPVPHonorXPBar_Update();
    elseif ( event == "PLAYER_PVP_TALENT_UPDATE" ) then
		Armory:Execute(ArmoryPVPFrame_UpdateTalents);
    else
        ArmoryPVPHonor_Update();
    end

    ArmoryConquestFrame_Update();
end

function ArmoryPVPFrame_UpdateTalents()
    Armory:SetHonorTalents();
	ArmoryPVPTalents_Update();
end

function ArmoryPVPFrame_OnShow(self)
	RequestRatedInfo();
	RequestPVPRewards();
    ArmoryPVPFrame_Update(PanelTemplates_GetSelectedTab(self));
end

function ArmoryPVPFrameTab_OnClick(self)
    PanelTemplates_SetTab(self:GetParent(), self:GetID());
    ArmoryPVPFrame_Update(self:GetID());
end

function ArmoryPVPFrame_SetFaction()
    local factionGroup = Armory:UnitFactionGroup("player");
    if ( factionGroup and factionGroup ~= "Neutral" ) then
        ArmoryPVPFrameHonorIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup);
        ArmoryPVPFrameHonorIcon:Show();
    end
end

function ArmoryPVPFrame_Update(currentTab)
    ArmoryPVPFrame_SetFaction();
    ArmoryPVPHonor_Update();
    ArmoryConquestFrame_Update();
    ArmoryPVPHonorXPBar_Update();
    ArmoryPVPTalents_Update();

    if ( Armory:GetPvpTalentInfo(1, 1) ) then
        ArmoryPVPFrameTab1:Show();
        ArmoryPVPFrameTab2:Show();
        PanelTemplates_SetTab(ArmoryPVPFrame, currentTab);
    else
        ArmoryPVPFrameTab1:Hide();
        ArmoryPVPFrameTab2:Hide();
    end

    if ( currentTab == 2 and Armory:GetPvpTalentInfo(1, 1) ) then
        ArmoryPVPFrameHonor:Hide();
        ArmoryConquestFrame:Hide();
        
        ArmoryPVPHonorXPBar:Show();
        ArmoryPVPTalents:Show();
    else
        ArmoryPVPHonorXPBar:Hide();
        ArmoryPVPTalents:Hide();

        ArmoryPVPFrameHonor:Show();
        ArmoryConquestFrame:Show();
    end
end


----------------------------------------------------------
-- PVP Honor
----------------------------------------------------------

function ArmoryPVPHonor_Update(updateAll)
    local hk, cp, contribution;

    -- Yesterday's values (this only gets set on player entering the world)
    hk, contribution = Armory:GetPVPYesterdayStats(updateAll);
    ArmoryPVPHonorYesterdayKills:SetText(hk);
    ArmoryPVPHonorYesterdayHonor:SetText(contribution);

    -- Lifetime values
    hk, contribution = Armory:GetPVPLifetimeStats();
    ArmoryPVPHonorLifetimeKills:SetText(hk);

    -- Today's values
    hk, cp = Armory:GetPVPSessionStats();
    ArmoryPVPHonorTodayKills:SetText(hk);
    ArmoryPVPHonorTodayHonor:SetText(cp);
    ArmoryPVPHonorTodayHonor:SetHeight(14);

    local _, quantity = Armory:GetCurrencyInfo(HONOR_CURRENCY);
    ArmoryPVPFrameHonorPoints:SetText(quantity);
end


----------------------------------------------------------
-- PVP Conquest
----------------------------------------------------------

function ArmoryConquestFrame_Update()
    _, quantity = Armory:GetCurrencyInfo(CONQUEST_CURRENCY);
    ArmoryConquestFramePoints:SetText(quantity);

	for i = 1, RATED_BG_ID do
		local button = ARMORY_CONQUEST_BUTTONS[i];
		local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon = Armory:GetPersonalRatedInfo(i);
		button.Wins:SetText(seasonWon);
		button.BestRating:SetText(weeklyBest);
		button.CurrentRating:SetText(rating);
	end
end

local CONQUEST_TOOLTIP_PADDING = 30 --counts both sides

function ArmoryConquestFrameButton_OnEnter(self)
	local tooltip = ArmoryConquestTooltip;

	local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon = Armory:GetPersonalRatedInfo(self.id);

	tooltip.Title:SetText(self.toolTipTitle);

    tooltip.WeeklyBest:SetText(PVP_BEST_RATING..weeklyBest);
    tooltip.WeeklyGamesWon:SetText(PVP_GAMES_WON..weeklyWon);
    tooltip.WeeklyGamesPlayed:SetText(PVP_GAMES_PLAYED..weeklyPlayed);

    tooltip.SeasonBest:SetText(PVP_BEST_RATING..seasonBest);
    tooltip.SeasonWon:SetText(PVP_GAMES_WON..seasonWon);
    tooltip.SeasonGamesPlayed:SetText(PVP_GAMES_PLAYED..seasonPlayed);

	local maxWidth = 0;
	for i, fontString in ipairs(tooltip.Content) do
		maxWidth = math.max(maxWidth, fontString:GetStringWidth());
	end

    tooltip:SetWidth(maxWidth + CONQUEST_TOOLTIP_PADDING);
    tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0);
    tooltip:Show();
end


----------------------------------------------------------
-- PVP XP
----------------------------------------------------------

ArmoryPVPHonorRewardTalentMixin = Mixin({}, PVPHonorRewardInfoMixin);

function ArmoryPVPHonorRewardTalentMixin:Set(...)
	local id = ...;
	self.id = id;
	self.icon = select(3, GetPvpTalentInfoByID(id, function() return Armory:GetActiveSpecGroup() end));
end

function ArmoryPVPHonorRewardTalentMixin:SetTooltip()
	GameTooltip:SetPvpTalent(self.id);
    return true;
end

ArmoryPVPHonorRewardArtifactPowerMixin = Mixin({}, PVPHonorRewardInfoMixin);

function ArmoryPVPHonorRewardArtifactPowerMixin:Set(...)
	local quantity = ...;
	self.icon = select(4, Armory:GetEquippedArtifactInfo()) or 1109508;
	self.quantity = quantity;
end

function ArmoryPVPHonorRewardArtifactPowerMixin:SetTooltip()
	GameTooltip:SetText(HONOR_REWARD_ARTIFACT_POWER);
	GameTooltip:AddLine(ARTIFACT_POWER_GAIN:format(self.quantity), 1, 1, 1, true);
    return true;
end


function ArmoryPVPHonorXPBar_OnLoad(self)
    self:SetScale(.85);
end

function ArmoryPVPHonorXPBar_OnShow(self)
	if ( self.Bar.Lock ) then
        ArmoryPVPHonorXPBar_CheckLockState(self);
    end
end

function ArmoryPVPHonorXPBar_CheckLockState(self)
    if ( Armory:UnitLevel("player") < MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_LEVEL_CURRENT] ) then
        ArmoryPVPHonorXPBar_Lock(self);
    else
        ArmoryPVPHonorXPBar_Unlock(self);
    end
end

function ArmoryPVPHonorXPBar_Lock(self)
    self.NextAvailable:Hide();
    self.Level:Hide();
    self.Bar.ExhaustionLevelFillBar:Hide();
    self.Bar.ExhaustionTick:Hide();
    self.Bar.Lock:Show();
    self.Frame:SetAlpha(.5);
    self.Bar.Background:SetAlpha(.5);
    self.Frame:SetDesaturated(true);
    self.Bar.Background:SetDesaturated(true);

    self.locked = true;
end

function ArmoryPVPHonorXPBar_Unlock(self)
    self.Level:Show();
    self.Frame:SetAlpha(1);
    self.Bar.Background:SetAlpha(1);
    self.Bar.Lock:Hide();
    self.Frame:SetDesaturated(false);
    self.Bar.Background:SetDesaturated(false);
    self.locked = false;
    ArmoryPVPHonorXPBar_Update();
end

function ArmoryPVPHonorXPBar_Update()
    local frame = ArmoryPVPHonorXPBar;
    local current = Armory:UnitHonor("player");
    local max = Armory:UnitHonorMax("player");

    local level = Armory:UnitHonorLevel("player");
    local levelmax = GetMaxPlayerHonorLevel();

    if ( level == levelmax ) then
        -- Force the bar to full for the max level
        frame.Bar:SetMinMaxValues(0, 1);
        frame.Bar:SetValue(1);
    else
        frame.Bar:SetMinMaxValues(0, max);
        frame.Bar:SetValue(current);
    end

    local exhaustionStateID = Armory:GetHonorRestState();
    if ( exhaustionStateID == 1 ) then
        frame.Bar:SetStatusBarAtlas("_honorsystem-bar-fill-rested");
    else
        frame.Bar:SetStatusBarAtlas("_honorsystem-bar-fill");
    end

    if ( not frame.locked ) then
        frame.Level:SetText(Armory:UnitHonorLevel("player"));
        ArmoryPVPHonorXPBar_SetNextAvailable(frame);
        ArmoryHonorExhaustionTick_Update(frame.Bar.ExhaustionTick);
    end
end

function ArmoryPVPHonorXPBar_SetNextAvailable(self)
    local showNext = false;
    local showPrestige = false;

    if ( Armory:CanPrestige() ) then
        showPrestige = true;
        ArmoryPVPHonorXPBar_SetPrestige(self.PrestigeReward);
    else
        showPrestige = false;

        self.rewardInfo = ArmoryPVPHonorXPBar_GetNextReward();

        if ( self.rewardInfo ) then
            self.rewardInfo:SetUpFrame(self.NextAvailable);
            showNext = true;	
        end
    end

    self.NextAvailable:SetShown(showNext);
    self.PrestigeReward:SetShown(showPrestige);
end

function ArmoryPVPHonorXPBar_SetPrestige(self)
    local newPrestigeLevel = Armory:UnitPrestige("player") + 1;

    self.PortraitBg:SetAtlas("honorsystem-prestige-laurel-bg-"..Armory:UnitFactionGroup("player"), false);
    self.Icon:SetTexture(GetPrestigeInfo(newPrestigeLevel) or 0);

    self:Show();
end


local function CreateHackRewardInfo()
    local rewardInfo;
    local factionGroup = Armory:UnitFactionGroup("player");
    local itemID;
    if ( factionGroup == "Horde" ) then
        itemID = 138996;
    else
        itemID = 138992;
    end
    rewardInfo = CreateFromMixins(PVPHonorRewardItemMixin);
    rewardInfo:Set(itemID);
    return rewardInfo;
end

function ArmoryPVPHonorXPBar_GetNextReward()
    local rewardInfo;

    local talentID = Armory:GetPvpTalentUnlock();	
    if ( talentID ) then
        rewardInfo = CreateFromMixins(ArmoryPVPHonorRewardTalentMixin);
        rewardInfo:Set(talentID);
    -- TODO:  Remove this when we can figure this out in a better way
    elseif ( Armory:UnitPrestige("player") == 1 and Armory:UnitHonorLevel("player") == 49 ) then
        rewardInfo = CreateHackRewardInfo();
    else
        local rewardPackID = Armory:GetHonorLevelRewardPack();
        if ( rewardPackID ) then
            local items = GetRewardPackItems(rewardPackID);
            local currencies = GetRewardPackCurrencies(rewardPackID);
            local money = GetRewardPackMoney(rewardPackID);
            local artifactPower = GetRewardPackArtifactPower(rewardPackID);
            local title = GetRewardPackTitle(rewardPackID);
            if ( items and #items > 0 ) then
                rewardInfo = CreateFromMixins(PVPHonorRewardItemMixin);
                rewardInfo:Set(items[1]);
            elseif ( artifactPower and artifactPower > 0 ) then
                rewardInfo = CreateFromMixins(ArmoryPVPHonorRewardArtifactPowerMixin);
                rewardInfo:Set(artifactPower);
            elseif ( currencies and #currencies > 0 ) then
                rewardInfo = CreateFromMixins(PVPHonorRewardCurrencyMixin);
                rewardInfo:Set(currencies[1].currencyType, currencies[1].quantity);
            elseif ( money and money > 0 ) then
                rewardInfo = CreateFromMixins(PVPHonorRewardMoneyMixin);
                rewardInfo:Set(money);
            elseif ( title and title > 0 ) then
                rewardInfo = CreateFromMixins(PVPHonorRewardTitleMixin);
                rewardInfo:Set(title);
            end
        end
    end

    return rewardInfo;
end

function ArmoryPVPHonorXPBar_OnEnter(self)
    local current = Armory:UnitHonor("player");
    local max = Armory:UnitHonorMax("player");

    if ( not current or not max ) then
        return;
    end

    local level = Armory:UnitHonorLevel("player");
    local levelmax = GetMaxPlayerHonorLevel();

    if ( Armory:CanPrestige() ) then
        self.OverlayFrame.Text:SetText(PVP_HONOR_PRESTIGE_AVAILABLE);
    elseif ( level == levelmax ) then
        self.OverlayFrame.Text:SetText(MAX_HONOR_LEVEL);
    else
        self.OverlayFrame.Text:SetText(HONOR_BAR:format(current, max));
    end
    self.OverlayFrame.Text:Show();
end

function ArmoryPVPHonorXPBar_OnLeave(self)
    self.OverlayFrame.Text:Hide();
end

function ArmoryHonorExhaustionTick_OnLoad(self)
	self.fillBarAlpha = 0.15;
end

function ArmoryHonorExhaustionTick_Update(self)
	local fillBar = self:GetParent().ExhaustionLevelFillBar;
    local level = Armory:UnitHonorLevel("player");
    local levelmax = GetMaxPlayerHonorLevel();

    local playerCurrXP = Armory:UnitHonor("player");
    local playerMaxXP = Armory:UnitHonorMax("player");
    local exhaustionCountdown = Armory:GetTimeToWellRested();
    local exhaustionThreshold = Armory:GetHonorExhaustion();
    local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier, exhaustionTickSet;
    exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = Armory:GetHonorRestState();

    if ( level == levelmax or not exhaustionThreshold or exhaustionTreshold == 0 ) then
        self:Hide();
		fillBar:Hide();
        return;
    else
        exhaustionTickSet = max(((playerCurrXP + exhaustionThreshold) / playerMaxXP) * self:GetParent():GetWidth(), 0);
        if (exhaustionTickSet > self:GetParent():GetWidth()) then
            self:Hide();
		    fillBar:Hide();
        else
            fillBar:SetWidth(exhaustionTickSet);
            fillBar:Show();
            self:Show();
        end
    end
    
    if ( exhaustionStateID == 1 ) then
        local r, g, b = 1.0, 0.50, 0.0;
		fillBar:SetVertexColor(r, g, b, self.fillBarAlpha);
        self.Highlight:SetVertexColor(r, g, b, 1.0);
    end
end

function ArmoryHonorExhaustionToolTipText()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);	

    local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier;
    exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = Armory:GetHonorRestState();

    local exhaustionCurrXP, exhaustionMaxXP;
    local exhaustionThreshold = Armory:GetHonorExhaustion();

    exhaustionStateMultiplier = exhaustionStateMultiplier * 100;
    local exhaustionCountdown = nil;
    if ( Armory:GetTimeToWellRested() ) then
        exhaustionCountdown = Armory:GetTimeToWellRested() / 60;
    end

    local currXP = Armory:UnitHonor("player");
    local nextXP = Armory:UnitHonorMax("player");
    local percentXP = math.ceil(currXP / nextXP * 100);
    local XPText = format( XP_TEXT, BreakUpLargeNumbers(currXP), BreakUpLargeNumbers(nextXP), percentXP );
    local tooltipText = XPText..format(EXHAUST_HONOR_TOOLTIP1, exhaustionStateName, exhaustionStateMultiplier);
    local append = nil;
    if ( Armory:IsResting() ) then
        if ( exhaustionThreshold and exhaustionCountdown ) then
            append = format(EXHAUST_TOOLTIP4, exhaustionCountdown);
        end
    elseif ( (exhaustionStateID == 4) or (exhaustionStateID == 5) ) then
        append = EXHAUST_TOOLTIP2;
    end

    if ( append ) then
        tooltipText = tooltipText..append;
    end

    if ( SHOW_NEWBIE_TIPS ~= "1" ) then
        GameTooltip:SetText(tooltipText);
    end
end


----------------------------------------------------------
-- PVP Talents
----------------------------------------------------------

function ArmoryPVPTalentsTalent_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");	
	Armory:SetPvpTalent(self:GetID());
end

function ArmoryPVPTalentsTalent_OnClick(self)
	if ( IsModifiedClick("CHATLINK") ) then
		local link = GetPvpTalentLink(self:GetID());
		if ( link ) then
			ChatEdit_InsertLink(link);
		end
	end
end

function ArmoryPVPTalents_Update()
    local TalentFrame = ArmoryPVPTalents;

	local numTalentSelections = 0;
	for tier = 1, MAX_PVP_TALENT_TIERS do
		local talentRow = TalentFrame["tier"..tier];
		
		for column = 1, MAX_PVP_TALENT_COLUMNS do
			local talentID, name, iconTexture, selected, available = Armory:GetPvpTalentInfo(tier, column, ArmoryTalentFrame.talentGroup);
			local button = talentRow["talent"..column];
			button.tier = tier;
			button.column = column;

			if ( button and name ) then
				button:SetID(talentID);

				SetItemButtonTexture(button, iconTexture);
				if ( button.name ~= nil ) then
					button.name:SetText(name);
				end

				if ( button.knownSelection ~= nil ) then
					if( selected ) then
						button.knownSelection:Show();
						button.knownSelection:SetDesaturated(false);
					else
						button.knownSelection:Hide();
					end
				end

				if ( selected ) then
				    SetDesaturation(button.icon, false);
				    button.border:Show();
				else
				    SetDesaturation(button.icon, true);
				    button.border:Hide();
			    end

	            button:Show();
	        elseif ( button ) then
	            button:Hide();
	        end
	    end
	end

    local numUnspentTalents = Armory:GetNumUnspentPvpTalents();
    if ( numUnspentTalents > 0 ) then
        ArmoryPVPTalents.unspentText:SetFormattedText(PLAYER_UNSPENT_TALENT_POINTS, numUnspentTalents);
    else
        ArmoryPVPTalents.unspentText:SetText("");
    end
end

