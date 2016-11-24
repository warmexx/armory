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

local ARMORY_MAX_TALENT_SPECTABS = 4;

function ArmoryTalentFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED");
    self:RegisterEvent("PREVIEW_TALENT_PRIMARY_TREE_CHANGED");
    self:RegisterEvent("PLAYER_TALENT_UPDATE");
    self:RegisterEvent("PET_SPECIALIZATION_CHANGED");
    self:RegisterEvent("PLAYER_LEVEL_UP");

    self.talentGroup = 1;
    self.selectedSpec = 1;
end

function ArmoryTalentFrame_OnEvent(self, event, unit)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        self.talentGroup = Armory:GetActiveSpecGroup();
        self.selectedSpec = Armory:GetSpecialization(false, false, self.talentGroup) or 1;
        Armory:Execute(ArmoryTalentFrame_UpdateSpecs);
        if ( Armory.forceScan or not Armory:TalentsExists() ) then
            Armory:Execute(ArmoryTalentFrame_UpdateTalents);
        end
    elseif ( event == "PREVIEW_TALENT_POINTS_CHANGED" or event == "PREVIEW_TALENT_PRIMARY_TREE_CHANGED" or event == "PLAYER_TALENT_UPDATE" ) then
        Armory:Execute(ArmoryTalentFrame_UpdateTalents);
    elseif ( event == "PET_SPECIALIZATION_CHANGED" ) then
        Armory:Execute(ArmoryTalentFrame_UpdateSpecs);
    end
end

function ArmoryTalentFrame_UpdateSpecs()
    local _, isHunterPet = HasPetUI();
    Armory:SetSpecializations("player");
    if ( isHunterPet ) then
        Armory:SetSpecializations("pet");
    end
end

function ArmoryTalentFrame_UpdateTalents()
    Armory:SetTalents();
    ArmoryTalentFrame_UpdateFrame();
end

function ArmoryTalentFrame_OnShow(self)
    Armory:SetTalents();
    Armory:SetHonorTalents();
    ArmoryTalentFrame_UpdateSpecTabs(self);
    ArmoryTalentFrame_Update();
end

function ArmoryTalentFrame_Update()
    ArmoryTalentFrameSpec_OnShow(ArmoryTalentFrame.Spec);
    ArmoryTalentFrame_UpdateFrame();
end

function ArmoryTalentFrame_UpdateFrame()
    local TalentFrame = ArmoryTalentFrame.Talents;
    local talentGroup = ArmoryTalentFrame.talentGroup;
    local spec = ArmoryTalentFrame.selectedSpec;
    
    -- have to disable stuff if not active talent group
    local disable = ( talentGroup ~= Armory:GetActiveSpecGroup() or spec ~= Armory:GetSpecialization(false, false, talentGroup) );

    if ( ArmoryTalentFrame.bg ~= nil ) then
        ArmoryTalentFrame.bg:SetDesaturated(disable);
    end

    local numTalentSelections = 0;
    for tier = 1, MAX_TALENT_TIERS do
        local talentRow = TalentFrame["tier"..tier];
        
        for column = 1, NUM_TALENT_COLUMNS do
            local talentID, name, iconTexture, selected, available = Armory:GetTalentInfo(tier, column, talentGroup, spec);
            local button = talentRow["talent"..column];
            button.tier = tier;
            button.column = column;

            if ( button and name ) then
                button:SetID(talentID);

                SetItemButtonTexture(button, iconTexture);
                if ( button.name ~= nil ) then
                    button.name:SetText(name);
                end

                if ( button.knownSelection ~= nil ) then
                    if( selected ) then
                        button.knownSelection:Show();
                        button.knownSelection:SetDesaturated(false);
                    else
                        button.knownSelection:Hide();
                    end
                end

                if ( selected ) then
                    SetDesaturation(button.icon, false);
                    button.border:Show();
                else
                    SetDesaturation(button.icon, true);
                    button.border:Hide();
                end

                button:Show();
            elseif ( button ) then
                button:Hide();
            end
        end
    end

    local numUnspentTalents = Armory:GetNumUnspentTalents(spec);
    if ( numUnspentTalents > 0 ) then
        ArmoryTalentFrame.unspentText:SetFormattedText(PLAYER_UNSPENT_TALENT_POINTS, numUnspentTalents);
    else
        ArmoryTalentFrame.unspentText:SetText("");
    end
