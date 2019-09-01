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

local REWARDS_SECTION_OFFSET = 5;        -- vertical distance between sections

local SEAL_QUESTS = {
    [40519] = { bgAtlas = "QuestBG-Alliance", text = "|cff042c54"..QUEST_KING_VARIAN_WRYNN.."|r", sealAtlas = "Quest-Alliance-WaxSeal"},
    [43926] = { bgAtlas = "QuestBG-Horde", text = "|cff480404"..QUEST_WARCHIEF_VOLJIN.."|r", sealAtlas = "Quest-Horde-WaxSeal"},
	[46730] = { bgAtlas = "QuestBG-Legionfall", text = "|cff2f0a48"..QUEST_KHADGAR.."|r", sealAtlas = "Quest-Legionfall-WaxSeal"},
};

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
            local questLink = Armory:GetQuestLink(questIndex);
            if ( questLink ) then
                ChatEdit_InsertLink(questLink);
            end
        end
    end
    ArmoryQuestLog_SetSelection(questIndex);
    ArmoryQuestLog_Update();
end

function ArmoryQuestLogTitleButton_OnEnter(self)
    -- Set highlight
    self.tag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
end

function ArmoryQuestLogTitleButton_OnLeave(self)
    if ( ArmoryQuestLogFrame.selectedButtonID and (self:GetID() ~= (ArmoryQuestLogFrame.selectedButtonID - FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame))) ) then
        self.tag:SetTextColor(self.r, self.g, self.b);
    end
    GameTooltip:Hide();
end

function ArmoryQuestLogFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("QUEST_LOG_UPDATE");
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
    else
        Armory:Execute(ArmoryQuestLogFrame_UpdateQuests);
    end
end

function ArmoryQuestLogFrame_UpdateQuests()
    Armory:UpdateQuests();
    ArmoryQuestLog_Update();
    if ( ArmoryQuestLogDetailScrollFrame:IsVisible() ) then
        ArmoryQuestLog_UpdateQuestDetails(false);
    end
end

function ArmoryQuestLogFrame_OnShow(self)
    Armory:SelectQuestLogEntry(0);
    ArmoryQuestLog_SetSelection(Armory:GetQuestLogSelection());
    ArmoryQuestLog_Update();
end

function ArmoryQuestInfoTimerFrame_OnUpdate(self, elapsed)
    if ( self.timeLeft ) then
        self.timeLeft = max(self.timeLeft - elapsed, 0);
        ArmoryQuestInfoTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(self.timeLeft));
    end
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
    ArmoryQuestLog_Update();
end

function ArmoryQuestLog_Update()
    if ( not ArmoryQuestLogFrame:IsShown() ) then
        return;
    end

    local numEntries, numQuests = Armory:GetNumQuestLogEntries();
    if ( numQuests == 0 ) then
        ArmoryEmptyQuestLogFrame:Show();
        ArmoryQuestLogDetailScrollFrame:Hide();
        ArmoryQuestLogExpandButtonFrame:Hide();
    else
        ArmoryEmptyQuestLogFrame:Hide();
        ArmoryQuestLogDetailScrollFrame:Show();
        ArmoryQuestLogExpandButtonFrame:Show();
    end

    -- Update Quest Count
    ArmoryQuestLogUpdateQuestCount(numQuests);

    -- ScrollFrame update
    FauxScrollFrame_Update(ArmoryQuestLogListScrollFrame, numEntries, ARMORY_QUESTS_DISPLAYED, ARMORY_QUESTLOG_QUEST_HEIGHT, nil, nil, nil, ArmoryQuestLogHighlightFrame, 293, 316 )

    -- Update the quest listing
    ArmoryQuestLogHighlightFrame:Hide();

    -- If no selection then set it to the first available quest
    if ( Armory:GetQuestLogSelection() == 0 ) then
        ArmoryQuestLog_SetFirstValidSelection();
    end

    local questIndex, questLogTitle, questTag, questTitleTag, questNormalText, questHighlight;
    local questLogTitleText, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, color, questID, displayQuestID;

    for i = 1, ARMORY_QUESTS_DISPLAYED do
        questIndex = i + FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
        questLogTitle = _G["ArmoryQuestLogTitle"..i];
        questTitleTag = _G["ArmoryQuestLogTitle"..i.."Tag"];
        questNormalText = _G["ArmoryQuestLogTitle"..i.."NormalText"];
        questHighlight = _G["ArmoryQuestLogTitle"..i.."Highlight"];
        if ( questIndex <= numEntries ) then
            questLogTitleText, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, _, displayQuestID = Armory:GetQuestLogTitle(questIndex);
            -- title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory
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
                if ( questID and displayQuestID ) then
                    questLogTitle:SetText("  "..questID.." - "..questLogTitleText);
                else
                    questLogTitle:SetText("  "..questLogTitleText);
                end
                if ( questID and C_CampaignInfo.IsCampaignQuest(questID) ) then
                    local faction = Armory:UnitFactionGroup("player");
                    local coords = faction == "Horde" and QUEST_TAG_TCOORDS.HORDE or QUEST_TAG_TCOORDS.ALLIANCE;
                    questLogTitle:SetNormalTexture(QUEST_ICONS_FILE);
                    questLogTitle:GetNormalTexture():SetTexCoord( unpack(coords) );
                else
                    questLogTitle:SetNormalTexture("");
                    questLogTitle:GetNormalTexture():SetTexCoord(0, 1, 0, 1);
                end
                questHighlight:SetTexture("");
            end
            -- Save if its a header or not
            questLogTitle.isHeader = isHeader;
            
            local questTag = ArmoryQuestLog_GetQuestTag(questID, isComplete, frequency);
            if ( questTag ) then
                questTitleTag:SetText("("..questTag..")");
                -- Shrink text to accomdate quest tags without wrapping
                questNormalText:SetWidth(275 - 15 - questTitleTag:GetWidth());
            else
                questTitleTag:SetText("");
                questNormalText:SetWidth(275);
            end

            -- Color the quest title and highlight according to the difficulty level
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
            if ( ArmoryQuestLogFrame.selectedButtonID and Armory:GetQuestLogSelection() == questIndex ) then
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
        questLogTitleText, _, _, isHeader, isCollapsed = Armory:GetQuestLogTitle(i);
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

