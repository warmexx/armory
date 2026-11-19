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
local container = "Spells";

----------------------------------------------------------
-- Spells Internals
----------------------------------------------------------

local function GetSubSpellName(id, spellBank)
    local spellName, subSpellName = C_SpellBook.GetSpellBookItemName(id, spellBank);
    if ( subSpellName == "" ) then
        local isPassive = C_SpellBook.IsSpellBookItemPassive(id, spellBank);
        if ( isPassive ) then
            subSpellName = SPELL_PASSIVE;
        end
    end
    if ( subSpellName ~= "" ) then
        return subSpellName;
    end
end

-- Retail still has GetSpecializationSpells (spell ID and level in turns); Forever gets the spell IDs
-- from GetSpellsDisplay
local GetPetSpecializationSpells;
if ( _G.GetSpecializationSpells ) then
    GetPetSpecializationSpells = function(spec)
        local spells = {};
        local values = { _G.GetSpecializationSpells(spec, nil, true) };
        for i = 1, #values, 2 do
            table.insert(spells, values[i]);
        end
        return spells;
    end;
else
    GetPetSpecializationSpells = function(spec)
        local specID = C_SpecializationInfo.GetSpecializationInfo(spec, false, true);
        return specID and C_SpecializationInfo.GetSpellsDisplay(specID) or {};
    end;
end

local function IsSpecializationSpell(spellID, specSpells)
    for i = 1, #specSpells do
        if ( spellID == specSpells[i] ) then
            return true;
        end
    end
    return false;
end

local function SaveSpellBook(dbEntry, oldNum, newNum, spellBank, offSpec)
    local family, isHunterPet, spec, specSpells;

    if ( spellBank == Enum.SpellBookSpellBank.Pet ) then
        family = _G.UnitCreatureFamily("pet");
        if ( family ) then
            Armory:SetClassValue("player", 2, container, family, nil);
        end

        _, isHunterPet = _G.HasPetUI();
        if ( isHunterPet ) then
            spec = C_SpecializationInfo.GetSpecialization(false, true) or 1;
            specSpells = GetPetSpecializationSpells(spec);
            if ( spec ) then
                Armory:SetClassValue("pet", 2, container, spec, nil);
            end
        end
    end

    for i = 1, max(oldNum, newNum) do
        if ( i > newNum ) then
            dbEntry:SetValue(2, container, i, nil);
        else
            local slotType, actionID, spellID = C_SpellBook.GetSpellBookItemType(i, spellBank);
            if ( slotType == Enum.SpellBookItemType.Spell ) then
                slotType = "SPELL";
            elseif ( slotType == Enum.SpellBookItemType.PetAction ) then
                slotType = "PETACTION";
            elseif ( slotType == Enum.SpellBookItemType.Flyout ) then
                slotType = "FLYOUT";
            elseif ( slotType == Enum.SpellBookItemType.FutureSpell ) then
                slotType = "FUTURESPELL";
            end

            if ( actionID or spellID ) then
                local subSpellName = GetSubSpellName(i, spellBank);
                local spellName, texture, link;

                if ( spellBank == Enum.SpellBookSpellBank.Pet ) then
                    if ( slotType == "PETACTION" ) then
                        if ( not spellID ) then
                            spellName = C_SpellBook.GetSpellBookItemName(i, spellBank);
                            texture = C_SpellBook.GetSpellBookItemTexture(i, spellBank);
                            Armory:SetSharedValue(2, slotType, spellName, subSpellName, texture);
                        elseif ( family ) then
                            Armory:SetClassValue("player", 3, container, family, tostring(spellID), subSpellName or "");
                        end
                    elseif ( spec and specSpells and IsSpecializationSpell(spellID, specSpells) ) then
                        Armory:SetClassValue("pet", 3, container, spec, tostring(spellID), subSpellName or "");
                    end
                elseif ( spellID ) then
                    local attachedGlyph = _G.HasAttachedGlyph(spellID) and GetCurrentGlyphNameForSpell(spellID) or nil;
                    local isDisabled = C_Spell.IsSpellDisabled(spellID);
                    local isLocked = C_LevelLink.IsSpellLocked(spellID);
                    local level = C_SpellBook.GetSpellBookItemLevelLearned(i, spellBank);

                    if ( slotType == "FLYOUT" ) then
                        spellName = C_SpellBook.GetSpellBookItemName(i, spellBank);
                        texture = C_SpellBook.GetSpellBookItemTexture(i, spellBank);
                        local tradeSkillLink, tradeSkillSpellID = C_SpellBook.GetSpellBookItemTradeSkillLink(i, spellBank);
                        if ( tradeSkillSpellID ) then
                            link = tradeSkillLink;
                        else
                            link = C_SpellBook.GetSpellBookItemLink(i, spellBank);
                        end
                     elseif ( attachedGlyph ) then
                        link = C_SpellBook.GetSpellBookItemLink(i, spellBank);
                    end
                    dbEntry:SetValue(2, container, i, spellID, subSpellName, slotType, spellName, texture, link, level, attachedGlyph, isDisabled, isLocked);
                    if ( slotType == "FLYOUT" ) then
                        local _, _, numSlots, isKnown = _G.GetFlyoutInfo(spellID);
                        if ( (isKnown or offSpec) and numSlots > 0 ) then
                            for slot = 1, numSlots do
                                local flyoutSpellID, overrideSpellID, isKnown, spellName, slotSpecID = _G.GetFlyoutSlotInfo(spellID, slot);
                                dbEntry:SetValue(4, container, i, "Info", slot, flyoutSpellID, overrideSpellID, isKnown, spellName, slotSpecID);
                            end
                        end
                    end
                end
            end
        end
    end