end

----------------------------------------------------------
-- SpecTab Button Functions
----------------------------------------------------------

function ArmoryTalentFrame_UpdateSpecTabs(self)
    self.selectedSpec = Armory:GetSpecialization(false, false, self.talentGroup) or 1;

    local numSpecs = Armory:GetNumSpecializations();
    local numTalentGroups = 0;
    for i = 1, numSpecs do
        local tab = self["specTab"..i];
        local _, name, _, icon = Armory:GetSpecializationInfo(i, false, nil, nil, Armory:UnitSex("player"));
        tab.tooltip = name;
        
        local iconTexture = tab:GetNormalTexture();
        iconTexture:SetTexture(icon);
        if ( Armory:TalentsForSpecExist(i) ) then
            numTalentGroups = numTalentGroups + 1;
            tab:Show();
        else
            tab:Hide();
        end
        local prevTab = self["specTab"..i-1];
        if ( prevTab ) then
            if ( not prevTab:IsShown() ) then
                tab:SetPoint("TOPRIGHT", prevTab, "TOPRIGHT", 0, 0);
            else
                tab:SetPoint("TOPRIGHT", prevTab, "TOPLEFT", -6, 0);
            end
        end
    end
    self.unspentText:ClearAllPoints();
    if ( numTalentGroups <= 1 ) then
        numSpecs = 0;
        self.unspentText:SetPoint("TOP", 22, -35);
    else
        self.unspentText:SetPoint("TOPLEFT", 62, -35);
        self.unspentText:SetPoint("BOTTOMRIGHT", self["specTab"..numSpecs], "BOTTOMLEFT", -6, 0 )
    end
    -- demon hunters have 2 specs, druids have 4
    for i = numSpecs + 1, ARMORY_MAX_TALENT_SPECTABS do
        local tab = self["specTab"..i];
        tab:Hide();
    end
end

function ArmoryPlayerSpecTab_OnClick(self)
    ArmoryTalentFrame.selectedSpec = self:GetID();
    ArmoryTalentFrame_Update();
end

function ArmoryPlayerSpecTab_OnEnter(self)
    if ( self.tooltip ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:AddLine(self.tooltip);
        if ( self:GetID() == Armory:GetSpecialization(false, false, ArmoryTalentFrame.talentGroup) ) then
            GameTooltip:AddLine(TALENT_ACTIVE_SPEC_STATUS, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
        end
        GameTooltip:Show();
    end
end

----------------------------------------------------------
-- Specialization Button Functions
----------------------------------------------------------

function ArmoryTalentFrameSpec_OnShow(self)
    local spec = ArmoryTalentFrame.selectedSpec;

    if ( spec ~= nil and spec > 0 ) then
        local id, name, description, icon, background, role = Armory:GetSpecializationInfo(spec, nil, nil, nil, Armory:UnitSex("player"));
        if ( role ~= nil ) then
            self.specIcon:Show();
            SetPortraitToTexture(self.specIcon, icon);
            self.specName:SetText(name);
            self.roleIcon:Show();
            self.roleName:SetText(_G[role]);
            self.roleIcon:SetTexCoord(GetTexCoordsForRole(role));
            self.tooltip = description;
        end
    else
        ArmoryTalentFrameSpec_OnClear(self);
    end
end

function ArmoryTalentFrameSpec_OnClear(self)
    self.specName:SetText("");
    self.specIcon:Hide();
    self.roleName:SetText("");
    self.roleIcon:Hide();
end

function ArmoryTalentFrameSpec_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP");
    GameTooltip:AddLine(self.tooltip, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    GameTooltip:SetMinimumWidth(300, true);
    GameTooltip:Show();
end

function ArmoryTalentFrameSpec_OnLeave(self)
    GameTooltip:SetMinimumWidth(0, 0);
    GameTooltip:Hide();
end


----------------------------------------------------------
-- Talent Button Functions
----------------------------------------------------------

function ArmoryTalentFrameTalents_OnShow(self)
    ArmoryTalentFrame_UpdateFrame();
end

function ArmoryTalentFrameTalent_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");    
    Armory:SetTalent(self:GetID());
end

function ArmoryTalentFrameTalent_OnClick(self)
    if ( IsModifiedClick("CHATLINK") ) then
        local link = GetTalentLink(self:GetID());
        if ( link ) then
            ChatEdit_InsertLink(link);
        end
    end
end
