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

local function GetActiveSpec(spec)
    return tostring(spec or Armory:GetSpecialization(false, false, Armory:GetActiveSpecGroup() or 1));
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
    
        local activeTalentGroup = _G.GetActiveSpecGroup() or 1;
        local activeSpec = GetActiveSpec(_G.GetSpecialization(false, false, activeTalentGroup));
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local id, _, _, selected, available = _G.GetTalentInfo(tier, column, activeTalentGroup);
				dbEntry:SetValue(4, container, activeSpec, tier, column, id, selected, available);
			end
		end
	    
        dbEntry:SetValue(3, container, activeSpec, "Unspent", _G.GetNumUnspentTalents());
        
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

function Armory:GetNumUnspentTalents(spec)
	local dbEntry = self.selectedDbBaseEntry;
	return (dbEntry and dbEntry:GetValue(container, GetActiveSpec(spec), "Unspent")) or 0;
end

function Armory:GetNumSpecGroups(inspect)
    return 1;
end

function Armory:GetTalentInfo(tier, column, talentGroup, spec)
	local dbEntry = self.selectedDbBaseEntry;
	if ( dbEntry ) then
		local id, selected, available = dbEntry:GetValue(container, GetActiveSpec(spec), tier, column);
        local name, iconTexture;
        if ( id ) then
            _, name, iconTexture = GetTalentInfoByID(id);
        end
	    return id, name, iconTexture, selected, available;
	end
end

function Armory:TalentsForSpecExist(spec) 
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:Contains(container, tostring(spec));
end