end

local petSpells = {};
local spellsFamily;
local petSpec;
local hasSpecSpells;
local function GetPetSpells(specialization)
    local hasPetUI, isHunterPet = Armory:HasPetUI();
    local family = Armory:UnitCreatureFamily("pet");
    local spec;
    if ( isHunterPet ) then
        spec = specialization or Armory:GetSpecialization(false, true);
    end

    if ( not (hasPetUI and family) ) then
        table.wipe(petSpells);

    elseif ( spellsFamily ~= family or petSpec ~= spec ) then
        local spells, spellName;

        table.wipe(petSpells);

        spells = Armory:GetSharedValue("PETACTION");
        if ( spells ) then
            for spellName, data in pairs(spells) do
                local subSpellName, texture = ArmoryDbEntry.Load(data);
                table.insert(petSpells, { name=spellName, subName=subSpellName, icon=texture, isAction=true });
            end
        end

        hasSpecSpells = false;
        if ( spec ) then
            spells = Armory:GetClassValue("pet", container, spec);
            if ( spells ) then
                for spellID in pairs(spells) do
                    local subSpellName = Armory:GetClassValue("pet", container, spec, spellID);
                    spellName = C_Spell.GetSpellName(spellID);
                    if ( spellName ) then
                        table.insert(petSpells, { spellID=spellID, name=spellName, subName=subSpellName });
                        hasSpecSpells = true;
                    end
                end
            end
        end

        spells = Armory:GetClassValue("player", container, family);
        if ( spells ) then
            for spellID in pairs(spells) do
                local subSpellName = Armory:GetClassValue("player", container, family, spellID);
                spellName = C_Spell.GetSpellName(spellID);
                if ( spellName ) then
                    table.insert(petSpells, { spellID=spellID, name=spellName, subName=subSpellName });
                end
            end
        end

        table.sort(petSpells, function(a, b) return a.name < b.name end);
    end

    spellsFamily = family;
    petSpec = spec;

    return petSpells, hasSpecSpells;
end

