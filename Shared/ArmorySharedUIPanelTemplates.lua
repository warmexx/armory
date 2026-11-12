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

local Armory = Armory;

ARMORY_ID = "Armory";

function ArmoryUIPanelCloseButton_OnClick(self)
    local parent = self:GetParent();
    if ( parent ) then
        if parent.onCloseCallback then
            parent.onCloseCallback(self);
        else
            parent:Hide();
        end
    end
end

function ArmoryUIPanelScrollBarScrollUpButton_OnClick(self)
    local parent = self:GetParent();
    local scrollStep = self:GetParent().scrollStep or (parent:GetHeight() / 2);
    parent:SetValue(parent:GetValue() - scrollStep);
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
end

function ArmoryUIPanelScrollBarScrollDownButton_OnClick(self)
    local parent = self:GetParent();
    local scrollStep = self:GetParent().scrollStep or (parent:GetHeight() / 2);
    parent:SetValue(parent:GetValue() + scrollStep);
    PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
end

function ArmoryUIPanelScrollBar_OnValueChanged(self, value)
    self:GetParent():SetVerticalScroll(value);
end

function ArmoryScrollFrame_OnLoad(self)
    local scrollbar = self.ScrollBar or _G[self:GetName().."ScrollBar"];
    scrollbar:SetMinMaxValues(0, 0);
    scrollbar:SetValue(0);
    self.offset = 0;

    local scrollDownButton = scrollbar.ScrollDownButton or _G[scrollbar:GetName().."ScrollDownButton"];
    local scrollUpButton = scrollbar.ScrollUpButton or _G[scrollbar:GetName().."ScrollUpButton"];

    scrollDownButton:Disable();
    scrollUpButton:Disable();

    if ( self.scrollBarHideable ) then
        scrollbar:Hide();
        scrollDownButton:Hide();
        scrollUpButton:Hide();
    else
        scrollDownButton:Disable();
        scrollUpButton:Disable();
        scrollDownButton:Show();
        scrollUpButton:Show();
    end
    if ( self.noScrollThumb ) then
        (scrollbar.ThumbTexture or _G[scrollbar:GetName().."ThumbTexture"]):Hide();
    end
end

function ArmoryScrollFrame_OnScrollRangeChanged(self, xrange, yrange)
    local name = self:GetName();
    local scrollbar = self.ScrollBar or _G[name.."ScrollBar"];
    if ( not yrange ) then
        yrange = self:GetVerticalScrollRange();
    end

    -- Accounting for very small ranges
    yrange = math.floor(yrange);

    local value = math.min(scrollbar:GetValue(), yrange);
    scrollbar:SetMinMaxValues(0, yrange);
    scrollbar:SetValue(value);

    local scrollDownButton = scrollbar.ScrollDownButton or _G[scrollbar:GetName().."ScrollDownButton"];
    local scrollUpButton = scrollbar.ScrollUpButton or _G[scrollbar:GetName().."ScrollUpButton"];
    local thumbTexture = scrollbar.ThumbTexture or _G[scrollbar:GetName().."ThumbTexture"];

    if ( yrange == 0 ) then
        if ( self.scrollBarHideable ) then
            scrollbar:Hide();
            scrollDownButton:Hide();
            scrollUpButton:Hide();
            thumbTexture:Hide();
        else
            scrollDownButton:Disable();
            scrollUpButton:Disable();
            scrollDownButton:Show();
            scrollUpButton:Show();
            if ( not self.noScrollThumb ) then
                thumbTexture:Show();
            end
        end
    else
        scrollDownButton:Show();
        scrollUpButton:Show();
        scrollbar:Show();
        if ( not self.noScrollThumb ) then
            thumbTexture:Show();
        end
        -- The 0.005 is to account for precision errors
        if ( yrange - value > 0.005 ) then
            scrollDownButton:Enable();
        else
            scrollDownButton:Disable();
        end
    end

    -- Hide/show scrollframe borders
    local top = self.Top or name and _G[name.."Top"];
    local bottom = self.Bottom or name and _G[name.."Bottom"];
    local middle = self.Middle or name and _G[name.."Middle"];
    if ( top and bottom and self.scrollBarHideable ) then
        if ( self:GetVerticalScrollRange() == 0 ) then
            top:Hide();
            bottom:Hide();
        else
            top:Show();
            bottom:Show();
        end
    end
    if ( middle and self.scrollBarHideable ) then
        if ( self:GetVerticalScrollRange() == 0 ) then
            middle:Hide();
        else
            middle:Show();
        end
    end
