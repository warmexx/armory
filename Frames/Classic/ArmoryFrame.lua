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

ARMORY_MAX_LINE_TABS = 10;

ARMORYFRAME_MAINFRAMES = { "ArmoryFrame", "ArmoryLookupFrame", "ArmoryFindFrame" };
ARMORYFRAME_SUBFRAMES = { "ArmoryPaperDollFrame", "ArmoryPetFrame", "ArmoryTalentFrame", "ArmoryPVPFrame", "ArmoryOtherFrame" };
ARMORYFRAME_CHILDFRAMES = { "ArmoryTradeSkillFrame", "ArmoryInventoryFrame", "ArmoryQuestLogFrame", "ArmorySpellBookFrame", "ArmorySocialFrame" };

ARMORYFRAME_SUBFRAME = "ArmoryPaperDollFrame";

local tabWidthCache = {};

function ArmoryFrame_ToggleArmory(tab)
    local subFrame = _G[tab];
    if ( subFrame ) then
        PanelTemplates_SetTab(ArmoryFrame, subFrame:GetID());
        if ( ArmoryFrame:IsVisible() ) then
            if ( subFrame:IsVisible() ) then
                HideUIPanel(ArmoryFrame);
            else
                PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
                ArmoryFrame_ShowSubFrame(tab);
            end
        else
            ShowUIPanel(ArmoryFrame);
            ArmoryFrame_ShowSubFrame(tab);
        end
    end
end

function ArmoryFrame_ShowSubFrame(frameName)
    for index, value in pairs(ARMORYFRAME_SUBFRAMES) do
        if ( value == frameName ) then
            _G[value]:Show();
            ARMORYFRAME_SUBFRAME = value;
        else
            _G[value]:Hide();
        end
    end
end

function ArmoryFrame_OpenFrame(id)
    local tab = _G["ArmoryFrameTab"..id];
    local frame = _G[ARMORYFRAME_SUBFRAMES[id]];
    ArmoryFrameTab_Update();
    if ( tab.enabled and not frame:IsVisible() ) then
        ArmoryFrameTab_OnClick(tab);
    end
end

function ArmoryFrame_OpenSideFrame(frame)
    ArmoryFrame_UpdateLineTabs();
    if ( frame.enabled ) then
        if ( not ArmoryFrame:IsShown() ) then
            ShowUIPanel(ArmoryFrame);
        end
        if ( not frame:IsVisible() ) then
            ArmoryCloseChildWindows();
            ShowUIPanel(frame);
        end
    end
end

function ArmoryFrame_OpenSkillFrame(id)
    if ( Armory:HasTradeSkills() ) then
        local skill = Armory:GetPrimaryTradeSkills()[id];
        local name = skill and skill[1] or nil;
        if ( name and Armory:HasTradeSkillLines(name) ) then
            Armory:SetSelectedProfession(name);
            ArmoryTradeSkillFrame_Show();
            ArmoryFrame_OpenSideFrame(ArmoryTradeSkillFrame);
        end
    end
end

