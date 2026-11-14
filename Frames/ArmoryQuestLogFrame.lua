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

ARMORY_QUESTLOG_QUEST_HEIGHT = 16;

local QUESTS_DISPLAYED = 6;

local REWARDS_SECTION_OFFSET = 5;       -- vertical distance between sections
local REWARDS_ROW_OFFSET = 2;            -- vertical distance between rows within a section

local table = table;
local ipairs = ipairs;
local select = select;
local unpack = unpack;
local type = type;

-- Per family, chosen once
local MoneyFrame_Update = Armory.isClassic and MoneyFrame_Update or ArmoryMoneyFrame_Update;
local GetQuestDetailsTheme, QuestHasWarModeBonus, GetMajorFactionReputationRewards, QuestHasQuestSessionBonus, SetQuestLegendToFontString;
local OBJECTIVE_FINISHED_COLOR; -- Mainline: QUEST_OBJECTIVE_DISABLED_FONT_COLOR
if ( Armory.isClassic ) then
    local function None() end
    OBJECTIVE_FINISHED_COLOR = CreateColor(0.2, 0.2, 0.2);
    GetQuestDetailsTheme = None;
    QuestHasWarModeBonus = None;
    GetMajorFactionReputationRewards = None;
    QuestHasQuestSessionBonus = None;
    SetQuestLegendToFontString = None;
else
    GetQuestDetailsTheme = C_QuestLog.GetQuestDetailsTheme;
    QuestHasWarModeBonus = C_QuestLog.QuestHasWarModeBonus;
    GetMajorFactionReputationRewards = C_QuestLog.GetQuestLogMajorFactionReputationRewards;
    QuestHasQuestSessionBonus = C_QuestLog.QuestHasQuestSessionBonus;
    SetQuestLegendToFontString = QuestUtil.SetQuestLegendToFontString;
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
        if ( IsModifiedClick("CHATLINK") and ChatFrameUtil.GetActiveWindow() ) then
            local questLink;
            if ( Armory.isClassic ) then
                -- Classic has no quest links: the title without the leading spaces, as Blizzard does
                questLink = gsub(self:GetText(), " *(.*)", "%1");
            else
                questLink = Armory:GetQuestLink(questIndex);
            end
            if ( questLink ) then
                ChatFrameUtil.InsertLink(questLink);
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

-- Classic has no atlas for the empty quest log: the empty book of Blizzard's Classic quest log, 320x384 in four files.
-- The cobwebs go into the upper inset and the book into the lower one, each filling its own inset.
local CLASSIC_EMPTY_BOOK_FILES = {
    -- file, left, top, width and height in the image
    { "TopLeft", 0, 0, 256, 256 },
    { "TopRight", 256, 0, 64, 256 },
    { "BotLeft", 0, 256, 256, 128 },
    { "BotRight", 256, 256, 64, 128 },
};
local CLASSIC_EMPTY_BOOK_REGIONS = {
    -- left, top, right and bottom in the image; the rest of the image is transparent
    { 0, 0, 302, 95 },      -- cobwebs, upper inset
    { 0, 101, 302, 362 },   -- book, lower inset
};
local CLASSIC_EMPTY_BOOK_EDGE = 3;  -- inside the border of the insets

-- In the empty frame itself, below the text: one texture per part of a file in a region
local function CreateClassicEmptyBook(emptyFrame)
    emptyFrame.Bg:Hide();
    emptyFrame.book = {};
    for regionIndex, region in ipairs(CLASSIC_EMPTY_BOOK_REGIONS) do
        for _, file in ipairs(CLASSIC_EMPTY_BOOK_FILES) do
            local left, top = max(region[1], file[2]), max(region[2], file[3]);
            local right, bottom = min(region[3], file[2] + file[4]), min(region[4], file[3] + file[5]);
            if ( right > left and bottom > top ) then
                local texture = emptyFrame:CreateTexture(nil, "BACKGROUND", nil, -1);
                texture:SetTexture("Interface\\QuestFrame\\UI-QuestLog-Empty-"..file[1]);
                texture:SetTexCoord((left - file[2]) / file[4], (right - file[2]) / file[4], (top - file[3]) / file[5], (bottom - file[3]) / file[5]);
                texture.region = regionIndex;
                texture.left, texture.top, texture.width, texture.height = left - region[1], top - region[2], right - left, bottom - top;
                tinsert(emptyFrame.book, texture);
            end
        end
    end
end

