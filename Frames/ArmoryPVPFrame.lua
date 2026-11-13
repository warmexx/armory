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

ARMORY_CONQUEST_SIZE_STRINGS = { RATED_SOLO_SHUFFLE_SIZE, ARENA_2V2, ARENA_3V3, BATTLEGROUND_10V10 };

local CONQUEST_BUTTONS = {};
local CONQUEST_BRACKET_INDEXES = { 7, 1, 2, 4 }; -- 5v5 was removed
local RATED_BG_BUTTON_ID = 4;
local RATED_SOLO_SHUFFLE_BUTTON_ID = 1;

local ipairs = ipairs;
local math = math;
local select = select;

function ArmoryPVPFrame_OnLoad(self)
    CONQUEST_BUTTONS = {ArmoryConquestFrame.RatedSoloShuffle, ArmoryConquestFrame.Arena2v2, ArmoryConquestFrame.Arena3v3, ArmoryConquestFrame.RatedBG};

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
    self:RegisterEvent("PLAYER_PVP_TALENT_UPDATE");

    RequestRatedInfo();
    RequestPVPRewards();

    -- update the tabs
    ArmoryPanelTemplates_SetNumTabs(self, 2);
    ArmoryPanelTemplates_UpdateTabs(self);
    ArmoryPanelTemplates_SetTab(self, 1);
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
    elseif ( event == "HONOR_XP_UPDATE" or event == "HONOR_LEVEL_UPDATE" ) then
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
    ArmoryPVPFrame_Update(ArmoryPanelTemplates_GetSelectedTab(self));
end

function ArmoryPVPFrameTab_OnClick(self)
    ArmoryPanelTemplates_SetTab(self:GetParent(), self:GetID());
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

    ArmoryPVPFrameTab1:Show();
    ArmoryPVPFrameTab2:Show();
    ArmoryPanelTemplates_SetTab(ArmoryPVPFrame, currentTab);

    local tab;
    local totalTabWidth = 0;
    local tabWidthCache = {};
    for i, tab in ipairs(ArmoryPVPFrame.Tabs) do
        tabWidthCache[i] = 0;
        ArmoryPanelTemplates_TabResize(tab, 0);
        tab.Text:SetWidth(0);
        tabWidthCache[i] = ArmoryPanelTemplates_GetTabWidth(tab);
        totalTabWidth = totalTabWidth + tabWidthCache[i];
    end
    ArmoryPanelTemplates_ResizeTabsToFit(ArmoryPVPFrame.Tabs, totalTabWidth, 260, tabWidthCache);

    if ( currentTab == 2 ) then
        ArmoryPVPFrameHonor:Hide();
        ArmoryConquestFrame:Hide();

        ArmoryPVPHonorXPBar:Show();
        ArmoryPVPTalents:Show();
    else
        ArmoryPVPHonorXPBar:Show();
        ArmoryPVPTalents:Hide();

        ArmoryPVPFrameHonor:Show();
        ArmoryConquestFrame:Show();
    end
end


----------------------------------------------------------
-- PVP Honor
----------------------------------------------------------

function ArmoryPVPHonor_Update(updateAll)
    local _, quantity = Armory:GetCurrencyInfo(Constants.CurrencyConsts.HONOR_CURRENCY_ID);
    ArmoryPVPFrameHonorPoints:SetText(quantity);
end


----------------------------------------------------------
-- PVP Conquest
----------------------------------------------------------

function ArmoryConquestFrame_Update()
    local _, quantity = Armory:GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID);
    ArmoryConquestFramePoints:SetText(quantity);

    for i = 1, RATED_BG_BUTTON_ID do
        local button = CONQUEST_BUTTONS[i];
        local bracketIndex = CONQUEST_BRACKET_INDEXES[i];
        local rating, _, weeklyBest, _, seasonWon = Armory:GetPersonalRatedInfo(bracketIndex);
        button.bracketIndex = bracketIndex;
        button.Wins:SetText(seasonWon);
        button.BestRating:SetText(weeklyBest);
        button.CurrentRating:SetText(rating);
    end
end

local CONQUEST_TOOLTIP_PADDING = 30 --counts both sides