function ArmoryFrame_OnLoad(self)
    Armory:Init();

    -- Sliding frame
    --this:SetAttribute("UIPanelLayout-defined", true);
    --this:SetAttribute("UIPanelLayout-enabled", true);
    --this:SetAttribute("UIPanelLayout-area", "left");
    --this:SetAttribute("UIPanelLayout-pushable", 5);
    --this:SetAttribute("UIPanelLayout-whileDead", true);

    self:RegisterEvent("VARIABLES_LOADED");
    self:RegisterEvent("UNIT_NAME_UPDATE");
    self:RegisterEvent("PLAYER_PVP_RANK_CHANGED");
    self:RegisterEvent("PLAYER_UPDATE_RESTING");
    self:RegisterEvent("PLAYER_LOGIN");
    self:RegisterEvent("PLAYER_LOGOUT");
    self:RegisterEvent("TIME_PLAYED_MSG");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PLAYER_ENTER_COMBAT");
    self:RegisterEvent("PLAYER_LEAVE_COMBAT");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");

	ButtonFrameTemplate_HideButtonBar(self);

	self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", PANEL_DEFAULT_WIDTH + PANEL_INSET_RIGHT_OFFSET, PANEL_INSET_BOTTOM_OFFSET);

	self.TitleText:SetPoint("LEFT", self, "LEFT", 84, 0);
	self.TitleText:SetPoint("RIGHT", self, "RIGHT", -40, 0);
	self.TitleText:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    -- Tab Handling code
    PanelTemplates_SetNumTabs(self, #ARMORYFRAME_SUBFRAMES);
    PanelTemplates_SetTab(self, 1);

    -- Allows Armory to be closed with the Escape key
    table.insert(UISpecialFrames, "ArmoryFrame");
end

function ArmoryFrame_OnEvent(self, event, ...)
    local arg1 = ...;

    if ( event == "VARIABLES_LOADED" ) then
        Armory:InitDb();
        Armory:SetProfile(Armory:CurrentProfile());

        Armory:InitializeIcon();
        Armory:PrepareMenu();

        Armory:RegisterTooltipHooks(GameTooltip);
        Armory:RegisterTooltipHooks(ItemRefTooltip);
        --Armory:RegisterTooltipHooks(ArmoryComparisonTooltip1);
        --Armory:RegisterTooltipHooks(ArmoryComparisonTooltip2);

        Armory:ExecuteDelayed(5, ArmoryFrame_Initialize);
    elseif ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( (event == "UNIT_NAME_UPDATE" and arg1 == "player") or event == "PLAYER_PVP_RANK_CHANGED" ) then
        Armory:Execute(ArmoryFrame_UpdateName);
    elseif ( event == "PLAYER_UPDATE_RESTING" ) then
        Armory:Execute(ArmoryFrame_UpdateResting);
    elseif ( event == "PLAYER_LOGIN" ) then
        if ( Armory:GetConfigScanOnEnter() ) then
            Armory.forceScan = true;
            Armory:SetConfigScanOnEnter(false);
        end
        Armory:ShowIcon();
    elseif ( event == "PLAYER_LOGOUT" ) then
        Armory:SetTimePlayed(Armory:GetTimePlayed("player"));
    elseif ( event == "TIME_PLAYED_MSG" ) then
        Armory.hasTimePlayed = true;
        Armory:SetTimePlayed(arg1);
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        Armory.inCombat = false;
        Armory.onHateList = false;
    elseif ( event == "PLAYER_ENTER_COMBAT" ) then
        Armory.inCombat = true;
    elseif ( event == "PLAYER_LEAVE_COMBAT" ) then
        Armory.inCombat = false;
    elseif ( event == "PLAYER_REGEN_DISABLED" ) then
        Armory.onHateList = true;
    elseif ( event == "PLAYER_REGEN_ENABLED" ) then
        Armory.onHateList = false;
    end

    if ( (Armory.inCombat or Armory.onHateList) and Armory:GetConfigPauseWhileInCombat() ) then
        Armory.commandHandler:Pause();
    elseif ( not (IsInInstance() and Armory:GetConfigRemainPausedInInstance()) ) then
        Armory.commandHandler:Resume();
        Armory:ResetTooltipHook();
    end
end

function ArmoryFrame_UpdateName()
    ArmoryFrame.TitleText:SetText(Armory:UnitPVPName("player"));
end

function ArmoryFrame_UpdateResting()
    if ( Armory:IsResting() ) then
        ArmoryRestIcon:Show();
    else
        ArmoryRestIcon:Hide();
    end
end

local ChatFrame_DisplayTimePlayed_Orig = ChatFrame_DisplayTimePlayed;
function ChatFrame_DisplayTimePlayed(...)
    if ( not Armory.requestedTimePlayed ) then
        return ChatFrame_DisplayTimePlayed_Orig(...);
    end
    Armory.requestedTimePlayed = nil;
end

function ArmoryFrame_Initialize()
    if ( not Armory.hasTimePlayed ) then
        Armory.requestedTimePlayed = true;
        RequestTimePlayed();
    end

    Armory:RemoveOldAuctions();

    local expire = Armory:CheckMailItems(1);
    if ( expire > 0 ) then
        ArmoryStaticPopup_Show("ARMORY_CHECK_MAIL_POPUP", expire);
    end
end

function ArmoryFrame_UpdateMail()
    if ( Armory:HasNewMail() ) then
        ArmoryMailFrame:Show();
        if( GameTooltip:IsOwned(ArmoryMailFrame) ) then
            ArmoryMailFrameUpdate();
        end
    else
        ArmoryMailFrame:Hide();
    end
end

function ArmoryMailFrameUpdate()
    local sender1, sender2, sender3 = Armory:GetLatestThreeSenders();
    local toolText;

    if( sender1 or sender2 or sender3 ) then
        toolText = HAVE_MAIL_FROM;
    else
        toolText = HAVE_MAIL;
    end

    if( sender1 ) then
        toolText = toolText.."\n"..sender1;
    end
    if( sender2 ) then
        toolText = toolText.."\n"..sender2;
    end
    if( sender3 ) then
        toolText = toolText.."\n"..sender3;
    end
    GameTooltip:SetText(toolText);
end

function ArmoryFrame_OnShow(self)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
    ArmoryFrame_Update(Armory:CurrentProfile());
end

function ArmoryFrame_OnHide(self)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

function ArmoryFrameTab_OnClick(self)
    local id = self:GetID();

    if ( id == 1 ) then
        ArmoryFrame_ToggleArmory("ArmoryPaperDollFrame");
    elseif ( id == 2 ) then
        ArmoryFrame_ToggleArmory("ArmoryPetFrame");
    elseif ( id == 3 ) then
        ArmoryFrame_ToggleArmory("ArmoryTalentFrame");
    elseif ( id == 4 ) then
        ArmoryFrame_ToggleArmory("ArmoryPVPFrame");
    elseif ( id == 5 ) then
        ArmoryFrame_ToggleArmory("ArmoryOtherFrame");
    end
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function ArmoryFrame_CheckTabBounds(tabName, totalTabWidth, maxTotalTabWidth, tabWidthCache)
    -- readjust tab sizes to fit
    local change, largestTab, tab;
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
        tab = _G[tabName..largestTab];
        PanelTemplates_TabResize(tab, 0, tabWidthCache[largestTab]);
        -- now update the total width
        totalTabWidth = totalTabWidth - change;
    end
end

function ArmoryFrame_Update(profile, refresh)
    Armory:SetProfile(profile);
    Armory:SetPortraitTexture(ArmoryFramePortrait, "player");
    ArmoryFrame_UpdateName();
    ArmoryFrame_UpdateResting();
    ArmoryFrame_UpdateMail();
    ArmoryFrame_UpdateLineTabs();
    ArmoryAlternateSlotFrame_HideSlots();
    ArmoryFrameTab_Update();

    if ( table.getn(Armory:SelectableProfiles()) > 1 ) then
        ArmorySelectCharacter:Enable();
        ArmoryFrameLeftButton:Enable();
        ArmoryFrameRightButton:Enable();
    else
        ArmorySelectCharacter:Disable();
        ArmoryFrameLeftButton:Disable();
        ArmoryFrameRightButton:Disable();
    end

    if ( refresh ) then
        ArmoryPetFrame.page = 1;
        local subFrameUpdate = _G[ARMORYFRAME_SUBFRAME.."_OnShow"];
        if ( subFrameUpdate ) then
            subFrameUpdate(_G[ARMORYFRAME_SUBFRAME]);
        end
        ArmoryCloseChildWindows(true);
    end
end

local function TabAdjust(id, enable)
    local tab = _G["ArmoryFrameTab"..id];
    local nextTab = _G["ArmoryFrameTab"..(id+1)];
    local frame = _G[ARMORYFRAME_SUBFRAMES[id]];
    tab.enabled = enable;
    if ( not enable ) then
        if ( frame:IsVisible() ) then
             ArmoryFrame_ToggleArmory("ArmoryPaperDollFrame");
        end
        tab:Hide();
        if ( nextTab ) then
            nextTab:SetPoint("LEFT", tab, "LEFT", 0, 0);
        end
    else
        tab:Show();
        if ( nextTab ) then
            nextTab:SetPoint("LEFT", tab, "RIGHT", -16, 0);
        end
    end
end

function ArmoryFrameTab_Update()
    local firstTab, numOtherTabs = ArmoryOtherFrameTab_Update();
    if ( numOtherTabs == 1 ) then
        ArmoryFrameTab5:SetText(ARMORY_OTHER_TABS[firstTab]);
    else
        ArmoryFrameTab5:SetText(OTHER);
    end

    TabAdjust(1, true);
    TabAdjust(2, Armory:HasPetUI());
    TabAdjust(3, Armory:HasTalents());
    TabAdjust(4, Armory:PVPEnabled());
    TabAdjust(5, numOtherTabs > 0);

    local tab;
    local totalTabWidth = 0;
    for i = 1, #ARMORYFRAME_SUBFRAMES do
        tabWidthCache[i] = 0;
        tab = _G["ArmoryFrameTab"..i];
        if ( tab:IsShown() ) then
            _G[tab:GetName().."Text"]:SetWidth(0);
            PanelTemplates_TabResize(tab, 0);
            tabWidthCache[i] = PanelTemplates_GetTabWidth(tab);
            totalTabWidth = totalTabWidth + tabWidthCache[i];
        end
    end
    ArmoryFrame_CheckTabBounds("ArmoryFrameTab", totalTabWidth, 384, tabWidthCache);
end

function ArmorySelectCharacter_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(CHARACTER);
end

function ArmorySelectCharacter_OnLeave(self)
    if ( GameTooltip:IsOwned(self) ) then
      GameTooltip:Hide();
    end
end

function ArmorySelectCharacter_OnClick(self)
    if ( self.characterList and self.characterList:IsVisible() ) then
        ArmorySelectCharacter_OnHide(self);
        return;
    end

    SharedTooltip_SetBackdropStyle(GameTooltip);

    self.characterList = Armory.qtip:Acquire("ArmoryCharacterList", 2);
    self.characterList:SetScale(Armory:GetConfigFrameScale());
    self.characterList:ClearAllPoints();
    self.characterList:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
    self.characterList:SetAutoHideDelay(1, self);

    ArmorySelectCharacter_OnLeave(self);
    ArmorySelectCharacter_Update(self.characterList);
end

function ArmorySelectCharacter_OnHide(self)
    if ( self.characterList ) then
        Armory.qtip:Release(self.characterList);
        self.characterList = nil;
    end
end

function ArmorySelectCharacter_Update(characterList)
    local unit = "player";
    local iconProvider = Armory.qtipIconProvider;
    local realms = Armory:RealmList();
    local collapsed = Armory:RealmState();

    local currentProfile = Armory:CurrentProfile();
    if ( not Armory:ProfileExists(currentProfile) ) then
        currentProfile = {realm=Armory.playerRealm, character=Armory.player};
    end

    characterList:Clear();

    if ( #realms == 1 ) then
        table.wipe(collapsed);
    end

    local index, column, myColumn;

    for _, realm in ipairs(realms) do
        index, column = characterList:AddLine();

        if ( #realms > 1 ) then
            myColumn = column; index, column = characterList:SetCell(index, myColumn, format("Interface\\Buttons\\UI-%sButton-Up", collapsed[realm] and "Plus" or "Minus"), iconProvider);
            characterList:SetCellScript(index, myColumn, "OnMouseDown",
                function(self, realm)
                    if ( collapsed[realm] ) then
                        collapsed[realm] = nil;
                    else
                        collapsed[realm] = 1;
                    end
                    ArmorySelectCharacter_Update(characterList);
                end,
                realm
            );
            myColumn = column; index, column = characterList:SetCell(index, myColumn, realm, GameFontNormalSmallLeft);
        else
            myColumn = column; index, column = characterList:SetCell(index, myColumn, realm, GameFontNormalSmallLeft, "LEFT", 2);
        end

        for _, character in ipairs(Armory:CharacterList(realm)) do
            if ( not collapsed[realm] ) then
                index, column = characterList:AddLine();

                local profile = {realm=realm, character=character};
                Armory:SelectProfile(profile);

                if ( realm == currentProfile.realm and character == currentProfile.character ) then
                    myColumn = column; index, column = characterList:SetCell(index, myColumn, "Interface\\Buttons\\UI-CheckBox-Check", iconProvider);
                else
                    myColumn = column; index, column = characterList:SetCell(index, myColumn, "");
                end

                if ( Armory:GetConfigUseClassColors() ) then
					local class, classEn = Armory:UnitClass(unit);
					character = "|c"..Armory:ClassColor(classEn, true)..character..FONT_COLOR_CODE_CLOSE;
				end

                myColumn = column; index, column = characterList:SetCell(index, myColumn, character, GameFontHighlightSmallLeft);
                if ( Armory:GetConfigShowEnhancedTips() and Armory:UnitLevel(unit) and Armory:UnitClass(unit) ) then
                    local class, classEn = Armory:UnitClass(unit);
                    characterList:SetCellScript(index, myColumn, "OnEnter",
                        function(self, tooltipInfo)
                            Armory:AddEnhancedTip(self, tooltipInfo[1], 1.0, 1.0, 1.0, tooltipInfo[2], 1);
                        end,
                        {Armory:UnitPVPName(unit), format(PLAYER_LEVEL_NO_SPEC, Armory:UnitLevel(unit), Armory:ClassColor(classEn, true), class)}
                    );
                    characterList:SetCellScript(index, myColumn, "OnLeave",
                        function(self)
                            GameTooltip:Hide();
                        end
                    );
                end
                characterList:SetCellScript(index, myColumn, "OnMouseDown",
                    function(self, profile)
                        characterList:Hide();
                        ArmoryFrameSelectCharacter(profile);
                    end,
                    profile
                );
            end
        end
    end
    Armory:SelectProfile(currentProfile);

    characterList:UpdateScrolling(398);
    characterList:Show();
end

function ArmoryFrame_DeleteCharacter(data)
    local profile = Armory:CurrentProfile();
    if ( data.realm == profile.realm and data.character == profile.character ) then
        profile = ArmoryFrameCharacterCycle(false, true);
    end
    Armory:DeleteProfile(data.realm, data.character, true);
    ArmoryFrame_Update(profile, true);
    if ( Armory.summary ) then
        Armory:UpdateSummary();
    end
end

function ArmoryFrame_UpdateLineTabs()
    local tabId = 1;
    local frame;

    for i = 1, #ARMORYFRAME_CHILDFRAMES do
        frame = _G[ARMORYFRAME_CHILDFRAMES[i]];
        frame.enabled = nil;
    end

    if ( Armory:HasInventory() ) then
        ArmoryFrame_SetLineTab(tabId, "Inventory", INVENTORY_TOOLTIP, "Interface\\Icons\\INV_Misc_Bag_08");
        ArmoryInventoryFrame.enabled = true;
        tabId = tabId + 1;
    end

    if ( Armory:HasQuestLog() ) then
        ArmoryFrame_SetLineTab(tabId, "Quests", QUESTLOG_BUTTON, "Interface\\Icons\\INV_Misc_Book_08");
        ArmoryQuestLogFrame.enabled = true;
        tabId = tabId + 1;
    end

    if ( Armory:HasSpellBook() and Armory:GetNumSpellTabs() > 0 ) then
        ArmoryFrame_SetLineTab(tabId, "SpellBook", SPELLBOOK_BUTTON, "Interface\\Icons\\INV_Misc_Book_09");
        ArmorySpellBookFrame.enabled = true;
        tabId = tabId + 1;
    end

    if ( Armory:HasSocial() ) then
        ArmoryFrame_SetLineTab(tabId, "Social", SOCIAL_BUTTON, "Interface\\Icons\\INV_Scroll_03");
        ArmorySocialFrame.enabled = true;
        tabId = tabId + 1;
    end

    if ( Armory:HasTradeSkills() ) then
        for _, name in ipairs(Armory:GetProfessionNames()) do
            if ( Armory:HasTradeSkillLines(name) ) then
                local lineTab = ArmoryFrame_SetLineTab(tabId, "TradeSkill", name, Armory:GetProfessionTexture(name));
                if ( lineTab ) then
                    ArmoryTradeSkillFrame.enabled = true;
                    lineTab.skillName = name;
                    tabId = tabId + 1;
                end
            end
        end
    end

    -- Hide unused tabs
    for i = tabId, ARMORY_MAX_LINE_TABS do
        _G["ArmoryFrameLineTab"..i]:Hide();
    end
end

function ArmoryFrame_SetLineTab(id, tabType, tooltip, texture)
    if ( id and id > 0 and id <= ARMORY_MAX_LINE_TABS ) then
        local lineTab = _G["ArmoryFrameLineTab"..id];
        if ( lineTab ) then
            lineTab:SetNormalTexture(texture);
            lineTab.tooltip = tooltip;
            lineTab.tabType = tabType;
            lineTab:Show();
        end
        return lineTab;
    end
end

function ArmoryFrameLineTabTooltip(self)
    if ( self.tooltip ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.tooltip);
    end
end

function ArmoryFrameLineTab_OnClick(self)
    for i = 1, ARMORY_MAX_LINE_TABS do
        local lineTab = _G["ArmoryFrameLineTab"..i];
        if ( lineTab:GetID() ~= self:GetID() ) then
            lineTab:SetChecked(false);
        end
    end

    if ( self.tabType == "Inventory" ) then
        ArmoryInventoryFrame_Toggle();
    elseif ( self.tabType == "Quests" ) then
        ArmoryQuestLogFrame_Toggle();
    elseif ( self.tabType == "SpellBook" ) then
        ArmoryToggleSpellBook(BOOKTYPE_SPELL);
    elseif ( self.tabType == "Social" ) then
        ArmorySocialFrame_Toggle();
    elseif ( self.tabType == "TradeSkill" ) then
        if ( ArmoryTradeSkillFrame:IsShown() and self.skillName == Armory:GetSelectedProfession() ) then
            ArmoryTradeSkillFrame_Hide();
            return;
        end
        Armory:SetSelectedProfession(self.skillName);
        ArmoryTradeSkillFrame_Show();
    end
end

function ArmoryFrameLeft_Click(self)
    ArmoryFrameCharacterCycle(false);
end

function ArmoryFrameLeft_OnEnter(self)
    local profile = ArmoryFrameCharacterCycle(false, true);
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
    if ( profile ) then
        GameTooltip:SetText(profile.character, 1.0, 1.0, 1.0);
        GameTooltip:AddLine(profile.realm);
        GameTooltip:SetScale(0.85);
        GameTooltip:Show();
        self.UpdateTooltip = ArmoryFrameLeft_OnEnter;
    else
        self.UpdateTooltip = nil;
    end
end

function ArmoryFrameRight_Click(self)
    ArmoryFrameCharacterCycle(true);
end

function ArmoryFrameRight_OnEnter(self)
    local profile = ArmoryFrameCharacterCycle(true, true);
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
    if ( profile ) then
        GameTooltip:SetText(profile.character, 1.0, 1.0, 1.0);
        GameTooltip:AddLine(profile.realm);
        GameTooltip:SetScale(0.85);
        GameTooltip:Show();
        self.UpdateTooltip = ArmoryFrameRight_OnEnter;
    else
        self.UpdateTooltip = nil;
    end
end

function ArmoryFrameCharacterCycle(next, peek)
    local currentRealm, currentCharacter = Armory:GetPaperDollLastViewed();
    local profiles = Armory:SelectableProfiles();
    local selected = 0;

    for index, profile in ipairs(profiles) do
        if ( profile.realm == currentRealm and profile.character == currentCharacter ) then
            selected = index;
            break;
        end
    end

    if ( next ) then
        selected = selected + 1;
    else
        selected = selected - 1;
    end
    if ( selected > #profiles ) then
        selected = 1;
    elseif ( selected < 1 ) then
        selected = #profiles;
    end

    if ( peek ) then
        return profiles[selected];
    end

    ArmoryFrameSelectCharacter(profiles[selected])
end

function ArmoryFrameSelectCharacter(profile)
    ArmoryFrame_Update(profile, true);
    ArmoryCloseDropDownMenus();
    Armory_EQC_Refresh();
    if ( not ArmoryFrame:IsShown() ) then
        local text = profile.character;
        if ( table.getn(Armory:RealmList()) > 1 ) then
            if ( profile.realm == GetRealmName() ) then
                text = text..RED_FONT_COLOR_CODE;
            end
            text = text.." ("..profile.realm..")";
        end
        ArmoryMessageFrame:AddMessage(text);
        ArmoryMessageFrame:Show();
    end
    if ( Armory.summary and Armory.summary:IsShown() ) then
        Armory:DisplaySummary();
    end
end

function ArmoryCloseChildWindows(reopen)
    local childWindow, currentChild;
    for index, value in pairs(ARMORYFRAME_CHILDFRAMES) do
        childWindow = _G[value];
        if ( childWindow ) then
            if ( childWindow:IsVisible() ) then
                currentChild = childWindow;
            end
            childWindow:Hide();
        end
    end
    if ( reopen and currentChild ) then
        if ( currentChild:GetName() == "ArmoryTradeSkillFrame" ) then
            for _, name in ipairs(Armory:GetProfessionNames()) do
                if ( name == Armory:GetSelectedProfession() ) then
                    if ( Armory:HasTradeSkillLines(name) ) then
                        Armory:SetSelectedProfession(name);
                        ArmoryTradeSkillFrame_Show();
                    end
                    break;
                end
            end
        elseif ( currentChild.enabled ) then
            currentChild:Show();
        end
    end
end

function ArmoryFrame_OnMouseUp(self, button)
    if ( ArmoryFrame.isMoving ) then
        ArmoryFrame:StopMovingOrSizing();
        ArmoryFrame.isMoving = false;
    end
end

function ArmoryFrame_OnMouseDown(self, button)
    if ( ( ( not ArmoryFrame.isLocked ) or ( ArmoryFrame.isLocked == 0 ) ) and ( button == "LeftButton" ) ) then
        ArmoryFrame:StartMoving();
        ArmoryFrame.isMoving = true;
    end
end

local Orig_GameTooltip_ShowCompareItem = GameTooltip_ShowCompareItem;
function GameTooltip_ShowCompareItem(...)
    if ( ArmoryComparisonTooltip1:IsVisible() or ArmoryComparisonTooltip2:IsVisible() ) then
        return;
    end
    return Orig_GameTooltip_ShowCompareItem(...);
end

local function TooltipGetEquipmentSlot(tooltip)
    local text;
    for i = 1, tooltip:NumLines() do
        text = Armory:GetTooltipText(tooltip, i);
        if ( text == INVTYPE_HEAD ) then
            return "INVTYPE_HEAD";
        elseif ( text == INVTYPE_NECK ) then
            return "INVTYPE_NECK";
        elseif ( text == INVTYPE_SHOULDER ) then
            return "INVTYPE_SHOULDER";
        elseif ( text == INVTYPE_CLOAK ) then
            return "INVTYPE_CLOAK";
        elseif ( text == INVTYPE_CHEST ) then
            return "INVTYPE_CHEST";
        elseif ( text == INVTYPE_ROBE ) then
            return "INVTYPE_ROBE";
        elseif ( text == INVTYPE_BODY ) then
            return "INVTYPE_BODY";
        elseif ( text == INVTYPE_TABARD ) then
            return "INVTYPE_TABARD";
        elseif ( text == INVTYPE_WRIST ) then
            return "INVTYPE_WRIST";
        elseif ( text == INVTYPE_HAND ) then
            return "INVTYPE_HAND";
        elseif ( text == INVTYPE_WAIST ) then
            return "INVTYPE_WAIST";
        elseif ( text == INVTYPE_LEGS ) then
            return "INVTYPE_LEGS";
        elseif ( text == INVTYPE_FEET ) then
            return "INVTYPE_FEET";
        elseif ( text == INVTYPE_FINGER ) then
            return "INVTYPE_FINGER";
        elseif ( text == INVTYPE_TRINKET ) then
            return "INVTYPE_TRINKET";
        elseif ( text == INVTYPE_WEAPONMAINHAND ) then
            return "INVTYPE_WEAPONMAINHAND";
        elseif ( text == INVTYPE_2HWEAPON ) then
            return "INVTYPE_2HWEAPON";
        elseif ( text == INVTYPE_WEAPON ) then
            return "INVTYPE_WEAPON";
        elseif ( text == INVTYPE_WEAPONOFFHAND ) then
            return "INVTYPE_WEAPONOFFHAND";
        elseif ( text == INVTYPE_HOLDABLE ) then
            return "INVTYPE_HOLDABLE";
        elseif ( text == INVTYPE_RANGED ) then
            return "INVTYPE_RANGED";
        elseif ( text == INVTYPE_SHIELD ) then
            return "INVTYPE_SHIELD";
        elseif ( text == INVTYPE_RANGEDRIGHT ) then
            return "INVTYPE_RANGEDRIGHT";
        elseif ( text == INVTYPE_THROWN ) then
            return "INVTYPE_THROWN";
        elseif ( text == INVTYPE_RELIC ) then
            return "INVTYPE_RELIC";
        end
    end
end

function ArmoryComparisonFrame_OnUpdate(self, elapsed)
    local link, tooltip;

    self.updateTime = self.updateTime - elapsed;
    if ( self.updateTime > 0 ) then
        return;
    end
    self.updateTime = TOOLTIP_UPDATE_TIME;

    if ( not Armory:GetConfigShowEqcTooltips() ) then
        return;
    elseif ( GameTooltip:IsVisible() ) then
        tooltip = GameTooltip;
    elseif ( ItemRefTooltip:IsVisible() ) then
        tooltip = ItemRefTooltip;
    elseif ( AtlasLootTooltip and AtlasLootTooltip:IsVisible() ) then
        tooltip = AtlasLootTooltip;
    end
    self.tooltip = tooltip;
    if ( IsAltKeyDown() and tooltip ) then
        local buyable = MerchantFrame and MerchantFrame:IsVisible();
        local learnable = ClassTrainerFrame and ClassTrainerFrame:IsVisible();
        _, link = Armory:GetItemFromTooltip(tooltip);
        if ( not link or buyable or learnable ) then
            link = TooltipGetEquipmentSlot(tooltip);
        end
        if ( self.link ~= link ) then
            self.link = link;
            self.hasShoppingTooltips = ShoppingTooltip1:IsVisible() or ShoppingTooltip2:IsVisible();
            if ( link ) then
                self.hasComparison = true;

                ShoppingTooltip1:Hide();
                ShoppingTooltip2:Hide();

                ArmoryShowCompareItem(tooltip, link);
            else
                ArmoryComparisonTooltip1:Hide();
                ArmoryComparisonTooltip2:Hide();
            end
        end

    elseif ( self.hasComparison ) then
        self.hasComparison = false;
        self.link = nil;

        ArmoryComparisonTooltip1:Hide();
        ArmoryComparisonTooltip2:Hide();

        if ( self.hasShoppingTooltips ) then
            if ( GameTooltip:IsVisible() ) then
                GameTooltip_ShowCompareItem();
            elseif ( AtlasLootTooltip and AtlasLootTooltip:IsVisible() ) then
                if ( AtlasLootItem_ShowCompareItem ) then
                    AtlasLootItem_ShowCompareItem();
                elseif ( AtlasLoot.ItemShowCompareItem ) then
                    AtlasLoot:ItemShowCompareItem();
                end
            end
        end

    end
end

local compareSlots = {};
local relicPattern = "^"..RELIC_TOOLTIP_TYPE:gsub("%%s", "(.+)").."$";
function ArmoryShowCompareItem(tooltip, link)
    ArmoryComparisonTooltip1:Hide();
    ArmoryComparisonTooltip2:Hide();

    if ( (link or "") == ""  ) then
        return;
    end

    local equipLoc, subtype;
    if ( link:find("|H") ) then
        _, _, _, equipLoc, _, _, subtype = GetItemInfoInstant(link);
    else
        equipLoc = link;
    end

    local setItemFunc;
    if ( not equipLoc ) then
        return;

    else
        local slot = ARMORY_SLOTINFO[equipLoc];
        if ( not slot ) then
            return;
        elseif ( slot:match("Finger.Slot") ) then
            compareSlots[1] = "Finger0Slot";
            compareSlots[2] = "Finger1Slot";
        elseif ( slot:match("Trinket.Slot") ) then
            compareSlots[1] = "Trinket0Slot";
            compareSlots[2] = "Trinket1Slot";
        elseif ( slot == "MainHandSlot" or slot == "SecondaryHandSlot" ) then
            compareSlots[1] = "SecondaryHandSlot";
            compareSlots[2] = "MainHandSlot";
        else
            compareSlots[1] = slot;
            compareSlots[2] = nil;
        end

        local slotId = GetInventorySlotInfo(compareSlots[1]);
        local itemLink = Armory:GetInventoryItemLink("player", slotId);
        if ( not itemLink ) then
            compareSlots[1] = compareSlots[2];
            compareSlots[2] = nil;
        end

        setItemFunc = function(tooltip, slot)
            Armory:SetInventoryItem("player", GetInventorySlotInfo(slot), nil, tooltip);
        end
    end
    if ( not compareSlots[1] ) then
        return;
    end

    -- find correct side
    local side = "left";
    local rightDist = 0;
    local leftPos = tooltip:GetLeft();
    local rightPos = tooltip:GetRight();
    if ( not rightPos ) then
        rightPos = 0;
    end
    if ( not leftPos ) then
        leftPos = 0;
    end

    rightDist = GetScreenWidth() - rightPos;

    if (leftPos and (rightDist < leftPos)) then
        side = "left";
    else
        side = "right";
    end

    local setCompareItem = function(index)
        local tooltip = _G["ArmoryComparisonTooltip"..index];
        if ( tooltip and compareSlots[index] ) then
            setItemFunc(tooltip, compareSlots[index]);
            return tooltip:GetWidth();
        end
        return 0;
    end

    -- see if we should slide the tooltip
    if ( tooltip:GetAnchorType() ) then
        local totalWidth = 0;
        for i = 1, 2 do
            if ( compareSlots[i] ) then
                totalWidth = totalWidth + setCompareItem(i);
            end
        end

        if ( (side == "left") and (totalWidth > leftPos) ) then
            tooltip:SetAnchorType(tooltip:GetAnchorType(), (totalWidth - leftPos), 0);
        elseif ( (side == "right") and (rightPos + totalWidth) >  GetScreenWidth() ) then
            tooltip:SetAnchorType(tooltip:GetAnchorType(), -((rightPos + totalWidth) - GetScreenWidth()), 0);
        end
    end

    -- anchor the compare tooltips
    if ( compareSlots[1] ) then
        ArmoryComparisonTooltip1:SetOwner(tooltip, "ANCHOR_NONE");
        ArmoryComparisonTooltip1:SetScale(GameTooltip:GetScale());
        ArmoryComparisonTooltip1:ClearAllPoints();
        if ( side and side == "left" ) then
            ArmoryComparisonTooltip1:SetPoint("TOPRIGHT", tooltip:GetName(), "TOPLEFT", 0, -10);
        else
            ArmoryComparisonTooltip1:SetPoint("TOPLEFT", tooltip:GetName(), "TOPRIGHT", 0, -10);
        end
        setCompareItem(1);

        if ( compareSlots[2] ) then
            ArmoryComparisonTooltip2:SetOwner(ArmoryComparisonTooltip1, "ANCHOR_NONE");
            ArmoryComparisonTooltip2:SetScale(GameTooltip:GetScale());
            ArmoryComparisonTooltip2:ClearAllPoints();
            if ( side and side == "left" ) then
                ArmoryComparisonTooltip2:SetPoint("TOPRIGHT", "ArmoryComparisonTooltip1", "TOPLEFT", 0, 0);
            else
                ArmoryComparisonTooltip2:SetPoint("TOPLEFT", "ArmoryComparisonTooltip1", "TOPRIGHT", 0, 0);
            end
            setCompareItem(2);
        end
    end
end

function Armory_EQC_Refresh()
    local frame = ArmoryComparisonFrame;
    if ( frame.hasComparison ) then
        ArmoryShowCompareItem(frame.tooltip, frame.link);
    end

    if ( EquipCompare_PostClearTooltip ) then
        EquipCompare_PostClearTooltip();
    end
end
