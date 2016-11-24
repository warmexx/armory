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

local ARTIFACT_POWER_STYLE_RUNE = 1;
local ARTIFACT_POWER_STYLE_MAXED = 2;
local ARTIFACT_POWER_STYLE_CAN_UPGRADE = 3;
local ARTIFACT_POWER_STYLE_PURCHASED = 4;
local ARTIFACT_POWER_STYLE_UNPURCHASED = 5;
local ARTIFACT_POWER_STYLE_UNPURCHASED_LOCKED = 6;

local ARTIFACT_POWER_STYLE_PURCHASED_READ_ONLY = 7;
local ARTIFACT_POWER_STYLE_UNPURCHASED_READ_ONLY = 8;

----------------------------------------------------------
-- ArmoryArtifactFrame Mixin
----------------------------------------------------------

ArmoryArtifactFrameMixin = {};

function ArmoryArtifactFrameMixin:OnLoad()
    self:RegisterEvent("ARTIFACT_UPDATE");
    self:RegisterEvent("ARTIFACT_XP_UPDATE");
    --self:RegisterEvent("ARTIFACT_MAX_RANKS_UPDATE");
end

function ArmoryArtifactFrameMixin:OnShow()
    PlaySound("igCharacterInfoOpen");
    
    self:SetScale(Armory:GetConfigFrameScale());
    
    self:SetupPerArtifactData();
    self:RefreshKnowledgeRanks();
    self.PerksTab:Refresh(true);
end

function ArmoryArtifactFrameMixin:OnHide()
    PlaySound("igCharacterInfoClose");
end

function ArmoryArtifactFrameMixin:OnEvent(event, ...)
    if ( event == "ARTIFACT_UPDATE" ) then
        Armory:UpdateArtifact();

        local newItem = ...;

        if ( self:IsShown() ) then
            self:RefreshKnowledgeRanks();
            if ( newItem ) then
                self:SetupPerArtifactData();
            end
            self.PerksTab:Refresh(newItem);
        end
    elseif ( event == "ARTIFACT_XP_UPDATE" ) then
        if ( self:IsShown() ) then
            self.PerksTab:Refresh();
        end
    end
end

function ArmoryArtifactFrameMixin:ShowArtifact(link)
    local id = Armory:GetItemId(link);
    if ( id and Armory:IsArtifact(id) ) then
        if ( self:IsShown() ) then
            HideUIPanel(self);
        end
        Armory:SetSelectedArtifact(id);
        ShowUIPanel(self);
    end
end

