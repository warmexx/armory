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

ArmoryPanelTabButtonMixin = {};

-- Classic's UI-Character-ActiveTab is 128x32 instead of 128x64: show the selected tab
-- like Blizzard's CharacterFrameTabButtonTemplate in Classic does, which also has the
-- unselected tab 1 pixel higher than in Mainline
local function SetClassicTabs(tab)
    local name = tab:GetName();
    _G[name.."Left"]:SetPoint("TOPLEFT", 0, 0);
    local left = _G[name.."LeftDisabled"];
    left:SetPoint("TOPLEFT", 0, 4);
    left:SetHeight(32);
    left:SetTexCoord(0, 0.15625, 0, 1.0);
    _G[name.."MiddleDisabled"]:SetHeight(32);
    _G[name.."MiddleDisabled"]:SetTexCoord(0.15625, 0.84375, 0, 1.0);
    _G[name.."RightDisabled"]:SetHeight(32);
    _G[name.."RightDisabled"]:SetTexCoord(0.84375, 1.0, 0, 1.0);
    tab.selectedTextY = 4;
end

function ArmoryPanelTabButtonMixin:OnLoad()
    if ( Armory.isClassic ) then
        SetClassicTabs(self);
    end
    self:SetFrameLevel(self:GetFrameLevel() + 4);
    self:RegisterEvent("DISPLAY_SIZE_CHANGED");
end

function ArmoryPanelTabButtonMixin:OnEvent()
    if ( self:IsVisible() ) then
        ArmoryPanelTemplates_TabResize(self, 0, nil, 36, self:GetParent().maxTabWidth or 88);
    end
end

function ArmoryPanelTabButtonMixin:OnShow()
    ArmoryPanelTemplates_TabResize(self, 0, nil, 36, self:GetParent().maxTabWidth or 88);
end

function ArmoryPanelTabButtonMixin:OnClick()
    ArmoryPanelTemplates_Tab_OnClick(self, self:GetParent());
end

function ArmoryPanelTabButtonMixin:OnEnter()
    local buttonText = self.Text;
    if (buttonText and buttonText:IsTruncated()) then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(buttonText:GetText(), 1.0, 1.0, 1.0);
    end
end

function ArmoryPanelTabButtonMixin:OnLeave()
    GameTooltip_Hide();
end


ArmoryPanelTopTabButtonMixin = {};

function ArmoryPanelTopTabButtonMixin:OnLoad()
    ArmoryPanelTemplates_TabResize(self, 0, nil, self.minWidth);
end

function ArmoryPanelTopTabButtonMixin:OnShow()
    ArmoryPanelTemplates_TabResize(self, 0);
end

function ArmoryPanelTopTabButtonMixin:OnEnter()
    local buttonText = self.Text;
    if (buttonText and buttonText:IsTruncated()) then
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
      GameTooltip:SetText(buttonText:GetText());
    end
end

function ArmoryPanelTopTabButtonMixin:OnLeave()
    GameTooltip_Hide();
end



-- functions to manage tab interfaces where only one tab of a group may be selected
function ArmoryPanelTemplates_Tab_OnClick(self, frame)
    ArmoryPanelTemplates_SetTab(frame, self:GetID())
end

function ArmoryPanelTemplates_SetTab(frame, id)
    frame.selectedTab = id;
    ArmoryPanelTemplates_UpdateTabs(frame);
end

function ArmoryPanelTemplates_GetSelectedTab(frame)
    return frame.selectedTab;
end

local function GetTabByIndex(frame, index)
    return frame.Tabs and frame.Tabs[index] or _G[frame:GetName().."Tab"..index];
end

function ArmoryPanelTemplates_UpdateTabs(frame)
    if ( frame.selectedTab ) then
        local tab;
        for i=1, frame.numTabs, 1 do
            tab = GetTabByIndex(frame, i);
            if ( tab.isDisabled ) then
                ArmoryPanelTemplates_SetDisabledTabState(tab);
            elseif ( i == frame.selectedTab ) then
                ArmoryPanelTemplates_SelectTab(tab);
            else
                ArmoryPanelTemplates_DeselectTab(tab);
            end
        end
    end
end

function ArmoryPanelTemplates_GetTabWidth(tab)
    local tabName = tab:GetName();

    local sideWidths = 2 * _G[tabName.."Left"]:GetWidth();
    return tab:GetTextWidth() + sideWidths;
end

function ArmoryPanelTemplates_ResizeTabsToFit(tabs, totalTabWidth, maxTotalTabWidth, tabWidthCache)
    -- readjust tab sizes to fit
    local change, largestTab;
    while ( totalTabWidth >= maxTotalTabWidth ) do
        if ( not change ) then
            change = 10;
            totalTabWidth = totalTabWidth - change;
        end
        -- progressively shave 10 pixels off of the largest tab until they all fit within the max width
        largestTab = 1;
        for i = 2, #tabWidthCache do
            if ( tabWidthCache[largestTab] < tabWidthCache[i] ) then
                largestTab = i;
            end
        end
        -- shave the width
        tabWidthCache[largestTab] = tabWidthCache[largestTab] - change;
        -- apply the shaved width
        ArmoryPanelTemplates_TabResize(tabs[largestTab], 0, tabWidthCache[largestTab]);
        -- now update the total width
        totalTabWidth = totalTabWidth - change;
    end
