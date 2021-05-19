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

ARMORY_QUESTS_DISPLAYED = 6;
ARMORY_QUESTLOG_QUEST_HEIGHT = 16;
ARMORY_MAX_OBJECTIVES = 10;

function ArmoryQuestLogFrame_Toggle()
    if ( ArmoryQuestLogFrame:IsShown() ) then
        HideUIPanel(ArmoryQuestLogFrame);
    else
        ArmoryCloseChildWindows();
        ShowUIPanel(ArmoryQuestLogFrame);
    end
end

function ArmoryQuestLogTitleButton_OnClick(self, button)
    local questName = self:GetText();
    local questIndex = self:GetID() + FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
    if ( IsModifiedClick() ) then
        -- If header then return
        if ( self.isHeader ) then
            return;
        end
        -- Otherwise put it into chat
        if ( IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() ) then
            ChatEdit_InsertLink(gsub(self:GetText(), " *(.*)", "%1"));
        end
    end
    ArmoryQuestLog_SetSelection(questIndex);
    ArmoryQuestLog_Update();
end

function ArmoryQuestLogTitleButton_OnEnter(self)
    -- Set highlight
    _G[self:GetName().."Tag"]:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
end

function ArmoryQuestLogFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("QUEST_LOG_UPDATE");
    self:RegisterEvent("UPDATE_FACTION");
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED");
end

function ArmoryQuestLogFrame_OnEvent(self, event, ...)
    local arg1 = ...;
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD") then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        if ( Armory.forceScan or not Armory:QuestsExists() ) then
            Armory:Execute(ArmoryQuestLogFrame_UpdateQuests);
        end
    elseif ( event == "UNIT_QUEST_LOG_CHANGED" and arg1 ~= "player" ) then
        return;
    end
    Armory:Execute(ArmoryQuestLogFrame_UpdateQuests);
end

function ArmoryQuestLogFrame_UpdateQuests()
    Armory:UpdateQuests();
    ArmoryQuestLog_Update();
    if ( ArmoryQuestLogFrame:IsVisible() ) then
        ArmoryQuestLog_UpdateQuestDetails(1);
    end
end

function ArmoryQuestLogFrame_OnShow(self)
    PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN);
    Armory:SelectQuestLogEntry(0);
    ArmoryQuestLog_SetSelection(Armory:GetQuestLogSelection());
    ArmoryQuestLog_Update();
end

function ArmoryQuestLogFrame_OnHide(self)
    PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE);
end

function ArmoryQuestLogFrame_OnUpdate(self, elapsed)
    if ( self.hasTimer ) then
        self.timePassed = self.timePassed + elapsed;
        if ( self.timePassed > UPDATE_DELAY ) then
            ArmoryQuestLogTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(Armory:GetQuestLogTimeLeft()));
            self.timePassed = 0;        
        end
    end
end

