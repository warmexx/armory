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

-- Forever's PvP frame in the layout of Classic Era (Frames\Vanilla\ArmoryPVPFrame); the rank is a renown
-- (Armory:GetPVPRankInfo), the weeks of Era make way for the season and the honor points

local Armory, _ = Armory;

local HONOR_CURRENCY_ID = 1792;

-- A format that is missing in the client gives nil instead of an error
local function Format(text, ...)
    if ( type(text) == "string" ) then
        return text:format(...);
    end
end

local function IsAlliance()
    return Armory:UnitFactionGroup("player") == "Alliance";
end

-- Blizzard's GetPVPRankText (Camelot\PVPRankFrame.lua); value is a PvPRanks value
local function GetRankText(value)
    local key = "PVP_RANK_"..value.."_"..(IsAlliance() and 1 or 0);
    if ( _G[key] ) then
        return GetText(key, Armory:UnitSex("player"));
    end
end

local function GetRankName(rank)
    if ( (rank or 0) > 0 and Enum.PvPRanks ) then
        return GetRankText(Enum.PvPRanks.Rank_1 + rank - 1);
    end
end

-- The lines that are missing in the client are left out
local function SetTooltip(frame, title, ...)
    local lines = {};
    for i = 1, select("#", ...) do
        local line = select(i, ...);
        if ( line ) then
            table.insert(lines, line);
        end
    end
    frame.title = title;
    frame.tooltip = #lines > 0 and table.concat(lines, "\n\n") or nil;
end

function ArmoryHonorFrameTextButton_OnLoad(self, title, tooltip, color)
    self.Text:SetText(title);
    self.title = title;
    self.tooltip = tooltip;
    if ( color ) then
        self.Value:SetTextColor(color:GetRGB());
    end
end