function ArmoryQuestLog_GetQuestTag(questID, isComplete, frequency)
    local questTagID, questTag = GetQuestTagInfo(questID);
    if ( isComplete and isComplete < 0 ) then
        questTag = FAILED;
    elseif ( isComplete and isComplete > 0 ) then
        questTag = COMPLETE;
    elseif( questTagID and questTagID == Enum.QuestTag.Account ) then
        local factionGroup = GetQuestFactionGroup(questID);
        if( factionGroup ) then
            questTag = FACTION_ALLIANCE;
            if ( factionGroup == LE_QUEST_FACTION_HORDE ) then
                questTag = FACTION_HORDE;
            end
        end
    elseif( frequency == LE_QUEST_FREQUENCY_DAILY and (not isComplete or isComplete == 0) ) then
        questTag = DAILY;
    elseif( frequency == LE_QUEST_FREQUENCY_WEEKLY and (not isComplete or isComplete == 0) )then
        questTag = WEEKLY;
    end
    return questTag;
end

function ArmoryQuestLog_SetSelection(questIndex)
    local selectedQuest;

    if ( questIndex == 0 ) then
        ArmoryQuestLogDetailScrollFrame:Hide();
        return;
    end

    -- Get xml id
    local id = questIndex - FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);

    Armory:SelectQuestLogEntry(questIndex);
    local titleButton = _G["ArmoryQuestLogTitle"..id];
    local titleButtonTag = _G["ArmoryQuestLogTitle"..id.."Tag"];
    local questLogTitleText, level, suggestedGroup, isHeader, isCollapsed = Armory:GetQuestLogTitle(questIndex);
    if ( isHeader ) then
        if ( isCollapsed ) then
            Armory:ExpandQuestHeader(questIndex);
        else
            Armory:CollapseQuestHeader(questIndex);
        end
        if ( not ArmoryQuestLogFrame.selectedButtonID ) then
            questIndex = ArmoryQuestLog_GetFirstSelectableQuest();
            ArmoryQuestLog_SetSelection(questIndex);
        end
        return;
    else
        -- Set newly selected quest and highlight it
        ArmoryQuestLogFrame.selectedButtonID = questIndex;
        local scrollFrameOffset = FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
        if ( questIndex > scrollFrameOffset and questIndex <= (scrollFrameOffset + ARMORY_QUESTS_DISPLAYED) and questIndex <= Armory:GetNumQuestLogEntries() ) then
            titleButton:LockHighlight();
            titleButtonTag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            --QuestLogSkillHighlight:SetVertexColor(titleButton.r, titleButton.g, titleButton.b);
            ArmoryQuestLogHighlightFrame:SetPoint("TOPLEFT", "ArmoryQuestLogTitle"..id, "TOPLEFT", 5, 0);
            ArmoryQuestLogHighlightFrame:Show();
        end
    end
    ArmoryQuestLog_UpdateQuestDetails(true);
end

function ArmoryQuestLog_UpdateQuestDetails(resetScrollBar)
    ArmoryQuestInfo_Display(ARMORY_QUEST_TEMPLATE_LOG, ArmoryQuestLogDetailScrollChildFrame);
    
    if ( resetScrollBar ) then
        ArmoryQuestLogDetailScrollFrameScrollBar:SetValue(0);
    end    
    ArmoryQuestLogDetailScrollFrame:Show();
end

function ArmoryQuestLogUpdateQuestCount(numQuests)
    if (numQuests > MAX_QUESTLOG_QUESTS) then
        ArmoryQuestLogQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, RED_FONT_COLOR_CODE, numQuests, MAX_QUESTLOG_QUESTS);
    else
        ArmoryQuestLogQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, "|cffffffff", numQuests, MAX_QUESTLOG_QUESTS);
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
    local questLogTitleText, isHeader;
    for i = 1, numEntries do
        index = i;
        questLogTitleText, _, _, isHeader = Armory:GetQuestLogTitle(i);
        if ( questLogTitleText and not isHeader ) then
            return index;
        end
    end
    return 0;
end