function ArmoryQuestLog_Update()
    local numEntries, numQuests = Armory:GetNumQuestLogEntries();
    if ( numEntries and numQuests ) then
        if ( numEntries == 0 ) then
            ArmoryEmptyQuestLogFrame:Show();
            ArmoryQuestLogFrame.hasTimer = nil;
            ArmoryQuestLogDetailScrollFrame:Hide();
            ArmoryQuestLogExpandButtonFrame:Hide();
        else
            ArmoryEmptyQuestLogFrame:Hide();
            ArmoryQuestLogDetailScrollFrame:Show();
            ArmoryQuestLogExpandButtonFrame:Show();
        end
    else
        ArmoryQuestLogFrame.hasTimer = nil;
        return;
    end

    -- Update Quest Count
    ArmoryQuestLogQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, numQuests, MAX_QUESTLOG_QUESTS);
    
    -- ScrollFrame update
    FauxScrollFrame_Update(ArmoryQuestLogListScrollFrame, numEntries, ARMORY_QUESTS_DISPLAYED, ARMORY_QUESTLOG_QUEST_HEIGHT, nil, nil, nil, ArmoryQuestLogHighlightFrame, 293, 316 )

    -- Update the quest listing
    ArmoryQuestLogHighlightFrame:Hide();

    -- If no selection then set it to the first available quest
    if ( Armory:GetQuestLogSelection() == 0 ) then
        ArmoryQuestLog_SetFirstValidSelection();
    end

    local questIndex, questLogTitle, questTitleTag, questNormalText, questHighlight;
    local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID;
    local color;
    for i = 1, ARMORY_QUESTS_DISPLAYED do
        questIndex = i + FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
        questLogTitle = _G["ArmoryQuestLogTitle"..i];
        questTitleTag = _G["ArmoryQuestLogTitle"..i.."Tag"];
        questNormalText = _G["ArmoryQuestLogTitle"..i.."NormalText"];
        questHighlight = _G["ArmoryQuestLogTitle"..i.."Highlight"];
        if ( questIndex <= numEntries ) then
			questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID = Armory:GetQuestLogTitle(questIndex);
            if ( isHeader ) then
                if ( questLogTitleText ) then
                    questLogTitle:SetText(questLogTitleText);
                else
                    questLogTitle:SetText("");
                end

                if ( isCollapsed ) then
                    questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
                else
                    questLogTitle:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
                end
                questHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
            else
                questLogTitle:SetText("  "..questLogTitleText);
                questLogTitle:SetNormalTexture("");
                questHighlight:SetTexture("");
            end
            -- Save if its a header or not
            questLogTitle.isHeader = isHeader;

            if ( isComplete and isComplete < 0 ) then
                questTag = FAILED;
            elseif ( isComplete and isComplete > 0 ) then
                questTag = COMPLETE;
            end

            if ( questTag ) then
                questTitleTag:SetText("("..questTag..")");
                -- Shrink text to accommodate quest tags without wrapping
                questNormalText:SetWidth(275 - 15 - questTitleTag:GetWidth());
            else
                questTitleTag:SetText("");
                questNormalText:SetWidth(275);
            end

            -- Color the quest title and highlight according to the difficulty level
            local playerLevel = Armory:UnitLevel("player");
            if ( isHeader ) then
                color = QuestDifficultyColors["header"];
            else
                color = ArmoryGetDifficultyColor(level);
            end
            questTitleTag:SetTextColor(color.r, color.g, color.b);
            questLogTitle:SetNormalFontObject(color.font);
            questLogTitle.r = color.r;
            questLogTitle.g = color.g;
            questLogTitle.b = color.b;
            questLogTitle:Show();

            -- Place the highlight and lock the highlight state
            if ( ArmoryQuestLogFrame.selectedButtonID and Armory:GetQuestLogSelection() == questIndex and not isHeader ) then
                ArmoryQuestLogHighlightFrame:SetPoint("TOPLEFT", "ArmoryQuestLogTitle"..i, "TOPLEFT", 0, 0);
                ArmoryQuestLogSkillHighlight:SetVertexColor(questLogTitle.r, questLogTitle.g, questLogTitle.b);
                ArmoryQuestLogHighlightFrame:Show();
                questTitleTag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
                questLogTitle:LockHighlight();
            else
                questLogTitle:UnlockHighlight();
            end

        else
            questLogTitle:Hide();
        end
    end

    -- Set the expand/collapse all button texture
    local numHeaders = 0;
    local notExpanded = 0;
    -- Somewhat redundant loop, but cleaner than the alternatives
    for i=1, numEntries, 1 do
        local index = i;
        local questLogTitleText, level, questTag, isHeader, isCollapsed = Armory:GetQuestLogTitle(i);
        if ( questLogTitleText and isHeader ) then
            numHeaders = numHeaders + 1;
            if ( isCollapsed ) then
                notExpanded = notExpanded + 1;
            end
        end
    end
    -- If all headers are not expanded then show collapse button, otherwise show the expand button
    if ( notExpanded ~= numHeaders ) then
        ArmoryQuestLogCollapseAllButton.collapsed = nil;
        ArmoryQuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
    else
        ArmoryQuestLogCollapseAllButton.collapsed = 1;
        ArmoryQuestLogCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
    end
end