function ArmoryHonorFrameTextButton_OnEnter(self)
    if ( self.title ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.title, HIGHLIGHT_FONT_COLOR:GetRGB());
        if ( self.tooltip ) then
            GameTooltip:AddLine(self.tooltip, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        end
        GameTooltip:Show();
    end
end

function ArmoryHonorFrameRankButton_OnEnter(self)
    local rank, _, _, maxRank, _, _, _, _, maxPoints = Armory:GetPVPRankInfo();
    if ( rank ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(GetRankName(rank) or PVP_RANK_0_NAME or NONE, HIGHLIGHT_FONT_COLOR:GetRGB());
        local description = Format(PVP_RANK_SEASON_RANKUP_DESCRIPTION, maxPoints, maxRank);
        if ( description ) then
            GameTooltip:AddLine(description, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        end
        GameTooltip:Show();
    end
end

function ArmoryHonorFrameProgressButton_OnEnter(self)
    local _, points, threshold = Armory:GetPVPRankInfo();
    if ( points ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(Format(PVP_RANK_CURRENT_PROGRESS, points, threshold) or points.." / "..threshold, HIGHLIGHT_FONT_COLOR:GetRGB());
        GameTooltip:Show();
    end
end

function ArmoryPVPFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PLAYER_PVP_KILLS_CHANGED");
    self:RegisterEvent("PLAYER_PVP_RANK_CHANGED");
    self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED");
    self:RegisterEvent("UPDATE_FACTION");
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
end

function ArmoryPVPFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        ArmoryPVPFrame_Update(true);
    else
        ArmoryPVPFrame_Update();
    end
end

function ArmoryPVPFrame_Update(updateAll)
    local hk, dk, highestRank;

    -- Yesterday's values; this only gets set on player entering the world
    hk, dk = Armory:GetPVPYesterdayStats(updateAll);
    ArmoryHonorFrameYesterdayHKValue:SetText(hk);
    ArmoryHonorFrameYesterdayDKValue:SetText(dk);

    -- This session's values
    hk, dk = Armory:GetPVPSessionStats();
    ArmoryHonorFrameCurrentHKValue:SetText(hk);
    ArmoryHonorFrameCurrentDKValue:SetText(dk);

    -- Lifetime stats; Forever has no lifetime dishonorable kills
    hk, highestRank = Armory:GetPVPLifetimeStats();
    ArmoryHonorFrameLifeTimeHKValue:SetText(hk or 0);
    ArmoryHonorFrameLifeTimeRankValue:SetText((highestRank or 0) > 0 and GetRankText(highestRank) or NONE);

    -- Rank, season and progress
    local rank, points, threshold, maxRank, seasonPoints, weekMaxPoints, capIncrease, season, _, pointsName = Armory:GetPVPRankInfo();
    rank = rank or 0;

    ArmoryHonorFrameCurrentPVPTitle:SetText(GetRankName(rank) or PVP_RANK_0_NAME or NONE);
    if ( rank > 0 ) then
        ArmoryHonorFrameCurrentPVPRank:SetText("("..RANK.." "..rank..")");
        ArmoryHonorFramePvPIcon:SetTexture(format("%s%02d", "Interface\\PvPRankBadges\\PvPRank", rank));
        ArmoryHonorFramePvPIcon:Show();
    else
        ArmoryHonorFrameCurrentPVPRank:SetText("");
        ArmoryHonorFramePvPIcon:Hide();
    end

    if ( IsAlliance() ) then
        ArmoryHonorFrameProgressBar:SetStatusBarColor(0.05, 0.15, 0.36);
    else
        ArmoryHonorFrameProgressBar:SetStatusBarColor(0.63, 0.09, 0.09);
    end
    if ( (threshold or 0) > 0 ) then
        ArmoryHonorFrameProgressBar:SetValue(min(points / threshold, 1));
    else
        ArmoryHonorFrameProgressBar:SetValue(0);
    end

    ArmoryHonorFrameSeasonTitle:SetText((season or 0) > 0 and strtrim(Format(EXPANSION_SEASON_NAME, "", season) or "") or "");

    seasonPoints = seasonPoints or 0;
    weekMaxPoints = weekMaxPoints or 0;
    ArmoryHonorFrameSeasonProgress.Text:SetText(pointsName or "");
    if ( weekMaxPoints > 0 ) then
        ArmoryHonorFrameSeasonProgressValue:SetText(seasonPoints.." / "..weekMaxPoints);
        SetTooltip(ArmoryHonorFrameSeasonProgress, pointsName, Format(PVP_RANK_SEASON_PROGRESS, seasonPoints, weekMaxPoints),
            (capIncrease or 0) > 0 and Format(PVP_RANK_WEEKLY_CAP_INCREASE, capIncrease) or nil);
    else
        ArmoryHonorFrameSeasonProgressValue:SetText(seasonPoints);
        SetTooltip(ArmoryHonorFrameSeasonProgress, pointsName, Format(PVP_RANK_SEASON_PROGRESS_NO_MAX, seasonPoints));
    end

    ArmoryHonorFrameSeasonCap.Text:SetText(RANK);
    ArmoryHonorFrameSeasonCapValue:SetText(rank.." / "..(maxRank or 0));
    SetTooltip(ArmoryHonorFrameSeasonCap, RANK);

    -- Honor points
    local constants = Constants and Constants.CurrencyConsts;
    local name, quantity = Armory:GetCurrencyInfo(constants and constants.HONOR_CURRENCY_ID or HONOR_CURRENCY_ID);
    ArmoryHonorFrameHonorTitle:SetText(HONOR);
    ArmoryHonorFrameHonorPoints.Text:SetText(name or HONOR_POINTS or "");
    ArmoryHonorFrameHonorPointsValue:SetText(quantity or 0);
    SetTooltip(ArmoryHonorFrameHonorPoints, name);

    -- Recenter rank text
    ArmoryHonorFrameCurrentPVPTitle:SetPoint("TOP", "ArmoryPVPFrame", "TOP", - ArmoryHonorFrameCurrentPVPRank:GetWidth()/2, -83);
end
