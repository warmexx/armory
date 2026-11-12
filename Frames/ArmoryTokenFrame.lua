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

local TOKEN_BUTTON_OFFSET = 3;

function ArmoryTokenButton_OnLoad(self)
    local name = self:GetName();
    self.count = _G[name.."Count"];
    self.name = _G[name.."Name"];
    self.icon = _G[name.."Icon"];
    self.check = _G[name.."Check"];
    self.highlight = _G[name.."Highlight"];
end

function ArmoryTokenButton_OnClick(self)
    if ( self.isHeader ) then
        if ( self.isExpanded ) then
            Armory:ExpandCurrencyList(self.index, 0);
        else
            Armory:ExpandCurrencyList(self.index, 1);
        end
    elseif ( IsModifiedClick("CHATLINK") and self.LinkButton.link ) then
        HandleModifiedItemClick(self.LinkButton.link);
    end
    ArmoryTokenFrame_Update();
end

function ArmoryTokenFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE");

    ArmoryTokenFrameContainerScrollBar.Show =
        function (self)
            ArmoryTokenFrameContainer:SetWidth(299);
            for _, button in next, _G["ArmoryTokenFrameContainer"].buttons do
                button:SetWidth(310 - (button.indent or 0));
            end
            getmetatable(self).__index.Show(self);
        end;

    ArmoryTokenFrameContainerScrollBar.Hide =
        function (self)
            ArmoryTokenFrameContainer:SetWidth(313);
            for _, button in next, ArmoryTokenFrameContainer.buttons do
                button:SetWidth(328 - (button.indent or 0));
            end
            getmetatable(self).__index.Hide(self);
        end;

    ArmoryTokenFrameContainer.update = ArmoryTokenFrame_Update;
    ArmoryHybridScrollFrame_CreateButtons(ArmoryTokenFrameContainer, "ArmoryTokenButtonTemplate", 0, -2, "TOPLEFT", "TOPLEFT", 0, -TOKEN_BUTTON_OFFSET);
end

function ArmoryTokenFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:CurrencyExists() ) then
            Armory:Execute(ArmoryTokenFrame_UpdateCurrency);
        end
    else
        Armory:Execute(ArmoryTokenFrame_UpdateCurrency);
    end
end

function ArmoryTokenFrame_OnShow(self)
    ArmoryTokenFrame_Update();
end

function ArmoryTokenFrame_Update()

    -- Setup the buttons
    local scrollFrame = ArmoryTokenFrameContainer;
    local offset = ArmoryHybridScrollFrame_GetOffset(scrollFrame);
    local buttons = scrollFrame.buttons;
    local numButtons = #buttons;
    local numTokenTypes = Armory:GetCurrencyListSize();
    local name, isHeader, isExpanded, isUnused, isWatched, count, icon, link, depth;
    local button, index;
    for i=1, numButtons do
        index = offset+i;
        name, isHeader, isExpanded, isUnused, isWatched, count, icon, link, depth = Armory:GetCurrencyListInfo(index);

        button = buttons[i];
        button.check:Hide();
        if ( not name or name == "" ) then
            button:Hide();
        else
            if ( isHeader ) then
                button.count:SetText("");
                button.icon:SetTexture("");
                if ( isExpanded ) then
                    button:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
                else
                    button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
                end

                button.highlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
                button.name:SetText(name);
                button.name:SetFontObject("GameFontNormal");
                button.LinkButton:Hide();
            else
                button.count:SetText(BreakUpLargeNumbers(count));
                button.icon:SetTexture(icon);
                if ( isWatched ) then
                    button.check:Show();
                end
                button:ClearNormalTexture();
                button.highlight:SetTexture("");
                --Gray out the text if the count is 0
                if ( count == 0 ) then
                    button.count:SetFontObject("GameFontDisable");
                    button.name:SetFontObject("GameFontDisable");
                else
                    button.count:SetFontObject("GameFontHighlight");
                    button.name:SetFontObject("GameFontHighlight");
                end
                button.name:SetText(name);
                button.LinkButton:Show();
            end
            --Manage highlight
            if ( name == ArmoryTokenFrame.selectedToken ) then
                ArmoryTokenFrame.selectedID = index;
                button:LockHighlight();
            else
                button:UnlockHighlight();
            end

            button.indent = (depth - 1) * 16 + (isHeader and 16 or 0);
            button.index = index;
            button.isHeader = isHeader;
            button.isExpanded = isExpanded;
            button.isUnused = isUnused;
            button.isWatched = isWatched;
            button.LinkButton.link = link;

            local point, relativeTo, relativePoint, x, y = button:GetPoint();
            button:SetPoint(point, relativeTo, relativePoint, button.indent - (i > 1 and relativeTo.indent or 0), y);

            button:Show();
        end
    end
    local totalHeight = numTokenTypes * (button:GetHeight()+TOKEN_BUTTON_OFFSET);
    local displayedHeight = #buttons * (button:GetHeight()+TOKEN_BUTTON_OFFSET);

    ArmoryHybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight);
end

function ArmoryTokenFrame_UpdateCurrency()
    Armory:UpdateCurrency();
    ArmoryTokenFrame_Update();
end