end

function ArmoryScrollFrame_OnVerticalScroll(self, offset)
    local scrollbar = self.ScrollBar or _G[self:GetName().."ScrollBar"];
    scrollbar:SetValue(offset);

    local min, max = scrollbar:GetMinMaxValues();
    (scrollbar.ScrollUpButton or _G[scrollbar:GetName().."ScrollUpButton"]):SetEnabled(offset ~= 0);
    (scrollbar.ScrollDownButton or _G[scrollbar:GetName().."ScrollDownButton"]):SetEnabled((scrollbar:GetValue() - max) ~= 0);
end

function ArmoryScrollFrameTemplate_OnMouseWheel(self, value, scrollBar)
    scrollBar = scrollBar or self.ScrollBar or _G[self:GetName() .. "ScrollBar"];
    local scrollStep = scrollBar.scrollStep or scrollBar:GetHeight() / 2
    if ( value > 0 ) then
        scrollBar:SetValue(scrollBar:GetValue() - scrollStep);
    else
        scrollBar:SetValue(scrollBar:GetValue() + scrollStep);
    end
end

function ArmoryHybridScrollFrame_OnLoad(self)
    self:EnableMouse(true);
end

function ArmoryHybridScrollFrameScrollUp_OnLoad(self)
    self:GetParent():GetParent().scrollUp = self;
    self:Disable();
    self:RegisterForClicks("LeftButtonUp", "LeftButtonDown");
    self.direction = 1;
end

function ArmoryHybridScrollFrameScrollDown_OnLoad(self)
    self:GetParent():GetParent().scrollDown = self;
    self:Disable();
    self:RegisterForClicks("LeftButtonUp", "LeftButtonDown");
    self.direction = -1;
end

function ArmoryHybridScrollFrame_OnValueChanged(self, value)
    ArmoryHybridScrollFrame_SetOffset(self:GetParent(), value);
    ArmoryHybridScrollFrame_UpdateButtonStates(self:GetParent(), value);
end

function ArmoryHybridScrollFrame_UpdateButtonStates(self, currValue)
    if ( not currValue ) then
        currValue = self.scrollBar:GetValue();
    end

    self.scrollUp:Enable();
    self.scrollDown:Enable();

    local minVal, maxVal = self.scrollBar:GetMinMaxValues();
    if ( currValue >= maxVal ) then
        self.scrollBar.thumbTexture:Show();
        if ( self.scrollDown ) then
            self.scrollDown:Disable()
        end
    end
    if ( currValue <= minVal ) then
        self.scrollBar.thumbTexture:Show();
        if ( self.scrollUp ) then
            self.scrollUp:Disable();
        end
    end
end

function ArmoryHybridScrollFrame_OnMouseWheel(self, delta, stepSize)
    if ( not self.scrollBar:IsVisible() or not self.scrollBar:IsEnabled() ) then
        return;
    end

    local minVal, maxVal = 0, self.range;
    stepSize = stepSize or self.stepSize or self.buttonHeight;
    if ( delta == 1 ) then
        self.scrollBar:SetValue(max(minVal, self.scrollBar:GetValue() - stepSize));
    else
        self.scrollBar:SetValue(min(maxVal, self.scrollBar:GetValue() + stepSize));
    end
end

