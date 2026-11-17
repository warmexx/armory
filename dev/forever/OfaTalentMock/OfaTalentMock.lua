-- OfaTalentMock: mock talents in WoW Forever for Armory One for All, to look at Armory's talent frame
-- with a character below level 10, where Armory stores no talents and hides the Talents tab.
--
-- While on, Armory gets:
--   - the real structure of the tree, which Forever already gives at level 5;
--   - mock ranks for two spec groups: group 1 is the active one, group 2 is inactive (gray background);
--   - the Talents tab, whatever the level.
--
-- /otm             show the state
-- /otm on | off    turn the mock on or off; off removes the mock talents of this character
-- /otm next        show the background of the next class of Forever in the talent frame (the tree stays your own)
-- /otm class X     show the background of class X (MAGE, DRUID, ...); /otm class without X shows your own
--
-- Not part of the release: dev is ignored in .pkgmeta. Remove the addon when done.

OfaTalentMockDB = OfaTalentMockDB or { enabled = true };

local Armory = Armory;
local container = "Talents";
local NUM_SPEC_GROUPS = 2;
local stored;
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" };

local original = {
    SetTalents = Armory.SetTalents,
    HasTalents = Armory.HasTalents,
    GetNumSpecGroups = Armory.GetNumSpecGroups,
    UnitClass = Armory.UnitClass,
};

local function Print(text)
    print("|cff33ff99OfaTalentMock|r: " .. text);
end

----------------------------------------------------------
-- Structure, as StoreGroupStructure in Core\ArmoryTalents.lua
----------------------------------------------------------

local function GetConfigAndTree()
    local specGroup = C_SpecializationInfo.GetActiveSpecGroup();
    local configID = (specGroup and C_SpecializationInfo.GetCombatConfigIDForSpecGroup(specGroup)) or C_ClassTalents.GetActiveConfigID();
    local configInfo = configID and C_Traits.GetConfigInfo(configID);
    return configID, configInfo and configInfo.treeIDs and configInfo.treeIDs[1];
end

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