local function MetaPowerTooltipHelper(...)
    local hasAddedAny = false;
    for i = 1, select("#", ...), 3 do
        local spellID, cost, currentRank = select(i, ...);
        local metaPowerDescription = GetSpellDescription(spellID);
        if ( metaPowerDescription ) then
            if ( hasAddedAny ) then
                GameTooltip:AddLine(" ");
            end
            GameTooltip:AddLine(metaPowerDescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            hasAddedAny = true;
        end
    end

    return hasAddedAny;
end

function ArmoryArtifactFrameMixin:RefreshKnowledgeRanks()
    local totalRanks = Armory:GetTotalPurchasedRanks();
    if ( totalRanks > 0 ) then
        self.ForgeBadgeFrame.ForgeLevelLabel:SetText(totalRanks);
        self.ForgeBadgeFrame.ForgeLevelLabel:Show();
        self.ForgeBadgeFrame.ForgeLevelBackground:Show();
        self.ForgeBadgeFrame.ForgeLevelBackgroundBlack:Show();
        self.ForgeLevelFrame:Show();
    else
        self.ForgeBadgeFrame.ForgeLevelLabel:Hide();
        self.ForgeBadgeFrame.ForgeLevelBackground:Hide();
        self.ForgeBadgeFrame.ForgeLevelBackgroundBlack:Hide();
        self.ForgeLevelFrame:Hide();
    end
end

function ArmoryArtifactFrameMixin:OnKnowledgeEnter(knowledgeFrame)
    GameTooltip:SetOwner(knowledgeFrame, "ANCHOR_BOTTOMRIGHT", -25, 27);
    local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = Armory:GetArtifactArtInfo();
    GameTooltip:SetText(titleName, titleR, titleG, titleB);

    GameTooltip:AddLine(ARTIFACTS_NUM_PURCHASED_RANKS:format(Armory:GetTotalPurchasedRanks()), HIGHLIGHT_FONT_COLOR:GetRGB());

    local addedAnyMetaPowers = MetaPowerTooltipHelper(Armory:GetMetaPowerInfo());

    local knowledgeLevel = Armory:GetArtifactKnowledgeLevel();
    if ( knowledgeLevel and knowledgeLevel > 0 ) then
        local knowledgeMultiplier = Armory:GetArtifactKnowledgeMultiplier();
        local percentIncrease = math.floor(((knowledgeMultiplier - 1.0) * 100) + .5);
        if ( percentIncrease > 0.0 ) then
            if ( addedAnyMetaPowers ) then
                GameTooltip:AddLine(" ");
            end

            GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_LEVEL:format(knowledgeLevel), HIGHLIGHT_FONT_COLOR:GetRGB());
            GameTooltip:AddLine(ARTIFACTS_KNOWLEDGE_TOOLTIP_DESC:format(BreakUpLargeNumbers(percentIncrease)), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        end
    end
    
    GameTooltip:Show();
end

function ArmoryArtifactFrameMixin:SetupPerArtifactData()
    local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = Armory:GetArtifactArtInfo();
    if ( textureKit ) then
        local classBadgeTexture = ("%s-ClassBadge"):format(textureKit);
        self.ForgeBadgeFrame.ForgeClassBadgeIcon:SetAtlas(classBadgeTexture, true);
    end
end


----------------------------------------------------------
-- ArmoryArtifactPerks Mixin
----------------------------------------------------------

ArmoryArtifactPerksMixin = {};

function ArmoryArtifactPerksMixin:RefreshModel()
    local itemID, altItemID, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop, uiCameraID, altHandUICameraID, modelAlpha, modelDesaturation = Armory:GetArtifactInfoEx();

    self.Model.uiCameraID = uiCameraID;
    self.Model.desaturation = modelDesaturation;
    if ( itemAppearanceID ) then
        self.Model:SetItemAppearance(itemAppearanceID);
    else
        self.Model:SetItem(itemID, appearanceModID);
    end

    self.Model.BackgroundFront:SetAlpha(1.0 - (modelAlpha or 1.0));

    self.Model:SetModelDrawLayer(altOnTop and "BORDER" or "ARTWORK");
    self.AltModel:SetModelDrawLayer(altOnTop and "ARTWORK" or "BORDER");

    if ( altItemID and altHandUICameraID ) then
        self.AltModel.uiCameraID = altHandUICameraID;
        self.AltModel.desaturation = modelDesaturation;
        if ( altItemAppearanceID ) then
            self.AltModel:SetItemAppearance(altItemAppearanceID);
        else
            self.AltModel:SetItem(altItemID, appearanceModID);
        end

        self.AltModel:Show();
    else
        self.AltModel:Hide();
    end
end

function ArmoryArtifactsModelTemplate_OnModelLoaded(self)
    local CUSTOM_ANIMATION_SEQUENCE = 213;
    local animationSequence = self:HasAnimation(CUSTOM_ANIMATION_SEQUENCE) and CUSTOM_ANIMATION_SEQUENCE or 0;

    if ( self.uiCameraID ) then
        Model_ApplyUICamera(self, self.uiCameraID);
    end
    self:SetLight(true, false, 0, 0, 0, .7, 1.0, 1.0, 1.0);
                
    self:SetDesaturation(self.desaturation or .5);

    self:SetAnimation(animationSequence, 0);
end

function ArmoryArtifactPerksMixin:RefreshBackground()
    local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = Armory:GetArtifactArtInfo();
    if ( textureKit ) then
        local bgAtlas = ("%s-BG"):format(textureKit);
        self.BackgroundBack:SetAtlas(bgAtlas);
        self.Model.BackgroundFront:SetAtlas(bgAtlas);
    end
end

function ArmoryArtifactPerksMixin:RefreshPowers(newItem)
    if ( newItem or not self.powerIDToPowerButton ) then
        self.powerIDToPowerButton = {};
    end

    self.startingPowerButton = nil;
    self.finalPowerButton = nil;

    local powers = Armory:GetPowers();

    -- Determine if all Gold Medal traits are fully purchased to determine when the final power should be shown
    local areAllGoldMedalsPurchased = true;
    for i, powerID in ipairs(powers) do
        local powerButton = self.powerIDToPowerButton[powerID];

        if ( not powerButton ) then
            powerButton = self:GetOrCreatePowerButton(i);
            self.powerIDToPowerButton[powerID] = powerButton;

            powerButton:ClearOldData();
        end

        powerButton:SetupButton(powerID, self.BackgroundBack);
        powerButton.links = {};
        powerButton.owner = self;

        if ( powerButton:IsStart() ) then
            self.startingPowerButton = powerButton;
        elseif ( powerButton:IsFinal() ) then
            self.finalPowerButton = powerButton;
        elseif ( powerButton:IsGoldMedal() ) then
            if ( not powerButton:IsCompletelyPurchased() ) then
                areAllGoldMedalsPurchased = false;
            end
        end

        powerButton:Show();
    end

    if ( self.finalPowerButton ) then
        if ( areAllGoldMedalsPurchased ) then
            if ( self.wasFinalPowerButtonUnlocked == false ) then
                self.wasFinalPowerButtonUnlocked = true;
            end
        else
            self.finalPowerButton:Hide();
            self.wasFinalPowerButtonUnlocked = false;
        end
    end

    self:HideUnusedWidgets(self.PowerButtons, #powers);
    self:RefreshDependencies(powers);
    self:RefreshRelics();
end

function ArmoryArtifactPerksMixin:GetOrCreatePowerButton(powerIndex)
    local button = self.PowerButtons and self.PowerButtons[powerIndex];
    if ( button ) then
        return button;
    end
    return CreateFrame("BUTTON", nil, self, "ArmoryArtifactPowerButtonTemplate");
end

function ArmoryArtifactPerksMixin:GetOrCreateDependencyLine(lineIndex)
    local lineContainer = self.DependencyLines and self.DependencyLines[lineIndex];
    if ( lineContainer ) then
        lineContainer:Show();
        return lineContainer;
    end

    lineContainer = CreateFrame("FRAME", nil, self, "ArmoryArtifactDependencyLineTemplate");

    return lineContainer;
end

function ArmoryArtifactPerksMixin:HideUnusedWidgets(widgetTable, numUsed, customHideFunc)
    if ( widgetTable ) then
        for i = numUsed + 1, #widgetTable do
            widgetTable[i]:Hide();
            if ( customHideFunc ) then
                customHideFunc(widgetTable[i]);
            end
        end
    end
end

local function Reveal(self, powerButton, distance)
    for linkedPowerID, linkedLineContainer in pairs(powerButton.links) do
        local linkedPowerButton = self.powerIDToPowerButton[linkedPowerID];
        
        if ( linkedPowerButton.hasSpentAny ) then
            Reveal(self, linkedPowerButton, distance);
        else 
            local distanceToLink = powerButton:CalculateDistanceTo(linkedPowerButton);
            local totalDistance = distance + distanceToLink;

            Reveal(self, linkedPowerButton, totalDistance);

            linkedLineContainer.Background:SetAlpha(0.0);
            linkedLineContainer.Fill:SetAlpha(0.0);
            linkedLineContainer.FillScroll1:SetAlpha(0.0);
            linkedLineContainer.FillScroll2:SetAlpha(0.0);
        end
    end
end

function ArmoryArtifactPerksMixin:Refresh(newItem)
    self.newItem = self.newItem or newItem;

    if ( newItem ) then
        self.revealed = nil;

        self:HideAllLines();
        self:RefreshBackground();
        self:RefreshModel();
    end

    local reveal = false;
    local hasBoughtAnyPowers = Armory:GetTotalPurchasedRanks() > 0;
    if ( newItem ) then
        self.hasBoughtAnyPowers = hasBoughtAnyPowers;
        self.wasFinalPowerButtonUnlocked = nil;
    elseif ( self.hasBoughtAnyPowers ~= hasBoughtAnyPowers ) then
        self:HideAllLines();
        self.hasBoughtAnyPowers = hasBoughtAnyPowers;
        if ( hasBoughtAnyPowers ) then
            reveal = true;
        end
    end

    self:RefreshPowers(newItem);
    
    self.TitleContainer:SetPointsRemaining(Armory:GetPointsRemaining());
    
    self.newItem = nil;

    if ( reveal and self.startingPowerButton and not self.revealed ) then
        self.revealed = true;
        Reveal(self, self.startingPowerButton, 0);
    end
end

local LINE_TYPE_CONNECTED = 1;
local LINE_TYPE_UNLOCKED = 2;
local LINE_TYPE_LOCKED = 3;

local function ShowDependencyLine(lineContainer, lineType)
    if ( lineType == LINE_TYPE_CONNECTED ) then
        lineContainer.Background:SetAlpha(0.0);
        lineContainer.Fill:SetAlpha(1.0);
        lineContainer.FillScroll1:SetAlpha(1.0);
        lineContainer.FillScroll2:SetAlpha(1.0);

    elseif ( lineType == LINE_TYPE_UNLOCKED ) then
        lineContainer.Background:SetAlpha(1.0);
        lineContainer.Fill:SetAlpha(1.0);
        lineContainer.FillScroll1:SetAlpha(0.0);
        lineContainer.FillScroll2:SetAlpha(0.0);

    elseif ( lineType == LINE_TYPE_LOCKED ) then
        lineContainer.Background:SetAlpha(0.85);
        lineContainer.Fill:SetAlpha(0.0);
        lineContainer.FillScroll1:SetAlpha(0.0);
        lineContainer.FillScroll2:SetAlpha(0.0);
    end
end

local function OnUnusedLineHidden(lineContainer)
    lineContainer.Background:SetAlpha(0.0);
    lineContainer.Fill:SetAlpha(0.0);
    lineContainer.FillScroll1:SetAlpha(0.0);
    lineContainer.FillScroll2:SetAlpha(0.0);
end

function ArmoryArtifactPerksMixin:RefreshDependencies(powers)
    local numUsedLines = 0;

    local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = Armory:GetArtifactArtInfo();

    for i, fromPowerID in ipairs(powers) do
        local fromButton = self.powerIDToPowerButton[fromPowerID];
        local fromLinks = Armory:GetPowerLinks(fromPowerID);

        if ( fromLinks ) then
            for j, toPowerID in ipairs(fromLinks) do
                if ( not fromButton.links[toPowerID] ) then
                    local toButton = self.powerIDToPowerButton[toPowerID];
                    if ( toButton and not toButton.links[fromPowerID] ) then
                        numUsedLines = numUsedLines + 1;
                        local lineContainer = self:GetOrCreateDependencyLine(numUsedLines);

                        lineContainer.Fill:SetStartPoint("CENTER", fromButton);
                        lineContainer.Fill:SetEndPoint("CENTER", toButton);

                        if ( self.hasBoughtAnyPowers or ((toButton:IsStart() or toButton.prereqsMet) and (fromButton:IsStart() or fromButton.prereqsMet)) ) then
                            local hasSpentAny = fromButton.hasSpentAny and toButton.hasSpentAny;
                            if ( hasSpentAny or (fromButton.isCompletelyPurchased and (toButton.couldSpendPoints or toButton.isMaxRank)) or (toButton.isCompletelyPurchased and (fromButton.couldSpendPoints or fromButton.isMaxRank)) ) then
                                if ( (fromButton.isCompletelyPurchased and toButton.hasSpentAny) or (toButton.isCompletelyPurchased and fromButton.hasSpentAny) ) then
                                    lineContainer.Fill:SetVertexColor(barConnectedR, barConnectedG, barConnectedB);
                                    lineContainer.FillScroll1:SetVertexColor(barConnectedR, barConnectedG, barConnectedB);
                                    lineContainer.FillScroll2:SetVertexColor(barConnectedR, barConnectedG, barConnectedB);

                                    lineContainer.FillScroll1:Show();
                                    lineContainer.FillScroll1:SetStartPoint("CENTER", fromButton);
                                    lineContainer.FillScroll1:SetEndPoint("CENTER", toButton);

                                    lineContainer.FillScroll2:Show();
                                    lineContainer.FillScroll2:SetStartPoint("CENTER", fromButton);
                                    lineContainer.FillScroll2:SetEndPoint("CENTER", toButton);

                                    ShowDependencyLine(lineContainer, LINE_TYPE_CONNECTED);
                                else
                                    lineContainer.Fill:SetVertexColor(barDisconnectedR, barDisconnectedG, barDisconnectedB);

                                    lineContainer.Background:SetStartPoint("CENTER", fromButton);
                                    lineContainer.Background:SetEndPoint("CENTER", toButton);

                                    ShowDependencyLine(lineContainer, LINE_TYPE_UNLOCKED);
                                end
                            else
                                lineContainer.Fill:SetVertexColor(barConnectedR, barConnectedG, barConnectedB);
                                lineContainer.Background:SetStartPoint("CENTER", fromButton);
                                lineContainer.Background:SetEndPoint("CENTER", toButton);

                                ShowDependencyLine(lineContainer, LINE_TYPE_LOCKED);
                            end
                        end

                        fromButton.links[toPowerID] = lineContainer;
                        toButton.links[fromPowerID] = lineContainer;
                    end
                end
            end
        end
    end

    self:HideUnusedWidgets(self.DependencyLines, numUsedLines, OnUnusedLineHidden);
end

local function RelicRefreshHelper(self, relicSlotIndex, powersAffected, ...)
    for i = 1, select("#", ...) do
        local powerID = select(i, ...);
        powersAffected[powerID] = true;
        self:AddRelicToPower(powerID, relicSlotIndex);
    end
end

function ArmoryArtifactPerksMixin:RefreshRelics()
    local powersAffected = {};
    for relicSlotIndex = 1, Armory:GetNumRelicSlots() do
        RelicRefreshHelper(self, relicSlotIndex, powersAffected, Armory:GetPowersAffectedByRelic(relicSlotIndex));
    end

    for powerID, button in pairs(self.powerIDToPowerButton) do
        if ( not powersAffected[powerID] ) then
            button:RemoveRelicType();
        end
    end
end

function ArmoryArtifactPerksMixin:AddRelicToPower(powerID, relicSlotIndex)
    local button = self.powerIDToPowerButton[powerID];
    if ( button ) then
        local relicType = Armory:GetRelicSlotType(relicSlotIndex);
        local lockedReason, relicName, relicIcon, relicLink = Armory:GetRelicInfo(relicSlotIndex);
        button:ApplyRelicType(relicType, relicLink, self.newItem);
    end
end

local function RelicHighlightHelper(self, highlightEnabled, ...)
    for i = 1, select("#", ...) do
        local powerID = select(i, ...);
        self:SetRelicPowerHighlightEnabled(powerID, highlightEnabled);
    end
end

function ArmoryArtifactPerksMixin:OnRelicSlotMouseEnter(relicSlotIndex)
    RelicHighlightHelper(self, true, Armory:GetPowersAffectedByRelic(relicSlotIndex));
end

function ArmoryArtifactPerksMixin:OnRelicSlotMouseLeave(relicSlotIndex)
    RelicHighlightHelper(self, false, Armory:GetPowersAffectedByRelic(relicSlotIndex));
end

function ArmoryArtifactPerksMixin:SetRelicPowerHighlightEnabled(powerID, highlight, tempRelicType, tempRelicLink)
    local button = self.powerIDToPowerButton[powerID];
    if ( button ) then
        if ( highlight and tempRelicType and tempRelicLink ) then
            button:ApplyTemporaryRelicType(tempRelicType, tempRelicLink);
        else
            button:RemoveTemporaryRelicType();
        end
        button:SetRelicHighlightEnabled(highlight);
    end
end

function ArmoryArtifactPerksMixin:HideAllLines()
    self:HideUnusedWidgets(self.DependencyLines, 0, OnUnusedLineHidden);
end

----------------------------------------------------------
-- ArmoryArtifactTitleTemplate Mixin
----------------------------------------------------------

ArmoryArtifactTitleTemplateMixin = {};

function ArmoryArtifactTitleTemplateMixin:RefreshTitle()
    local textureKit, titleName, titleR, titleG, titleB, barConnectedR, barConnectedG, barConnectedB, barDisconnectedR, barDisconnectedG, barDisconnectedB = Armory:GetArtifactArtInfo();
    self.ArtifactName:SetText(titleName);
    self.ArtifactName:SetVertexColor(titleR, titleG, titleB);

    if ( textureKit ) then
        local headerAtlas = ("%s-Header"):format(textureKit);
        self.Background:SetAtlas(headerAtlas, true);
        self.Background:Show();
    else
        self.Background:Hide();
    end
end

function ArmoryArtifactTitleTemplateMixin:OnShow()
    self:RefreshTitle();
    self:EvaluateRelics();

    self:RegisterEvent("ARTIFACT_UPDATE");
end

function ArmoryArtifactTitleTemplateMixin:OnHide()
    self:UnregisterEvent("ARTIFACT_UPDATE");
end

function ArmoryArtifactTitleTemplateMixin:OnEvent(event, ...)
    local newItem = ...;
    if ( newItem ) then
        self:RefreshTitle();
    end
    self:EvaluateRelics();
    self:RefreshRelicTooltips();
end

function ArmoryArtifactTitleTemplateMixin:OnRelicSlotMouseEnter(relicSlot)
    if ( relicSlot.lockedReason ) then
        GameTooltip:SetOwner(relicSlot, "ANCHOR_BOTTOMRIGHT", 0, 10);
        local slotName = _G["RELIC_SLOT_TYPE_" .. relicSlot.relicType:upper()];
        if ( slotName ) then
            GameTooltip:SetText(LOCKED_RELIC_TOOLTIP_TITLE:format(slotName), 1, 1, 1);
            if relicSlot.lockedReason == "" then
                GameTooltip:AddLine(LOCKED_RELIC_TOOLTIP_BODY, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            else
                GameTooltip:AddLine(relicSlot.lockedReason, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            end
            GameTooltip:Show();
        end
    elseif ( relicSlot.relicLink ) then
        GameTooltip:SetOwner(relicSlot, "ANCHOR_BOTTOMRIGHT", 0, 10);
        GameTooltip:SetHyperlink(relicSlot.relicLink);
    elseif ( relicSlot.relicType ) then
        GameTooltip:SetOwner(relicSlot, "ANCHOR_BOTTOMRIGHT", 0, 10);
        local slotName = _G["RELIC_SLOT_TYPE_" .. relicSlot.relicType:upper()];
        if ( slotName ) then
            GameTooltip:SetText(EMPTY_RELIC_TOOLTIP_TITLE:format(slotName), 1, 1, 1);
            GameTooltip:AddLine(EMPTY_RELIC_TOOLTIP_BODY:format(slotName), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
            GameTooltip:Show();
        end
    end
    self:GetParent():OnRelicSlotMouseEnter(relicSlot.relicSlotIndex);
end

function ArmoryArtifactTitleTemplateMixin:OnRelicSlotMouseLeave(relicSlot)
    GameTooltip_Hide();
    self:GetParent():OnRelicSlotMouseLeave(relicSlot.relicSlotIndex);
end

function ArmoryArtifactTitleTemplateMixin:OnRelicSlotClicked(relicSlot)
    for i = 1, #self.RelicSlots do
        if ( self.RelicSlots[i] == relicSlot ) then
            if ( IsModifiedClick() ) then
                local _, _, _, itemLink = Armory:GetRelicInfo(i);
                HandleModifiedItemClick(itemLink);
            end
            break;
        end
    end
end

function ArmoryArtifactTitleTemplateMixin:RefreshRelicTooltips()
    for i = 1, #self.RelicSlots do
        if ( GameTooltip:IsOwned(self.RelicSlots[i]) ) then
            self.RelicSlots[i]:GetScript("OnEnter")(self.RelicSlots[i]);
            break;
        end
    end
end

function ArmoryArtifactTitleTemplateMixin:EvaluateRelics()
    local numRelicSlots = Armory:GetNumRelicSlots() or 0;

    self:SetHeight(140);
    
    for i = 1, numRelicSlots do
        local relicSlot = self.RelicSlots[i];

        local relicType = Armory:GetRelicSlotType(i);

        local relicAtlasName = ("Relic-%s-Slot"):format(relicType);
        relicSlot:GetNormalTexture():SetAtlas(relicAtlasName, true);
        relicSlot:GetHighlightTexture():SetAtlas(relicAtlasName, true);
        relicSlot.GlowBorder1:SetAtlas(relicAtlasName, true);
        relicSlot.GlowBorder2:SetAtlas(relicAtlasName, true);
        relicSlot.GlowBorder3:SetAtlas(relicAtlasName, true);
        local lockedReason, relicName, relicIcon, relicLink = Armory:GetRelicInfo(i);
        if ( lockedReason ) then
            relicSlot:GetNormalTexture():SetAlpha(.5);
            relicSlot:Disable();
            relicSlot.LockedIcon:Show();
            relicSlot.Icon:SetMask(nil);
            relicSlot.Icon:SetAtlas("Relic-SlotBG", true);
            relicSlot.Glass:Hide();
        else
            relicSlot:GetNormalTexture():SetAlpha(1);
            relicSlot:Enable();
            relicSlot.LockedIcon:Hide();
            if ( relicIcon ) then
                relicSlot.Icon:SetSize(34, 34);
                relicSlot.Icon:SetMask(nil);
                relicSlot.Icon:SetTexCoord(0, 1, 0, 1); -- Masks may overwrite our tex coords (even ones set by an atlas), force it back to using the full item icon texture
                relicSlot.Icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask");
                relicSlot.Icon:SetTexture(relicIcon);
                relicSlot.Glass:Show();
            else
                relicSlot.Icon:SetMask(nil);
                relicSlot.Icon:SetAtlas("Relic-SlotBG", true);
                relicSlot.Glass:Hide();
            end
        end

        relicSlot.relicLink = relicLink;
        relicSlot.relicType = relicType;
        relicSlot.relicSlotIndex = i;
        relicSlot.lockedReason = lockedReason;

        relicSlot:ClearAllPoints();
        local PADDING = 0;
        if ( i == 1 ) then
            local offsetX = -(numRelicSlots - 1) * (relicSlot:GetWidth() + PADDING) * .5;
            relicSlot:SetPoint("CENTER", self, "CENTER", offsetX, -6);
        else
            relicSlot:SetPoint("LEFT", self.RelicSlots[i - 1], "RIGHT", PADDING, 0);
        end

        relicSlot:Show();
    end

    for i = numRelicSlots + 1, #self.RelicSlots do
        self.RelicSlots[i]:Hide();
    end
end

function ArmoryArtifactTitleTemplateMixin:SetPointsRemaining(value)
    self.PointsRemainingLabel:SetText(value);
end


----------------------------------------------------------
-- ArmoryArtifactPowerButton Mixin
----------------------------------------------------------

ArmoryArtifactPowerButtonMixin = {};

function ArmoryArtifactPowerButtonMixin:OnLoad()
    local NUM_RUNE_TYPES = 11;
    local runeIndex = math.random(1, NUM_RUNE_TYPES);

    self.LightRune:SetAtlas(("Rune-%02d-light"):format(runeIndex), true);
end

function ArmoryArtifactPowerButtonMixin:OnEnter()
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetArtifactPowerByID(self:GetPowerID());

        Armory:FilterTooltip(GameTooltip, TOOLTIP_TALENT_RANK, ARTIFACT_POWER_UNLINKED_TOOLTIP);

        self.UpdateTooltip = self.OnEnter;
    end
end

function ArmoryArtifactPowerButtonMixin:OnClick(button)
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and IsModifiedClick("CHATLINK") ) then
        local link = Armory:GetPowerHyperlink(self:GetPowerID());
        if ( link ) then
            ChatEdit_InsertLink(link);
        end
    end
end

function ArmoryArtifactPowerButtonMixin:UpdatePowerType()
    if ( self.isStart ) then
        self.Icon:SetSize(52, 52);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-MainProc", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-MainProc", true);
    elseif ( self.isGoldMedal ) then
        self.Icon:SetSize(50, 50);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-GoldMedal", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-GoldMedal", true);
    else
        self.Icon:SetSize(45, 45);
        self.IconBorder:SetAtlas("Artifacts-PerkRing-Small", true);
        self.IconBorderDesaturated:SetAtlas("Artifacts-PerkRing-Small", true);
    end
end

function ArmoryArtifactPowerButtonMixin:SetStyle(style)
    self.style = style;
    self.Icon:SetAlpha(1);
    self.Icon:SetVertexColor(1, 1, 1);
    self.IconDesaturated:SetAlpha(1);
    self.IconDesaturated:SetVertexColor(1, 1, 1);
    
    self.IconBorder:SetAlpha(1);
    self.IconBorder:SetVertexColor(1, 1, 1);
    self.IconBorderDesaturated:SetAlpha(0);

    self.Rank:SetAlpha(1);
    self.RankBorder:SetAlpha(1);

    self.LightRune:Hide();

    if ( style == ARTIFACT_POWER_STYLE_RUNE ) then
        self.LightRune:Show();

        self.Icon:SetAlpha(0);
        self.IconBorder:SetAlpha(0);

        self.Rank:SetAlpha(0);
        self.RankBorder:SetAlpha(0);

        self.IconDesaturated:SetAlpha(0);
    elseif ( style == ARTIFACT_POWER_STYLE_MAXED ) then
        self.Rank:SetText(self.currentRank);
        self.Rank:SetTextColor(1, 0.82, 0);
        self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        self.RankBorder:Show();        
    elseif ( style == ARTIFACT_POWER_STYLE_CAN_UPGRADE ) then
        self.Rank:SetText(self.currentRank);
        self.Rank:SetTextColor(0.1, 1, 0.1);
        self.RankBorder:SetAtlas("Artifacts-PointsBoxGreen", true);
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_PURCHASED or style == ARTIFACT_POWER_STYLE_PURCHASED_READ_ONLY ) then
        self.Rank:SetText(self.currentRank);
        self.Rank:SetTextColor(1, 0.82, 0);
        self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_UNPURCHASED ) then
        self.Icon:SetVertexColor(.6, .6, .6);
        self.IconBorder:SetVertexColor(.9, .9, .9);

        self.Rank:SetText(self.currentRank);
        self.Rank:SetTextColor(1, 0.82, 0);
        self.RankBorder:SetAtlas("Artifacts-PointsBox", true);
        self.RankBorder:Show();
    elseif ( style == ARTIFACT_POWER_STYLE_UNPURCHASED_READ_ONLY or style == ARTIFACT_POWER_STYLE_UNPURCHASED_LOCKED ) then
        if ( self.isGoldMedal or self.isStart ) then
            self.Icon:SetVertexColor(.4, .4, .4);
            self.IconBorder:SetVertexColor(.7, .7, .7);
            self.IconDesaturated:SetVertexColor(.4, .4, .4);
            self.RankBorder:Hide();
            self.Rank:SetText(nil);
            self.IconBorderDesaturated:SetAlpha(.5);
            self.Icon:SetAlpha(.5);
        else
            self.Icon:SetVertexColor(.15, .15, .15);
            self.IconBorder:SetVertexColor(.4, .4, .4);
            self.IconDesaturated:SetVertexColor(.15, .15, .15);
            self.RankBorder:Hide();
            self.Rank:SetText(nil);
            self.Icon:SetAlpha(.2);
        end
    end
