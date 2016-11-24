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

local container = "Artifacts";

----------------------------------------------------------
-- Artifact Internals
----------------------------------------------------------

local selectedArtifact = nil;

local function GetArtifactValue(key)
    local dbEntry = Armory.selectedDbBaseEntry;
    if ( dbEntry and selectedArtifact ) then
        return dbEntry:GetValue(container, selectedArtifact, key);
    end
end


----------------------------------------------------------
-- Artifact Storage
----------------------------------------------------------

function Armory:ClearArtifacts()
    self:ClearModuleData(container);
end

function Armory:UpdateArtifact()
    local dbEntry = self.playerDbBaseEntry;
    if ( not dbEntry ) then
        return;
    end

    if ( not self:ArtifactsEnabled() ) then
        dbEntry:SetValue(container, nil);
        return;
    end
    
    if ( not self:IsLocked(container) ) then
        self:Lock(container);
        
        self:PrintDebug("UPDATE", container);
        
        local itemID, altItemID, _, _, _, _, _, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetArtifactInfo();
        local _, _, _, _, _, _, uiCameraID, altHandUICameraID, _, _, _, modelAlpha, modelDesaturation = C_ArtifactUI.GetAppearanceInfoByID(artifactAppearanceID);

        itemID = tostring(itemID);
        if ( altItemID ) then
            dbEntry:SetValue(2, container, tostring(altItemID), itemID);
        end
        dbEntry:SetValue(3, container, itemID, "Info", altItemID, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop, uiCameraID, altHandUICameraID, modelAlpha, modelDesaturation);
        dbEntry:SetValue(3, container, itemID, "ArtInfo", C_ArtifactUI.GetArtifactArtInfo());
        dbEntry:SetValue(3, container, itemID, "PointsRemaining", C_ArtifactUI.GetPointsRemaining());
        dbEntry:SetValue(3, container, itemID, "PurchasedRanks", C_ArtifactUI.GetTotalPurchasedRanks());
        dbEntry:SetValue(3, container, itemID, "KnowledgeLevel", C_ArtifactUI.GetArtifactKnowledgeLevel());
        dbEntry:SetValue(3, container, itemID, "KnowledgeMultiplier", C_ArtifactUI.GetArtifactKnowledgeMultiplier());
        dbEntry:SetValue(3, container, itemID, "MetaPower", C_ArtifactUI.GetMetaPowerInfo());
        dbEntry:SetValue(3, container, itemID, "Powers", C_ArtifactUI.GetPowers());

	    local powers = C_ArtifactUI.GetPowers();
        for i, powerID in ipairs(powers) do
            dbEntry:SetValue(3, container, itemID, "PowerInfo"..powerID, C_ArtifactUI.GetPowerInfo(powerID));
            dbEntry:SetValue(3, container, itemID, "PowerLinks"..powerID, C_ArtifactUI.GetPowerLinks(powerID));
            dbEntry:SetValue(3, container, itemID, "PowerLink"..powerID, C_ArtifactUI.GetPowerHyperlink(powerID));
        end
        
        local numRelicSlots = C_ArtifactUI.GetNumRelicSlots();
        dbEntry:SetValue(3, container, itemID, "Relics", numRelicSlots);
        for relicSlotIndex = 1, numRelicSlots do
            dbEntry:SetValue(3, container, itemID, "RelicType"..relicSlotIndex, C_ArtifactUI.GetRelicSlotType(relicSlotIndex));
            dbEntry:SetValue(3, container, itemID, "RelicInfo"..relicSlotIndex, C_ArtifactUI.GetRelicInfo(relicSlotIndex));
            dbEntry:SetValue(3, container, itemID, "RelicPowers"..relicSlotIndex, C_ArtifactUI.GetPowersAffectedByRelic(relicSlotIndex));
        end
        
        self:Unlock(container);
    else
        self:PrintDebug("LOCKED", container);
    end
end

----------------------------------------------------------
-- Artifacts Interface
----------------------------------------------------------

function Armory:IsArtifact(id)
    local dbEntry = self.selectedDbBaseEntry;
    return dbEntry and dbEntry:Contains(container, tostring(id));
end

function Armory:SetSelectedArtifact(id)
    local dbEntry = self.selectedDbBaseEntry;
    local itemID = tostring(id);
    if ( dbEntry and dbEntry:Contains(container, itemID) ) then
        local value = dbEntry:GetValue(container, itemID);
        if ( type(value) == "string" ) then
            selectedArtifact = value;
        else
            selectedArtifact = itemID;
        end
    else
        selectedArtifact = nil;
    end
end

function Armory:GetNumObtainedArtifacts()
    local dbEntry = self.selectedDbBaseEntry;
    local count = 0;
    if ( dbEntry ) then
        local artifacts = dbEntry:GetValue(container);
        for _, value in pairs(artifacts) do
            if ( type(value) ~= "string" ) then
                count = count + 1;
            end
        end
    end
    return count;
end

function Armory:GetArtifactInfoEx()
    return tonumber(selectedArtifact), GetArtifactValue("Info");
end

function Armory:GetArtifactArtInfo()
    return GetArtifactValue("ArtInfo");
end

function Armory:GetPointsRemaining()
    return GetArtifactValue("PointsRemaining");
end

function Armory:GetTotalPurchasedRanks()
   return GetArtifactValue("PurchasedRanks");
end

function Armory:GetArtifactKnowledgeLevel()
   return GetArtifactValue("KnowledgeLevel");
end

function Armory:GetArtifactKnowledgeMultiplier()
   return GetArtifactValue("KnowledgeMultiplier");
end

function Armory:GetMetaPowerInfo()
   return GetArtifactValue("MetaPower");
end

function Armory:GetPowers()
   return GetArtifactValue("Powers");
end

function Armory:GetPowerInfo(id)
   return GetArtifactValue("PowerInfo"..id);
end

function Armory:GetPowerLinks(id)
   return GetArtifactValue("PowerLinks"..id);
end

function Armory:GetPowerHyperlink(id)
    return GetArtifactValue("PowerLink"..id);
end

function Armory:IsPowerKnown(id)
    return self:GetPowerInfo(id) and true or false;
end

function Armory:GetNumRelicSlots()
    return GetArtifactValue("Relics") or 0;
end

function Armory:GetRelicSlotType(index)
    return GetArtifactValue("RelicType"..index);
end

function Armory:GetRelicInfo(index)
    return GetArtifactValue("RelicInfo"..index);
end

function Armory:GetPowersAffectedByRelic(index)
    return GetArtifactValue("RelicPowers"..index);
end
