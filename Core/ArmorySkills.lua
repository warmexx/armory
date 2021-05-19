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
local container = "Skills";

----------------------------------------------------------
-- Skills Internals
----------------------------------------------------------

local skillLines = {}
local dirty = true;
local owner = "";

local function GetSkillLines()
    local dbEntry = Armory.selectedDbBaseEntry;

    table.wipe(skillLines);

    if ( dbEntry ) then
        local count = dbEntry:GetNumValues(container);
        local expanded = true;

        for i = 1, count do
            local name, isHeader = dbEntry:GetValue(container, i);
            if ( isHeader ) then
                table.insert(skillLines, i);
                expanded = not Armory:GetHeaderLineState(container, name);
            elseif ( expanded ) then
                table.insert(skillLines, i);
            end
        end
    end

    dirty = false;
    owner = Armory:SelectedCharacter();

    return skillLines;
end

local function UpdateSkillHeaderState(index, isCollapsed)
    local dbEntry = Armory.selectedDbBaseEntry;
    
    if ( dbEntry ) then
        if ( index == 0 ) then
            for i = 1, dbEntry:GetNumValues(container) do
                local name, isHeader = dbEntry:GetValue(container, i);
                if ( isHeader ) then
                    Armory:SetHeaderLineState(container, name, isCollapsed);
                end
            end
        else
            local numLines = Armory:GetNumSkillLines();
            if ( index > 0 and index <= numLines ) then
                local name = dbEntry:GetValue(container, skillLines[index]);
                Armory:SetHeaderLineState(container, name, isCollapsed);
            end
        end
    end

    dirty = true;
end

----------------------------------------------------------
-- Skills Storage
----------------------------------------------------------

function Armory:SkillsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:ClearSkills()
    self:ClearModuleData(container);
    dirty = true;
end

function Armory:SetSkills()
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    if ( not self:SkillsEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        -- store the complete (expanded) list
        local funcNumLines = _G.GetNumSkillLines;
        local funcGetLineInfo = _G.GetSkillLineInfo;
        local funcGetLineState = function(index)
            local _, isHeader, isExpanded = _G.GetSkillLineInfo(index);
            return isHeader, isExpanded;
        end;
        local funcExpand = _G.ExpandSkillHeader;
        local funcCollapse = _G.CollapseSkillHeader;
        
        dbEntry:SetExpandableListValues(container, funcNumLines, funcGetLineState, funcGetLineInfo, funcExpand, funcCollapse);
 
        dirty = dirty or self:IsPlayerSelected();
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Skills Interface
----------------------------------------------------------

function Armory:GetNumSkillLines()
    if ( dirty or not self:IsSelectedCharacter(owner) ) then
        GetSkillLines();
    end
    return #skillLines;
end

function Armory:GetSkillLineInfo(index)
    local dbEntry = self.selectedDbBaseEntry;
    local numLines = self:GetNumSkillLines();
    if ( dbEntry and index > 0 and index <= numLines ) then
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription = dbEntry:GetValue(container, skillLines[index]);
        isExpanded = not Armory:GetHeaderLineState(container, skillName);
        return skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank, isAbandonable, stepCost, rankCost, minLevel, skillCostType, skillDescription;
    end
end

function Armory:ExpandSkillHeader(index)
    UpdateSkillHeaderState(index, false);
end

function Armory:CollapseSkillHeader(index)
    UpdateSkillHeaderState(index, true);
end
