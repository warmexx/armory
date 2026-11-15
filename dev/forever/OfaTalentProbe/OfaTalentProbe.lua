-- OfaTalentProbe: measures the talent tree and the specializations of WoW Forever for Armory One for All,
-- and checks which functions from the open questions exist.
-- Reads only; changes nothing (no InitializeViewLoadout, no loadouts).
--
-- /otp        measure the current character and save it in OfaTalentProbeDB (WTF\...\SavedVariables)
-- /otp clear  remove all measurements
--
-- After /otp: /reload or log out, so the game writes the file.

OfaTalentProbeDB = OfaTalentProbeDB or {};

local errors;

-- An API function, or nil when the namespace or function is missing
local function Api(namespace, name)
    local functions = _G[namespace];
    return type(functions) == "table" and functions[name] or nil;
end

-- Calls an API and keeps the error instead of stopping
local function Try(label, func, ...)
    if ( type(func) ~= "function" ) then
        table.insert(errors, label .. ": no function");
        return;
    end
    local result = { pcall(func, ...) };
    if ( not result[1] ) then
        table.insert(errors, label .. ": " .. tostring(result[2]));
        return;
    end
    return select(2, unpack(result));
end

-- A copy without functions, userdata and secret values, at most a few levels deep
local function Copy(value, depth)
    depth = depth or 0;
    local kind = type(value);
    if ( kind == "table" ) then
        if ( depth > 5 ) then
            return "<deep>";
        end
        local copy = {};
        for k, v in pairs(value) do
            if ( type(k) == "string" or type(k) == "number" ) then
                copy[k] = Copy(v, depth + 1);
            end
        end
        return copy;
    elseif ( kind == "string" or kind == "number" or kind == "boolean" ) then
        if ( issecretvalue and issecretvalue(value) ) then
            return "<secret>";
        end
        return value;
    end
    return nil;
end

-- Globals that Armory uses and that are not in Forever's documentation or code
local GLOBALS = {
    "GetGuildRosterInfo", "GetBattlegroundInfo", "GetTalentInfoByID", "GetTalentLink",
    "QuestIsDaily", "QuestIsWeekly", "GetQuestResetTime", "GetInboxItemLink",
    "GetMaxRewardCurrencies", "GetNumUnspentPvpTalents", "SHOW_PVP_TALENT_LEVEL",
    "GetSpecializationSpells", "GetNumSpecializations", "GetSpecializationInfoForClassID",
    "GetNumSpecGroups", "GetActiveSpecGroup", "EJ_GetCreatureInfo", "MAX_PLAYER_LEVEL",
};
local FUNCTIONS = {
    "C_Bank.FetchPurchasedBankTabData", "C_Bank.CanViewBank", "C_SpecializationInfo.GetSpellsDisplay",
    "C_PetInfo.GetPetHappiness", "C_PetInfo.GetPetLoyalty", "C_PetInfo.GetPetTrainingPoints",
    "C_QuestInfoSystem.GetQuestRewardCurrencies", "C_SkillInfo.GetSkillLineInfo",
};

