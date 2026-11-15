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

ARMORY_FIND_HEIGHT = 16;

local FIND_LINES_DISPLAYED = 13;
local FIND_RESULTS = {};

-- Blizzard's WhoFrameColumn_SetWidth is only in the FriendsFrame of Retail and Classic, not in Forever's
function ArmoryFindFrameColumn_SetWidth(frame, width)
    frame:SetWidth(width);
    local middle = _G[frame:GetName().."Middle"];
    if ( middle ) then
        middle:SetWidth(width - 9);
    end
end

function ArmoryFindFrame_Toggle()
    if ( ArmoryFindFrame:IsShown() ) then
        ArmoryFindFrame:Hide();
    else
        ArmoryFindFrame:Show();
    end
end

function ArmoryFindFrame_OnLoad(self)
    self:SetAttribute("UIPanelLayout-defined", true);
    self:SetAttribute("UIPanelLayout-enabled", true);
    self:SetAttribute("UIPanelLayout-area", "left");
    self:SetAttribute("UIPanelLayout-pushable", 5);
    self:SetAttribute("UIPanelLayout-whileDead", true);

    if ( Armory.isClassic ) then
        Armory:SetPortraitToTexture(ArmoryFindFramePortrait, "Interface\\Icons\\INV_Misc_QuestionMark");
    else
        self:SetPortraitToAsset("Interface\\Icons\\INV_Misc_QuestionMark");
    end
    self:SetTitle(ARMORY_CMD_FIND_MENUTEXT);

    self.Inset:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 4, 332);
    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 120);

    table.insert(UISpecialFrames, "ArmoryFindFrame");
end

function ArmoryFindFrame_OnShow(self)
    ArmoryFindFrame_Update();
end

function ArmoryFindFrame_OnHide(self)
    if ( ArmoryFindFrame.running ) then
        Armory:CancelFind();
    end
end