local function LayoutClassicEmptyBook()
    local insets = { ArmoryQuestFrame.Inset, ArmoryQuestFrame.bottomInset };
    for _, texture in ipairs(ArmoryEmptyQuestLogFrame.book) do
        local inset = insets[texture.region];
        local region = CLASSIC_EMPTY_BOOK_REGIONS[texture.region];
        local xScale = (inset:GetWidth() - 2 * CLASSIC_EMPTY_BOOK_EDGE) / (region[3] - region[1]);
        local yScale = (inset:GetHeight() - 2 * CLASSIC_EMPTY_BOOK_EDGE) / (region[4] - region[2]);
        texture:ClearAllPoints();
        texture:SetPoint("TOPLEFT", inset, "TOPLEFT", CLASSIC_EMPTY_BOOK_EDGE + texture.left * xScale, -(CLASSIC_EMPTY_BOOK_EDGE + texture.top * yScale));
        texture:SetSize(texture.width * xScale, texture.height * yScale);
    end
    ArmoryQuestLogNoQuestsText:ClearAllPoints();
    ArmoryQuestLogNoQuestsText:SetPoint("CENTER", insets[1]);
end

-- Without the button bar the lower inset runs further down in Classic than the details:
-- it ends just below them, as in Retail, with the quest count below it
local CLASSIC_DETAIL_BOTTOM = 4;
local function LayoutClassicDetails()
    local frame = ArmoryQuestFrame;
    local bottom, frameBottom = ArmoryQuestLogDetailScrollFrame:GetBottom(), frame:GetBottom();
    if ( bottom and frameBottom ) then
        frame.bottomInset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, bottom - CLASSIC_DETAIL_BOTTOM - frameBottom);
    end
end

function ArmoryQuestLogFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("QUEST_LOG_UPDATE");
    self:RegisterEvent("UNIT_QUEST_LOG_CHANGED");
    if ( Armory.isClassic ) then
        self:RegisterEvent("UPDATE_FACTION");
        CreateClassicEmptyBook(ArmoryEmptyQuestLogFrame);
        -- below the lower inset, which runs further down in Classic
        ArmoryQuestLogCount:ClearAllPoints();
        ArmoryQuestLogCount:SetPoint("TOPLEFT", ArmoryQuestFrame.bottomInset, "BOTTOMLEFT", 11, -4);
    else
        -- not in the XML: Classic has no such atlas and warns about it when loading
        self.Bg:SetAtlas("QuestBG-Parchment", false);
    end
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

local function SetClassicParchment(texture)
    -- Classic has no parchment atlas; Blizzard uses this file, at its own size
    texture:SetTexture("Interface\\QuestFrame\\QuestBG");
    local width, height = texture:GetSize();
    texture:SetTexCoord(0, min(width / 512, 1), 0, min(height / 512, 1));
end

function ArmoryQuestLogFrame_OnShow(self)
    self:GetParent().bottomInset:Show();
    self:GetParent().Inset:SetPoint("BOTTOMRIGHT", self:GetParent(), "TOPRIGHT", -6, -162);
    if ( Armory.isClassic ) then
        SetClassicParchment(self.Bg);
        LayoutClassicDetails();
        LayoutClassicEmptyBook();
    end

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

