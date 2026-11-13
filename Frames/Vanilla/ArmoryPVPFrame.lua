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

function ArmoryPVPFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_PVP_KILLS_CHANGED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_PVP_RANK_CHANGED");
end

function ArmoryPVPFrame_OnEvent(self, event, ...)
    local arg1 = ...;
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
	local hk, dk, contribution, rank, highestRank, rankName, rankNumber;

	-- This only gets set on player entering the world
	if ( updateAll ) then
		-- Yesterday's values
		hk, dk, contribution = Armory:GetPVPYesterdayStats(updateAll);
		ArmoryHonorFrameYesterdayHKValue:SetText(hk);
		ArmoryHonorFrameYesterdayContributionValue:SetText(contribution);
		-- This Week's values
		hk, contribution = Armory:GetPVPThisWeekStats(updateAll);
		ArmoryHonorFrameThisWeekHKValue:SetText(hk);
		ArmoryHonorFrameThisWeekContributionValue:SetText(contribution);
		-- Last Week's values
		hk, dk, contribution, rank = Armory:GetPVPLastWeekStats(updateAll);
		ArmoryHonorFrameLastWeekHKValue:SetText(hk);
		ArmoryHonorFrameLastWeekContributionValue:SetText(contribution);
	end

	-- This session's values
	hk, dk = Armory:GetPVPSessionStats();
	ArmoryHonorFrameCurrentHKValue:SetText(hk);
	ArmoryHonorFrameCurrentDKValue:SetText(dk);

	-- Lifetime stats
	hk, dk, highestRank = Armory:GetPVPLifetimeStats();
	ArmoryHonorFrameLifeTimeHKValue:SetText(hk);
	ArmoryHonorFrameLifeTimeDKValue:SetText(dk);
	rankName, rankNumber = GetPVPRankInfo(highestRank);
	if ( not rankName ) then
		rankName = NONE;
	end
	ArmoryHonorFrameLifeTimeRankValue:SetText(rankName);

	-- Set rank name and number
	rankName, rankNumber = GetPVPRankInfo(Armory:UnitPVPRank("player"));
	if ( not rankName ) then
		rankName = NONE;
	end
	ArmoryHonorFrameCurrentPVPTitle:SetText(rankName);
	ArmoryHonorFrameCurrentPVPRank:SetText("("..RANK.." "..rankNumber..")");

	-- Set icon
	if ( rankNumber > 0 ) then
		ArmoryHonorFramePvPIcon:SetTexture(format("%s%02d","Interface\\PvPRankBadges\\PvPRank",rankNumber));
		ArmoryHonorFramePvPIcon:Show();
	else
		ArmoryHonorFramePvPIcon:Hide();
	end

	-- Set rank progress and bar color
	local factionGroup, factionName = Armory:UnitFactionGroup("player");
	if ( factionGroup == "Alliance" ) then
		ArmoryHonorFrameProgressBar:SetStatusBarColor(0.05, 0.15, 0.36);
	else
		ArmoryHonorFrameProgressBar:SetStatusBarColor(0.63, 0.09, 0.09);
	end
	ArmoryHonorFrameProgressBar:SetValue(Armory:GetPVPRankProgress());

	-- Recenter rank text
    ArmoryHonorFrameCurrentPVPTitle:SetPoint("TOP", "ArmoryPVPFrame", "TOP", - ArmoryHonorFrameCurrentPVPRank:GetWidth()/2, -83);
end
