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

ARMORY_SOCIAL_TABS = 2;

ARMORY_SOCIALFRAME_SUBFRAMES = { "ArmoryFriendsListFrame", "ArmoryIgnoreListFrame" };

ARMORY_FRIENDS_TO_DISPLAY = 11;
ARMORY_SOCIALFRAME_FRIEND_HEIGHT = 34;

ARMORY_IGNORES_TO_DISPLAY = 21;
ARMORY_SOCIALFRAME_IGNORE_HEIGHT = 16;

local tabWidthCache = {};

function ArmorySocialFrame_ShowSubFrame(frameName)
    for index, value in pairs(ARMORY_SOCIALFRAME_SUBFRAMES) do
        _G[value]:Hide();
        if ( value == ARMORY_SOCIALFRAME_SUBFRAMES[PanelTemplates_GetSelectedTab(ArmorySocialFrame)] ) then
            _G[value]:Show();
        end
    end
end

function ArmorySocialFrame_Toggle()
    if ( ArmorySocialFrame:IsShown() or not Armory:HasSocial() ) then
        HideUIPanel(ArmorySocialFrame);
    else
        ArmoryCloseChildWindows();
        ShowUIPanel(ArmorySocialFrame);
    end
end

function ArmorySocialFrameTab_OnClick(self)
    PanelTemplates_SetTab(ArmorySocialFrame, self:GetID());
    ArmorySocialFrame_ShowSubFrame();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function ArmorySocialFrame_OnLoad(self)
    self:RegisterEvent("FRIENDLIST_UPDATE");
    self:RegisterEvent("IGNORELIST_UPDATE");

    PanelTemplates_SetNumTabs(self, ARMORY_SOCIAL_TABS);
    PanelTemplates_SetTab(self, 1);
end

function ArmorySocialFrame_OnShow(self)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    PanelTemplates_SetTab(self, PanelTemplates_GetSelectedTab(self));

    local tab;
    local totalTabWidth = 0;
    for i = 1, ARMORY_SOCIAL_TABS do
        tabWidthCache[i] = 0;
        tab = _G["ArmorySocialFrameTab"..i];
        PanelTemplates_TabResize(tab, 0);
        tab.textWidth = tab:GetTextWidth();
        tabWidthCache[i] = PanelTemplates_GetTabWidth(tab);
        totalTabWidth = totalTabWidth + tabWidthCache[i];
        tab:Show();
    end
    ArmoryFrame_CheckTabBounds("ArmorySocialFrameTab", totalTabWidth, 270, tabWidthCache);

    ArmorySocialFrame_ShowSubFrame();
end

function ArmorySocialFrame_OnEvent(self, event, ...)
    if ( not Armory:CanHandleEvents() ) then
        return;
    else
        Armory:Execute(ArmorySocialFrame_UpdateFriends);
    end
end

function ArmorySocialFrame_UpdateFriends()
    Armory:UpdateFriends();
    if ( ArmoryFriendsListFrame:IsShown() ) then
        ArmoryFriendsList_Update();
    elseif ( ArmoryIgnoreListFrame:IsShown() ) then
        ArmoryIgnoreList_Update();
    end
end

function ArmorySocialFrame_OnHide(self)
	for index, value in pairs(ARMORY_SOCIALFRAME_SUBFRAMES) do
		_G[value]:Hide();
	end
end

function ArmoryFriendsListFrame_OnShow(self)
    ArmorySocialFrameTitleText:SetText(FRIENDS_LIST);
    ArmoryFriendsList_Update();
end

function ArmoryFriendsList_Update()
    local numFriends = Armory:GetNumFriends();
    local showScrollBar = (numFriends > ARMORY_FRIENDS_TO_DISPLAY);
    local nameText, infoText, noteText, noteHiddenText;
    local name, class, note;
    local friendButton;

    local friendOffset = FauxScrollFrame_GetOffset(ArmoryFriendsListScrollFrame);
    local friendIndex;

    for i = 1, ARMORY_FRIENDS_TO_DISPLAY, 1 do
        friendIndex = friendOffset + i;
        name, class, note = Armory:GetFriendInfo(friendIndex);
        nameText = _G["ArmoryFriendsListButton"..i.."ButtonTextName"];
        infoText = _G["ArmoryFriendsListButton"..i.."ButtonTextInfo"];
        noteText = _G["ArmoryFriendsListButton"..i.."ButtonTextNoteText"];
        noteHiddenText = _G["ArmoryFriendsListButton"..i.."ButtonTextNoteHiddenText"];
        friendButton = _G["ArmoryFriendsListButton"..i];
        nameText:ClearAllPoints();
        nameText:SetPoint("TOPLEFT", 10, -3);
        friendButton:SetID(friendIndex);

        friendButton.candidate = nil;
        if ( not name ) then
            name = UNKNOWN;
        elseif ( Armory.characterRealm == Armory.playerRealm and Armory.player ~= Armory.character and Armory:UnitFactionGroup() == _G.UnitFactionGroup("player") ) then
            friendButton.candidate = name;
        end
        nameText:SetText(name);
        infoText:SetText(class);

        if ( note ) then
            noteText:SetFormattedText(FRIENDS_LIST_NOTE_TEMPLATE, note);
            noteHiddenText:SetText(note);
            local width = noteHiddenText:GetWidth() + infoText:GetWidth();
            local friendButtonWidth = friendButton:GetWidth();
            if ( showScrollBar ) then
                friendButtonWidth = friendButtonWidth - ArmoryFriendsListScrollFrameScrollBarTop:GetWidth();
            end
            if ( width > friendButtonWidth ) then
                width = friendButtonWidth - infoText:GetWidth();
            end
            noteText:SetWidth(width);
            noteText:SetHeight(14);
        else
            noteText:SetText("");
        end

        if ( friendIndex > numFriends ) then
            friendButton:Hide();
        else
            friendButton:Show();
        end
    end

    -- ScrollFrame stuff
    FauxScrollFrame_Update(ArmoryFriendsListScrollFrame, numFriends, ARMORY_FRIENDS_TO_DISPLAY, ARMORY_SOCIALFRAME_FRIEND_HEIGHT);
end

function ArmoryIgnoreListFrame_OnShow(self)
    ArmorySocialFrameTitleText:SetText(IGNORE_LIST);
    ArmoryIgnoreList_Update();
end

function ArmoryIgnoreList_Update()
    local numIgnores = Armory:GetNumIgnores();
    local nameText;
    local name;
    local ignoreButton;

    local ignoreOffset = FauxScrollFrame_GetOffset(ArmoryIgnoreListScrollFrame);
    local ignoreIndex;
    for i = 1, ARMORY_IGNORES_TO_DISPLAY do
        ignoreIndex = i + ignoreOffset;
        name = Armory:GetIgnoreName(ignoreIndex);
        nameText = _G["ArmoryIgnoreListButton"..i.."ButtonTextName"];
        ignoreButton = _G["ArmoryIgnoreListButton"..i];
        ignoreButton:SetID(ignoreIndex);

        ignoreButton.candidate = nil;
        if ( name ~= "" and Armory.characterRealm == Armory.playerRealm and Armory.player ~= Armory.character ) then
            ignoreButton.candidate = name;
        end
        nameText:SetText(name);

        if ( ignoreIndex > numIgnores ) then
            ignoreButton:Hide();
        else
            ignoreButton:Show();
        end
    end

    -- ScrollFrame stuff
    FauxScrollFrame_Update(ArmoryIgnoreListScrollFrame, numIgnores, ARMORY_IGNORES_TO_DISPLAY, ARMORY_SOCIALFRAME_IGNORE_HEIGHT);
end