end

function ArmoryArtifactPowerButtonMixin:ApplyTemporaryRelicType(relicType, relicLink)
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and self.originalRelicType == nil and self.originalRelicLink == nil ) then
        self.originalRelicType = self.relicType or false;
        self.originalRelicLink = self.relicLink or false;
        self:ApplyRelicType(relicType, relicLink, true);
    end
end

function ArmoryArtifactPowerButtonMixin:RemoveTemporaryRelicType()
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and self.originalRelicType ~= nil and self.originalRelicLink ~= nil ) then
        self:ApplyRelicType(self.originalRelicType or nil, self.originalRelicLink or nil, true);

        self.originalRelicType = nil;
        self.originalRelicLink = nil;
    end
end

function ArmoryArtifactPowerButtonMixin:ApplyRelicType(relicType, relicLink)
    if ( self.style == ARTIFACT_POWER_STYLE_RUNE ) then
        -- Runes cannot have relics
        relicType = nil;
        relicLink = nil;
    end

    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE and relicType ) then
        local relicTraitBGAtlas = ("Relic-%s-TraitBG"):format(relicType);
        self.RelicTraitBG:SetAtlas(relicTraitBGAtlas);
        self.RelicTraitBG:Show();

        local relicTraitGlowAtlas = ("Relic-%s-TraitGlow"):format(relicType);
        self.RelicTraitGlow:SetAtlas(relicTraitGlowAtlas);

        local relicTraitGlowRingAtlas = ("Relic-%s-TraitGlowRing"):format(relicType);
        self.RelicTraitGlowRing:SetAtlas(relicTraitGlowRingAtlas);

        local isLarge = self.isStart or self.isGoldMedal;
        local traitSize = isLarge and 120 or 82;
        self.RelicTraitBG:SetSize(traitSize, traitSize);
        self.RelicTraitGlow:SetSize(traitSize, traitSize);

        local ringSize = isLarge and 98 or 82;
        self.RelicTraitGlowRing:SetSize(ringSize, ringSize);

        self:SetRelicHighlightEnabled(false);
    else
        self.RelicTraitBG:Hide();
        self.RelicTraitGlow:Hide();
        self.RelicTraitGlowRing:Hide();
    end
    self.relicType = relicType;
    self.relicLink = relicLink;