function ArmoryQuestInfo_ToggleRewardElement(frame, value, anchor)
    if ( value and tonumber(value) ~= 0 ) then
        frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
        frame.ValueText:SetText(value);
        frame:Show();
        return true;
    else
        frame:Hide();
    end
end

function ArmoryQuestInfo_Display(template, parentFrame)
    local questID = select(8, Armory:GetQuestLogTitle(Armory:GetQuestLogSelection()));
    ArmoryQuestInfoSealFrame.sealInfo = SEAL_QUESTS[questID];

    if ( ArmoryQuestInfoFrame.material ~= material ) then
        ArmoryQuestInfoFrame.material = material;    
        local textColor, titleTextColor = GetMaterialTextColors(material);    
        -- headers
        ArmoryQuestInfoTitleHeader:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
        ArmoryQuestInfoDescriptionHeader:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
        ArmoryQuestInfoObjectivesHeader:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
        ArmoryQuestInfoRewardsFrame.Header:SetTextColor(titleTextColor[1], titleTextColor[2], titleTextColor[3]);
        -- other text
        ArmoryQuestInfoDescriptionText:SetTextColor(textColor[1], textColor[2], textColor[3]);
        ArmoryQuestInfoObjectivesText:SetTextColor(textColor[1], textColor[2], textColor[3]);
        ArmoryQuestInfoGroupSize:SetTextColor(textColor[1], textColor[2], textColor[3]);
        ArmoryQuestInfoRewardText:SetTextColor(textColor[1], textColor[2], textColor[3]);
        -- reward frame text
        ArmoryQuestInfoRewardsFrame.ItemChooseText:SetTextColor(textColor[1], textColor[2], textColor[3]);
        ArmoryQuestInfoRewardsFrame.ItemReceiveText:SetTextColor(textColor[1], textColor[2], textColor[3]);
        ArmoryQuestInfoRewardsFrame.PlayerTitleText:SetTextColor(textColor[1], textColor[2], textColor[3]);        
        ArmoryQuestInfoRewardsFrame.XPFrame.ReceiveText:SetTextColor(textColor[1], textColor[2], textColor[3]);

        ArmoryQuestInfoRewardsFrame.spellHeaderPool.textR, ArmoryQuestInfoRewardsFrame.spellHeaderPool.textG, ArmoryQuestInfoRewardsFrame.spellHeaderPool.textB = textColor[1], textColor[2], textColor[3];
    end

    local elementsTable = template.elements;
    local lastFrame;
    for i = 1, #elementsTable, 3 do
        local shownFrame, bottomShownFrame = elementsTable[i](parentFrame);
        if ( shownFrame ) then
            shownFrame:SetParent(parentFrame);
            shownFrame:ClearAllPoints();
            if ( lastFrame ) then
                shownFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", elementsTable[i+1], elementsTable[i+2]);
            else
                shownFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", elementsTable[i+1], elementsTable[i+2]);            
            end
            lastFrame = bottomShownFrame or shownFrame;
        end
    end
end

function ArmoryQuestInfo_ShowTitle()
    local questTitle = Armory:GetQuestLogTitle(Armory:GetQuestLogSelection());
    if ( not questTitle ) then
        questTitle = "";
    end
    if ( Armory:IsCurrentQuestFailed() ) then
        questTitle = questTitle.." - ("..FAILED..")";
    end
    ArmoryQuestInfoTitleHeader:SetText(questTitle);
    return ArmoryQuestInfoTitleHeader;
end

function ArmoryQuestInfo_ShowType()
    local questID = select(8, Armory:GetQuestLogTitle(Armory:GetQuestLogSelection()));
    local questTypeMarkup = QuestUtils_GetQuestTypeTextureMarkupString(questID);
    local showType = questTypeMarkup ~= nil;

    ArmoryQuestInfoQuestType:SetShown(showType);

    if ( showType ) then
        ArmoryQuestInfoQuestType:SetText(questTypeMarkup);
        return ArmoryQuestInfoQuestType;
    end
end

function ArmoryQuestInfo_ShowDescriptionText()
    local questDescription = Armory:GetQuestLogQuestText();
    ArmoryQuestInfoDescriptionText:SetText(questDescription);
    return ArmoryQuestInfoDescriptionText;
end

function ArmoryQuestInfo_ShowObjectives()
    local numObjectives = Armory:GetNumQuestLeaderBoards();
    local objective;
    local text, type, finished;
    local objectivesTable = ArmoryQuestInfoObjectivesFrame.Objectives;
    local numVisibleObjectives = 0;
    for i = 1, numObjectives do
        text, type, finished = Armory:GetQuestLogLeaderBoard(i);
        if ( type ~= "spell" and type ~= "log" and numVisibleObjectives < MAX_OBJECTIVES ) then
            numVisibleObjectives = numVisibleObjectives + 1;
            objective = objectivesTable[numVisibleObjectives];
            if ( not objective ) then
                objective = ArmoryQuestInfoObjectivesFrame:CreateFontString("ArmoryQuestInfoObjective"..numVisibleObjectives, "BACKGROUND", "QuestFontNormalSmall");
                objective:SetPoint("TOPLEFT", objectivesTable[numVisibleObjectives - 1], "BOTTOMLEFT", 0, -2);
                objective:SetJustifyH("LEFT");
                objective:SetWidth(285);
                objectivesTable[numVisibleObjectives] = objective;
            end
            if ( not text or strlen(text) == 0 ) then
                text = type;
            end
            if ( finished ) then
                objective:SetTextColor(0.2, 0.2, 0.2);
                text = text.." ("..COMPLETE..")";
            else
                objective:SetTextColor(0, 0, 0);
            end
            objective:SetText(text);
            objective:Show();
        end
    end
    for i = numVisibleObjectives + 1, #objectivesTable do
        objectivesTable[i]:Hide();
    end
    if ( objective ) then
        ArmoryQuestInfoObjectivesFrame:Show();
        return ArmoryQuestInfoObjectivesFrame, objective;
    else
        ArmoryQuestInfoObjectivesFrame:Hide();
        return nil;
    end