function ArmoryHybridScrollFrame_CreateButtons(self, buttonTemplate, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
    local scrollChild = self.scrollChild;
    local button, buttonHeight, buttons, numButtons;

    local parentName = self:GetName();
    local buttonName = parentName and (parentName .. "Button") or nil;

    initialPoint = initialPoint or "TOPLEFT";
    initialRelative = initialRelative or "TOPLEFT";
    point = point or "TOPLEFT";
    relativePoint = relativePoint or "BOTTOMLEFT";
    offsetX = offsetX or 0;
    offsetY = offsetY or 0;

    if ( self.buttons ) then
        buttons = self.buttons;
        buttonHeight = buttons[1]:GetHeight();
    else
        button = CreateFrame("BUTTON", buttonName and (buttonName .. 1) or nil, scrollChild, buttonTemplate);
        buttonHeight = button:GetHeight();
        button:SetPoint(initialPoint, scrollChild, initialRelative, initialOffsetX, initialOffsetY);
        buttons = {}
        tinsert(buttons, button);
    end

    self.buttonHeight = Armory:Round(buttonHeight) - offsetY;

    local numButtons = math.ceil(self:GetHeight() / buttonHeight) + 1;

    for i = #buttons + 1, numButtons do
        button = CreateFrame("BUTTON", buttonName and (buttonName .. i) or nil, scrollChild, buttonTemplate);
        button:SetPoint(point, buttons[i-1], relativePoint, offsetX, offsetY);
        tinsert(buttons, button);
    end

    scrollChild:SetWidth(self:GetWidth())
    scrollChild:SetHeight(numButtons * buttonHeight);
    self:SetVerticalScroll(0);
    self:UpdateScrollChildRect();

    self.buttons = buttons;
    local scrollBar = self.scrollBar;
    scrollBar:SetMinMaxValues(0, numButtons * buttonHeight)
    scrollBar.buttonHeight = buttonHeight;
    scrollBar:SetValueStep(buttonHeight);
    scrollBar:SetStepsPerPage(numButtons - 2); -- one additional button was added above. Need to remove that, and one more to make the current bottom the new top (and vice versa)
    scrollBar:SetValue(0);
end

function ArmoryHybridScrollFrameScrollButton_OnUpdate(self, elapsed)
    self.timeSinceLast = self.timeSinceLast + elapsed;
    if ( self.timeSinceLast >= ( self.updateInterval or 0.08 ) ) then
        if ( not IsMouseButtonDown("LeftButton") ) then
            self:SetScript("OnUpdate", nil);
        elseif ( self:IsMouseOver() ) then
            local parent = self.parent or self:GetParent():GetParent();
            ArmoryHybridScrollFrame_OnMouseWheel(parent, self.direction, (self.stepSize or parent.buttonHeight/3));
            self.timeSinceLast = 0;
        end
    end
end

function ArmoryHybridScrollFrameScrollButton_OnClick(self, button, down)
    local parent = self.parent or self:GetParent():GetParent();

    if ( down ) then
        self.timeSinceLast = (self.timeToStart or -0.2);
        self:SetScript("OnUpdate", ArmoryHybridScrollFrameScrollButton_OnUpdate);
        ArmoryHybridScrollFrame_OnMouseWheel(parent, self.direction);
        PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
    else
        self:SetScript("OnUpdate", nil);
    end
end

function ArmoryHybridScrollFrame_Update(self, totalHeight, displayedHeight)
    local range = floor(totalHeight - self:GetHeight() + 0.5);
    if ( range > 0 and self.scrollBar ) then
        local minVal, maxVal = self.scrollBar:GetMinMaxValues();
        if ( math.floor(self.scrollBar:GetValue()) >= math.floor(maxVal) ) then
            self.scrollBar:SetMinMaxValues(0, range);
            if ( range < maxVal ) then
                if ( math.floor(self.scrollBar:GetValue()) ~= math.floor(range) ) then
                    self.scrollBar:SetValue(range);
                else
                    ArmoryHybridScrollFrame_SetOffset(self, range); -- If we've scrolled to the bottom, we need to recalculate the offset.
                end
            end
        else
            self.scrollBar:SetMinMaxValues(0, range)
        end
        self.scrollBar:Enable();
        ArmoryHybridScrollFrame_UpdateButtonStates(self);
        self.scrollBar:Show();
    elseif ( self.scrollBar ) then
        self.scrollBar:SetValue(0);
        if ( self.scrollBar.doNotHide ) then
            self.scrollBar:Disable();
            self.scrollUp:Disable();
            self.scrollDown:Disable();
            self.scrollBar.thumbTexture:Hide();
        else
            self.scrollBar:Hide();
        end
    end

    self.range = range;
    self.totalHeight = totalHeight;
    self.scrollChild:SetHeight(displayedHeight);
    self:UpdateScrollChildRect();
end

function ArmoryHybridScrollFrame_GetOffset(self)
    return math.floor(self.offset or 0), (self.offset or 0);
end

function ArmoryHybridScrollFrame_SetOffset(self, offset)
    local buttons = self.buttons
    local buttonHeight = self.buttonHeight;
    local element, overflow;

    local scrollHeight = 0;

    local largeButtonTop = self.largeButtonTop
    if ( self.dynamic ) then --This is for frames where buttons will have different heights
        if ( offset < buttonHeight ) then
            -- a little optimization
            element = 0;
            scrollHeight = offset;
        else
            element, scrollHeight = self.dynamic(offset);
        end
    elseif ( largeButtonTop and offset >= largeButtonTop ) then
        local largeButtonHeight = self.largeButtonHeight;
        -- Initial offset...
        element = largeButtonTop / buttonHeight;

        if ( offset >= (largeButtonTop + largeButtonHeight) ) then
            element = element + 1;

            local leftovers = (offset - (largeButtonTop + largeButtonHeight) );

            element = element + ( leftovers / buttonHeight );
            overflow = element - math.floor(element);
            scrollHeight = overflow * buttonHeight;
        else
            scrollHeight = math.abs(offset - largeButtonTop);
        end
    else
        element = offset / buttonHeight;
        overflow = element - math.floor(element);
        scrollHeight = overflow * buttonHeight;
    end

    if ( math.floor(self.offset or 0) ~= math.floor(element) and self.update ) then
        self.offset = element;
        self:update();
    else
        self.offset = element;
    end

    self:SetVerticalScroll(scrollHeight);
end

function ArmoryHybridScrollFrameScrollChild_OnLoad(self)
    self:GetParent().scrollChild = self;
end

function ArmoryEditBox_OnTabPressed(self)
    if ( self.previousEditBox and IsShiftKeyDown() ) then
        self.previousEditBox:SetFocus();
    elseif ( self.nextEditBox ) then
        self.nextEditBox:SetFocus();
    end
end

function ArmoryEditBox_ClearFocus(self)
    self:ClearFocus();
end

function ArmoryEditBox_HighlightText(self)
    self:HighlightText();
end

function ArmoryEditBox_ClearHighlight(self)
    self:HighlightText(0, 0);
end

function ArmorySearchBoxTemplate_OnLoad(self)
    self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
    self:SetTextInsets(16, 20, 0, 0);
    self.Instructions:SetText(SEARCH);
    self.Instructions:ClearAllPoints();
    self.Instructions:SetPoint("TOPLEFT", self, "TOPLEFT", 16, 0);
    self.Instructions:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -20, 0);
