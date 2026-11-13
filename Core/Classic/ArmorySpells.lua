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
local container = "Spells";

----------------------------------------------------------
-- Spells Internals
----------------------------------------------------------

local function GetSpellBookInfo(index, bookType)
    local dbEntry = Armory.selectedDbBaseEntry;

    if ( dbEntry and bookType == BOOKTYPE_PET ) then
        if ( not Armory:PetExists(Armory:GetCurrentPet()) ) then
            return;
        end
        dbEntry = Armory:SelectPet(dbEntry, Armory:GetCurrentPet());
    end

    if ( dbEntry ) then
        return dbEntry:GetValue(container, index);
    end
end

local function SaveSpellBook(dbEntry, oldNum, newNum, bookType)
    for i = 1, max(oldNum, newNum) do
        if ( i > newNum ) then
            dbEntry:SetValue(2, container, i, nil);
        else
            local spellName, subSpellName =  _G.GetSpellBookItemName(i, bookType);
            local texture = _G.GetSpellBookItemTexture(i, bookType);
            local autoCastAllowed = _G.GetSpellAutocast(i, bookType);
            local isPassive = _G.IsPassiveSpell(i, bookType);
            local link = _G.GetSpellLink(i, bookType);
            local tooltip = Armory:AllocateTooltip();
            tooltip:SetSpellBookItem(i, bookType);
            local tooltipLines = Armory:Tooltip2Table(tooltip);
            Armory:ReleaseTooltip(tooltip);

            dbEntry:SetValue(2, container, i, spellName, subSpellName, texture, isPassive, autoCastAllowed, link, tooltipLines);
        end
    end
end

----------------------------------------------------------
-- Spells Storage
----------------------------------------------------------

function Armory:SpellsExists()
    local dbEntry = self.playerDbBaseEntry;
    return dbEntry and dbEntry:Contains(container);
end

function Armory:ClearSpells()
    self:ClearModuleData(container);
end

function Armory:SetSpells()
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    if ( not self:IsLocked(container) ) then
        self:Lock(container);

        self:PrintDebug("UPDATE", container);

        if ( not self:HasSpellBook() ) then
            dbEntry:SetValue(container, nil);
        else
            local oldTabs = dbEntry:GetNumValues(container, "Tabs");
            local newTabs = _G.GetNumSpellTabs();

            for i = 1, max(oldTabs, newTabs) do
                if ( i > newTabs ) then
                    dbEntry:SetValue(3, container, "Tabs", i, nil);
                else
                    dbEntry:SetValue(3, container, "Tabs", i, _G.GetSpellTabInfo(i));
                end
            end

            local _, _, offset, numSpells = _G.GetSpellTabInfo(newTabs);
            local oldNum = dbEntry:GetNumValues(container);
            local newNum = (offset or 0) + (numSpells or 0);
            SaveSpellBook(dbEntry, oldNum, newNum, BOOKTYPE_SPELL);
        end

        if ( self:IsPersistentPet() ) then
            dbEntry = self:SelectPet(dbEntry, self:GetPetName());
            if ( not self:HasSpellBook() or not _G.PetHasSpellbook() ) then
                dbEntry:SetValue(container, nil);
            else
                local oldNum = dbEntry:GetNumValues(container);
                local newNum = _G.HasPetSpells() or 0;
                SaveSpellBook(dbEntry, oldNum, newNum, BOOKTYPE_PET);
            end
        end

        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Spells Interface
----------------------------------------------------------

function Armory:PetHasSpellbook()
    local dbEntry = self.selectedDbBaseEntry;
    return self:PetExists(self:GetCurrentPet()) and self:SelectPet(dbEntry, self:GetCurrentPet()):Contains(container);
end

function Armory:HasPetSpells()
    local dbEntry = self.selectedDbBaseEntry;
    local numSpells = self:PetExists(self:GetCurrentPet()) and self:SelectPet(dbEntry, self:GetCurrentPet()):GetNumValues(container) or 0;
    if ( numSpells > 0 ) then
        return numSpells, "PET";
    end
end

function Armory:GetNumSpellTabs()
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:GetNumValues(container, "Tabs");
end

function Armory:GetSpellAutocast(id, bookType)
    local _, _, _, _, autoCastAllowed = GetSpellBookInfo(id, bookType);
    return autoCastAllowed;
end

function Armory:GetSpellBookItemName(id, bookType)
    local spellName, subSpellName = GetSpellBookInfo(id, bookType);
    return spellName, subSpellName;
end

function Armory:GetSpellLink(id, bookType)
    local _, _, _, _, _, link = GetSpellBookInfo(id, bookType);
    return link;
end

function Armory:GetSpellTooltip(id, bookType)
    local _, _, _, _, _, _, tooltipLines = GetSpellBookInfo(id, bookType);
    return tooltipLines;
end

function Armory:GetSpellTabInfo(spellTab)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, "Tabs", spellTab);
    end
end

function Armory:GetSpellBookItemTexture(id, bookType)
    local _, _, texture = GetSpellBookInfo(id, bookType);
    return texture;
end

function Armory:IsPassiveSpell(id, bookType)
    local _, _, _, isPassive = GetSpellBookInfo(id, bookType);
    return isPassive;
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindSpell(spellList, ...)
    local list = spellList or {};

    local numSkillLineTabs = self:GetNumSpellTabs();
    local tabName, spellName, subSpellName, offset, numSpells, tooltipLines, text;
    if ( numSkillLineTabs ) then
        for i = 1, numSkillLineTabs do
            tabName, _, offset, numSpells = self:GetSpellTabInfo(i);
            for j = 1, numSpells do
                spellName, subSpellName = self:GetSpellBookItemName(j + offset, BOOKTYPE_SPELL);
                tooltipLines = self:GetSpellTooltip(j + offset, BOOKTYPE_SPELL);
                if ( self:GetConfigExtendedSearch() ) then
                    text = self:Table2Text(tooltipLines);
                else
                    text = spellName;
                end
                if ( self:FindTextParts(text, ...) ) then
                    if ( subSpellName and subSpellName ~= "" ) then
                        table.insert(list, {label=SPELLBOOK.." "..tabName, name=spellName, tooltipLines=tooltipLines, extra=subSpellName});
                    else
                        table.insert(list, {label=SPELLBOOK.." "..tabName, name=spellName, tooltipLines=tooltipLines});
                    end
                end
            end
        end
    end

    local pets = self:GetPets();
    local currentPet = self.selectedPet;
    for i = 1, #pets do
        self.selectedPet = pets[i];
        local numPetSpells = self:HasPetSpells() or 0;
        for id = 1, numPetSpells do
            spellName, subSpellName = self:GetSpellBookItemName(id, BOOKTYPE_PET);
            tooltipLines = self:GetSpellTooltip(id, BOOKTYPE_PET);
            if ( self:GetConfigExtendedSearch() ) then
                text = self:Table2Text(tooltipLines);
            else
                text = spellName;
            end
            if ( self:FindTextParts(text, ...) ) then
                if ( subSpellName and subSpellName ~= "" ) then
                    table.insert(list, {label=SPELLBOOK.." "..self.selectedPet, name=spellName, tooltipLines=tooltipLines, extra=subSpellName});
                else
                    table.insert(list, {label=SPELLBOOK.." "..self.selectedPet, name=spellName, tooltipLines=tooltipLines});
                end
            end
        end
    end
    self.selectedPet = currentPet;

    return list;
end
