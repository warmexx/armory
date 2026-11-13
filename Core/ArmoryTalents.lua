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
local container = "Talents";

local SHOW_TALENT_LEVEL = 10;

-- Raise it when the stored structure changes, so the structure is stored again
local STRUCTURE_VERSION = 2;

local PART_CLASS = "class";
local PART_SPEC = "spec";
local PART_HERO = "hero";
local PART_SELECTOR = "selector";

----------------------------------------------------------
-- Talents Internals
----------------------------------------------------------

local function GetTreeKey(treeID)
    local hash = C_Traits.GetTreeHash(treeID);
    if ( hash ) then
        return STRUCTURE_VERSION..":"..select(2, _G.GetBuildInfo()).."-"..table.concat(hash, ".");
    end
end

local function GetNodeCostID(configID, nodeID)
    local costs = C_Traits.GetNodeCost(configID, nodeID);
    return costs and costs[1] and costs[1].ID;
end

local function IsNodeValid(nodeInfo)
    return nodeInfo and nodeInfo.ID and nodeInfo.ID ~= 0;
end

-- Nodes without a part, like the invisible helper nodes of some classes, are not talents
local function GetNodePart(nodeInfo, costID, currencies)
    if ( nodeInfo.subTreeID ) then
        return PART_HERO;
    elseif ( nodeInfo.type == Enum.TraitNodeType.SubTreeSelection ) then
        return PART_SELECTOR;
    elseif ( not costID ) then
        return;
    elseif ( currencies[1] and costID == currencies[1].traitCurrencyID ) then
        return PART_CLASS;
    elseif ( currencies[2] and costID == currencies[2].traitCurrencyID ) then
        return PART_SPEC;
    end
end

-- A node that is granted for free, like the first node of the class tree, has no cost and belongs to the part it is linked to
local function GetLinkedPart(nodeID, parts, links)
    for linkedID in pairs(links[nodeID] or {}) do
        local part = parts[linkedID];
        if ( part == PART_CLASS or part == PART_SPEC ) then
            return part;
        end
    end
end

local function AddLink(links, nodeID, linkedID)
    links[nodeID] = links[nodeID] or {};
    links[nodeID][linkedID] = true;
end

-- The view config is shared with Blizzard's talent frame when it shows a loadout from a link
local function CanUseViewConfig()
    return not (_G.PlayerSpellsFrame and _G.PlayerSpellsFrame:IsShown());
end

----------------------------------------------------------
-- Talents Storage: structure, shared by the class
----------------------------------------------------------

