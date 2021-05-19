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

ARMORY_NUM_FACTIONS_DISPLAYED = 15;
ARMORY_REPUTATIONFRAME_FACTIONHEIGHT = 26;

function ArmoryReputationFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("UPDATE_FACTION");
end

function ArmoryReputationFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        Armory:Execute(ArmoryReputationFrame_UpdateFactions);
    elseif ( event == "UPDATE_FACTION" ) then
        Armory:Execute(ArmoryReputationFrame_UpdateFactions);
        Armory:Execute(ArmoryReputationFrame_Update);
    end
end

function ArmoryReputationFrame_OnShow(self)
    ArmoryReputationFrame_UpdateFactions();
    ArmoryReputationFrame_Update();
end

function ArmoryReputationFrame_UpdateFactions()
    -- SetFactions will trigger UPDATE_FACTION
    ArmoryReputationFrame:UnregisterEvent("UPDATE_FACTION");
    Armory:UpdateFactions();
    ArmoryReputationFrame:RegisterEvent("UPDATE_FACTION");
end

function ArmoryReputationFrame_UpdateHeader(show)
    if ( show ) then
        ArmoryReputationFrameFactionLabel:Show();
        ArmoryReputationFrameStandingLabel:Show();
    else
        ArmoryReputationFrameFactionLabel:Hide();
        ArmoryReputationFrameStandingLabel:Hide();
    end
end

function ArmoryReputationFrame_Update()
    local numFactions = Armory:GetNumFactions();

    -- Update scroll frame
    if ( not FauxScrollFrame_Update(ArmoryReputationListScrollFrame, numFactions, ARMORY_NUM_FACTIONS_DISPLAYED, ARMORY_REPUTATIONFRAME_FACTIONHEIGHT ) ) then
        ArmoryReputationListScrollFrameScrollBar:SetValue(0);
    end
    local factionOffset = FauxScrollFrame_GetOffset(ArmoryReputationListScrollFrame);

    local gender = Armory:UnitSex("player");

    for i=1, ARMORY_NUM_FACTIONS_DISPLAYED, 1 do
        local factionIndex = factionOffset + i;
        local factionBar = _G["ArmoryReputationBar"..i];
        local factionHeader = _G["ArmoryReputationHeader"..i];
        if ( factionIndex <= numFactions ) then
            local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = Armory:GetFactionInfo(factionIndex);
            if ( isHeader ) then
                factionHeader:SetText(name);
                if ( isCollapsed ) then
                    factionHeader:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
                else
                    factionHeader:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
                end
                factionHeader.index = factionIndex;
                factionHeader.isCollapsed = isCollapsed;
                factionBar:Hide();
                factionHeader:Show();
            else
                factionStanding = GetText("FACTION_STANDING_LABEL"..standingID, gender);
                factionName = _G["ArmoryReputationBar"..i.."FactionName"];
                factionName:SetText(name);
                _G["ArmoryReputationBar"..i.."FactionStanding"]:SetText(factionStanding);
                
                local atWarIndicator = _G["ArmoryReputationBar"..i.."AtWarCheck"];
                if ( atWarWith ) then
                    atWarIndicator:Show();
                else
                    atWarIndicator:Hide();
                end

                -- Normalize values
                barMax = barMax - barMin;
                barValue = barValue - barMin;
                barMin = 0;

                factionBar.index = factionIndex;
                factionBar.standingText = factionStanding;
                factionBar.tooltip = HIGHLIGHT_FONT_COLOR_CODE.." "..barValue.." / "..barMax..FONT_COLOR_CODE_CLOSE;
                factionBar:SetMinMaxValues(0, barMax);
                factionBar:SetValue(barValue);
                local color = FACTION_BAR_COLORS[standingID];
                factionBar:SetStatusBarColor(color.r, color.g, color.b);
                factionBar:SetID(factionIndex);
                factionBar:Show();
                factionHeader:Hide();

                -- Update details if this is the selected faction
                if ( factionIndex == ArmoryReputationFrame.selectedFaction ) then
                    if ( ArmoryReputationDetailFrame:IsShown() ) then
                        ArmoryReputationDetailFactionName:SetText(name);
                        ArmoryReputationDetailFactionDescription:SetText(description);
                    end
                    _G["ArmoryReputationBar"..i.."Highlight1"]:Show();
                    _G["ArmoryReputationBar"..i.."Highlight2"]:Show();
                else
                    _G["ArmoryReputationBar"..i.."Highlight1"]:Hide();
                    _G["ArmoryReputationBar"..i.."Highlight2"]:Hide();
                end
            end
        else
            factionHeader:Hide();
            factionBar:Hide();
        end
    end
    if ( ArmoryReputationFrame.selectedFaction == 0 ) then
        ArmoryReputationDetailFrame:Hide();
    end
end

function ArmoryReputationBar_OnClick(self)
    if ( IsModifiedClick("CHATLINK") ) then
        local name, _, standingID, barMin, barMax, barValue = Armory:GetFactionInfo(self.index);
        if ( standingID ) then
            local standing = GetText("FACTION_STANDING_LABEL"..standingID, Armory:UnitSex("player"));
            ChatEdit_InsertLink(format(ARMORY_REPUTATION_SUMMARY, name, standing, barValue - barMin, barMax - barMin, barMax - barValue));
        end
    elseif ( ArmoryReputationDetailFrame:IsShown() and (ArmoryReputationFrame.selectedFaction == self.index) ) then
        ArmoryReputationDetailFrame:Hide();
    else
        ArmoryReputationFrame.selectedFaction = self.index;
        ArmoryReputationDetailFrame:Show();
        ArmoryReputationFrame_Update();
    end
end