function ArmoryQuestLog_SetSelection(questID)
    local selectedQuest;
    if ( questID == 0 ) then
        ArmoryQuestLogDetailScrollFrame:Hide();
        return;
    end

    -- Get xml id
    local id = questID - FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);

    Armory:SelectQuestLogEntry(questID);
    local titleButton = _G["ArmoryQuestLogTitle"..id];
    local titleButtonTag = _G["ArmoryQuestLogTitle"..id.."Tag"];
    local questLogTitleText, level, questTag, isHeader, isCollapsed = Armory:GetQuestLogTitle(questID);
    if ( isHeader ) then
        ArmoryQuestLogHighlightFrame:Hide();
        if ( isCollapsed ) then
            Armory:ExpandQuestHeader(questID);
        else
            Armory:CollapseQuestHeader(questID);
        end
        questIndex = ArmoryQuestLog_GetFirstSelectableQuest();
        ArmoryQuestLog_SetSelection(questIndex);
        return;
    else
        -- Set newly selected quest and highlight it
        ArmoryQuestLogFrame.selectedButtonID = questID;
        local scrollFrameOffset = FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
        if ( questID > scrollFrameOffset and questID <= (scrollFrameOffset + ARMORY_QUESTS_DISPLAYED) and questID <= Armory:GetNumQuestLogEntries() ) then
            titleButton:LockHighlight();
            titleButtonTag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            ArmoryQuestLogSkillHighlight:SetVertexColor(titleButton.r, titleButton.g, titleButton.b);
            ArmoryQuestLogHighlightFrame:SetPoint("TOPLEFT", "ArmoryQuestLogTitle"..id, "TOPLEFT", 5, 0);
            ArmoryQuestLogHighlightFrame:Show();
        end
    end
    ArmoryQuestLog_UpdateQuestDetails();
end