local function StoreNode(nodeID, nodeInfo, part, configID)
    local maxRanks = nodeInfo.maxRanks;
    local isTiered = (nodeInfo.type == Enum.TraitNodeType.Tiered);
    if ( isTiered ) then
        maxRanks = 0;
    end

    for i, entryID in ipairs(nodeInfo.entryIDs) do
        local entryInfo = C_Traits.GetEntryInfo(configID, entryID);
        local definitionInfo = entryInfo and entryInfo.definitionID and C_Traits.GetDefinitionInfo(entryInfo.definitionID);
        Armory:SetClassValue("player", 4, container, "Entries", nodeID, i,
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

    Armory:SetClassValue("player", 3, container, "Nodes", nodeID, nodeInfo.posX, nodeInfo.posY, nodeInfo.type, part, nodeInfo.subTreeID, maxRanks);
end

local function StoreSpecStructure(specID, treeID, level, edges)
    local configID = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID;

    C_ClassTalents.InitializeViewLoadout(specID, level);

    local currencies = C_Traits.GetTreeCurrencyInfo(configID, treeID, false) or {};
    if ( currencies[1] and currencies[2] ) then
        Armory:SetClassValue("player", 2, container, "Currencies", currencies[1].traitCurrencyID, currencies[2].traitCurrencyID);
    end

    -- A spec can also report hero trees of other specs as visible
    local isOwnSubTree, subTreeCost = {}, {};
    local subTreeIDs, heroLevel = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID);
    subTreeIDs = subTreeIDs or {};
    for _, subTreeID in ipairs(subTreeIDs) do
        isOwnSubTree[subTreeID] = true;
    end

    local nodes, parts, links = {}, {}, {};
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
        if ( IsNodeValid(nodeInfo) and nodeInfo.isVisible and (not nodeInfo.subTreeID or isOwnSubTree[nodeInfo.subTreeID]) ) then
            local costID = GetNodeCostID(configID, nodeID);
            table.insert(nodes, nodeInfo);
            parts[nodeID] = GetNodePart(nodeInfo, costID, currencies);

            if ( nodeInfo.subTreeID ) then
                subTreeCost[nodeInfo.subTreeID] = subTreeCost[nodeInfo.subTreeID] or costID;
            end

            for _, edge in ipairs(nodeInfo.visibleEdges) do
                AddLink(links, nodeID, edge.targetNode);
                AddLink(links, edge.targetNode, nodeID);
            end
        end
    end

    local specNodes = {};
    for _, nodeInfo in ipairs(nodes) do
        local nodeID = nodeInfo.ID;
        local part = parts[nodeID];
        if ( not part and #nodeInfo.entryIDs > 0 ) then
            part = GetLinkedPart(nodeID, parts, links);
        end
        if ( part ) then
            table.insert(specNodes, nodeID);
            StoreNode(nodeID, nodeInfo, part, configID);

            -- The edges of a node differ per spec, a target is only drawn when it is visible
            for _, edge in ipairs(nodeInfo.visibleEdges) do
                edges[nodeID] = edges[nodeID] or {};
                edges[nodeID][edge.targetNode] = true;
            end
        end
    end
    Armory:SetClassValue("player", 4, container, "Specs", specID, "Nodes", specNodes);
    Armory:SetClassValue("player", 4, container, "Specs", specID, "HeroLevel", heroLevel);

    local numSubTrees = 0;
    for _, subTreeID in ipairs(subTreeIDs) do
        local info = C_Traits.GetSubTreeInfo(configID, subTreeID);
        if ( info ) then
            numSubTrees = numSubTrees + 1;
            Armory:SetClassValue("player", 5, container, "Specs", specID, "HeroTrees", numSubTrees, info.ID, info.name, info.iconElementID, info.posX, info.posY, subTreeCost[subTreeID]);
        end
    end
end

local function StoreStructure(treeID)
    local key = GetTreeKey(treeID);
    if ( not key or key == Armory:GetClassValue("player", container, "Key") or not CanUseViewConfig() ) then
        return;
    end

    Armory:PrintDebug("UPDATE", container, "structure");

    Armory:SetClassValue("player", container, nil);

    -- The structure is shared, while a low level does not see the selection of the hero tree
    local level = _G.GetMaxLevelForPlayerExpansion();
    local edges = {};
    for i = 1, _G.GetNumSpecializations() do
        local specID = C_SpecializationInfo.GetSpecializationInfo(i);
        if ( specID ) then
            StoreSpecStructure(specID, treeID, level, edges);
        end
    end

    for nodeID, targets in pairs(edges) do
        local list = {};
        for target in pairs(targets) do
            table.insert(list, target);
        end
        Armory:SetClassValue("player", 3, container, "Edges", nodeID, list);
    end

    Armory:SetClassValue("player", 2, container, "Key", key);
end

----------------------------------------------------------
-- Talents Storage: choices, per character and spec
----------------------------------------------------------

-- The choices can only be read reliably while a spec is active, they do not change after that
local function StorePoints(dbEntry, specID, configID, treeID)
    for _, currency in ipairs(C_Traits.GetTreeCurrencyInfo(configID, treeID, false) or {}) do
        dbEntry:SetValue(4, container, specID, "Points", currency.traitCurrencyID, currency.spent, currency.quantity, currency.maxQuantity);
    end
end

local function StoreActiveSpec(dbEntry, specID, configID, treeID)
    dbEntry:SetValue(2, container, specID, nil);
    dbEntry:SetValue(3, container, specID, "HeroTree", C_ClassTalents.GetActiveHeroTalentSpec());

    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
        if ( IsNodeValid(nodeInfo) and nodeInfo.isVisible and nodeInfo.activeRank > 0 ) then
            dbEntry:SetValue(4, container, specID, "Nodes", nodeID, nodeInfo.activeRank, nodeInfo.activeEntry and nodeInfo.activeEntry.entryID);
        end
    end

    StorePoints(dbEntry, specID, configID, treeID);
end

----------------------------------------------------------
-- Talents Storage
----------------------------------------------------------

function Armory:TalentsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:ClearTalents()
    self:ClearModuleData(container);
end

function Armory:SetTalents()
    local dbEntry = self.playerDbBaseEntry;

    if ( not dbEntry ) then
        return;
    elseif ( not self:TalentsEnabled() or _G.UnitLevel("player") < SHOW_TALENT_LEVEL ) then
        dbEntry:SetValue(container, nil);
        return;
    elseif ( _G.InCombatLockdown() ) then
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        local specIndex = C_SpecializationInfo.GetSpecialization();
        local specID = specIndex and C_SpecializationInfo.GetSpecializationInfo(specIndex);
        local configID = C_ClassTalents.GetActiveConfigID();
        local treeID = specID and C_ClassTalents.GetTraitTreeForSpec(specID);

        if ( configID and treeID ) then
            StoreStructure(treeID);
            StoreActiveSpec(dbEntry, specID, configID, treeID);
        end

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Talents Interface
----------------------------------------------------------

function Armory:HasTalents()
    return self:TalentsEnabled() and self:UnitLevel("player") >= SHOW_TALENT_LEVEL;
end

-- returns classCurrencyID, specCurrencyID
function Armory:GetTalentCurrencies()
    return self:GetClassValue("player", container, "Currencies");
end

-- returns a list of nodeIDs, do not change it
function Armory:GetTalentSpecNodes(specID)
    return self:GetClassValue("player", container, "Specs", specID, "Nodes");
end

-- returns posX, posY, type, part, subTreeID, maxRanks
function Armory:GetTalentNodeInfo(nodeID)
    return self:GetClassValue("player", container, "Nodes", nodeID);
end

function Armory:GetNumTalentNodeEntries(nodeID)
    return self:GetClassNumValues("player", container, "Entries", nodeID);
end

-- returns entryID, spellID, maxRanks, overriddenSpellID, overrideName, overrideIcon, subTreeID, entryType
function Armory:GetTalentNodeEntryInfo(nodeID, index)
    return self:GetClassValue("player", container, "Entries", nodeID, index);
end

-- returns a list of nodeIDs of all specs, do not change it
function Armory:GetTalentNodeEdges(nodeID)
    return self:GetClassValue("player", container, "Edges", nodeID);
end

function Armory:GetNumTalentHeroTrees(specID)
    return self:GetClassNumValues("player", container, "Specs", specID, "HeroTrees");
end

-- returns subTreeID, name, iconElementID, posX, posY, currencyID
function Armory:GetTalentHeroTreeInfo(specID, index)
    return self:GetClassValue("player", container, "Specs", specID, "HeroTrees", index);
end

-- The level from which a hero tree can be chosen
function Armory:GetTalentHeroLevel(specID)
    return self:GetClassValue("player", container, "Specs", specID, "HeroLevel");
end

-- A spec is only known after it has been active
function Armory:TalentsForSpecExist(specID)
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:Contains(container, specID);
end

function Armory:GetActiveTalentHeroTree(specID)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, specID, "HeroTree");
    end
end

-- returns rank, entryID
function Armory:GetTalentNodeState(specID, nodeID)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, specID, "Nodes", nodeID);
    end
end

-- returns spent, quantity, maxQuantity
function Armory:GetTalentPoints(specID, currencyID)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, specID, "Points", currencyID);
    end
end

function Armory:GetNumSpecGroups(inspect)
    return 1;
end