end

function ArmoryArtifactPowerButtonMixin:RemoveRelicType()
    self.relicType = nil;
    self.relicLink = nil;
    self.originalRelicType = nil;
    self.originalRelicLink = nil;

    self.RelicTraitBG:Hide();
    self.RelicTraitGlow:Hide();
    self.RelicTraitGlowRing:Hide();
end

local HIGHLIGHT_ALPHA = 1.0;
local NO_HIGHLIGHT_ALPHA = .8;
function ArmoryArtifactPowerButtonMixin:SetRelicHighlightEnabled(enabled)
    if ( self.style ~= ARTIFACT_POWER_STYLE_RUNE ) then
        self.RelicTraitGlow:SetShown(enabled);
        self.RelicTraitGlowRing:SetShown(enabled);
        self.RelicTraitBG:SetAlpha(enabled and HIGHLIGHT_ALPHA or NO_HIGHLIGHT_ALPHA);
    end
end

function ArmoryArtifactPowerButtonMixin:GetPowerID()
    return self.powerID;
end

function ArmoryArtifactPowerButtonMixin:IsStart()
    return self.isStart;
end

function ArmoryArtifactPowerButtonMixin:IsFinal()
    return self.isFinal;
end

function ArmoryArtifactPowerButtonMixin:IsGoldMedal()
    return self.isGoldMedal;