function ArmoryFindFrame_Initialize(searchType, exact, search)
    ArmoryFindFrameEditBox:SetText("");
    ArmoryDropDownMenu_Initialize(ArmoryFindTypeDropDown, ArmoryFindTypeDropDown_Initialize);

    if ( searchType ) then
        table.wipe(FIND_RESULTS);

        FauxScrollFrame_SetOffset(ArmoryFindFrameScrollFrame, 0);
        ArmoryFindFrameScrollFrameScrollBar:SetMinMaxValues(0, 0);
        ArmoryFindFrameScrollFrameScrollBar:SetValue(0);

        if ( (search or "") ~= "" ) then
            if ( exact and search:find(" ") ) then
                if ( search:find('"') ) then
                    search = "'"..search.."'";
                else
                    search = '"'..search..'"';
                end
            end
            ArmoryFindFrame.running = true;
            ArmoryFindFrameEditBox:SetText(search);
            ArmoryFindFrameTotals:SetText(ARMORY_SEARCHING);
        else
            ArmoryFindFrameTotals:SetText("");
        end

        ArmoryFindFrame.searchType = searchType;
        ArmoryDropDownMenu_SetSelectedValue(ArmoryFindTypeDropDown, searchType);
    else
        if ( #FIND_RESULTS == 0 ) then
            ArmoryFindFrameTotals:SetText("");
        end
        if ( not ArmoryFindFrame.searchType ) then
            ArmoryFindFrame.searchType = Armory:GetConfigDefaultSearch();
        end
        ArmoryDropDownMenu_SetSelectedValue(ArmoryFindTypeDropDown, ArmoryFindFrame.searchType);
    end

    ArmoryFindFrame_InitializeView(ArmoryDropDownMenu_GetSelectedValue(ArmoryFindTypeDropDown));
    ArmoryFindFrame_UpdateFindButton();
end

function ArmoryFindFrame_InitializeView(searchType)
    ArmoryFindFrame.simpleView = (searchType == ARMORY_CMD_FIND_INVENTORY);
    if ( ArmoryFindFrame.simpleView ) then
        ArmoryFindFrameColumnHeader1:Hide();
        ArmoryFindFrameColumnHeader2:Hide();
        ArmoryFindFrameColumnHeader3:Hide();
    else
        ArmoryFindFrameColumnHeader1:Show();
        ArmoryFindFrameColumnHeader2:Show();
        ArmoryFindFrameColumnHeader3:Show();
    end
end

function ArmoryFindFrame_Finalize()
    ArmoryFindFrame.running = false;
    ArmoryFindFrameTotals:SetText(format(ARMORY_CMD_FIND_FOUND, #FIND_RESULTS));
    ArmoryFindFrame_UpdateFindButton();

    if ( ArmoryFindFrame:IsShown() ) then
        ArmoryFindFrame_Update();
    else
        ArmoryFindFrame:Show();
    end
end

-- tooltipLines: a stored tooltip for results without a link (spells in Classic)
function ArmoryFindFrame_Add(who, where, what, link, tinker, anchor, count, tooltipLines)
    table.insert(FIND_RESULTS, {who=who, where=where, what=what, link=link, tinker=tinker, anchor=anchor, count=count, tooltipLines=tooltipLines});
end

function ArmoryFindFrame_Sort(sortType)
    if ( sortType == "who" ) then
        table.sort(FIND_RESULTS, function(a, b) return a.who < b.who; end);
    elseif ( sortType == "where" ) then
        table.sort(FIND_RESULTS, function(a, b) return a.where < b.where; end);
    elseif ( sortType == "what" ) then
        table.sort(FIND_RESULTS, function(a, b) return a.what < b.what; end);
    end
    ArmoryFindFrame_Update();
end

function ArmoryFindFrameEditBox_OnEnterPressed(self)
    if ( ArmoryFindButton:IsEnabled() ) then
        ArmoryFindButton_OnClick(ArmoryFindButton);
    end
end

function ArmoryFindFrameEditBox_OnTextChanged(self)
    ArmorySearchBoxTemplate_OnTextChanged(self);
    ArmoryFindFrame_UpdateFindButton();
end

function ArmoryFindType_CreateButtons(onClick)
    local info = ArmoryDropDownMenu_CreateInfo();

    info.func = onClick;
    info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;

    for _, value in ipairs({ARMORY_CMD_FIND_ALL, ARMORY_CMD_FIND_INVENTORY, ARMORY_CMD_FIND_ITEM, ARMORY_CMD_FIND_QUEST, ARMORY_CMD_FIND_SPELL, ARMORY_CMD_FIND_SKILL}) do
        info.text =  Armory:Proper(value);
        info.value = value;
        info.checked = nil;
        ArmoryDropDownMenu_AddButton(info);
    end
end

function ArmoryFindTypeDropDown_OnLoad(self)
    ArmoryDropDownMenu_SetWidth(self, 90);
    ArmoryDropDownMenu_Initialize(self, ArmoryFindTypeDropDown_Initialize);
    ArmoryDropDownMenu_SetSelectedValue(ArmoryFindTypeDropDown, Armory:GetConfigDefaultSearch());
end

function ArmoryFindTypeDropDown_Initialize()
    ArmoryFindType_CreateButtons(ArmoryFindTypeDropDown_OnClick);
end

function ArmoryFindTypeDropDown_OnClick(self)
    ArmoryDropDownMenu_SetSelectedValue(ArmoryFindTypeDropDown, self.value);
end

function ArmoryFindButton_OnClick(self)
    local text = ArmoryFindFrameEditBox:GetText();
    local exact = text:match([[^['"](.*)['"]$]]);
    local where = ArmoryDropDownMenu_GetSelectedValue(ArmoryFindTypeDropDown);

    ArmoryFindFrame.running = true;
    ArmoryFindFrame_InitializeView(where);

    if ( exact ) then
        Armory:Find(where, exact);
    else
        Armory:Find(where, strsplit(" ", text));
    end
end

function ArmoryFindFrameButton_OnClick(self, button)
    local index = self.index;
    if ( index and index <= #FIND_RESULTS ) then
        local link = FIND_RESULTS[index].link;
        if ( link and IsModifiedClick("CHATLINK") and ChatFrameUtil.GetActiveWindow() ) then
           ChatFrameUtil.InsertLink(link);
        end
    end
end

function ArmoryFindFrameButton_OnEnter(self)
    local index = self.index;

    if ( index and index <= #FIND_RESULTS ) then
        local link = FIND_RESULTS[index].link;
        local tinker = FIND_RESULTS[index].tinker;
        local anchor = FIND_RESULTS[index].anchor;
        local tooltipLines = FIND_RESULTS[index].tooltipLines;
        if ( link ) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            Armory:SetHyperlink(GameTooltip, link, tinker, anchor);
        elseif ( tooltipLines ) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            Armory:Table2Tooltip(GameTooltip, tooltipLines, 2);
            GameTooltip:Show();
        end

        if ( ArmoryFindFrame.simpleView ) then
            ArmoryFindFrameDetailWho:Hide();
            ArmoryFindFrameDetailWhere:Hide();
            ArmoryFindFrameDetailWhat:SetPoint("TOPLEFT", "ArmoryFindFrame", "TOPLEFT", 23, -348);
        else
            ArmoryFindFrameDetailWho:SetText(FIND_RESULTS[index].who);
            ArmoryFindFrameDetailWho:Show();
            ArmoryFindFrameDetailWhere:SetText(FIND_RESULTS[index].where);
            ArmoryFindFrameDetailWhere:Show();
            ArmoryFindFrameDetailWhat:SetPoint("TOPLEFT", "ArmoryFindFrameDetailWhere", "BOTTOMLEFT", 0, -3);
        end
        ArmoryFindFrameDetailWhat:SetText(FIND_RESULTS[index].what);
        ArmoryFindFrameDetailWhat:Show();
        if ( FIND_RESULTS[index].count ) then
            ArmoryFindFrameDetailCount:SetText("x"..FIND_RESULTS[index].count);
            ArmoryFindFrameDetailCount:Show();
        else
            ArmoryFindFrameDetailCount:Hide();
        end
    else
        ArmoryFindFrameDetailWho:Hide();
        ArmoryFindFrameDetailWhere:Hide();
        ArmoryFindFrameDetailWhat:Hide();
        ArmoryFindFrameDetailCount:Hide();
    end
end

function ArmoryFindFrame_UpdateFindButton()
    local text = ArmoryFindFrameEditBox:GetText();

    if ( not ArmoryFindFrame.running and strlen(text) > 0 ) then
        ArmoryFindButton:Enable();
    else
        ArmoryFindButton:Disable();
    end
end

function ArmoryFindFrame_Update()
    local numResults = #FIND_RESULTS;
    local showScrollBar = (numResults > FIND_LINES_DISPLAYED);
    local button, buttonText;
    local offset = FauxScrollFrame_GetOffset(ArmoryFindFrameScrollFrame);
    local index, width;

    for i = 1, FIND_LINES_DISPLAYED, 1 do
        index = offset + i;
        button = _G["ArmoryFindFrameButton"..i];
        button.index = index;

        if ( index > numResults ) then
            button:Hide();
        else
            if ( ArmoryFindFrame.simpleView ) then
                buttonText = _G["ArmoryFindFrameButton"..i.."Who"];
                buttonText:Hide();
                buttonText = _G["ArmoryFindFrameButton"..i.."Where"];
                buttonText:Hide();
                buttonText = _G["ArmoryFindFrameButton"..i.."What"];
                buttonText:Hide();
                buttonText = _G["ArmoryFindFrameButton"..i.."Text"];
                buttonText:SetText(FIND_RESULTS[index].what);
                buttonText:Show();
                width = 310;
            else
                buttonText = _G["ArmoryFindFrameButton"..i.."Text"];
                buttonText:Hide();
                buttonText = _G["ArmoryFindFrameButton"..i.."Who"];
                buttonText:SetText(FIND_RESULTS[index].who);
                buttonText:Show();
                buttonText = _G["ArmoryFindFrameButton"..i.."Where"];
                buttonText:SetText(FIND_RESULTS[index].where);
                buttonText:Show();
                buttonText = _G["ArmoryFindFrameButton"..i.."What"];
                buttonText:SetText(FIND_RESULTS[index].what);
                buttonText:Show();
                width = 145;
            end

            -- If need scrollbar resize columns
            if ( showScrollBar ) then
                buttonText:SetWidth(width - 14);
            else
                buttonText:SetWidth(width);
            end

            button:Show();
        end
    end

    ArmoryFindFrameDetailWho:Hide();
    ArmoryFindFrameDetailWhere:Hide();
    ArmoryFindFrameDetailWhat:Hide();
    ArmoryFindFrameDetailCount:Hide();

    -- If need scrollbar resize columns
    if ( ArmoryFindFrame.simpleView ) then
    elseif ( showScrollBar ) then
        ArmoryFindFrameColumn_SetWidth(ArmoryFindFrameColumnHeader3, 131);
    else
        ArmoryFindFrameColumn_SetWidth(ArmoryFindFrameColumnHeader3, 154);
    end

    C_Timer.After(0, function() ArmoryFindFrameEditBox:SetFocus(); end);

    -- ScrollFrame update
    FauxScrollFrame_Update(ArmoryFindFrameScrollFrame, numResults, FIND_LINES_DISPLAYED, ARMORY_FIND_HEIGHT);
end