end

function ArmoryQuestInfo_ShowSpecialObjectives()
    -- Show objective spell
    local spellID, spellName, spellTexture, finished = Armory:GetQuestLogCriteriaSpell();

    local lastFrame = nil;
    local totalHeight = 0;

    if ( spellID ) then
        ArmoryQuestInfoSpellObjectiveFrame.Icon:SetTexture(spellTexture);
        ArmoryQuestInfoSpellObjectiveFrame.Name:SetText(spellName);
        ArmoryQuestInfoSpellObjectiveFrame.spellID = spellID;

        ArmoryQuestInfoSpellObjectiveFrame:ClearAllPoints();
        if ( lastFrame ) then
            ArmoryQuestInfoSpellObjectiveLearnLabel:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -4);
            totalHeight = totalHeight + 4;
        else
            ArmoryQuestInfoSpellObjectiveLearnLabel:SetPoint("TOPLEFT", 0, 0);
        end

        ArmoryQuestInfoSpellObjectiveFrame:SetPoint("TOPLEFT", ArmoryQuestInfoSpellObjectiveLearnLabel, "BOTTOMLEFT", 0, -4);

        if ( finished ) then -- don't show as completed for the initial offer, as it won't update properly
            ArmoryQuestInfoSpellObjectiveLearnLabel:SetText(LEARN_SPELL_OBJECTIVE.." ("..COMPLETE..")");
            ArmoryQuestInfoSpellObjectiveLearnLabel:SetTextColor(0.2, 0.2, 0.2);
        else
            ArmoryQuestInfoSpellObjectiveLearnLabel:SetText(LEARN_SPELL_OBJECTIVE);
            ArmoryQuestInfoSpellObjectiveLearnLabel:SetTextColor(0, 0, 0);
        end

        ArmoryQuestInfoSpellObjectiveLearnLabel:Show();
        ArmoryQuestInfoSpellObjectiveFrame:Show();
        totalHeight = totalHeight + ArmoryQuestInfoSpellObjectiveFrame:GetHeight() + ArmoryQuestInfoSpellObjectiveLearnLabel:GetHeight();
        lastFrame = ArmoryQuestInfoSpellObjectiveFrame;
    else
        ArmoryQuestInfoSpellObjectiveFrame:Hide();
        ArmoryQuestInfoSpellObjectiveLearnLabel:Hide();
    end

    if ( lastFrame ) then
        ArmoryQuestInfoSpecialObjectivesFrame:SetHeight(totalHeight);
        ArmoryQuestInfoSpecialObjectivesFrame:Show();
        return ArmoryQuestInfoSpecialObjectivesFrame;
    else
        ArmoryQuestInfoSpecialObjectivesFrame:Hide();
        return nil;
    end
end

function ArmoryQuestInfo_ShowTimer()
    local timeLeft = Armory:GetQuestLogTimeLeft();
    ArmoryQuestInfoTimerFrame.timeLeft = timeLeft;
    if ( timeLeft ) then
        ArmoryQuestInfoTimerText:SetText(TIME_REMAINING.." "..SecondsToTime(timeLeft));
        ArmoryQuestInfoTimerFrame:SetHeight(ArmoryQuestInfoTimerFrame:GetTop() - ArmoryQuestInfoTimerText:GetTop() + ArmoryQuestInfoTimerText:GetHeight());
        ArmoryQuestInfoTimerFrame:Show();
        return ArmoryQuestInfoTimerFrame;
    else
        ArmoryQuestInfoTimerFrame:Hide();
        return nil;
    end
end

function ArmoryQuestInfo_ShowRequiredMoney()
    local requiredMoney = Armory:GetQuestLogRequiredMoney();
    if ( requiredMoney > 0 ) then
        MoneyFrame_Update("ArmoryQuestInfoRequiredMoneyDisplay", requiredMoney);
        if ( requiredMoney > Armory:GetMoney() ) then
            -- Not enough money
            ArmoryQuestInfoRequiredMoneyText:SetTextColor(0, 0, 0);
            SetMoneyFrameColor("ArmoryQuestInfoRequiredMoneyDisplay", "red");
        else
            ArmoryQuestInfoRequiredMoneyText:SetTextColor(0.2, 0.2, 0.2);
            SetMoneyFrameColor("ArmoryQuestInfoRequiredMoneyDisplay", "white");
        end
        ArmoryQuestInfoRequiredMoneyFrame:Show();
        return ArmoryQuestInfoRequiredMoneyFrame;
    else
        ArmoryQuestInfoRequiredMoneyFrame:Hide();
        return nil;
    end