local petTabs = {};
local function GetPetTabs()
    local numTalentGroups = Armory:GetNumSpecGroups();
    local activeTalentGroup = Armory:GetActiveSpecGroup();

    table.wipe(petTabs);

    for talentGroup = 1, numTalentGroups do
        local spec = Armory:GetSpecialization(false, true, talentGroup);
        if ( spec ) then
            local _, name, _, texture = Armory:GetSpecializationInfo(spec, false, true, nil, Armory:UnitSex("pet"));
            if ( name ) then
                local spells, hasSpecSpells = GetPetSpells(spec);
                local offSpecID;
                if ( hasSpecSpells ) then
                    if ( talentGroup == activeTalentGroup ) then
                        offSpecID = 0;
                    else
                        offSpecID = spec;
                    end
                    table.insert(petTabs, { name=name, icon=texture, offSpec=offSpecID });
                end
            end
        end
    end

    if ( #petTabs > 1 ) then
        table.sort(petTabs, function(a, b) return a.offSpec < b.offSpec end);
    end

    return petTabs;
end

local function GetSpellBookInfo(id, spellBank, specialization)
    local dbEntry = Armory.selectedDbBaseEntry;
    if ( dbEntry ) then
        local spellID, subSpellName, slotType, spellName, texture, link, level, hasAttachedGlyph;
        if ( spellBank == Enum.SpellBookSpellBank.Pet ) then
            local spell = GetPetSpells(specialization)[id];
            if ( spell ) then
                spellID = spell.spellID;
                spellName = spell.name;
                subSpellName = spell.subName;
                slotType = spell.isAction and "PETACTION" or "SPELL";
                texture = spell.icon;
            end
        else
            spellID, subSpellName, slotType, spellName, texture, link, level, hasAttachedGlyph = dbEntry:GetValue(container, id);
        end
        return spellID, subSpellName, slotType, spellName, texture, link, level, hasAttachedGlyph;
    end
end

local function GetSpellTabInfo(index)
    local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(index);
    if ( skillLineInfo ) then
        return skillLineInfo.name, skillLineInfo.iconID, skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems, skillLineInfo.isGuild, skillLineInfo.offSpecID or 0, skillLineInfo.shouldHide, skillLineInfo.specID;
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
    self:SetSharedValue("PETACTION", nil);
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
            local newTabs = C_SpellBook.GetNumSpellBookSkillLines();
            for i = 1, max(oldTabs, newTabs) do
                if ( i > newTabs ) then
                    dbEntry:SetValue(3, container, "Tabs", i, nil);
                else
                    dbEntry:SetValue(3, container, "Tabs", i, GetSpellTabInfo(i));
                end
            end
            local _, _, offset, numSlots, _, offSpecID = GetSpellTabInfo(newTabs);
            local isOffSpec = (offSpecID ~= 0);
            local oldNum = dbEntry:GetNumValues(container);
            local newNum = (offset or 0) + (numSlots or 0);

            SaveSpellBook(dbEntry, oldNum, newNum, Enum.SpellBookSpellBank.Player, isOffSpec);
        end

        if ( self:IsPersistentPet() ) then
            dbEntry = self:SelectPet(dbEntry, self:GetPetName());
            if ( not self:HasSpellBook() or not _G.PetHasSpellbook() ) then
                dbEntry:SetValue(container, nil);
            else
                local oldNum = dbEntry:GetNumValues(container);
                local newNum = C_SpellBook.HasPetSpells() or 0;
                SaveSpellBook(dbEntry, oldNum, newNum, Enum.SpellBookSpellBank.Pet);
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

function Armory:PetHasSpellbook(specialization)
    local spells = GetPetSpells(specialization);
    return #spells > 0;
end

function Armory:HasPetSpells(specialization)
    local spells = GetPetSpells(specialization);
    if ( #spells > 0 ) then
        return #spells, "PET";
    end
end

function Armory:GetNumSpellTabs(spellBank)
    if ( spellBank == Enum.SpellBookSpellBank.Pet ) then
        local tabs = GetPetTabs();
        return #tabs;
    end
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:GetNumValues(container, "Tabs");
end

function Armory:GetSpellAutocast(id, spellBank, specialization)
    local spellID, _, slotType = GetSpellBookInfo(id, spellBank, specialization);
    if ( spellID ) then
        return C_Spell.GetSpellAutoCast(spellID);
    end
end

function Armory:GetSpellAvailableLevel(id, spellBank, specialization)
    local spellID, _, _, _, _, _, level = GetSpellBookInfo(id, spellBank, specialization);
    if ( level ) then
        return level;
    elseif ( spellID ) then
        return C_Spell.GetSpellLevelLearned(spellID);
    end
end

function Armory:GetSpellBookItemName(id, spellBank, specialization)
    local spellID, subSpellName, _, spellName = GetSpellBookInfo(id, spellBank, specialization);
    if ( not spellName and spellID ) then
        spellName = C_Spell.GetSpellName(spellID);
    end
    return spellName, subSpellName or "";
end

function Armory:GetSpellBookItemInfo(id, spellBank, specialization)
    local spellID, _, slotType, _, _, _, _, hasAttachedGlyph, isDisabled, isLocked = GetSpellBookInfo(id, spellBank, specialization);
    if ( spellID ) then
        return slotType, spellID, hasAttachedGlyph, isDisabled, isLocked;
    end
end

function Armory:GetSpellLevelLearned(id, spellBank, specialization)
    local spellID = GetSpellBookInfo(id, spellBank, specialization);
    if ( spellID ) then
        return C_Spell.GetSpellLevelLearned(spellID);
    end
end

function Armory:GetSpellLink(id, spellBank, specialization)
    local spellID, _, _, _, _, link = GetSpellBookInfo(id, spellBank, specialization);
    if ( link ) then
        return link;
    elseif ( spellID ) then
        return C_Spell.GetSpellLink(spellID);
    end
end

function Armory:GetSpellTabInfo(spellTab, spellBank)
    if ( spellBank == Enum.SpellBookSpellBank.Pet ) then
        local name, texture, offSpecID;
        local tabs = GetPetTabs();
        if ( spellTab <= #tabs ) then
            name = tabs[spellTab].name;
            texture = tabs[spellTab].icon;
            offSpecID = tabs[spellTab].offSpec;
        end
        return name, texture, 0, 0, nil, offSpecID;
    end
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, "Tabs", spellTab);
    end
end

function Armory:GetSpellBookItemTexture(id, spellBank, specialization)
    local spellID, _, _, _, texture = GetSpellBookInfo(id, spellBank, specialization);
    if ( texture ) then
        return texture;
    elseif ( spellID ) then
        return C_Spell.GetSpellTexture(spellID);
    end
end

function Armory:IsPassiveSpell(id, spellBank, specialization)
    local spellID, _, slotType = GetSpellBookInfo(id, spellBank, specialization);
    if ( spellID ) then
        return C_Spell.IsSpellPassive(spellID);
    end
end

local specSpells = {};
function Armory:GetPetSpecializationSpells(spec)
    local spells = self:GetClassValue("pet", container, (spec or self:GetSpecialization(false, true) or 1));
    table.wipe(specSpells);
    if ( spells ) then
        for spellID in pairs(spells) do
            table.insert(specSpells, spellID);
        end
    end
    return specSpells;
end

function Armory:GetSpellFlyoutNumSlots(slot)
    local dbEntry = self.selectedDbBaseEntry;
    local slots = dbEntry and dbEntry:GetValue(container, slot, "Info") or {};
    return #slots;
end

function Armory:GetSpellFlyoutSlotInfo(slot, index)
    local dbEntry = self.selectedDbBaseEntry;
    if ( dbEntry ) then
        return dbEntry:GetValue(container, slot, "Info", index);
    end
end

----------------------------------------------------------
-- Find Methods
----------------------------------------------------------

function Armory:FindSpell(spellList, ...)
    local list = spellList or {};

    local numSkillLineTabs = self:GetNumSpellTabs();
    local tabName, spellName, subSpellName, offset, numSpells, link, text;
    if ( numSkillLineTabs ) then
        for i = 1, numSkillLineTabs do
            tabName, _, offset, numSpells = self:GetSpellTabInfo(i);
            for j = 1, numSpells do
                spellName, subSpellName = self:GetSpellBookItemName(j + offset, Enum.SpellBookSpellBank.Player);
                link = self:GetSpellLink(j + offset, Enum.SpellBookSpellBank.Player);
                if ( self:GetConfigExtendedSearch() ) then
                    text = self:GetFindText(link);
                else
                    text = spellName;
                end
                if ( self:FindTextParts(text, ...) ) then
                    if ( subSpellName and subSpellName ~= "" ) then
                        table.insert(list, {label=SPELLBOOK.." "..tabName, name=spellName, link=link, extra=subSpellName});
                    else
                        table.insert(list, {label=SPELLBOOK.." "..tabName, name=spellName, link=link});
                    end
                end

                self:FindYield();
            end
        end
    end

    local pets = self:GetPets();
    local currentPet = self.selectedPet;
    for i = 1, #pets do
        self.selectedPet = pets[i];
        local numPetSpells = self:HasPetSpells() or 0;
        for id = 1, numPetSpells do
            spellName, subSpellName = self:GetSpellBookItemName(id, Enum.SpellBookSpellBank.Pet);
            link = self:GetSpellLink(id, Enum.SpellBookSpellBank.Pet);
            if ( self:GetConfigExtendedSearch() ) then
                text = self:GetFindText(link);
            else
                text = spellName;
            end
            if ( self:FindTextParts(text, ...) ) then
                if ( subSpellName and subSpellName ~= "" ) then
                    table.insert(list, {label=SPELLBOOK.." "..self.selectedPet, name=spellName, link=link, extra=subSpellName});
                else
                    table.insert(list, {label=SPELLBOOK.." "..self.selectedPet, name=spellName, link=link});
                end
            end

            self:FindYield();
        end
    end
    self.selectedPet = currentPet;

    return list;
end