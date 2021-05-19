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


----------------------------------------------------------
-- Arena Teams Storage
----------------------------------------------------------

function Armory:UpdateArenaTeams()
    local dbEntry = self.playerDbBaseEntry;
    local container, numTeamMembers;
    local i;

    for id = 1, MAX_ARENA_TEAMS do
        container = "ArenaTeam"..id;

        dbEntry:SetValue(container, _G.GetArenaTeam(id));

        if ( _G.GetArenaTeam(id) ) then
            _G.ArenaTeamRoster(id);

            numTeamMembers = _G.GetNumArenaTeamMembers(id, 1);
            if ( numTeamMembers > 0 ) then
                dbEntry:SetSubValue(container, "NumTeamMembers", numTeamMembers);
                for i = 1, numTeamMembers do
                    dbEntry:SetSubValue(container, "Info"..i, _G.GetArenaTeamRosterInfo(id, i));
                end
            end
        end
    end
end

----------------------------------------------------------
-- Arean Teams Internals
----------------------------------------------------------

function Armory:GetArenaTeamValue(id, key)
    local container = "ArenaTeam"..id;
    local dbEntry = self.selectedDbBaseEntry;
    if ( key == nil ) then
        return dbEntry:GetValue(container);
    end
    return dbEntry:GetSubValue(container, key);
end

----------------------------------------------------------
-- Arena Teams Interface
----------------------------------------------------------

function Armory:GetArenaTeam(id)
    return self:GetArenaTeamValue(id);
end

function Armory:GetNumArenaTeamMembers(id, showOffline)
    return self:GetArenaTeamValue(id, "NumTeamMembers") or 0;
end

function Armory:GetArenaTeamRosterInfo(id, index)
    if ( index ) then
        return self:GetArenaTeamValue(id, "Info"..index);
    end
end