-- Without a key, so Armory stores the structure again at level 10
local function StoreStructure(configID, treeID)
    Armory:SetClassValue("player", container, nil);

    local groups = C_Traits.GetGroupDisplayInfoByTreeID(treeID) or {};
    table.sort(groups, function(a, b) return a.orderIndex < b.orderIndex; end);
    local partOfGroup = {};
    for i, info in ipairs(groups) do
        partOfGroup[info.groupID] = i;
        Armory:SetClassValue("player", 3, container, "Groups", i, info.groupID, info.displayName, info.icon);
    end

    local treeNodes = {};
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
        if ( nodeInfo and nodeInfo.ID and nodeInfo.ID ~= 0 and nodeInfo.isVisible and #nodeInfo.entryIDs > 0 ) then
            local part;
            for _, groupID in ipairs(nodeInfo.groupIDs or {}) do
                part = part or partOfGroup[groupID];
            end
            if ( part ) then
                table.insert(treeNodes, nodeID);
                StoreNode(nodeID, nodeInfo, part, configID);

                local targets = {};
                for _, edge in ipairs(nodeInfo.visibleEdges) do
                    table.insert(targets, edge.targetNode);
                end
                if ( #targets > 0 ) then
                    Armory:SetClassValue("player", 3, container, "Edges", nodeID, targets);
                end
            end
        end
    end
    Armory:SetClassValue("player", 2, container, "TreeNodes", treeNodes);

    return #treeNodes;
end

----------------------------------------------------------
-- Mock ranks
----------------------------------------------------------

-- Per four nodes: empty, maxed, partial (or maxed with one rank), maxed; group 2 is shifted, so it differs
local function MockRank(index, maxRanks)
    local step = index % 4;
    if ( step == 0 or not maxRanks or maxRanks == 0 ) then
        return 0;
    elseif ( step == 2 and maxRanks > 1 ) then
        return maxRanks - 1;
    end
    return maxRanks;
end

local function StoreMockRanks(dbEntry)
    for specGroup = 1, NUM_SPEC_GROUPS do
        dbEntry:SetValue(2, container, specGroup, nil);
        for i, nodeID in ipairs(Armory:GetTalentSpecNodes() or {}) do
            local maxRanks = select(6, Armory:GetTalentNodeInfo(nodeID));
            local rank = MockRank(i + (specGroup - 1) * 2, maxRanks);
            if ( rank > 0 ) then
                local entryID = Armory:GetTalentNodeEntryInfo(nodeID, 1);
                dbEntry:SetValue(4, container, specGroup, "Nodes", nodeID, rank, entryID);
            end
        end
    end
end

local function MockSetTalents(self)
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry or not self:TalentsEnabled() ) then
        return original.SetTalents(self);
    end

    local configID, treeID = GetConfigAndTree();
    if ( not treeID ) then
        Print("no talent tree found, nothing mocked");
        return;
    end
    if ( not stored ) then
        local numNodes = StoreStructure(configID, treeID);
        stored = true;
        Print(format("structure stored: %d nodes, mock ranks for %d spec groups", numNodes, NUM_SPEC_GROUPS));
    end
    StoreMockRanks(dbEntry);
end

----------------------------------------------------------
-- On and off
----------------------------------------------------------

-- Only the background of the talent frame asks for the class there; the tree is read under the real class
local function MockUnitClass(self, unit)
    local name, classFile, classID = original.UnitClass(self, unit);
    if ( OfaTalentMockDB.class and strfind(debugstack(2, 1, 0) or "", "ArmoryTalentFrame") ) then
        return name, OfaTalentMockDB.class, classID;
    end
    return name, classFile, classID;
end

local function Refresh()
    if ( ArmoryTalentFrame and ArmoryTalentFrame:IsVisible() ) then
        ArmoryTalentFrame_UpdateSpecTabs(ArmoryTalentFrame);
        ArmoryTalentFrame_Update();
    end
end

local function Apply()
    if ( OfaTalentMockDB.enabled ) then
        Armory.SetTalents = MockSetTalents;
        Armory.HasTalents = function(self) return self:TalentsEnabled(); end;
        Armory.GetNumSpecGroups = function() return NUM_SPEC_GROUPS; end;
        Armory.UnitClass = MockUnitClass;
    else
        for name, func in pairs(original) do
            Armory[name] = func;
        end
        stored = nil;
    end
end

local function State()
    if ( not OfaTalentMockDB.enabled ) then
        return "off";
    end
    return "on, background of " .. (OfaTalentMockDB.class or "your own class");
end

SLASH_OFATALENTMOCK1 = "/otm";
SlashCmdList["OFATALENTMOCK"] = function(msg)
    local command, argument = strsplit(" ", strtrim(msg or ""), 2);
    command = strlower(command or "");

    if ( command == "on" ) then
        OfaTalentMockDB.enabled = true;
        Apply();
        Armory:SetTalents();
    elseif ( command == "off" ) then
        OfaTalentMockDB.enabled = false;
        OfaTalentMockDB.class = nil;
        Apply();
        -- Below level 10 this removes the talents of the character; the structure stays until it is stored again
        Armory:SetTalents();
        Print("off; /reload to update the tabs of Armory");
    elseif ( command == "next" ) then
        local index = 0;
        for i, class in ipairs(CLASSES) do
            if ( class == OfaTalentMockDB.class ) then
                index = i;
            end
        end
        OfaTalentMockDB.class = CLASSES[index % #CLASSES + 1];
    elseif ( command == "class" ) then
        OfaTalentMockDB.class = argument and strupper(argument) or nil;
    elseif ( command ~= "" ) then
        Print("/otm [on | off | next | class X]");
    end

    Refresh();
    Print(State());
end

Apply();
