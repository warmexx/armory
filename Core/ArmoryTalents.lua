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
local container = "Talents";

----------------------------------------------------------
-- Talents Internals
----------------------------------------------------------

local function SelectTalent(baseEntry, index)
    local dbEntry = ArmoryDbEntry:new(baseEntry);
    dbEntry:SetPosition(container, index);
    return dbEntry;
end

local function SetTalentValue(index, key, ...)
    SelectTalent(Armory.playerDbBaseEntry, index):SetValue(key, ...);
end

local function GetTalentValue(index, key)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( dbEntry:Contains(container, index, key) ) then
        return SelectTalent(dbEntry, index):GetValue(key);
    end
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
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);
    
        local tooltip = self:AllocateTooltip();
        local inspect = false;
        local tooltipLines;
        for i = 1, _G.GetNumTalentTabs(inspect) do
            local name, texture, points, fileName = _G.GetTalentTabInfo(i, inspect);
            if ( not texture ) then
                _, texture = _G.GetSpellTabInfo(i + 1);
            end
            SetTalentValue(i, "Info", name, texture, points, fileName);
            SetTalentValue(i, "NumTalents", _G.GetNumTalents(i, inspect));
            for j = 1, _G.GetNumTalents(i, inspect) do
                tooltip:SetTalent(i, j);
                tooltipLines = self:Tooltip2Table(tooltip);
                if ( tooltipLines[#tooltipLines]:match(TOOLTIP_TALENT_LEARN) ) then
                    table.remove(tooltipLines);
                end
            
                SetTalentValue(i, "Info"..j, _G.GetTalentInfo(i, j, inspect));
                SetTalentValue(i, "Prereqs"..j, _G.GetTalentPrereqs(i, j, inspect));
                SetTalentValue(i, "Tooltip"..j, unpack(tooltipLines));
            end
        end
        self:ReleaseTooltip(tooltip);
        
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

function Armory:GetNumTalentTabs(inspect)
    return self.selectedDbBaseEntry:GetNumValues(container);
end

function Armory:GetNumTalents(index, inspect)
    if ( index ) then
        return GetTalentValue(index, "NumTalents") or 0;
    end
end

function Armory:GetTalentTabInfo(index, inspect)
    if ( index ) then
        return GetTalentValue(index, "Info");
    end
end

function Armory:GetTalentInfo(index, id, inspect)
    if ( index and id ) then
        return GetTalentValue(index, "Info"..id);
    end
end

function Armory:GetTalentPrereqs(index, id, inspect)
    if ( index and id ) then
        return GetTalentValue(index, "Prereqs"..id);
    end
end

local talentTooltip = {}
function Armory:GetTalentTooltip(index, id)
    if ( index and id ) then
        self:FillTable(talentTooltip, GetTalentValue(index, "Tooltip"..id));
        return talentTooltip;
    end
end