local function MeasureConfig(configID, treeID, withStructure)
    local config = {};
    config.configInfo = Copy(Try("GetConfigInfo", Api("C_Traits", "GetConfigInfo"), configID));
    config.treeCurrencies = Copy(Try("GetTreeCurrencyInfo", Api("C_Traits", "GetTreeCurrencyInfo"), configID, treeID, false));

    local displayInfos = Try("GetGroupDisplayInfoByTreeID", Api("C_Traits", "GetGroupDisplayInfoByTreeID"), treeID) or {};
    local groupIDs = {};
    for _, info in ipairs(displayInfos) do
        table.insert(groupIDs, info.groupID);
    end
    config.groups = Copy(displayInfos);
    config.groupCurrencies = Copy(Try("GetGroupCurrencyInfo", Api("C_Traits", "GetGroupCurrencyInfo"), configID, groupIDs));

    local nodes = {};
    local entries = {};
    local conditions = {};
    for _, nodeID in ipairs(Try("GetTreeNodes", Api("C_Traits", "GetTreeNodes"), treeID) or {}) do
        local info = Try("GetNodeInfo " .. nodeID, Api("C_Traits", "GetNodeInfo"), configID, nodeID);
        if ( info ) then
            local node = {
                activeRank = info.activeRank,
                ranksPurchased = info.ranksPurchased,
                activeEntryID = info.activeEntry and info.activeEntry.entryID,
                isVisible = info.isVisible,
            };
            if ( withStructure ) then
                node.posX = info.posX;
                node.posY = info.posY;
                node.flags = info.flags;
                node.type = info.type;
                node.maxRanks = info.maxRanks;
                node.totalMaxRanks = info.totalMaxRanks;
                node.groupIDs = Copy(info.groupIDs);
                node.subTreeID = info.subTreeID;
                node.entryIDs = Copy(info.entryIDs);
                node.conditionIDs = Copy(info.conditionIDs);
                node.edges = Copy(info.visibleEdges);
                node.cost = Copy(Try("GetNodeCost " .. nodeID, Api("C_Traits", "GetNodeCost"), configID, nodeID));

                for _, entryID in ipairs(info.entryIDs or {}) do
                    if ( not entries[entryID] ) then
                        local entryInfo = Try("GetEntryInfo " .. entryID, Api("C_Traits", "GetEntryInfo"), configID, entryID);
                        local entry = Copy(entryInfo) or {};
                        if ( entryInfo and entryInfo.definitionID ) then
                            local definition = Try("GetDefinitionInfo " .. entryInfo.definitionID, Api("C_Traits", "GetDefinitionInfo"), entryInfo.definitionID);
                            entry.definition = Copy(definition);
                            if ( definition and definition.spellID ) then
                                entry.spellName = Try("GetSpellName", Api("C_Spell", "GetSpellName"), definition.spellID);
                            end
                        end
                        entries[entryID] = entry;
                    end
                end
                for _, conditionID in ipairs(info.conditionIDs or {}) do
                    if ( not conditions[conditionID] ) then
                        conditions[conditionID] = Copy(Try("GetConditionInfo " .. conditionID, Api("C_Traits", "GetConditionInfo"), configID, conditionID));
                    end
                end
            end
            nodes[nodeID] = node;
        end
    end
    config.nodes = nodes;
    if ( withStructure ) then
        config.entries = entries;
        config.conditions = conditions;
    end
    return config;
end