function ArmoryQuestLog_UpdateQuestDetails(doNotScroll)
    local questID = Armory:GetQuestLogSelection();
    local questTitle = Armory:GetQuestLogTitle(questID);
    local spacerFrame = ArmoryQuestLogSpacerFrame;

    if ( not questTitle ) then
        questTitle = "";
    end
    if ( Armory:IsCurrentQuestFailed() ) then
        questTitle = questTitle.." - ("..FAILED..")";
    end
    ArmoryQuestLogQuestTitle:SetText(questTitle);

    local questDescription;
    local questObjectives;
    questDescription, questObjectives = Armory:GetQuestLogQuestText();
    ArmoryQuestLogObjectivesText:SetText(questObjectives);

    local questTimer = Armory:GetQuestLogTimeLeft();
    if ( questTimer ) then
        ArmoryQuestLogFrame.hasTimer = 1;
        ArmoryQuestLogFrame.timePassed = 0;
        ArmoryQuestLogTimerText:Show();
        ArmoryQuestLogTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(questTimer));
        ArmoryQuestLogObjective1:SetPoint("TOPLEFT", "ArmoryQuestLogTimerText", "BOTTOMLEFT", 0, -10);
    else
        ArmoryQuestLogFrame.hasTimer = nil;
        ArmoryQuestLogTimerText:Hide();
        ArmoryQuestLogObjective1:SetPoint("TOPLEFT", "ArmoryQuestLogObjectivesText", "BOTTOMLEFT", 0, -10);
    end

    local numObjectives = Armory:GetNumQuestLeaderBoards();
    for i = 1, numObjectives do
        local string = _G["ArmoryQuestLogObjective"..i];
        local text, type, finished = Armory:GetQuestLogLeaderBoard(i);
        if ( not text or strlen(text) == 0 ) then
            text = type;
        end
        if ( finished ) then
            string:SetTextColor(0.2, 0.2, 0.2);
            text = text.." ("..COMPLETE..")";
        else
            string:SetTextColor(0, 0, 0);
        end
        string:SetText(text);
        string:Show();
        QuestFrame_SetAsLastShown(string, spacerFrame);
    end

    for i=numObjectives + 1, ARMORY_MAX_OBJECTIVES, 1 do
        _G["ArmoryQuestLogObjective"..i]:Hide();
    end
    -- If there's money required then anchor and display it
    if ( Armory:GetQuestLogRequiredMoney() > 0 ) then
        if ( numObjectives > 0 ) then
            ArmoryQuestLogRequiredMoneyText:SetPoint("TOPLEFT", "ArmoryQuestLogObjective"..numObjectives, "BOTTOMLEFT", 0, -4);
        else
            ArmoryQuestLogRequiredMoneyText:SetPoint("TOPLEFT", "ArmoryQuestLogObjectivesText", "BOTTOMLEFT", 0, -10);
        end

        MoneyFrame_Update("ArmoryQuestLogRequiredMoneyFrame", Armory:GetQuestLogRequiredMoney());

        if ( Armory:GetQuestLogRequiredMoney() > Armory:GetMoney() ) then
            -- Not enough money
            ArmoryQuestLogRequiredMoneyText:SetTextColor(0, 0, 0);
            SetMoneyFrameColor("ArmoryQuestLogRequiredMoneyFrame", "red");
        else
            ArmoryQuestLogRequiredMoneyText:SetTextColor(0.2, 0.2, 0.2);
            SetMoneyFrameColor("ArmoryQuestLogRequiredMoneyFrame", "white");
        end
        ArmoryQuestLogRequiredMoneyText:Show();
        ArmoryQuestLogRequiredMoneyFrame:Show();
    else
        ArmoryQuestLogRequiredMoneyText:Hide();
        ArmoryQuestLogRequiredMoneyFrame:Hide();
    end

	if ( Armory:GetQuestLogRequiredMoney() > 0 ) then
		ArmoryQuestLogDescriptionTitle:SetPoint("TOPLEFT", "ArmoryQuestLogRequiredMoneyText", "BOTTOMLEFT", 0, -10);
	elseif ( numObjectives > 0 ) then
		ArmoryQuestLogDescriptionTitle:SetPoint("TOPLEFT", "ArmoryQuestLogObjective"..numObjectives, "BOTTOMLEFT", 0, -10);
	else
		if ( questTimer ) then
			ArmoryQuestLogDescriptionTitle:SetPoint("TOPLEFT", "ArmoryQuestLogTimerText", "BOTTOMLEFT", 0, -10);
		else
			ArmoryQuestLogDescriptionTitle:SetPoint("TOPLEFT", "ArmoryQuestLogObjectivesText", "BOTTOMLEFT", 0, -10);
		end
	end
    if ( questDescription ) then
        ArmoryQuestLogQuestDescription:SetText(questDescription);
        QuestFrame_SetAsLastShown(ArmoryQuestLogQuestDescription, spacerFrame);
    end
    local numRewards = Armory:GetNumQuestLogRewards();
    local numChoices = Armory:GetNumQuestLogChoices();
    local money = Armory:GetQuestLogRewardMoney();

    if ( (numRewards + numChoices + money) > 0 ) then
        ArmoryQuestLogRewardTitleText:Show();
        QuestFrame_SetAsLastShown(ArmoryQuestLogRewardTitleText, spacerFrame);
    else
        ArmoryQuestLogRewardTitleText:Hide();
    end

    ArmoryQuestFrameItems_Update();
    if ( not doNotScroll ) then
        ArmoryQuestLogDetailScrollFrameScrollBar:SetValue(0);
    end
    ArmoryQuestLogDetailScrollFrame:UpdateScrollChildRect();
end

function ArmoryQuestLogCollapseAllButton_OnClick(self)
    if (self.collapsed) then
        self.collapsed = nil;
        Armory:ExpandQuestHeader(0);
    else
        self.collapsed = 1;
        ArmoryQuestLogListScrollFrameScrollBar:SetValue(0);
        Armory:CollapseQuestHeader(0);
    end
    local questIndex = ArmoryQuestLog_GetFirstSelectableQuest();
    ArmoryQuestLog_SetSelection(questIndex);
    ArmoryQuestLog_Update();
end

function ArmoryQuestLogFrameEditBox_OnTextChanged(self)
    SearchBoxTemplate_OnTextChanged(self);

    local text = self:GetText();
    local refresh;

    refresh = Armory:SetQuestLogFilter(text);
    if ( refresh ) then
        Armory:ExpandQuestHeader(0);
        Armory:SelectQuestLogEntry(0);
        ArmoryQuestLog_Update();
    end
end