end

function ArmoryQuestInfo_ShowGroupSize()
    local groupNum = Armory:GetQuestLogGroupNum();
    if ( groupNum > 0 ) then
        local suggestedGroupString = format(QUEST_SUGGESTED_GROUP_NUM, groupNum);
        ArmoryQuestInfoGroupSize:SetText(suggestedGroupString);
        ArmoryQuestInfoGroupSize:Show();
        return ArmoryQuestInfoGroupSize;
    else
        ArmoryQuestInfoGroupSize:Hide();
        return nil;
    end
end

function ArmoryQuestInfo_ShowDescriptionHeader()
    return ArmoryQuestInfoDescriptionHeader;
end

function ArmoryQuestInfo_ShowObjectivesText()
    local _, questObjectives = Armory:GetQuestLogQuestText();
    ArmoryQuestInfoObjectivesText:SetText(questObjectives);
    return ArmoryQuestInfoObjectivesText;
end

function ArmoryQuestInfo_ShowSpacer()
    return ArmoryQuestInfoSpacerFrame;
end

function ArmoryQuestInfo_ShowAnchor()
    return ArmoryQuestInfoAnchor;
end

function ArmoryQuestInfo_ShowRewardText()
    ArmoryQuestInfoRewardText:SetText(Armory:GetRewardText());
    return ArmoryQuestInfoRewardText;
end

function ArmoryQuestInfo_ShowSeal(parentFrame)
    local frame = ArmoryQuestInfoSealFrame;
	-- Temporary anchor to ensure :IsTruncated will work for the seal text.
	frame:SetPoint("CENTER", parentFrame or UIParent);
    if ( frame.sealInfo ) then
        frame.Text:SetText(frame.sealInfo.text);
        frame.Texture:SetAtlas(frame.sealInfo.sealAtlas, true);
        frame.Texture:SetPoint("TOPLEFT", 160, -6);
        frame:Show();
        return frame;
    else
        frame:Hide();
        return nil;
    end
end

local function AddSpellToBucket(spellBuckets, type, rewardSpellIndex)
    if ( not spellBuckets[type] ) then
        spellBuckets[type] = {};
    end

    table.insert(spellBuckets[type], rewardSpellIndex);
end

