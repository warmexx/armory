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
local container = "Legacy";

-- The Legacy points are earned by the account, each character spends them in its own way;
-- the structure of the trees is shared by all characters.

-- Raise it when the stored structure changes, so the structure is stored again
local STRUCTURE_VERSION = 2;

local REWARD_TRACK_FACTION_ID = 2802;
local POINTS_CURRENCY_ID = 4225;

local TREES = {
    { id = 1187, name = "LEGACY_TREE_PROFESSIONS", fallback = "Professions", atlas = "UI-Legacy-Tree-Professions" },
    { id = 1188, name = "LEGACY_TREE_ADVENTURE", fallback = "Adventure", atlas = "UI-Legacy-Tree-Adventure" },
    { id = 1189, name = "LEGACY_TREE_PROGRESSION", fallback = "Resourcefulness", atlas = "UI-Legacy-Tree-Progression" },
};

----------------------------------------------------------
-- Legacy Internals
----------------------------------------------------------

local function GetConstant(name, default)
    local constants = Constants.LegacyConsts;
    return (constants and constants[name]) or default;
end

local function GetTreeID(index)
    local tree = TREES[index];
    if ( tree ) then
        local names = { "LEGACY_TREE_PROFESSIONS_ID", "LEGACY_TREE_ADVENTURE_ID", "LEGACY_TREE_PROGRESSION_ID" };
        return GetConstant(names[index], tree.id);
    end
end

local function GetConfigID()
    return C_Traits.GetConfigIDByTreeID(GetTreeID(1));
end

local function GetStructureKey()
    local hashes = {};
    for i = 1, #TREES do
        local hash = C_Traits.GetTreeHash(GetTreeID(i));
        if ( not hash ) then
            return;
        end
        table.insert(hashes, table.concat(hash, "."));
    end
    return STRUCTURE_VERSION..":"..select(2, _G.GetBuildInfo()).."-"..table.concat(hashes, "-");
end

-- The trees have nodes that can never be bought, without a known spell; Blizzard's Legacy guide does not have them either
local function IsNeverPurchasable(nodeInfo)
    local flag = Enum.TraitNodeFlag and Enum.TraitNodeFlag.NeverPurchasable;
    return flag and nodeInfo.flags and bit.band(nodeInfo.flags, flag) ~= 0;
end

local function IsNodeValid(nodeInfo)
    return nodeInfo and nodeInfo.ID and nodeInfo.ID ~= 0 and nodeInfo.isVisible and #nodeInfo.entryIDs > 0 and not IsNeverPurchasable(nodeInfo);
end

-- as Blizzard's LegacyMicroButtonMixin:IsLegacySystemUnlocked
local function GetEarnedPoints()
    return C_MajorFactions.GetCurrentRenownLevel(GetConstant("LEGACY_REWARD_TRACK_FACTION_ID", REWARD_TRACK_FACTION_ID)) or 0;
end

----------------------------------------------------------
-- Legacy Storage: structure, shared by all characters
----------------------------------------------------------

-- The same values as the talent nodes, so the talent frame can draw them; the part of a node is the index of its tree
local function StoreNode(nodeID, nodeInfo, part, configID)
    local maxRanks = nodeInfo.maxRanks;
    local isTiered = (nodeInfo.type == Enum.TraitNodeType.Tiered);
    if ( isTiered ) then
        maxRanks = 0;
    end

    for i, entryID in ipairs(nodeInfo.entryIDs) do
        local entryInfo = C_Traits.GetEntryInfo(configID, entryID);
        local definitionInfo = entryInfo and entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID);
        Armory:SetSharedValue(4, container, "Entries", nodeID, i,
            entryID,
            definitionInfo and definitionInfo.spellID,
            entryInfo and entryInfo.maxRanks,
            definitionInfo and definitionInfo.overriddenSpellID,
            definitionInfo and definitionInfo.overrideName,
            definitionInfo and definitionInfo.overrideIcon,
            entryInfo and entryInfo.subTreeID,
            entryInfo and entryInfo.type);
        if ( isTiered and entryInfo ) then
            maxRanks = maxRanks + entryInfo.maxRanks;
        end
    end

    Armory:SetSharedValue(3, container, "Nodes", nodeID, nodeInfo.posX, nodeInfo.posY, nodeInfo.type, part, nil, maxRanks);
end