function ArmoryConquestFrameButton_OnEnter(self)
    local tooltip = ArmoryConquestTooltip;

    local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon, roundsSeasonPlayed, roundsSeasonWon, roundsWeeklyPlayed, roundsWeeklyWon = Armory:GetPersonalRatedInfo(self.bracketIndex);
    local isSoloShuffle = self.id == RATED_SOLO_SHUFFLE_BUTTON_ID;

    tooltip.Title:SetText(self.toolTipTitle);

    tooltip.WeeklyBest:SetText(PVP_BEST_RATING..weeklyBest);
    tooltip.WeeklyWon:SetText(isSoloShuffle and (PVP_ROUNDS_WON .. roundsWeeklyWon) or (PVP_GAMES_WON .. weeklyWon));
    tooltip.WeeklyPlayed:SetText(isSoloShuffle and (PVP_ROUNDS_PLAYED .. roundsWeeklyPlayed) or (PVP_GAMES_PLAYED .. weeklyPlayed));

    tooltip.SeasonBest:SetText(PVP_BEST_RATING..seasonBest);
    tooltip.SeasonWon:SetText(isSoloShuffle and (PVP_ROUNDS_WON .. roundsSeasonWon) or (PVP_GAMES_WON .. seasonWon));
    tooltip.SeasonGamesPlayed:SetText(isSoloShuffle and (PVP_ROUNDS_PLAYED .. roundsSeasonPlayed) or (PVP_GAMES_PLAYED .. seasonPlayed));

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
    if ( Armory:UnitLevel("player") < SHOW_PVP_TALENT_LEVEL ) then
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

    frame.Bar:SetMinMaxValues(0, max);
    frame.Bar:SetValue(current);
    -- frame.Bar:SetStatusBarTexture("_honorsystem-bar-fill");

    if ( not frame.locked ) then
        frame.Level:SetText(Armory:UnitHonorLevel("player"));
        ArmoryPVPHonorXPBar_SetNextAvailable(frame);
    end
end

function ArmoryPVPHonorXPBar_SetNextAvailable(self)
    local showNext = false;

    self.rewardInfo = ArmoryPVPHonorXPBar_GetNextReward();

    if ( self.rewardInfo ) then
        self.rewardInfo:SetUpFrame(self.NextAvailable);
        showNext = true;
    end

    self.NextAvailable:SetShown(showNext);
    self.PrestigeReward:SetShown(false);
end

function ArmoryPVPHonorXPBar_GetNextReward()
    local rewardInfo;

    local rewardPackID = nil;
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

    return rewardInfo;
end

function ArmoryPVPHonorXPBar_OnEnter(self)
    local current = Armory:UnitHonor("player");
    local max = Armory:UnitHonorMax("player");

    if ( not current or not max ) then
        return;
    end

    self.OverlayFrame.Text:SetText(HONOR_BAR:format(current, max));
    self.OverlayFrame.Text:Show();
end

function ArmoryPVPHonorXPBar_OnLeave(self)
    self.OverlayFrame.Text:Hide();
end

function ArmoryHonorExhaustionTick_OnLoad(self)
    self.fillBarAlpha = 0.15;
end

function ArmoryHonorExhaustionTick_Update(self)
    ArmoryPVPHonorXPBar_Update();
end

function ArmoryHonorExhaustionToolTipText()
    return;
end


----------------------------------------------------------
-- PVP Talents
----------------------------------------------------------

function ArmoryPVPTalentsTalent_OnEnter(self)
    if ( self.talentID ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        Armory:SetPvpTalent(self.talentID);
    end
end

function ArmoryPVPTalentsTalent_OnClick(self)
    if ( self.talentID and IsModifiedClick("CHATLINK") ) then
        local link = GetPvpTalentLink(self.talentID);
        if ( link ) then
            ChatFrameUtil.InsertLink(link);
        end
    end
end

function ArmoryPVPTalents_Update()
    local TalentFrame = ArmoryPVPTalents;

    local numTalentSelections = 0;

    for index = 1, #ArmoryPVPTalents.Slots do
        local talentID, name, iconTexture = Armory:GetPvpTalentSlotInfo(index, ArmoryTalentFrame.selectedSpec);
        local button = ArmoryPVPTalents.Slots[index];

        button.Texture:Show();
        button.talentID = talentID;
        if ( name ) then
            Armory:SetPortraitToTexture(button.Texture, iconTexture);
            button.TalentName:SetText(name);
            button.TalentName:Show();
        else
            button.Texture:SetAtlas("pvptalents-talentborder-empty");
            button.TalentName:Hide();
        end
    end

    local numUnspentTalents = Armory:GetNumUnspentPvpTalents(ArmoryTalentFrame.selectedSpec);
    if ( numUnspentTalents > 0 ) then
        ArmoryPVPTalents.unspentText:SetFormattedText(PLAYER_UNSPENT_TALENT_POINTS, numUnspentTalents);
    else
        ArmoryPVPTalents.unspentText:SetText("");
    end
end


ArmoryPVPHonorRewardCodeMixin = {};

function ArmoryPVPHonorRewardCodeMixin:OnLoad()
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED");
end

function ArmoryPVPHonorRewardCodeMixin:OnEvent(event, ...)
    if (event == "GET_ITEM_INFO_RECEIVED" and self.rewardInfo and self.rewardInfo.waitingOnItem) then
        local id = ...;
        if (id == self.rewardInfo.id) then
            self.rewardInfo:Set(id);
            self.rewardInfo:SetUpFrame(self);
        end
    end
end