function ArmoryQuestLog_Update()
    if ( not ArmoryQuestLogFrame:IsShown() ) then
        return;
    end

    local numEntries, numQuests = Armory:GetNumQuestLogEntries();
    if ( numQuests == 0 ) then
        ArmoryEmptyQuestLogFrame:Show();
        ArmoryQuestLogDetailScrollFrame:Hide();
        ArmoryQuestFrameExpandButtonFrame:Hide();
    else
        ArmoryEmptyQuestLogFrame:Hide();
        ArmoryQuestLogDetailScrollFrame:Show();
        ArmoryQuestFrameExpandButtonFrame:Show();
    end
    if ( Armory.isClassic ) then
        -- the parchment would show next to the empty book
        ArmoryQuestLogFrame.Bg:SetShown(numQuests > 0);
    end

    -- Update Quest Count
    ArmoryQuestLogUpdateQuestCount(numQuests);

    -- ScrollFrame update
    FauxScrollFrame_Update(ArmoryQuestLogListScrollFrame, numEntries, QUESTS_DISPLAYED, ARMORY_QUESTLOG_QUEST_HEIGHT, nil, nil, nil, ArmoryQuestLogHighlightFrame, 293, 316 )

    -- Update the quest listing
    ArmoryQuestLogHighlightFrame:Hide();

    if ( numQuests == 0 ) then
        -- the list may still show the quests of the previous character
        for i = 1, QUESTS_DISPLAYED do
            _G["ArmoryQuestLogTitle"..i]:Hide();
        end
        return;
    end

    -- If no selection then set it to the first available quest
    if ( Armory:GetQuestLogSelection() == 0 ) then
        ArmoryQuestLog_SetFirstValidSelection();
    end

    local questIndex, questLogTitle, questTag, questTitleTag, questNormalText, questHighlight;
    local questLogTitleText, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, color, questID, displayQuestID, difficultyLevel;

    for i = 1, QUESTS_DISPLAYED do
        questIndex = i + FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
        questLogTitle = _G["ArmoryQuestLogTitle"..i];
        questTitleTag = _G["ArmoryQuestLogTitle"..i.."Tag"];
        questNormalText = _G["ArmoryQuestLogTitle"..i.."NormalText"];
        questHighlight = _G["ArmoryQuestLogTitle"..i.."Highlight"];
        if ( questIndex <= numEntries ) then
            questLogTitleText, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, _, displayQuestID, _, _, _, _, _, _, _, difficultyLevel = Armory:GetQuestLogTitle(questIndex);
            -- title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling, difficultyLevel, campaignID, isCalling;
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
                questLogTitle:GetNormalTexture():SetTexCoord(0, 1, 0, 1);
                questHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
            else
                if ( questID and displayQuestID ) then
                    questLogTitleText = questID.." - "..questLogTitleText;
                end
                if ( difficultyLevel and ENABLE_COLORBLIND_MODE == "1" ) then
                    questLogTitleText = "["..difficultyLevel.."] "..questLogTitleText;
                end
                questLogTitle:SetText("  "..questLogTitleText);
                questLogTitle:ClearNormalTexture();
                questHighlight:SetTexture("");
            end
            -- Save if its a header or not
            questLogTitle.isHeader = isHeader;

            -- In Classic the third value is the quest tag
            local questTag = ArmoryQuestLog_GetQuestTag(questID, questIndex, isComplete, frequency, suggestedGroup);
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
        questLogTitleText, _, _, isHeader, isCollapsed = Armory:GetQuestLogTitle(i);
        if ( questLogTitleText and isHeader ) then
            numHeaders = numHeaders + 1;
            if ( isCollapsed ) then
                notExpanded = notExpanded + 1;
            end
        end
    end
    ArmoryQuestFrameCollapseAllButton_Update(notExpanded ~= numHeaders);
end

if ( Armory.isClassic ) then
    -- Classic stores the quest tag itself
    function ArmoryQuestLog_GetQuestTag(questID, questIndex, isComplete, frequency, questTag)
        if ( isComplete and isComplete < 0 ) then
            questTag = FAILED;
        elseif ( isComplete and isComplete > 0 ) then
            questTag = COMPLETE;
        elseif ( Armory.isTBC and frequency == LE_QUEST_FREQUENCY_DAILY ) then
            if ( questTag ) then
                questTag = format(DAILY_QUEST_TAG_TEMPLATE, questTag);
            else
                questTag = DAILY;
            end
        end
        return questTag;
    end
else
    function ArmoryQuestLog_GetQuestTag(questID, questIndex, isComplete, frequency)
        local tagInfo = Armory:GetQuestTagInfo(questIndex);
        local questTagID = tagInfo and tagInfo.tagID;
        local questTag = tagInfo and tagInfo.tagName;

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
        elseif( frequency == Enum.QuestFrequency.Daily and (not isComplete or isComplete == 0) ) then
            questTag = DAILY;
        elseif( frequency == Enum.QuestFrequency.Weekly and (not isComplete or isComplete == 0) )then
            questTag = WEEKLY;
        end
        return questTag;
    end
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
        ArmoryQuestLogHighlightFrame:Hide();
        if ( isCollapsed ) then
            Armory:ExpandQuestHeader(questIndex);
        else
            Armory:CollapseQuestHeader(questIndex);
        end
        questIndex = ArmoryQuestLog_GetFirstSelectableQuest();
        ArmoryQuestLog_SetSelection(questIndex);
        return;
    else
        -- Set newly selected quest and highlight it
        ArmoryQuestLogFrame.selectedButtonID = questIndex;
        local scrollFrameOffset = FauxScrollFrame_GetOffset(ArmoryQuestLogListScrollFrame);
        if ( questIndex > scrollFrameOffset and questIndex <= (scrollFrameOffset + QUESTS_DISPLAYED) and questIndex <= Armory:GetNumQuestLogEntries() ) then
            titleButton:LockHighlight();
            titleButtonTag:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
            if ( titleButton.r ) then
                ArmoryQuestLogSkillHighlight:SetVertexColor(titleButton.r, titleButton.g, titleButton.b);
            end
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

