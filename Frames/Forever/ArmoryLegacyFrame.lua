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

-- The tree is drawn by the talent frame, the page follows Blizzard's tree page (Blizzard_LegacyTree.lua).

local TAB_LEGACY = 3;

-- the part of a node is the index of its tree
local LEGACY_SOURCE = {
    GetNodes = function() return Armory:GetLegacyNodes(); end,
    GetNodeInfo = function(nodeID) return Armory:GetLegacyNodeInfo(nodeID); end,
    GetNumEntries = function(nodeID) return Armory:GetNumLegacyNodeEntries(nodeID); end,
    GetEntryInfo = function(nodeID, index) return Armory:GetLegacyNodeEntryInfo(nodeID, index); end,
    GetEdges = function(nodeID) return Armory:GetLegacyNodeEdges(nodeID); end,
    GetNodeState = function(_, nodeID) return Armory:GetLegacyNodeState(nodeID); end,
    squareNodes = true,
    showAllRanks = true,
};

-- Blizzard's strings of the Legacy frame are not in the exported code; a missing string gets the English text
local function FormatLegacyString(name, fallback, ...)
    local text = _G[name];
    if ( type(text) == "string" and text ~= "" ) then
        local ok, result = pcall(format, text, ...);
        if ( ok ) then
            return result;
        end
    end
    return format(fallback, ...);
end

local function GetAvailableText(available)
    return FormatLegacyString("LEGACY_POINTS_AVAILABLE", "%s available", FormatLegacyString("LEGACY_POINTS_AMOUNT", "%d Legacy Points", available or 0));
end

local function IsLegacyTree(treeID)
    for i = 1, Armory:GetNumLegacyTrees() do
        if ( treeID == Armory:GetLegacyTreeInfo(i) ) then
            return true;
        end
    end
    return false;
end

function ArmoryLegacyFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("TRAIT_CONFIG_UPDATED");
    self:RegisterEvent("TRAIT_TREE_CURRENCY_INFO_UPDATED");
    self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED");

    self.selectedTree = 1;
    for i = 1, Armory:GetNumLegacyTrees() do
        local _, _, atlas = Armory:GetLegacyTreeInfo(i);
        self["treeButton"..i]:GetNormalTexture():SetAtlas(atlas);
    end

    ArmoryAchievementFrameTab3:SetText(LEGACY_BUTTON or "Legacy");
    ArmoryPanelTemplates_SetNumTabs(ArmoryAchievementFrame, TAB_LEGACY);
end

function ArmoryLegacyFrame_OnEvent(self, event, arg1)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        Armory:Execute(ArmoryLegacyFrame_UpdateLegacy);
    elseif ( event == "TRAIT_CONFIG_UPDATED" ) then
        -- Also fires for other trait systems
        if ( Armory:IsLegacyConfig(arg1) ) then
            Armory:Execute(ArmoryLegacyFrame_UpdateLegacy);
        end
    elseif ( event == "TRAIT_TREE_CURRENCY_INFO_UPDATED" ) then
        if ( IsLegacyTree(arg1) ) then
            Armory:Execute(ArmoryLegacyFrame_UpdateLegacy);
        end
    elseif ( event == "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" ) then
        if ( Armory:IsLegacyRewardTrack(arg1) ) then
            Armory:Execute(ArmoryLegacyFrame_UpdateLegacy);
        end
    end
end

function ArmoryLegacyFrame_UpdateLegacy()
    Armory:SetLegacy();
    if ( ArmoryAchievementFrame:IsVisible() ) then
        ArmoryAchievementFrame_OnShow(ArmoryAchievementFrame);
    end
end

-- The Legacy tab only when the account has earned a Legacy point; after Statistics, or after Achievements without statistics
function ArmoryLegacyFrame_UpdateTab(hasStatistics)
    local tab = ArmoryAchievementFrameTab3;
    if ( Armory:HasLegacy() ) then
        local previous = hasStatistics and ArmoryAchievementFrameTab2 or ArmoryAchievementFrameTab1;
        tab:ClearAllPoints();
        tab:SetPoint("LEFT", previous, "RIGHT", -16, 0);
        tab:Show();
    else
        tab:Hide();
    end
    -- A new tab shows its selected and its unselected art until the tabs are updated
    ArmoryPanelTemplates_UpdateTabs(ArmoryAchievementFrame);
end

-- Shows the Legacy trees instead of the list when its tab is selected; returns true when it does
function ArmoryLegacyFrame_Update(selected)
    local self = ArmoryLegacyFrame;
    if ( selected and not Armory:HasLegacy() ) then
        ArmoryPanelTemplates_SetTab(ArmoryAchievementFrame, 1);
        ArmoryAchievementFrame_SelectSource(1);
        selected = false;
    end

    ArmoryAchievementFrameEditBox:SetShown(not selected);
    ArmoryAchievementExpandButtonFrame:SetShown(not selected);
    if ( not selected ) then
        self:Hide();
        return false;
    end

    for i = 1, 15 do
        _G["ArmoryAchievementBar"..i]:Hide();
    end
    ArmoryAchievementListScrollFrame:Hide();
    self:Show();

    local tree = self.selectedTree;
    local _, name, atlas = Armory:GetLegacyTreeInfo(tree);
    self.treeName:SetText(name);
    self.Tree.treeIcon:SetAtlas(atlas, false);
    for i = 1, Armory:GetNumLegacyTrees() do
        local button = self["treeButton"..i];
        if ( i == tree ) then
            button:LockHighlight();
        else
            button:UnlockHighlight();
        end
    end

    ArmoryTalentFrame_UpdateTree(self.Tree, LEGACY_SOURCE, nil, tree);

    self.availableText:SetText(GetAvailableText(Armory:GetLegacyPoints()));

    return true;
end

function ArmoryLegacyTreeButton_OnClick(self)
    ArmoryLegacyFrame.selectedTree = self:GetID();
    ArmoryLegacyFrame_Update(true);
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function ArmoryLegacyTreeButton_OnEnter(self)
    local _, name = Armory:GetLegacyTreeInfo(self:GetID());
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(name);
    GameTooltip:Show();
end

-- The points of Blizzard's Legacy frame: earned of the maximum (the reward track), unspent and the seasonal cap
function ArmoryLegacyPoints_OnEnter(self)
    local available, earned, maxAvailable, seasonalCap = Armory:GetLegacyPoints();
    if ( not earned ) then
        return;
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(LEGACY_BUTTON or "Legacy");
    GameTooltip:AddLine(FormatLegacyString("LEGACY_POINTS_CURR_MAX", "%d/%d", earned, maxAvailable or 0), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    GameTooltip:AddLine(GetAvailableText(available), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    if ( seasonalCap and seasonalCap > 0 ) then
        GameTooltip:AddLine(FormatLegacyString("LEGACY_POINTS_SEASONAL_CAP", "Seasonal cap: %d", seasonalCap), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
end