local function Measure()
    errors = {};
    local data = {};

    data.build = { GetBuildInfo() };
    data.projectID = WOW_PROJECT_ID;
    data.level = UnitLevel("player");
    data.class = select(2, UnitClass("player"));
    data.time = date("%Y-%m-%d %H:%M:%S");
    data.SHOW_TALENT_LEVEL = SHOW_TALENT_LEVEL;
    data.maxLevel = Try("GetMaxLevelForPlayerExpansion", GetMaxLevelForPlayerExpansion);

    -- What Armory's Retail code reads (Core\ArmoryTalents.lua, SetTalents)
    data.numSpecializations = Try("GetNumSpecializations", GetNumSpecializations);
    data.specialization = Try("GetSpecialization", Api("C_SpecializationInfo", "GetSpecialization"));
    data.specializations = {};
    for i = 1, data.numSpecializations or 0 do
        local specID, name = Try("GetSpecializationInfo " .. i, Api("C_SpecializationInfo", "GetSpecializationInfo"), i);
        data.specializations[i] = {
            specID = specID,
            name = name,
            treeID = specID and Try("GetTraitTreeForSpec " .. specID, Api("C_ClassTalents", "GetTraitTreeForSpec"), specID),
        };
    end
    -- Armory's fallback for other characters (Core\ArmorySpecializations.lua) and the pet specs
    local classID = select(3, UnitClass("player"));
    data.classID = classID;
    data.numSpecializationsForClassID = Try("GetNumSpecializationsForClassID", Api("C_SpecializationInfo", "GetNumSpecializationsForClassID"), classID);
    data.specializationsForClassID = {};
    for i = 1, data.numSpecializationsForClassID or 0 do
        data.specializationsForClassID[i] = { Try("GetSpecializationInfoForClassID " .. i, GetSpecializationInfoForClassID, classID, i) };
    end
    if ( UnitExists("pet") ) then
        data.numPetSpecializations = Try("GetNumSpecializations pet", GetNumSpecializations, false, true);
        data.petSpecialization = Try("GetSpecialization pet", Api("C_SpecializationInfo", "GetSpecialization"), false, true);
        data.petSpecializations = {};
        for i = 1, data.numPetSpecializations or 0 do
            data.petSpecializations[i] = { Try("GetSpecializationInfo pet " .. i, Api("C_SpecializationInfo", "GetSpecializationInfo"), i, false, true) };
        end
    end
    for i, spec in ipairs(data.specializations) do
        spec.info = { Try("GetSpecializationInfo all " .. i, Api("C_SpecializationInfo", "GetSpecializationInfo"), i) };
    end

    data.activeConfigID = Try("GetActiveConfigID", Api("C_ClassTalents", "GetActiveConfigID"));
    data.activeHeroTalentSpec = Try("GetActiveHeroTalentSpec", Api("C_ClassTalents", "GetActiveHeroTalentSpec"));

    -- What Blizzard's Forever talent frame reads (Camelot\ClassTalents\Blizzard_ClassTalentsFrame.lua)
    data.numSpecGroups = Try("GetNumSpecGroups", GetNumSpecGroups);
    data.activeSpecGroup = Try("GetActiveSpecGroup", Api("C_SpecializationInfo", "GetActiveSpecGroup"));
    data.specGroups = {};
    for group = 1, max(2, data.numSpecGroups or 0) do
        data.specGroups[group] = { configID = Try("GetCombatConfigIDForSpecGroup " .. group, Api("C_SpecializationInfo", "GetCombatConfigIDForSpecGroup"), group) };
    end

    -- The tree: from the active spec group, else from Armory's way
    local activeGroup = data.activeSpecGroup or 1;
    local configID = data.specGroups[activeGroup].configID or data.activeConfigID;
    local configInfo = configID and Try("GetConfigInfo", Api("C_Traits", "GetConfigInfo"), configID);
    local treeID = configInfo and configInfo.treeIDs and configInfo.treeIDs[1];
    data.treeID = treeID;
    data.treeHash = treeID and Copy(Try("GetTreeHash", Api("C_Traits", "GetTreeHash"), treeID));
    data.treeInfo = treeID and configID and Copy(Try("GetTreeInfo", Api("C_Traits", "GetTreeInfo"), configID, treeID));

    if ( treeID ) then
        for group, specGroup in pairs(data.specGroups) do
            if ( specGroup.configID ) then
                specGroup.config = MeasureConfig(specGroup.configID, treeID, group == activeGroup);
            end
        end
        if ( data.activeConfigID and data.activeConfigID ~= configID ) then
            data.armoryConfig = MeasureConfig(data.activeConfigID, treeID, false);
        end
    end

    -- Open questions in docs\FOREVER.md: does the client have these?
    data.exists = {};
    for _, name in ipairs(GLOBALS) do
        data.exists[name] = type(_G[name]);
    end
    for _, path in ipairs(FUNCTIONS) do
        local namespace, name = strsplit(".", path);
        data.exists[path] = type(Api(namespace, name));
    end

    data.errors = errors;

    local key = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?");
    OfaTalentProbeDB[key] = data;

    local numNodes = 0;
    local active = treeID and data.specGroups[activeGroup].config;
    if ( active ) then
        for _ in pairs(active.nodes) do
            numNodes = numNodes + 1;
        end
    end
    print(format("OfaTalentProbe: %s, level %s, tree %s, %d nodes, %d groups, %d errors. /reload to save the file.",
        key, tostring(data.level), tostring(treeID), numNodes, active and #(active.groups or {}) or 0, #errors));
end

SLASH_OFATALENTPROBE1 = "/otp";
SlashCmdList["OFATALENTPROBE"] = function(msg)
    if ( msg == "clear" ) then
        wipe(OfaTalentProbeDB);
        print("OfaTalentProbe: cleared.");
    else
        local ok, message = pcall(Measure);
        if ( not ok ) then
            print("OfaTalentProbe failed: " .. tostring(message));
        end
    end
end