if ( Armory.isClassic ) then
    -- Classic's template has no color, and TBC counts the dailies
    function ArmoryQuestLogUpdateQuestCount(numQuests)
        ArmoryQuestLogQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, numQuests, MAX_QUESTLOG_QUESTS);
        local dailyQuestsComplete = Armory.isTBC and Armory:GetDailyQuestsCompleted() or 0;
        if ( dailyQuestsComplete > 0 ) then
            ArmoryQuestLogDailyQuestCount:SetFormattedText(QUEST_LOG_DAILY_COUNT_TEMPLATE, dailyQuestsComplete, Armory:GetMaxDailyQuests());
            ArmoryQuestLogDailyQuestCount:Show();
        else
            ArmoryQuestLogDailyQuestCount:Hide();
        end
    end
else
    function ArmoryQuestLogUpdateQuestCount(numQuests)
        if (numQuests > MAX_QUESTLOG_QUESTS) then
            ArmoryQuestLogQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, RED_FONT_COLOR_CODE, numQuests, MAX_QUESTLOG_QUESTS);
        else
            ArmoryQuestLogQuestCount:SetFormattedText(QUEST_LOG_COUNT_TEMPLATE, "|cffffffff", numQuests, MAX_QUESTLOG_QUESTS);
        end
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

function ArmoryQuestInfo_Display(template, parentFrame)
    local questID = select(8, Armory:GetQuestLogTitle(Armory:GetQuestLogSelection()));
    local material = "Parchment";

    if ( questID ) then
        ArmoryQuestInfoSealFrame.theme = GetQuestDetailsTheme(questID);
    end

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
        ArmoryQuestInfoRewardsFrame.QuestSessionBonusReward:SetTextColor(textColor[1], textColor[2], textColor[3]);
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
    local added = SetQuestLegendToFontString(questID, ArmoryQuestInfoQuestType);
    ArmoryQuestInfoQuestType:SetShown(added);

    if ( added ) then
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
                objective:SetTextColor((OBJECTIVE_FINISHED_COLOR or QUEST_OBJECTIVE_DISABLED_FONT_COLOR):GetRGB());
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
    local theme = frame.theme;
    local hasAnyPartOfTheSeal = theme and (theme.signature ~= "" or theme.seal);
    frame:SetShown(hasAnyPartOfTheSeal);

    if ( hasAnyPartOfTheSeal ) then
        -- Temporary anchor to ensure :IsTruncated will work for the seal text.
        frame:SetPoint("CENTER", parentFrame or UIParent);

        frame.Text:SetText(theme.signature);
        frame.Texture:SetShown(theme.seal ~= nil);
        if ( theme.seal ) then
            frame.Texture:SetAtlas(theme.seal, true);
            frame.Texture:SetPoint("TOPLEFT", 160, -6);
        end

        return frame;
    end
end

local function QuestInfo_GetRewardButton(rewardsFrame, index)
    local rewardButtons = rewardsFrame.RewardButtons;
    if ( not rewardButtons[index] ) then
        local button = CreateFrame("BUTTON", "$parentQuestInfoItem"..index, rewardsFrame, rewardsFrame.buttonTemplate);
        rewardButtons[index] = button;
    end
    return rewardButtons[index];
end

local QUEST_INFO_SPELL_REWARD_ORDERING = {
    Enum.QuestCompleteSpellType.Follower,
    Enum.QuestCompleteSpellType.Companion,
    Enum.QuestCompleteSpellType.Tradeskill,
    Enum.QuestCompleteSpellType.Ability,
    Enum.QuestCompleteSpellType.Aura,
    Enum.QuestCompleteSpellType.Spell,
    Enum.QuestCompleteSpellType.Unlock,
    Enum.QuestCompleteSpellType.QuestlineUnlock,
	Enum.QuestCompleteSpellType.QuestlineReward,
	Enum.QuestCompleteSpellType.QuestlineUnlockPart,
};