function ArmoryQuestInfo_ShowRewards()
    local numQuestRewards = Armory:GetNumQuestLogRewards();
    local numQuestChoices = Armory:GetNumQuestLogChoices();
    local numQuestCurrencies = Armory:GetNumQuestLogRewardCurrencies();
    local numQuestSpellRewards = 0;
    local money = Armory:GetQuestLogRewardMoney();
    local skillName, skillIcon, skillPoints = Armory:GetQuestLogRewardSkillPoints();
    local xp = Armory:GetQuestLogRewardXP();
    local artifactXP, artifactCategory = Armory:GetQuestLogRewardArtifactXP();
    local honor = Armory:GetQuestLogRewardHonor();
    local playerTitle = Armory:GetQuestLogRewardTitle();
    local numSpellRewards = Armory:GetNumQuestLogRewardSpells();
    local rewardsFrame = ArmoryQuestInfoFrame.rewardsFrame;

    for rewardSpellIndex = 1, numSpellRewards do
        local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell, garrFollowerID, genericUnlock, spellID, knownSpell, isFollowerCollected = Armory:GetQuestLogRewardSpell(rewardSpellIndex);

        -- only allow the spell reward if user can learn it        
        if ( texture and not knownSpell and (not isBoostSpell or Armory:IsCharacterNewlyBoosted()) and (not garrFollowerID or not isFollowerCollected) ) then
            numQuestSpellRewards = numQuestSpellRewards + 1;
        end
    end

    local totalRewards = numQuestRewards + numQuestChoices + numQuestCurrencies;
    if ( totalRewards == 0 and money == 0 and xp == 0 and not playerTitle and numQuestSpellRewards == 0 and artifactXP == 0 and honor == 0 ) then
        rewardsFrame:Hide();
        return nil;
    end

    -- Hide unused rewards
    local rewardButtons = rewardsFrame.RewardButtons;
    for i = totalRewards + 1, #rewardButtons do
        rewardButtons[i]:ClearAllPoints();
        rewardButtons[i]:Hide();
    end

    local questItem, name, texture, quality, isUsable, itemID, numItems;
    local rewardsCount = 0;
    local lastFrame = rewardsFrame.Header;
    
    local totalHeight = rewardsFrame.Header:GetHeight();
    local buttonHeight = rewardsFrame.RewardButtons[1]:GetHeight();

    rewardsFrame.ArtifactXPFrame:ClearAllPoints();
    if ( artifactXP > 0 ) then
        local name, icon = C_ArtifactUI.GetArtifactXPRewardTargetInfo(artifactCategory);
        rewardsFrame.ArtifactXPFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
        rewardsFrame.ArtifactXPFrame.Name:SetText(BreakUpLargeNumbers(artifactXP));
        rewardsFrame.ArtifactXPFrame.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark");
        rewardsFrame.ArtifactXPFrame:Show();

        lastFrame = rewardsFrame.ArtifactXPFrame;
        totalHeight = totalHeight + rewardsFrame.ArtifactXPFrame:GetHeight() + REWARDS_SECTION_OFFSET;
    else
        rewardsFrame.ArtifactXPFrame:Hide();
    end

    -- Setup choosable rewards
    rewardsFrame.ItemChooseText:ClearAllPoints();
    if ( numQuestChoices > 0 ) then
        rewardsFrame.ItemChooseText:Show();
        rewardsFrame.ItemChooseText:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -5);
        
        local index;
        local baseIndex = rewardsCount;
        for i = 1, numQuestChoices do    
            index = i + baseIndex;
            questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
            questItem.type = "choice";
            questItem.objectType = "item";
            numItems = 1;
            name, texture, numItems, quality, isUsable, itemID = Armory:GetQuestLogChoiceInfo(i);
            SetItemButtonQuality(questItem, quality, itemID);
            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.Name:SetText(name);
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
                    questItem:SetPoint("TOPLEFT", rewardButtons[index - 2], "BOTTOMLEFT", 0, -2);
                    lastFrame = questItem;
                    totalHeight = totalHeight + buttonHeight + 2;
                else
                    questItem:SetPoint("TOPLEFT", rewardButtons[index - 1], "TOPRIGHT", 1, 0);
                end
            else
                questItem:SetPoint("TOPLEFT", rewardsFrame.ItemChooseText, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
                lastFrame = questItem;
                totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
            end
            rewardsCount = rewardsCount + 1;
        end
        if ( numQuestChoices == 1 ) then
            rewardsFrame.ItemChooseText:SetText(REWARD_ITEMS_ONLY);
        else
            rewardsFrame.ItemChooseText:SetText(REWARD_CHOICES);
        end
        totalHeight = totalHeight + rewardsFrame.ItemChooseText:GetHeight() + REWARDS_SECTION_OFFSET;
    else
        rewardsFrame.ItemChooseText:Hide();
    end

    rewardsFrame.spellRewardPool:ReleaseAll();
    rewardsFrame.followerRewardPool:ReleaseAll();
    rewardsFrame.spellHeaderPool:ReleaseAll();
    
    -- Setup spell rewards
    if ( numQuestSpellRewards > 0 ) then
        local spellBuckets = {};

        for rewardSpellIndex = 1, numSpellRewards do
            local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell, garrFollowerID, genericUnlock, spellID, knownSpell, isFollowerCollected = Armory:GetQuestLogRewardSpell(rewardSpellIndex);
            if ( texture and not knownSpell and (not isBoostSpell or Armory:IsCharacterNewlyBoosted()) and (not garrFollowerID or not isFollowerCollected) ) then
                if ( isTradeskillSpell ) then
                    AddSpellToBucket(spellBuckets, QUEST_SPELL_REWARD_TYPE_TRADESKILL_SPELL, rewardSpellIndex);
                elseif ( isBoostSpell ) then
                    AddSpellToBucket(spellBuckets, QUEST_SPELL_REWARD_TYPE_ABILITY, rewardSpellIndex);
                elseif ( garrFollowerID ) then
                    AddSpellToBucket(spellBuckets, QUEST_SPELL_REWARD_TYPE_FOLLOWER, rewardSpellIndex);            
                elseif ( isSpellLearned ) then
                    AddSpellToBucket(spellBuckets, QUEST_SPELL_REWARD_TYPE_SPELL, rewardSpellIndex);
				elseif ( genericUnlock ) then
					AddSpellToBucket(spellBuckets, QUEST_SPELL_REWARD_TYPE_UNLOCK, rewardSpellIndex);
				else
                    AddSpellToBucket(spellBuckets, QUEST_SPELL_REWARD_TYPE_AURA, rewardSpellIndex);        
                end
            end
        end

        for orderIndex, spellBucketType in ipairs(QUEST_INFO_SPELL_REWARD_ORDERING) do
            local spellBucket = spellBuckets[spellBucketType];
            if spellBucket then
                for i, rewardSpellIndex in ipairs(spellBucket) do
                    local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell, garrFollowerID = Armory:GetQuestLogRewardSpell(rewardSpellIndex);
                    -- hideSpellLearnText is a quest flag
                    if ( i == 1 and not hideSpellLearnText ) then
                        local header = rewardsFrame.spellHeaderPool:Acquire();
                        header:SetText(QUEST_INFO_SPELL_REWARD_TO_HEADER[spellBucketType]);
                        header:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
                        if rewardsFrame.spellHeaderPool.textR and rewardsFrame.spellHeaderPool.textG and rewardsFrame.spellHeaderPool.textB then
                            header:SetVertexColor(rewardsFrame.spellHeaderPool.textR, rewardsFrame.spellHeaderPool.textG, rewardsFrame.spellHeaderPool.textB);
                        end
                        header:Show();

                        totalHeight = totalHeight + header:GetHeight() + REWARDS_SECTION_OFFSET;
                        lastFrame = header;
                    end

                    local anchorFrame;
                    if ( garrFollowerID ) then
                        local followerFrame = rewardsFrame.followerRewardPool:Acquire();
                        local followerInfo = C_Garrison.GetFollowerInfo(garrFollowerID);
                        followerFrame.Name:SetText(followerInfo.name);
                        followerFrame.Class:SetAtlas(followerInfo.classAtlas);
                        followerFrame.PortraitFrame:SetupPortrait(followerInfo);
                        followerFrame.ID = garrFollowerID;
                        followerFrame:Show();

                        anchorFrame = followerFrame;
                    else
                        local spellRewardFrame = rewardsFrame.spellRewardPool:Acquire();
                        spellRewardFrame.Icon:SetTexture(texture);
                        spellRewardFrame.Name:SetText(name);
                        spellRewardFrame.rewardSpellIndex = rewardSpellIndex;
                        spellRewardFrame:Show();

                        anchorFrame = spellRewardFrame;
                    end
                    if ( i % 2 ==  1 ) then
                        anchorFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
                        totalHeight = totalHeight + anchorFrame:GetHeight() + REWARDS_SECTION_OFFSET;

                        lastFrame = anchorFrame;
                    else
                        anchorFrame:SetPoint("LEFT", lastFrame, "RIGHT", 1, 0);
                    end
                end
            end
        end
    end

    -- Title reward
    if ( playerTitle ) then
        rewardsFrame.PlayerTitleText:Show();
        rewardsFrame.PlayerTitleText:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
        totalHeight = totalHeight +  rewardsFrame.PlayerTitleText:GetHeight() + REWARDS_SECTION_OFFSET;
        rewardsFrame.TitleFrame:SetPoint("TOPLEFT", rewardsFrame.PlayerTitleText, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
        rewardsFrame.TitleFrame.Name:SetText(playerTitle);
        rewardsFrame.TitleFrame:Show();
        lastFrame = rewardsFrame.TitleFrame;
        totalHeight = totalHeight +  rewardsFrame.TitleFrame:GetHeight() + REWARDS_SECTION_OFFSET;
    else
        rewardsFrame.PlayerTitleText:Hide();
        rewardsFrame.TitleFrame:Hide();
    end

    -- Setup mandatory rewards
    if ( numQuestRewards > 0 or numQuestCurrencies > 0 or money > 0 or xp > 0 or honor > 0 ) then
        -- receive text, will either say "You will receive" or "You will also receive"
        local questItemReceiveText = rewardsFrame.ItemReceiveText;
        if ( numQuestChoices > 0 or numQuestSpellRewards > 0 or playerTitle ) then
            questItemReceiveText:SetText(REWARD_ITEMS);
        else
            questItemReceiveText:SetText(REWARD_ITEMS_ONLY);
        end
        questItemReceiveText:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
        questItemReceiveText:Show();
        totalHeight = totalHeight + questItemReceiveText:GetHeight() + REWARDS_SECTION_OFFSET;
        lastFrame = questItemReceiveText;

        -- Money rewards
        if ( money > 0 ) then
            MoneyFrame_Update(rewardsFrame.MoneyFrame, money);
            rewardsFrame.MoneyFrame:Show();
        else
            rewardsFrame.MoneyFrame:Hide();
        end
        -- XP rewards
        if ( ArmoryQuestInfo_ToggleRewardElement(rewardsFrame.XPFrame, BreakUpLargeNumbers(xp), lastFrame) ) then
            lastFrame = rewardsFrame.XPFrame;
            totalHeight = totalHeight + rewardsFrame.XPFrame:GetHeight() + REWARDS_SECTION_OFFSET;
        end
        -- Skill Point rewards
        if ( ArmoryQuestInfo_ToggleRewardElement(rewardsFrame.SkillPointFrame, skillPoints, lastFrame) ) then
            lastFrame = rewardsFrame.SkillPointFrame;
            rewardsFrame.SkillPointFrame.Icon:SetTexture(skillIcon);
            if ( skillName ) then
                rewardsFrame.SkillPointFrame.Name:SetFormattedText(BONUS_SKILLPOINTS, skillName);
                rewardsFrame.SkillPointFrame.tooltip = format(BONUS_SKILLPOINTS_TOOLTIP, skillPoints, skillName);
            else
                rewardsFrame.SkillPointFrame.tooltip = nil;
                rewardsFrame.SkillPointFrame.Name:SetText("");
            end
            totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
        end
        -- Item rewards
        local index;
        local baseIndex = rewardsCount;
        local buttonIndex = 0;
        for i = 1, numQuestRewards, 1 do
            buttonIndex = buttonIndex + 1;
            index = i + baseIndex;
            questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
            questItem.type = "reward";
            questItem.objectType = "item";
            name, texture, numItems, quality, isUsable = Armory:GetQuestLogRewardInfo(i);
            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.Name:SetText(name);
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            if ( isUsable ) then
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
                SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
            end
            
            if ( buttonIndex > 1 ) then
                if ( mod(buttonIndex,2) == 1 ) then
                    questItem:SetPoint("TOPLEFT", rewardButtons[index - 2], "BOTTOMLEFT", 0, -2);
                    lastFrame = questItem;
                    totalHeight = totalHeight + buttonHeight + 2;
                else
                    questItem:SetPoint("TOPLEFT", rewardButtons[index - 1], "TOPRIGHT", 1, 0);
                end
            else
                questItem:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
                lastFrame = questItem;
                totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;                
            end
            rewardsCount = rewardsCount + 1;
        end
        
        -- currency
        baseIndex = rewardsCount;
        local foundCurrencies = 0;
        buttonIndex = buttonIndex + 1;
        for i = 1, GetMaxRewardCurrencies(), 1 do
            index = i + baseIndex;
            questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
            questItem.type = "reward";
            questItem.objectType = "currency";
            local currencyID;
            name, texture, numItems, currencyID, quality = Armory:GetQuestLogRewardCurrencyInfo(i);
            if ( name and texture and numItems ) then
				name, texture, numItems, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, numItems, name, texture, quality); 
                questItem:SetID(i)
                questItem:Show();
                -- For the tooltip
                questItem.Name:SetText(name);
                SetItemButtonCount(questItem, numItems, true);
				local currencyColor = GetColorForCurrencyReward(currencyID, numItems);
				questItem.Count:SetTextColor(currencyColor:GetRGB());
                SetItemButtonTexture(questItem, texture);
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonQuality(questItem, quality, currencyID);
                
                if ( buttonIndex > 1 ) then
                    if ( mod(buttonIndex,2) == 1 ) then
                        questItem:SetPoint("TOPLEFT", rewardButtons[index - 2], "BOTTOMLEFT", 0, -2);
                        lastFrame = questItem;
                        totalHeight = totalHeight + buttonHeight + 2;
                    else
                        questItem:SetPoint("TOPLEFT", rewardButtons[index - 1], "TOPRIGHT", 1, 0);
                    end
                else
                    questItem:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
                    lastFrame = questItem;
                    totalHeight = totalHeight + buttonHeight + REWARDS_SECTION_OFFSET;
                end
                rewardsCount = rewardsCount + 1;
                foundCurrencies = foundCurrencies + 1;
                buttonIndex = buttonIndex + 1;
                if ( foundCurrencies == numQuestCurrencies ) then
                    break;
                end
            end
        end
        
        rewardsFrame.HonorFrame:ClearAllPoints();
        if ( honor > 0 ) then
            local icon;
            if ( Armory:UnitFactionGroup("player") == PLAYER_FACTION_GROUP[0] ) then
                icon = "Interface\\Icons\\PVPCurrency-Honor-Horde";
            else
                icon = "Interface\\Icons\\PVPCurrency-Honor-Alliance";
            end

            rewardsFrame.HonorFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -REWARDS_SECTION_OFFSET);
            rewardsFrame.HonorFrame.Count:SetText(BreakUpLargeNumbers(honor));
            rewardsFrame.HonorFrame.Name:SetText(HONOR);
            rewardsFrame.HonorFrame.Icon:SetTexture(icon);
            rewardsFrame.HonorFrame:Show();

            lastFrame = rewardsFrame.HonorFrame;
            totalHeight = totalHeight + rewardsFrame.HonorFrame:GetHeight() + REWARDS_SECTION_OFFSET;
        else
            rewardsFrame.HonorFrame:Hide();
        end
    else    
        rewardsFrame.ItemReceiveText:Hide();
        rewardsFrame.MoneyFrame:Hide();
        rewardsFrame.XPFrame:Hide();        
        rewardsFrame.SkillPointFrame:Hide();
        rewardsFrame.HonorFrame:Hide();
    end

    rewardsFrame:Show();
    rewardsFrame:SetHeight(totalHeight);
    return rewardsFrame, lastFrame;
