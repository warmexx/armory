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
local container = "Factions";

local table = table;
local select = select;
local tostring = tostring;
local tonumber = tonumber;

----------------------------------------------------------
-- Factions Internals
----------------------------------------------------------

local factionLines = {};
local dirty = true;
local owner = "";

local function GetFactionLines()
    local dbEntry = Armory.selectedDbBaseEntry;

    table.wipe(factionLines);

    if ( dbEntry ) then
        local count = dbEntry:GetNumValues(container);
        local collapsed = false;
        local childCollapsed = false;

        for i = 1, count do
            local name, _, _, _, _, _, _, _, isHeader, _, _, _, isChild = dbEntry:GetValue(container, i, "Info");
            local isCollapsed = Armory:GetHeaderLineState(container, name);
            if ( isHeader and not isChild ) then
                table.insert(factionLines, i);
                collapsed = isCollapsed;
                childCollapsed = false;
            elseif ( isHeader and isChild ) then
                if ( not collapsed ) then
                    table.insert(factionLines, i);
                end
                childCollapsed = collapsed or isCollapsed;
            elseif ( not (collapsed or childCollapsed) ) then
                table.insert(factionLines, i);
            end
        end
    end

    dirty = false;
    owner = Armory:SelectedCharacter();

    return factionLines;
end

local function GetFactionLineValue(index, key, subkey)
    local dbEntry = Armory.selectedDbBaseEntry;
    local numLines = Armory:GetNumFactions();
    if ( dbEntry and index > 0 and index <= numLines ) then
        local factionID = dbEntry:GetValue(container, factionLines[index], "Data");
        if ( subkey ) then
            return dbEntry:GetValue(container, factionID, key, subkey);
        elseif ( key ) then
            return dbEntry:GetValue(container, factionID, key);
        else
            return dbEntry:GetValue(container, factionLines[index], "Info");
        end
    end
end

local function UpdateFactionHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( dbEntry ) then
        if ( index == 0 ) then
            for i = 1, dbEntry:GetNumValues(container) do
                local name, _, _, _, _, _, _, _, isHeader = dbEntry:GetValue(container, i, "Info");
                if ( isHeader ) then
                    Armory:SetHeaderLineState(container, name, isCollapsed);
                end
            end
        else
            local numLines = Armory:GetNumFactions();
            if ( index > 0 and index <= numLines ) then
                local name = dbEntry:GetValue(container, factionLines[index], "Info");
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    end

    dirty = true;
end

----------------------------------------------------------
-- Factions Storage
----------------------------------------------------------

function Armory:FactionsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:ClearFactions()
    self:ClearModuleData(container);
    dirty = true;
end

