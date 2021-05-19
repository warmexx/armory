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
local container = "Instances";

----------------------------------------------------------
-- Raid Info Internals
----------------------------------------------------------

local function GetInstanceValue(key)
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry:GetSubValue(container, key);
end

----------------------------------------------------------
-- Raid Info Storage
----------------------------------------------------------

function Armory:ClearInstances()
    self:ClearModuleData(container);
end

function Armory:UpdateInstances()
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    elseif ( not self:RaidEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        local oldNum = dbEntry:GetValue(container, "NumInstances") or 0;
        local newNum = _G.GetNumSavedInstances();
        
        if ( newNum == 0 ) then
            dbEntry:SetValue(container, nil);
        else
            dbEntry:SelectContainer(container);
            dbEntry:SetValue(2, container, "NumInstances", newNum);
            dbEntry:SetValue(2, container, "TimeStamp", time());
            for i = 1, max(oldNum, newNum) do
                if ( i > newNum ) then
                    dbEntry:SetValue(2, container, "Instance"..i, nil);
                else
                    dbEntry:SetValue(2, container, "Instance"..i, _G.GetSavedInstanceInfo(i));
                end
            end
        end
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

function Armory:UpdateInstancesInProgress()
    return self:IsLocked(container);
end

----------------------------------------------------------
-- Raid Info Interface
----------------------------------------------------------

function Armory:GetNumSavedInstances()
    local dbEntry = self.selectedDbBaseEntry;
    return (dbEntry and dbEntry:GetValue(container, "NumInstances")) or 0;
end

function Armory:GetSavedInstanceInfo(id)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        local timestamp = dbEntry:GetValue(container, "TimeStamp");
        local instanceName, instanceID, instanceReset = dbEntry:GetValue(container, "Instance"..id);

        if ( instanceReset ) then
            instanceReset = instanceReset - (time() - timestamp);
            if ( instanceReset <= 0 ) then
                instanceReset = 0;
            end
        end

        return instanceName, instanceID, instanceReset;
    end
end