end

function ArmoryArtifactPowerButtonMixin:IsCompletelyPurchased()
    return self.isCompletelyPurchased;
end

function ArmoryArtifactPowerButtonMixin:CalculateDistanceTo(otherPowerButton)
    local cx, cy = self:GetCenter();
    local ocx, ocy = otherPowerButton:GetCenter();
    local dx, dy = ocx - cx, ocy - cy;
    return math.sqrt(dx * dx + dy * dy);
end

function ArmoryArtifactPowerButtonMixin:SetupButton(powerID, anchorRegion)
    local spellID, cost, currentRank, maxRank, bonusRanks, x, y, prereqsMet, isStart, isGoldMedal, isFinal = Armory:GetPowerInfo(powerID);
    self:ClearAllPoints();
    self:SetPoint("CENTER", anchorRegion, "TOPLEFT", x * anchorRegion:GetWidth(), -y * anchorRegion:GetHeight());

    local name, _, texture = GetSpellInfo(spellID);
    self.Icon:SetTexture(texture);
    self.IconDesaturated:SetTexture(texture);

    local totalPurchasedRanks = Armory:GetTotalPurchasedRanks();
    local wasJustUnlocked = prereqsMet and self.prereqsMet == false;
    local wasRespecced = self.currentRank and currentRank < self.currentRank;
    local wasBonusRankJustIncreased = self.bonusRanks and bonusRanks > self.bonusRanks;

    self.powerID = powerID;
    self.spellID = spellID;
    self.currentRank = currentRank;
    self.bonusRanks = bonusRanks;
    self.maxRank = maxRank;
    self.isStart = isStart;
    self.isGoldMedal = isGoldMedal;
    self.isFinal = isFinal;

    self.isCompletelyPurchased = currentRank == maxRank or self.isStart;
    self.hasSpentAny = currentRank > bonusRanks;
    self.isMaxRank = currentRank == maxRank;
    self.prereqsMet = prereqsMet;
    self.wasBonusRankJustIncreased = wasBonusRankJustIncreased;
    self.cost = cost;

    self:UpdatePowerType();

    self:EvaluateStyle();