local QUEST_INFO_SPELL_REWARD_TO_HEADER = {
    [Enum.QuestCompleteSpellType.Follower] = REWARD_FOLLOWER,
    [Enum.QuestCompleteSpellType.Companion] = REWARD_COMPANION,
    [Enum.QuestCompleteSpellType.Tradeskill] = REWARD_TRADESKILL_SPELL,
    [Enum.QuestCompleteSpellType.Ability] = REWARD_ABILITY,
    [Enum.QuestCompleteSpellType.Aura] = REWARD_AURA,
    [Enum.QuestCompleteSpellType.Spell] = REWARD_SPELL,
    [Enum.QuestCompleteSpellType.Unlock] = REWARD_UNLOCK,
	[Enum.QuestCompleteSpellType.QuestlineUnlock] = REWARD_QUESTLINE_UNLOCK,
	[Enum.QuestCompleteSpellType.QuestlineReward] = REWARD_QUESTLINE_REWARD,
	[Enum.QuestCompleteSpellType.QuestlineUnlockPart] = REWARD_QUESTLINE_UNLOCK_PART,
};

local function AddSpellToBucket(spellBuckets, type, rewardSpellIndex)
    if ( not spellBuckets[type] ) then
        spellBuckets[type] = {};
    end

    table.insert(spellBuckets[type], rewardSpellIndex);
end