end

function ArmorySearchBoxTemplate_OnEditFocusLost(self)
    if ( self:GetText() == "" ) then
        self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
        self.clearButton:Hide();
    end
end

function ArmorySearchBoxTemplate_OnEditFocusGained(self)
    self.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
    self.clearButton:Show();
end

function ArmorySearchBoxTemplate_OnTextChanged(self)
    if ( not self:HasFocus() and self:GetText() == "" ) then
        self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
        self.clearButton:Hide();
    else
        self.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
        self.clearButton:Show();
    end
    self.Instructions:SetShown(self:GetText() == "");
end

local function UpdateColorForEnabledState(self, color)
    if ( color ) then
        self:SetTextColor(color:GetRGBA());
    end
end

function ArmorySearchBoxTemplate_OnDisable(self)
    UpdateColorForEnabledState(self, self.disabledColor);
end

function ArmorySearchBoxTemplate_OnEnable(self)
    UpdateColorForEnabledState(self, self.enabledColor);
end

function ArmorySearchBoxTemplateClearButton_OnClick(self)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    local editBox = self:GetParent();
    editBox:SetText("");
    editBox:ClearFocus();
end


ArmoryUIMenuButtonStretchMixin = {};

function ArmoryUIMenuButtonStretchMixin:SetTextures(texture)
    self.TopLeft:SetTexture(texture);
    self.TopRight:SetTexture(texture);
    self.BottomLeft:SetTexture(texture);
    self.BottomRight:SetTexture(texture);
    self.TopMiddle:SetTexture(texture);
    self.MiddleLeft:SetTexture(texture);
    self.MiddleRight:SetTexture(texture);
    self.BottomMiddle:SetTexture(texture);
    self.MiddleMiddle:SetTexture(texture);
end