end

function ArmoryArtifactPowerButtonMixin:EvaluateStyle()
    if ( Armory:GetTotalPurchasedRanks() == 0 and not self.prereqsMet ) then
        self:SetStyle(ARTIFACT_POWER_STYLE_RUNE);    
    else
        if ( Armory:GetTotalPurchasedRanks() == 0 and Armory:GetNumObtainedArtifacts() <= 1 ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_RUNE);
        elseif ( Armory:IsPowerKnown(self.powerID) ) then
            self:SetStyle(ARTIFACT_POWER_STYLE_PURCHASED_READ_ONLY);
        else
            self:SetStyle(ARTIFACT_POWER_STYLE_UNPURCHASED_READ_ONLY);
        end
    end
end

function ArmoryArtifactPowerButtonMixin:ClearOldData()
    self.powerID = nil;
    self.spellID = nil;
    self.currentRank = nil;
    self.bonusRanks = nil;
    self.maxRank = nil;
    self.isStart = nil;
    self.isGoldMedal = nil;
    self.isFinal = nil;
    self.cost = nil;

    self.isCompletelyPurchased = nil;
    self.hasSpentAny = nil;
    self.isMaxRank = nil;
    self.prereqsMet = nil;
    self.wasBonusRankJustIncreased = nil;

    self.relicType = nil;
    self.relicLink = nil;
    self.originalRelicType = nil;
    self.originalRelicLink = nil;
end