function Armory:UpdateFactions(retries)
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    elseif ( not self:ReputationEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        -- store the complete (expanded) list
        local funcNumLines = C_Reputation.GetNumFactions;
        local funcGetLineInfo = function(index)
            -- description will be used for factionStandingtext ever since the details panel has been removed
            local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, isCapped;

            local factionData = C_Reputation.GetFactionDataByIndex(index);
            if ( factionData ) then
                name = factionData.name;
                description = factionData.description;
                standingID = factionData.reaction;
                barMin, barMax, barValue = factionData.currentReactionThreshold, factionData.nextReactionThreshold, factionData.currentStanding;
                atWarWith, canToggleAtWar = factionData.atWarWith, factionData.canToggleAtWar;
                isHeader, isCollapsed = factionData.isHeader, factionData.isCollapsed;
                hasRep, isWatched = factionData.isHeaderWithRep, factionData.isWatched;
                isChild = factionData.isChild;
                factionID = factionData.factionID;
                hasBonusRepGain = factionData.hasBonusRepGain;
                isCapped = standingID == MAX_REPUTATION_REACTION;

                local hasFriendship;

                local isMajorFaction = factionID and C_Reputation.IsMajorFaction(factionID);
                local repInfo = factionID and C_GossipInfo.GetFriendshipReputation(factionID);
                if ( repInfo and repInfo.friendshipFactionID > 0 ) then
                    description = repInfo.reaction;
                    if ( repInfo.nextThreshold ) then
                        barMin, barMax, barValue = repInfo.reactionThreshold, repInfo.nextThreshold, repInfo.standing;
                    else
                        -- max rank, make it look like a full bar
                        barMin, barMax, barValue = 0, 1, 1;
                        isCapped = true;
                    end
                elseif ( isMajorFaction ) then
                    local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID);

                    barMin, barMax = 0, majorFactionData.renownLevelThreshold;
                    isCapped = C_MajorFactions.HasMaximumRenown(factionID);
                    barValue = isCapped and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned or 0;

                    description = RENOWN_LEVEL_LABEL:format(majorFactionData.renownLevel);
                else
                    -- no need to store
                    description = nil;
                end
            end

            return name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, hasBonusRepGain, isCapped;
        end;
        local funcGetLineState = function(index)
            local factionData = C_Reputation.GetFactionDataByIndex(index);
            if ( factionData ) then
                return factionData.isHeader, not factionData.isCollapsed;
            end
        end;
        local funcExpand = C_Reputation.ExpandFactionHeader;
        local funcCollapse = C_Reputation.CollapseFactionHeader;
        local funcAdditionalInfo = function(index)
            local factionData = C_Reputation.GetFactionDataByIndex(index);
            if ( factionData and factionData.factionID ) then
                local id = tostring(factionData.factionID);
                local info = dbEntry:SelectContainer(container, id);

                if ( C_Reputation.IsFactionParagon(factionData.factionID) ) then
                    info.Paragon = dbEntry.Save(C_Reputation.GetFactionParagonInfo(factionData.factionID));
                    info.NoData = nil;
                else
                    info.Paragon = nil;
                    info.NoData = true;
                end

                return id;
            end
        end;

        retries = retries or 0;

        if ( not dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse, funcAdditionalInfo) ) then
            self:PrintDebug("Update failed", container);
        end

        dirty = dirty or self:IsPlayerSelected();

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Factions Interface
----------------------------------------------------------

function Armory:HasReputation()
    return self:ReputationEnabled() and self:GetNumFactions() > 0;
end

function Armory:GetNumFactions()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetFactionLines();
    end
    return #factionLines;
end

function Armory:GetFactionInfo(index)
    local dbEntry = self.selectedDbBaseEntry;
    local numLines = self:GetNumFactions();
    if ( dbEntry and index > 0 and index <= numLines ) then
        local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, hasBonusRepGain, isCapped = GetFactionLineValue(index);
        local factionID = dbEntry:GetValue(container, factionLines[index], "Data");
        if ( factionID ) then
            factionID = tonumber(factionID);
        end
        isCollapsed = self:GetHeaderLineState(container, name);
        return name, description, standingID or 1, barMin or 0, barMax or 0, barValue or 0, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, isCapped;
    end
end

function Armory:ExpandFactionHeader(index)
    UpdateFactionHeaderState(index, false);
end

function Armory:CollapseFactionHeader(index)
    UpdateFactionHeaderState(index, true);
end

function Armory:GetFactionStanding(factionName)
    local dbEntry = self.selectedDbBaseEntry;

    if ( dbEntry ) then
        local count = dbEntry:GetNumValues(container);
        for i = 1, count do
            local name, _, standingID = GetFactionLineValue(i);
            if ( name == factionName ) then
                return standingID, GetText("FACTION_STANDING_LABEL"..standingID, self:UnitSex("player"));
            end
        end
    end
    return 0, UNKNOWN;
end

function Armory:IsFactionParagon(factionID)
    local dbEntry = self.selectedDbBaseEntry;

    if ( dbEntry ) then
        return dbEntry:Contains(container, tostring(factionID), "Paragon");
    end
end

function Armory:GetFactionParagonInfo(factionID)
    local dbEntry = self.selectedDbBaseEntry;

    if ( dbEntry ) then
        return dbEntry:GetValue(container, tostring(factionID), "Paragon");
    end
end