local function StoreStructure(configID)
    local key = GetStructureKey();
    if ( not key or key == Armory:GetSharedValue(container, "Key") ) then
        return;
    end

    Armory:PrintDebug("UPDATE", container, "structure");

    Armory:SetSharedValue(container, nil);

    local treeNodes = {};
    for part = 1, #TREES do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(GetTreeID(part)) or {}) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
            if ( IsNodeValid(nodeInfo) ) then
                table.insert(treeNodes, nodeID);
                StoreNode(nodeID, nodeInfo, part, configID);

                local targets = {};
                for _, edge in ipairs(nodeInfo.visibleEdges) do
                    table.insert(targets, edge.targetNode);
                end
                if ( #targets > 0 ) then
                    Armory:SetSharedValue(3, container, "Edges", nodeID, targets);
                end
            end
        end
    end
    Armory:SetSharedValue(2, container, "TreeNodes", treeNodes);

    Armory:SetSharedValue(2, container, "Key", key);
end

----------------------------------------------------------
-- Legacy Storage: ranks and points, per character
----------------------------------------------------------

local function StoreRanks(dbEntry, configID)
    dbEntry:SetValue(container, nil);

    for part = 1, #TREES do
        local treeID = GetTreeID(part);
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
            if ( IsNodeValid(nodeInfo) and nodeInfo.activeRank > 0 ) then
                dbEntry:SetValue(3, container, "Nodes", nodeID, nodeInfo.activeRank, nodeInfo.activeEntry and nodeInfo.activeEntry.entryID);
            end
        end
    end

    -- as LegacySystem.GetCurrencyInfo; earned is the level of the reward track
    local currencies = C_Traits.GetTreeCurrencyInfo(configID, GetTreeID(1), false);
    local currency = currencies and currencies[1];
    if ( currency ) then
        local currencyID = currency.traitCurrencyID or GetConstant("LEGACY_POINTS_TRAIT_CURRENCY_ID", POINTS_CURRENCY_ID);
        local maxAvailable = C_Traits.GetMaxAvailableTraitCurrency(currencyID, false);
        dbEntry:SetValue(2, container, "Points", currency.quantity or 0, GetEarnedPoints(), maxAvailable or 0, currency.maxQuantity or 0);
    end
end

----------------------------------------------------------
-- Legacy Storage
----------------------------------------------------------

function Armory:SetLegacy()
    local dbEntry = self.playerDbBaseEntry;

    if ( not dbEntry ) then
        return;
    elseif ( not self:HasAchievements() or GetEarnedPoints() == 0 ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    local configID = GetConfigID();
    if ( not configID ) then
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        StoreStructure(configID);
        StoreRanks(dbEntry, configID);

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

function Armory:IsLegacyConfig(configID)
    return configID ~= nil and configID == GetConfigID();
end

function Armory:IsLegacyRewardTrack(factionID)
    return factionID == GetConstant("LEGACY_REWARD_TRACK_FACTION_ID", REWARD_TRACK_FACTION_ID);
end

----------------------------------------------------------
-- Legacy Interface
----------------------------------------------------------

-- Only once the account has earned a Legacy point, also for data stored before a character logs in again
function Armory:HasLegacy()
    if ( not (self:HasAchievements() and self:GetSharedValue(container, "TreeNodes")) ) then
        return false;
    end
    local _, earned = self:GetLegacyPoints();
    return (earned or 0) > 0;
end

function Armory:GetNumLegacyTrees()
    return #TREES;
end

-- returns treeID, name, atlas
function Armory:GetLegacyTreeInfo(index)
    local tree = TREES[index];
    if ( tree ) then
        return GetTreeID(index), _G[tree.name] or tree.fallback, tree.atlas;
    end
end

-- returns a list of nodeIDs of all trees, do not change it
function Armory:GetLegacyNodes()
    return self:GetSharedValue(container, "TreeNodes");
end

-- returns posX, posY, type, treeIndex, subTreeID, maxRanks; the same as GetTalentNodeInfo
function Armory:GetLegacyNodeInfo(nodeID)
    return self:GetSharedValue(container, "Nodes", nodeID);
end

function Armory:GetNumLegacyNodeEntries(nodeID)
    return self:GetSharedNumValues(container, "Entries", nodeID);
end

-- returns entryID, spellID, maxRanks, overriddenSpellID, overrideName, overrideIcon, subTreeID, entryType
function Armory:GetLegacyNodeEntryInfo(nodeID, index)
    return self:GetSharedValue(container, "Entries", nodeID, index);
end

-- returns a list of nodeIDs, do not change it
function Armory:GetLegacyNodeEdges(nodeID)
    return self:GetSharedValue(container, "Edges", nodeID);
end

-- returns rank, entryID
function Armory:GetLegacyNodeState(nodeID)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, "Nodes", nodeID);
    end
end

-- returns available, earned, maxAvailable, seasonalCap
function Armory:GetLegacyPoints()
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, "Points");
    end
end

function Armory:ClearLegacy()
    self:ClearModuleData(container);
    self:SetSharedValue(container, nil);
end