function ArmoryUIMenuButtonStretchMixin:OnMouseDown(button)
    if ( self:IsEnabled() ) then
        self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Down");
        if ( self.Icon ) then
            if ( not self.Icon.oldPoint ) then
                local point, relativeTo, relativePoint, x, y = self.Icon:GetPoint(1);
                self.Icon.oldPoint = point;
                self.Icon.oldX = x;
                self.Icon.oldY = y;
            end
            self.Icon:SetPoint(self.Icon.oldPoint, self.Icon.oldX + 1, self.Icon.oldY - 1);
        end
    end
end

function ArmoryUIMenuButtonStretchMixin:OnMouseUp(button)
    if ( self:IsEnabled() ) then
        self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Up");
        if ( self.Icon ) then
            self.Icon:SetPoint(self.Icon.oldPoint, self.Icon.oldX, self.Icon.oldY);
        end
    end
end

function ArmoryUIMenuButtonStretchMixin:OnShow()
    -- we need to reset our textures just in case we were hidden before a mouse up fired
    self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Up");
end

function ArmoryUIMenuButtonStretchMixin:OnEnable()
    self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Up");
end

function ArmoryUIMenuButtonStretchMixin:OnEnter()
    if(self.tooltipText ~= nil) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip_SetTitle(GameTooltip, self.tooltipText);
        GameTooltip:Show();
    end
end

function ArmoryUIMenuButtonStretchMixin:OnLeave()
    if(self.tooltipText ~= nil) then
        GameTooltip:Hide();
    end
end

ArmoryUIPanelButtonMixin = {};

function ArmoryUIPanelButtonMixin:OnLoad()
    if ( not self:IsEnabled() ) then
        self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
        self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
        self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
    end
end

function ArmoryUIPanelButtonMixin:OnMouseDown()
    if ( self:IsEnabled() ) then
        self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down");
        self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down");
        self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down");
    end
end

function ArmoryUIPanelButtonMixin:OnMouseUp()
    if ( self:IsEnabled() ) then
        self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
        self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
        self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
    end
end

function ArmoryUIPanelButtonMixin:OnShow()
    if ( self:IsEnabled() ) then
        -- we need to reset our textures just in case we were hidden before a mouse up fired
        self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
        self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
        self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
    end
end

function ArmoryUIPanelButtonMixin:OnDisable()
    self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
    self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
    self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled");
end

function ArmoryUIPanelButtonMixin:OnEnable()
    self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
    self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
    self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up");
end


ArmoryPortraitFrameMixin = {};

function ArmoryPortraitFrameMixin:SetBorder(layoutName)
    local layout = NineSliceUtil.GetLayout(layoutName);
    NineSliceUtil.ApplyLayout(self.NineSlice, layout);
end

function ArmoryPortraitFrameMixin:GetPortrait()
    return self.PortraitContainer.portrait;
end

function ArmoryPortraitFrameMixin:SetPortraitToAsset(texture)
    self:GetPortrait():SetTexture(texture);
end

function ArmoryPortraitFrameMixin:SetPortraitToUnit(unit)
    SetPortraitTexture(self:GetPortrait(), unit);
end

function ArmoryPortraitFrameMixin:SetPortraitTextureRaw(texture)
    self:GetPortrait():SetTexture(texture);
end

function ArmoryPortraitFrameMixin:SetPortraitAtlasRaw(atlas, ...)
    self:GetPortrait():SetAtlas(atlas, ...);
end

function ArmoryPortraitFrameMixin:SetPortraitTexCoord(...)
    self:GetPortrait():SetTexCoord(...);
end

function ArmoryPortraitFrameMixin:SetPortraitShown(shown)
    self:GetPortrait():SetShown(shown);
end

function ArmoryPortraitFrameMixin:GetTitleText()
    return self.TitleContainer.TitleText;
end

function ArmoryPortraitFrameMixin:SetTitleColor(color)
    self:GetTitleText():SetTextColor(color:GetRGBA());
end

function ArmoryPortraitFrameMixin:SetTitle(title)
    self:GetTitleText():SetText(title);
end

function ArmoryPortraitFrameMixin:SetTitleFormatted(fmt, ...)
    self:GetTitleText():SetFormattedText(fmt, ...);
end

function ArmoryPortraitFrameMixin:SetTitleMaxLinesAndHeight(maxLines, height)
    self:GetTitleText():SetMaxLines(maxLines);
    self:GetTitleText():SetHeight(height);
end