function ArmoryQuestInfo_ShowRewards()
    local rewardsFrame = ArmoryQuestInfoFrame.rewardsFrame;
    local questID = select(8, Armory:GetQuestLogTitle(Armory:GetQuestLogSelection()));

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
    local hasWarModeBonus = QuestHasWarModeBonus(questID);
    local majorFactionRepRewards = GetMajorFactionReputationRewards(questID);

    for rewardSpellIndex = 1, numSpellRewards do
        local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell, garrFollowerID, genericUnlock, spellID, knownSpell, isFollowerCollected = Armory:GetQuestLogRewardSpell(rewardSpellIndex);

        -- only allow the spell reward if user can learn it
        if ( texture and not knownSpell and (not isBoostSpell or Armory:IsCharacterNewlyBoosted()) and (not garrFollowerID or not isFollowerCollected) ) then
            numQuestSpellRewards = numQuestSpellRewards + 1;
        end
    end

    local totalRewards = numQuestRewards + numQuestChoices + numQuestCurrencies;
    if ( totalRewards == 0 and money == 0 and xp == 0 and not playerTitle and numQuestSpellRewards == 0 and artifactXP == 0 and honor == 0 and not majorFactionRepRewards ) then
        rewardsFrame:Hide();
        return nil;
    end

    -- Hide unused rewards
    local rewardButtons = rewardsFrame.RewardButtons;
    for i = totalRewards + 1, #rewardButtons do
        rewardButtons[i]:ClearAllPoints();
        rewardButtons[i]:Hide();
    end

    local questItem, name, texture, quality, isUsable, link, numItems;
    local rewardsCount = 0;

    local totalHeight = rewardsFrame.Header:GetHeight();
    local buttonHeight = rewardsFrame.RewardButtons[1]:GetHeight();

    -- [[ anchoring ]]
    local startNewSection = true;
    local useOneElementPerRow = false;        -- default is 2 elements per row
    local function BeginRewardsSection(largeElements)
        startNewSection = true;
        useOneElementPerRow = not not largeElements;
    end

    local lastAnchorElement = rewardsFrame.Header;
    local rightSideElementPlaced = false;
    local function AddRewardElement(rewardElement)
        if ( not startNewSection and not rightSideElementPlaced and not useOneElementPerRow ) then
            -- continue on same row
            rewardElement:SetPoint("TOPLEFT", lastAnchorElement, "TOPRIGHT", 1, 0);
            rightSideElementPlaced = true;
        else
            -- make new row
            local spacing = startNewSection and REWARDS_SECTION_OFFSET or REWARDS_ROW_OFFSET;
            rewardElement:SetPoint("TOPLEFT", lastAnchorElement, "BOTTOMLEFT", 0, -spacing);
            local isItemButton = rewardElement.smallItemButton or rewardElement.largeItemButton;
            local addedHeight = isItemButton and buttonHeight or rewardElement:GetHeight();
            totalHeight = totalHeight + addedHeight + spacing;
            lastAnchorElement = rewardElement;
            -- there's no frame on the right side of this row yet
            rightSideElementPlaced = false;
            -- inside a section now
            startNewSection = false;
        end
        rewardElement:Show();
    end

    local function AddHeaderElement(rewardElement)
        local largeElements = true;
        BeginRewardsSection(largeElements);
        AddRewardElement(rewardElement);
    end
    -- [[ anchoring ]]

    rewardsFrame.ArtifactXPFrame:ClearAllPoints();
    if ( artifactXP > 0 ) then
        local name, icon = C_ArtifactUI.GetArtifactXPRewardTargetInfo(artifactCategory);
        rewardsFrame.ArtifactXPFrame.Name:SetText(BreakUpLargeNumbers(artifactXP));
        rewardsFrame.ArtifactXPFrame.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark");
        rewardsFrame.ArtifactXPFrame:Show();
        AddRewardElement(rewardsFrame.ArtifactXPFrame);
    else
        rewardsFrame.ArtifactXPFrame:Hide();
    end

    -- Setup choosable rewards
    rewardsFrame.ItemChooseText:ClearAllPoints();
    if ( numQuestChoices > 0 ) then
        rewardsFrame.ItemChooseText:Show();
        if ( numQuestChoices == 1 ) then
            rewardsFrame.ItemChooseText:SetText(REWARD_ITEMS_ONLY);
        else
            rewardsFrame.ItemChooseText:SetText(REWARD_CHOICES);
        end
        AddHeaderElement(rewardsFrame.ItemChooseText);

        BeginRewardsSection();
        local index;
        local baseIndex = rewardsCount;
        for i = 1, numQuestChoices do
            index = i + baseIndex;
            name, texture, numItems, quality, isUsable, link = Armory:GetQuestLogChoiceInfo(i);
            questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
            questItem.type = "choice";
            questItem.objectType = "item";
            questItem.quality = quality;
            questItem:SetID(i)
            questItem:Show();
            -- For the tooltip
            questItem.Name:SetText(name);
            numItems = 1;
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            SetItemButtonQuality(questItem, quality, link);
            if ( isUsable ) then
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
                SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
            end
            AddRewardElement(questItem);
            rewardsCount = rewardsCount + 1;
        end
    else
        rewardsFrame.ItemChooseText:Hide();
    end

    rewardsFrame.spellRewardPool:ReleaseAll();
    rewardsFrame.followerRewardPool:ReleaseAll();
    rewardsFrame.spellHeaderPool:ReleaseAll();
    -- Classic has no major factions and no war mode
    if ( rewardsFrame.reputationRewardPool ) then
        rewardsFrame.reputationRewardPool:ReleaseAll();
        rewardsFrame.WarModeBonusFrame:Hide();
    end

    -- Setup spell rewards
    if ( numQuestSpellRewards > 0 ) then
        local spellBuckets = {};

        for rewardSpellIndex = 1, numSpellRewards do
            local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell, garrFollowerID, genericUnlock, spellID, knownSpell, isFollowerCollected, spellType = Armory:GetQuestLogRewardSpell(rewardSpellIndex);

            if ( type(spellType) == "number" and spellType ~= Enum.QuestCompleteSpellType.LegacyBehavior ) then
                AddSpellToBucket(spellBuckets, spellType, rewardSpellIndex);
            elseif ( isTradeskillSpell ) then
                AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Tradeskill, rewardSpellIndex);
            elseif ( isBoostSpell ) then
                AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Ability, rewardSpellIndex);
            elseif ( garrFollowerID ) then
                local followerInfo = C_Garrison.GetFollowerInfo(garrFollowerID);
                if ( followerInfo and followerInfo.followerTypeID == Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower ) then
                    AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Companion, rewardSpellIndex);
                else
                    AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Follower, rewardSpellIndex);
                end
            elseif ( isSpellLearned ) then
                AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Spell, rewardSpellIndex);
            elseif ( genericUnlock ) then
                AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Unlock, rewardSpellIndex);
            else
                AddSpellToBucket(spellBuckets, Enum.QuestCompleteSpellType.Aura, rewardSpellIndex);
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
                        if rewardsFrame.spellHeaderPool.textR and rewardsFrame.spellHeaderPool.textG and rewardsFrame.spellHeaderPool.textB then
                            header:SetVertexColor(rewardsFrame.spellHeaderPool.textR, rewardsFrame.spellHeaderPool.textG, rewardsFrame.spellHeaderPool.textB);
                        end
                        header:Show();
                        AddHeaderElement(header);
                    end

                    if i == 1 then
                        local largeElements = true;
                        BeginRewardsSection(largeElements);
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
                    AddRewardElement(anchorFrame);
                end
            end
        end
    end

    -- Title reward
    if ( playerTitle ) then
        AddHeaderElement(rewardsFrame.PlayerTitleText);
        rewardsFrame.TitleFrame.Name:SetText(playerTitle);
        BeginRewardsSection();
        AddRewardElement(rewardsFrame.TitleFrame);
    else
        rewardsFrame.PlayerTitleText:Hide();
        rewardsFrame.TitleFrame:Hide();
    end

    -- Setup mandatory rewards
    local hasChanceForQuestSessionBonusReward = QuestHasQuestSessionBonus(questID);
    if ( numQuestRewards > 0 or numQuestCurrencies > 0 or money > 0 or xp > 0 or honor > 0 or majorFactionRepRewards or hasChanceForQuestSessionBonusReward ) then
        -- receive text, will either say "You will receive" or "You will also receive"
        local questItemReceiveText = rewardsFrame.ItemReceiveText;
        if ( numQuestChoices > 0 or numQuestSpellRewards > 0 or playerTitle ) then
            questItemReceiveText:SetText(REWARD_ITEMS);
        else
            questItemReceiveText:SetText(REWARD_ITEMS_ONLY);
        end
        AddHeaderElement(questItemReceiveText);

        -- Money rewards
        if ( money > 0 ) then
            MoneyFrame_Update(rewardsFrame.MoneyFrame, money);
            rewardsFrame.MoneyFrame:Show();
        else
            rewardsFrame.MoneyFrame:Hide();
        end
        -- XP rewards
        if ( xp > 0 ) then
            rewardsFrame.XPFrame.ValueText:SetText(BreakUpLargeNumbers(xp));
            AddRewardElement(rewardsFrame.XPFrame);
        else
            rewardsFrame.XPFrame:Hide();
        end
        -- Skill Point rewards
        if ( skillPoints ) then
            rewardsFrame.SkillPointFrame.ValueText:SetText(skillPoints);
            rewardsFrame.SkillPointFrame.Icon:SetTexture(skillIcon);
            if ( skillName ) then
                rewardsFrame.SkillPointFrame.Name:SetFormattedText(BONUS_SKILLPOINTS, skillName);
                rewardsFrame.SkillPointFrame.tooltip = format(BONUS_SKILLPOINTS_TOOLTIP, skillPoints, skillName);
            else
                rewardsFrame.SkillPointFrame.tooltip = nil;
                rewardsFrame.SkillPointFrame.Name:SetText("");
            end
            AddRewardElement(rewardsFrame.SkillPointFrame);
        else
            rewardsFrame.SkillPointFrame:Hide();
        end

        BeginRewardsSection();

        -- Item rewards
        local index;
        local baseIndex = rewardsCount;
        local buttonIndex = 0;
        for i = 1, numQuestRewards, 1 do
            buttonIndex = buttonIndex + 1;
            index = i + baseIndex;
            name, texture, numItems, quality, isUsable, link = Armory:GetQuestLogRewardInfo(i);
            questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
            questItem.type = "reward";
            questItem.objectType = "item";
            questItem.quality = quality;
            questItem:SetID(i)
            -- For the tooltip
            questItem.Name:SetText(name);
            SetItemButtonCount(questItem, numItems);
            SetItemButtonTexture(questItem, texture);
            SetItemButtonQuality(questItem, quality, link);
            if ( isUsable ) then
                SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
            else
                SetItemButtonTextureVertexColor(questItem, 0.9, 0, 0);
                SetItemButtonNameFrameVertexColor(questItem, 0.9, 0, 0);
            end

            AddRewardElement(questItem);
            rewardsCount = rewardsCount + 1;
        end

        -- currency (none in Classic)
        if ( numQuestCurrencies > 0 ) then
            baseIndex = rewardsCount;
            local foundCurrencies = 0;
            for i = 1, GetMaxRewardCurrencies(), 1 do
                buttonIndex = buttonIndex + 1;
                index = i + baseIndex;
                questItem = QuestInfo_GetRewardButton(rewardsFrame, index);
                questItem.type = "reward";
                questItem.objectType = "currency";
                local currencyID;
                name, texture, numItems, currencyID, quality = Armory:GetQuestLogRewardCurrencyInfo(i);
                if ( name and texture and numItems ) then
                    name, texture, numItems, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, numItems, name, texture, quality);
                    questItem.quality = quality;
                    questItem:SetID(i)
                    -- For the tooltip
                    questItem.Name:SetText(name);
                    SetItemButtonCount(questItem, numItems, true);
                    local currencyColor = GetColorForCurrencyReward(currencyID, numItems);
                    questItem.Count:SetTextColor(currencyColor:GetRGB());
                    SetItemButtonTexture(questItem, texture);
                    SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                    SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
                    SetItemButtonQuality(questItem, quality, currencyID);

                    AddRewardElement(questItem);
                    rewardsCount = rewardsCount + 1;
                    foundCurrencies = foundCurrencies + 1;
                    if ( foundCurrencies == numQuestCurrencies ) then
                        break;
                    end
                end
            end
        end

        -- Major Faction Reputation Rewards
        if ( majorFactionRepRewards ) then
            for i, rewardInfo in ipairs(majorFactionRepRewards) do
                local reputationReward = rewardsFrame.reputationRewardPool:Acquire();
                reputationReward:SetUpMajorFactionReputationReward(rewardInfo);
                AddRewardElement(reputationReward);
            end
        end

        -- warmode bonus
        if ( hasWarModeBonus and Armory:IsWarModeDesired() ) then
            rewardsFrame.WarModeBonusFrame.Count:SetFormattedText(PLUS_PERCENT_FORMAT, C_PvP.GetWarModeRewardBonus());
            AddRewardElement(rewardsFrame.WarModeBonusFrame);
        end

        rewardsFrame.HonorFrame:ClearAllPoints();
        if ( honor > 0 ) then
            local icon;
            local isHorde = Armory:UnitFactionGroup("player") == PLAYER_FACTION_GROUP[PLAYER_FACTION_GROUP.Horde];
            if ( Armory.isClassic ) then
                -- the icons of Blizzard's quest info in TBC
                icon = isHorde and "Interface\\TargetingFrame\\UI-PVP-Horde" or "Interface\\TargetingFrame\\UI-PVP-Alliance";
            elseif ( isHorde ) then
                icon = "Interface\\Icons\\PVPCurrency-Honor-Horde";
            else
                icon = "Interface\\Icons\\PVPCurrency-Honor-Alliance";
            end

            rewardsFrame.HonorFrame.Count:SetText(BreakUpLargeNumbers(honor));
            rewardsFrame.HonorFrame.Name:SetText(HONOR);
            rewardsFrame.HonorFrame.Icon:SetTexture(icon);
            BeginRewardsSection();
            AddRewardElement(rewardsFrame.HonorFrame);
        else
            rewardsFrame.HonorFrame:Hide();
        end

        -- Bonus reward chance for quest sessions
        if ( hasChanceForQuestSessionBonusReward ) then
            rewardsCount = rewardsCount + 1;
            questItem = QuestInfo_GetRewardButton(rewardsFrame, rewardsCount);

            -- TODO: Go lookup the mouseover behavior to see how tooltips are created, probably need to use a specific tooltip:Set* function.
            questItem.type = "reward";
            questItem.objectType = "questSessionBonusReward";

            local QUEST_SESSION_BONUS_REWARD_ITEM_ID = 171305;
            local QUEST_SESSION_BONUS_REWARD_ITEM_COUNT = 1;
            local item = Item:CreateFromItemID(QUEST_SESSION_BONUS_REWARD_ITEM_ID);
            if ( item ) then
                item:ContinueOnItemLoad(function()
                    local quality = item:GetItemQuality();
                    questItem.quality = quality;
                    questItem.Name:SetText(item:GetItemName());
                    SetItemButtonCount(questItem, QUEST_SESSION_BONUS_REWARD_ITEM_COUNT);
                    SetItemButtonTexture(questItem, item:GetItemIcon());
                    SetItemButtonQuality(questItem, quality, QUEST_SESSION_BONUS_REWARD_ITEM_ID);
                    SetItemButtonTextureVertexColor(questItem, 1.0, 1.0, 1.0);
                    SetItemButtonNameFrameVertexColor(questItem, 1.0, 1.0, 1.0);
                end);
            end

            questItem:SetID(QUEST_SESSION_BONUS_REWARD_ITEM_ID);

            AddHeaderElement(rewardsFrame.QuestSessionBonusReward);
            AddRewardElement(questItem);
        else
            rewardsFrame.QuestSessionBonusReward:Hide();
        end
    else
        rewardsFrame.ItemReceiveText:Hide();
        rewardsFrame.QuestSessionBonusReward:Hide();
        rewardsFrame.MoneyFrame:Hide();
        rewardsFrame.XPFrame:Hide();
        rewardsFrame.SkillPointFrame:Hide();
        rewardsFrame.HonorFrame:Hide();
    end

    rewardsFrame:Show();
    rewardsFrame:SetHeight(totalHeight);
    return rewardsFrame, lastAnchorElement;
end

function ArmoryQuestInfoRewardItemCodeTemplate_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if (self.objectType == "questSessionBonusReward") then
        GameTooltip:SetItemByID(self:GetID());
        GameTooltip_ShowCompareItem(GameTooltip);
    elseif (self.objectType == "item") then
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
        ArmoryQuestInfo_ShowTitle, 8, -5,
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