function ArmoryQuestLog_SetFirstValidSelection()
    local selectableQuest = ArmoryQuestLog_GetFirstSelectableQuest();
    ArmoryQuestLog_SetSelection(selectableQuest);
    ArmoryQuestLogListScrollFrameScrollBar:SetValue(0);
end

function ArmoryQuestLog_GetFirstSelectableQuest()
    local numEntries = Armory:GetNumQuestLogEntries();
    local index = 0;
    local questLogTitleText, level, questTag, isHeader, isCollapsed ;
    for i = 1, numEntries do
        index = i;
        questLogTitleText, level, questTag, isHeader, isCollapsed = Armory:GetQuestLogTitle(i);
        if ( questLogTitleText and not isHeader ) then
            return index;
        end
    end
    return 0;
end

-- Used for quests and enemy coloration
function ArmoryGetDifficultyColor(level)
	return GetRelativeDifficultyColor(Armory:UnitLevel("player"), level);
end

function ArmoryQuestFrameItems_Update()
    -----------------
    -- QuestFrame ---
    -----------------
    local numQuestRewards = Armory:GetNumQuestLogRewards();
    local numQuestChoices = Armory:GetNumQuestLogChoices();
    local numQuestSpellRewards = 0;
    local money = Armory:GetQuestLogRewardMoney();
    local spacerFrame = ArmoryQuestLogSpacerFrame;
    local questState = "ArmoryQuestLog";

    if ( Armory:GetQuestLogRewardSpell() ) then
        numQuestSpellRewards = 1;
    end

    local totalRewards = numQuestRewards + numQuestChoices + numQuestSpellRewards;
    local questItemName = questState.."Item";
    local material = "Parchment";
    local questItemReceiveText = _G[questState.."ItemReceiveText"];
    local moneyFrame = _G[questState.."MoneyFrame"];

    if ( totalRewards == 0 and money == 0 ) then
        _G[questState.."RewardTitleText"]:Hide();
    else
        _G[questState.."RewardTitleText"]:Show();
        QuestFrame_SetTitleTextColor(_G[questState.."RewardTitleText"], material);
        QuestFrame_SetAsLastShown(_G[questState.."RewardTitleText"], spacerFrame);
    end
    if ( money == 0 ) then
        moneyFrame:Hide();
    else
        moneyFrame:Show();
        QuestFrame_SetAsLastShown(moneyFrame, spacerFrame);
        MoneyFrame_Update(questState.."MoneyFrame", money);
    end

    -- Hide unused rewards
    for i = totalRewards + 1, MAX_NUM_ITEMS do
        _G[questItemName..i]:Hide();
    end

    local questItem, name, texture, isTradeskillSpell, quality, isUsable, numItems = 1;
    local rewardsCount = 0;

    -- Setup choosable rewards
    if ( numQuestChoices > 0 ) then
        local itemChooseText = _G[questState.."ItemChooseText"];
        itemChooseText:Show();
        QuestFrame_SetTextColor(itemChooseText, material);
        QuestFrame_SetAsLastShown(itemChooseText, spacerFrame);

        local index;
        local baseIndex = rewardsCount;
        for i=1, numQuestChoices, 1 do    
            index = i + baseIndex;
            questItem = _G[questItemName..index];
            questItem.type = "choice";
            numItems = 1;
            name, texture, numItems, quality, isUsable = Armory:GetQuestLogChoiceInfo(i);

            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.rewardType = "item"
            QuestFrame_SetAsLastShown(questItem, spacerFrame);
            _G[questItemName..index.."Name"]:SetText(name);
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            if ( isUsable ) then
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
                SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
            end
            if ( i > 1 ) then
                if ( mod(i,2) == 1 ) then
                    questItem:SetPoint("TOPLEFT", questItemName..(index - 2), "BOTTOMLEFT", 0, -2);
                else
                    questItem:SetPoint("TOPLEFT", questItemName..(index - 1), "TOPRIGHT", 1, 0);
                end
            else
                questItem:SetPoint("TOPLEFT", itemChooseText, "BOTTOMLEFT", -3, -5);
            end
            Armory:SetItemLink(questItem, Armory:GetQuestLogItemLink(questItem.type, i));
            rewardsCount = rewardsCount + 1;
        end
    else
        _G[questState.."ItemChooseText"]:Hide();
    end

    -- Setup spell rewards
    if ( numQuestSpellRewards > 0 ) then
        local learnSpellText = _G[questState.."SpellLearnText"];
        learnSpellText:Show();
        QuestFrame_SetTextColor(learnSpellText, material);
        QuestFrame_SetAsLastShown(learnSpellText, spacerFrame);

        --Anchor learnSpellText if there were choosable rewards
        if ( rewardsCount > 0 ) then
            learnSpellText:SetPoint("TOPLEFT", questItemName..rewardsCount, "BOTTOMLEFT", 3, -5);
        else
            learnSpellText:SetPoint("TOPLEFT", questState.."RewardTitleText", "BOTTOMLEFT", 0, -5);
        end

        texture, name, isTradeskillSpell = Armory:GetQuestLogRewardSpell();
        if ( isTradeskillSpell ) then
            learnSpellText:SetText(REWARD_TRADESKILL_SPELL);
        else
            learnSpellText:SetText(REWARD_SPELL);
        end

        rewardsCount = rewardsCount + 1;
        questItem = _G[questItemName..rewardsCount];
        questItem:Show();
        -- For the tooltip
        questItem.rewardType = "spell";
        SetItemButtonCount(questItem, 0);
        SetItemButtonTexture(questItem, texture);
        _G[questItemName..rewardsCount.."Name"]:SetText(name);
        questItem:SetPoint("TOPLEFT", learnSpellText, "BOTTOMLEFT", -3, -5);
    else
        _G[questState.."SpellLearnText"]:Hide();
    end

    -- Setup mandatory rewards
    if ( numQuestRewards > 0 or money > 0 ) then
        QuestFrame_SetTextColor(questItemReceiveText, material);
        -- Anchor the reward text differently if there are choosable rewards
        if ( numQuestSpellRewards > 0  ) then
            questItemReceiveText:SetText(REWARD_ITEMS);
            questItemReceiveText:SetPoint("TOPLEFT", questItemName..rewardsCount, "BOTTOMLEFT", 3, -5);        
        elseif ( numQuestChoices > 0  ) then
            questItemReceiveText:SetText(REWARD_ITEMS);
            local index = numQuestChoices;
            if ( mod(index, 2) == 0 ) then
                index = index - 1;
            end
            questItemReceiveText:SetPoint("TOPLEFT", questItemName..index, "BOTTOMLEFT", 3, -5);
        else 
            questItemReceiveText:SetText(REWARD_ITEMS_ONLY);
            questItemReceiveText:SetPoint("TOPLEFT", questState.."RewardTitleText", "BOTTOMLEFT", 3, -5);
        end
        questItemReceiveText:Show();
        QuestFrame_SetAsLastShown(questItemReceiveText, spacerFrame);

        -- Setup mandatory rewards
        local index;
        local baseIndex = rewardsCount;
        for i = 1, numQuestRewards do
            index = i + baseIndex;
            questItem = _G[questItemName..index];
            questItem.type = "reward";
            numItems = 1;
            name, texture, numItems, quality, isUsable = Armory:GetQuestLogRewardInfo(i);
            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.rewardType = "item";
            QuestFrame_SetAsLastShown(questItem, spacerFrame);
            _G[questItemName..index.."Name"]:SetText(name);
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            if ( isUsable ) then
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                SetItemButtonTextureVertexColor(questItem, 0.5, 0, 0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 0, 0);
            end

            if ( i > 1 ) then
                if ( mod(i,2) == 1 ) then
                    questItem:SetPoint("TOPLEFT", questItemName..(index - 2), "BOTTOMLEFT", 0, -2);
                else
                    questItem:SetPoint("TOPLEFT", questItemName..(index - 1), "TOPRIGHT", 1, 0);
                end
            else
                questItem:SetPoint("TOPLEFT", questState.."ItemReceiveText", "BOTTOMLEFT", -3, -5);
            end
            Armory:SetItemLink(questItem, Armory:GetQuestLogItemLink(questItem.type, i));
            rewardsCount = rewardsCount + 1;
        end
    else    
        questItemReceiveText:Hide();
    end
end
