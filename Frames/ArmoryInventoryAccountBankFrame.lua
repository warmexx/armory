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

function ArmoryAccountBankFrameButton_OnEnter(self)
    -- maybe use setbagitem to update tt
    if ( self.link ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetHyperlink(self.link);
        GameTooltip:Show();
    end
end

function ArmoryInventoryAccountBankFrame_OnShow(self)
    FauxScrollFrame_SetOffset(ArmoryInventoryAccountBankScrollFrame, 0);
    ArmoryInventoryAccountBankScrollFrameScrollBar:SetMinMaxValues(0, 0);
    ArmoryInventoryAccountBankScrollFrameScrollBar:SetValue(0);

    ArmoryMoneyFrame_Update("ArmoryInventoryMoneyFrame", C_Bank.FetchDepositedMoney(Enum.BankType.Account) or 0);
    ArmoryInventoryAccountBankFrame_Update();
end

function ArmoryInventoryAccountBankFrame_OnHide(self)
    ArmoryInventoryMoneyFrame_OnShow(ArmoryInventoryMoneyFrame);
end

function ArmoryInventoryAccountBankFrame_Update()
    local unit = "account";
    if ( not ArmoryInventoryAccountBankFrame:IsShown() ) then
        return;
    end

    local numLines = Armory:GetNumInventoryLines(unit);
    local offset = FauxScrollFrame_GetOffset(ArmoryInventoryAccountBankScrollFrame);

    if ( numLines == 0 and not Armory:ContainerExists(ArmoryInventoryAccountContainers[1], unit) ) then
        ArmoryInventoryAccountBankFrameMessage:Show();
        ArmoryInventoryCollapseAllButton:Disable();
    else
        ArmoryInventoryAccountBankFrameMessage:Hide();
        ArmoryInventoryCollapseAllButton:Enable();
    end

    if ( offset > numLines ) then
        offset = 0;
        FauxScrollFrame_SetOffset(ArmoryInventoryAccountBankScrollFrame, offset);
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(ArmoryInventoryAccountBankScrollFrame, numLines, ARMORY_INVENTORY_LINES_DISPLAYED, ARMORY_INVENTORY_HEIGHT);

    for i = 1, ARMORY_INVENTORY_LINES_DISPLAYED do
        local lineIndex = i + offset;
        local name, id, numAvailable, _, isHeader, index, link, _, _, numFreeSlots, containerName = Armory:GetInventoryLineInfo(lineIndex, unit);
        local lineButton = _G["ArmoryInventoryAccountBankLine"..i];
        local lineButtonText = _G["ArmoryInventoryAccountBankLine"..i.."Text"];
        local lineButtonHighlight = _G["ArmoryInventoryAccountBankLine"..i.."Highlight"];
        local lineButtonTexture = _G["ArmoryInventoryAccountBankLine"..i.."NormalTexture"];

        if ( lineIndex <= numLines ) then
            -- Set button widths if scrollbar is shown or hidden
            if ( ArmoryInventoryAccountBankScrollFrame:IsShown() ) then
                lineButtonText:SetWidth(265);
            else
                lineButtonText:SetWidth(285);
            end
            lineButton:Enable();

            lineButton:SetID(lineIndex);
            lineButton.container = id;
            lineButton.item = index;
            lineButton.link = link;
            lineButton:Show();

            if ( isHeader ) then
                lineButton.isCollapsed = Armory:GetInventoryLineState(lineIndex, unit);
                if ( numFreeSlots ) then
                    if ( numAvailable ) then
                        name = format("#%d - [%d/%d] %s", Armory:GetAccountContainerIndex(id), numAvailable - numFreeSlots, numAvailable, containerName or name);
                    else
                        name = containerName or name;
                    end
                end
                lineButton:SetText(name);
                if ( lineButton.isCollapsed ) then
                    lineButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
                else
                    lineButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
                end
                lineButtonHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
                lineButton:UnlockHighlight();
            elseif ( not name ) then
                return;
            else
                lineButton:ClearNormalTexture();
                lineButtonHighlight:SetTexture("");
                if ( numAvailable and numAvailable > 1 ) then
                    name = name.." ["..numAvailable.."]";
                end
                if ( link ) then
                    local color = Armory:GetColorFromLink(link);
                    if ( color ) then
                        name = color..name.."|r";
                    end
                end
                lineButton:SetText(name);

                ArmoryInventoryListViewShowIcon(lineButton);
            end
        else
            lineButton:Hide();
        end
    end

    -- Set the expand/collapse all button texture
    local numHeaders = 0;
    local notExpanded = 0;
    for i = 1, numLines do
        local isHeader = select(5, Armory:GetInventoryLineInfo(i, unit));
        if ( isHeader ) then
            numHeaders = numHeaders + 1;
            if ( Armory:GetInventoryLineState(i, unit) ) then
                notExpanded = notExpanded + 1;
            end
        end
    end
    -- If all headers are not expanded then show collapse button, otherwise show the expand button
    if ( notExpanded ~= numHeaders ) then
        ArmoryInventoryCollapseAllButton.isCollapsed = nil;
        ArmoryInventoryCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
    else
        ArmoryInventoryCollapseAllButton.isCollapsed = 1;
        ArmoryInventoryCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
    end

    -- Indent items
    for i = 1, ARMORY_INVENTORY_LINES_DISPLAYED do
        local lineButton = _G["ArmoryInventoryAccountBankLine"..i];
        local _, id, _, _, isHeader = Armory:GetInventoryLineInfo(lineButton:GetID(), unit);
        if ( id and not isHeader ) then
            _G["ArmoryInventoryAccountBankLine"..i.."NormalTexture"]:SetPoint("TOPLEFT", lineButton, "TOPLEFT", 21, 0);
            _G["ArmoryInventoryAccountBankLine"..i.."Text"]:SetPoint("TOPLEFT", lineButton, "TOPLEFT", 40, 0);
        else
            _G["ArmoryInventoryAccountBankLine"..i.."NormalTexture"]:SetPoint("TOPLEFT", lineButton, "TOPLEFT", 3, 0);
            _G["ArmoryInventoryAccountBankLine"..i.."Text"]:SetPoint("TOPLEFT", lineButton, "TOPLEFT", 21, 0);
        end
    end
end