end

function ArmoryQuestInfoRewardItemCodeTemplate_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if (self.objectType == "item") then
        Armory:SetQuestLogItem(self.type, self:GetID());
        ArmoryShowCompareItem(GameTooltip, select(2, Armory:GetItemFromTooltip(GameTooltip)));
    elseif (self.objectType == "currency") then
        Armory:SetQuestLogCurrency(self.type, self:GetID());
    end
end

function ArmoryQuestInfoRewardItemCodeTemplate_OnClick(self, button)
    if ( IsModifiedClick() and self.objectType == "item" ) then
        HandleModifiedItemClick(Armory:GetQuestLogItemLink(self.type, self:GetID()));
    end
end

ARMORY_QUEST_TEMPLATE_LOG = { 
    elements = {
        ArmoryQuestInfo_ShowTitle, 5, -5,
        ArmoryQuestInfo_ShowType, 0, -5,
        ArmoryQuestInfo_ShowObjectivesText, 0, -5,
        ArmoryQuestInfo_ShowTimer, 0, -10,
        ArmoryQuestInfo_ShowObjectives, 0, -10,
        ArmoryQuestInfo_ShowSpecialObjectives, 0, -10,
        ArmoryQuestInfo_ShowRequiredMoney, 0, 0,
        ArmoryQuestInfo_ShowGroupSize, 0, -10,
        ArmoryQuestInfo_ShowDescriptionHeader, 0, -20,
        ArmoryQuestInfo_ShowDescriptionText, 0, -5,
        ArmoryQuestInfo_ShowSeal, 0, 0,
        ArmoryQuestInfo_ShowRewards, 0, -10,
        ArmoryQuestInfo_ShowSpacer, 0, -10
    }
}