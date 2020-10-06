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
local container = "HonorTalents";

SHOW_PVP_TALENT_LEVEL = 20;

----------------------------------------------------------
-- Talents Storage
----------------------------------------------------------

function Armory:HonorTalentsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:ClearHonorTalents()
    self:ClearModuleData(container);
end

function Armory:SetHonorTalents()
    local dbEntry = self.playerDbBaseEntry;
    
    if ( not dbEntry ) then
        return;
    elseif ( not self:PVPEnabled() or _G.UnitLevel("player") < SHOW_PVP_TALENT_LEVEL ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        local spec = _G.GetSpecialization();

        dbEntry:SetValue(3, container, spec, "Talents", C_SpecializationInfo.GetAllSelectedPvpTalentIDs());
        dbEntry:SetValue(3, container, spec, "Unspent", _G.GetNumUnspentPvpTalents());
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Talents Interface
----------------------------------------------------------
 
function Armory:GetNumUnspentPvpTalents(spec)
    local dbEntry = self.selectedDbBaseEntry;
	return (dbEntry and dbEntry:GetValue(container, spec, "Unspent")) or 0;
end

function Armory:GetPvpTalentSlotInfo(index, spec)
	local dbEntry = self.selectedDbBaseEntry;
	if ( dbEntry ) then
        local talentID = dbEntry:GetValue(container, spec, "Talents", index);
        local name, iconTexture;
        if ( talentID ) then
            _, name, iconTexture = GetPvpTalentInfoByID(talentID);
        end
	    return talentID, name, iconTexture;
	end
end