end

function ArmoryPanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
    local tabName = tab:GetName();

    local buttonMiddle = tab.Middle or tab.middleTexture or _G[tabName.."Middle"];
    local buttonMiddleDisabled = tab.MiddleDisabled or (tabName and _G[tabName.."MiddleDisabled"]);
    local left = tab.Left or tab.leftTexture or _G[tabName.."Left"];
    local sideWidths = 2 * left:GetWidth();
    local tabText = tab.Text or _G[tab:GetName().."Text"];
    local highlightTexture = tab.HighlightTexture or (tabName and _G[tabName.."HighlightTexture"]);

    local width, tabWidth;
    local textWidth;
    if ( absoluteTextSize ) then
        textWidth = absoluteTextSize;
    else
        tabText:SetWidth(0);
        textWidth = tabText:GetWidth();
    end
    -- If there's an absolute size specified then use it
    if ( absoluteSize ) then
        if ( absoluteSize < sideWidths) then
            width = 1;
            tabWidth = sideWidths
        else
            width = absoluteSize - sideWidths;
            tabWidth = absoluteSize
        end
        tabText:SetWidth(width);
    else
        -- Otherwise try to use padding
        if ( padding ) then
            width = textWidth + padding;
        else
            width = textWidth + 24;
        end
        -- If greater than the maxWidth then cap it
        if ( maxWidth and width > maxWidth ) then
            if ( padding ) then
                width = maxWidth + padding;
            else
                width = maxWidth + 24;
            end
            tabText:SetWidth(width);
        else
            tabText:SetWidth(0);
        end
        if (minWidth and width < minWidth) then
            width = minWidth;
        end
        tabWidth = width + sideWidths;
    end

    if ( buttonMiddle ) then
        buttonMiddle:SetWidth(width);
    end
    if ( buttonMiddleDisabled ) then
        buttonMiddleDisabled:SetWidth(width);
    end

    tab:SetWidth(tabWidth);

    if ( highlightTexture ) then
        highlightTexture:SetWidth(tabWidth);
    end
end

function ArmoryPanelTemplates_SetNumTabs(frame, numTabs)
    frame.numTabs = numTabs;
end

function ArmoryPanelTemplates_DeselectTab(tab)
    local name = tab:GetName();

    local left = tab.Left or _G[name.."Left"];
    local middle = tab.Middle or _G[name.."Middle"];
    local right = tab.Right or _G[name.."Right"];
    left:Show();
    middle:Show();
    right:Show();
    --tab:UnlockHighlight();
    tab:Enable();
    local text = tab.Text or _G[name.."Text"];
    text:SetPoint("CENTER", tab, "CENTER", (tab.deselectedTextX or 0), (tab.deselectedTextY or 2));

    local leftDisabled = tab.LeftDisabled or _G[name.."LeftDisabled"];
    local middleDisabled = tab.MiddleDisabled or _G[name.."MiddleDisabled"];
    local rightDisabled = tab.RightDisabled or _G[name.."RightDisabled"];
    leftDisabled:Hide();
    middleDisabled:Hide();
    rightDisabled:Hide();
end

function ArmoryPanelTemplates_SelectTab(tab)
    local name = tab:GetName();

    local left = tab.Left or _G[name.."Left"];
    local middle = tab.Middle or _G[name.."Middle"];
    local right = tab.Right or _G[name.."Right"];
    left:Hide();
    middle:Hide();
    right:Hide();
    --tab:LockHighlight();
    tab:Disable();
    tab:SetDisabledFontObject(GameFontHighlightSmall);
    local text = tab.Text or _G[name.."Text"];
    text:SetPoint("CENTER", tab, "CENTER", (tab.selectedTextX or 0), (tab.selectedTextY or -3));

    local leftDisabled = tab.LeftDisabled or _G[name.."LeftDisabled"];
    local middleDisabled = tab.MiddleDisabled or _G[name.."MiddleDisabled"];
    local rightDisabled = tab.RightDisabled or _G[name.."RightDisabled"];
    leftDisabled:Show();
    middleDisabled:Show();
    rightDisabled:Show();

    local tooltip = GetAppropriateTooltip();
    if tooltip:IsOwned(tab) then
        tooltip:Hide();
    end
end

function ArmoryPanelTemplates_SetDisabledTabState(tab)
    local name = tab:GetName();
    local left = tab.Left or _G[name.."Left"];
    local middle = tab.Middle or _G[name.."Middle"];
    local right = tab.Right or _G[name.."Right"];
    left:Show();
    middle:Show();
    right:Show();
    --tab:UnlockHighlight();
    tab:Disable();
    tab.text = tab:GetText();
    -- Gray out text
    tab:SetDisabledFontObject(GameFontDisableSmall);
    local leftDisabled = tab.LeftDisabled or _G[name.."LeftDisabled"];
    local middleDisabled = tab.MiddleDisabled or _G[name.."MiddleDisabled"];
    local rightDisabled = tab.RightDisabled or _G[name.."RightDisabled"];
    leftDisabled:Hide();
    middleDisabled:Hide();
    rightDisabled:Hide();
end