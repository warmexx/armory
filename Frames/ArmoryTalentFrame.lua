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

local MAX_TALENT_SPECTABS = 4;

local TAB_CLASS = 1;
local TAB_SPEC = 2;
local TAB_HERO = 3;
local TAB_PARTS = { "class", "spec", "hero" };
local TABS_MAX_WIDTH = 274;

-- The sizes in Blizzard's talent frame, in which a row is 600 units of a tenth of a pixel
local BLIZZARD_SCALE = 0.1;
local BLIZZARD_ROW = 600;
local BLIZZARD_BUTTON_SIZE = 40;
local BLIZZARD_CAPSTONE_SIZE = 64;
local BLIZZARD_ICON_RATIO = 0.9;
local BLIZZARD_LINE_THICKNESS = 6;

local MIN_BUTTON_SIZE = 22;
local MAX_BUTTON_SIZE = 36;
local BUTTON_ROW_RATIO = 0.85;
local TREE_MARGIN = 34;

local CHOICE_BUTTON_SIZE = 36;
local CHOICE_SPACING = 8;
local CHOICE_PADDING = 10;

local ART_SQUARE = { atlas = "talents-node-square-%s", baseSize = BLIZZARD_BUTTON_SIZE, scale = 1 };
local ART_CIRCLE = { atlas = "talents-node-circle-%s", mask = "talents-node-circle-mask", baseSize = BLIZZARD_BUTTON_SIZE, scale = 1 };
local ART_CHOICE = { atlas = "talents-node-choice-%s", mask = "talents-node-choice-mask", baseSize = BLIZZARD_BUTTON_SIZE, scale = 1 };
local ART_CAPSTONE_SQUARE = { atlas = "talents-node-apex-active-large-%s", baseSize = BLIZZARD_CAPSTONE_SIZE, scale = 1.4 };
local ART_CAPSTONE_CIRCLE = { atlas = "talents-node-apex-large-%s", mask = "talents-node-circle-mask", baseSize = BLIZZARD_CAPSTONE_SIZE, scale = 1.4 };

local STATE_MAXED = "yellow";
local STATE_PARTIAL = "green";
local STATE_EMPTY = "gray";

local buttons = {};
local choiceButtons = {};
local lines = {};
local shownNodes = {};
local shownButtons = {};

-- Forever: the spec tabs are the spec groups (dual spec), as there is one spec per class
local function GetActiveSpecTab(self)
    if ( Armory.isForever ) then
        return Armory:GetActiveSpecGroup();
    end
    return Armory:GetSpecialization(false, false, self.talentGroup) or 1;
end

-- Forever also stores the inactive spec group
local function IsTalentConfig(configID)
    if ( Armory.isForever ) then
        for specGroup = 1, GetNumSpecGroups() do
            if ( configID == C_SpecializationInfo.GetCombatConfigIDForSpecGroup(specGroup) ) then
                return true;
            end
        end
        return false;
    end
    return configID == C_ClassTalents.GetActiveConfigID();
end

function ArmoryTalentFrame_OnLoad(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PLAYER_TALENT_UPDATE");
    self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
    self:RegisterEvent("TRAIT_CONFIG_UPDATED");
    self:RegisterEvent("PET_SPECIALIZATION_CHANGED");
    self:RegisterEvent("PLAYER_LEVEL_UP");
    if ( Armory.isForever ) then
        self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
    end

    self.talentGroup = 1;
    self.selectedSpec = 1;

    ArmoryPanelTemplates_SetNumTabs(self, #TAB_PARTS);
    ArmoryPanelTemplates_SetTab(self, TAB_CLASS);
end

function ArmoryTalentFrame_OnEvent(self, event, arg1)
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "PLAYER_ENTERING_WORLD" ) then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
        self.talentGroup = Armory:GetActiveSpecGroup();
        self.selectedSpec = GetActiveSpecTab(self);
        Armory:Execute(ArmoryTalentFrame_UpdateSpecs);
        Armory:Execute(ArmoryTalentFrame_UpdateTalents);
    elseif ( event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_LEVEL_UP" or event == "ACTIVE_TALENT_GROUP_CHANGED" ) then
        Armory:Execute(ArmoryTalentFrame_UpdateTalents);
    elseif ( event == "TRAIT_CONFIG_UPDATED" ) then
        -- Also fires for other trait systems
        if ( IsTalentConfig(arg1) ) then
            Armory:Execute(ArmoryTalentFrame_UpdateTalents);
        end
    elseif ( event == "PET_SPECIALIZATION_CHANGED" ) then
        Armory:Execute(ArmoryTalentFrame_UpdateSpecs);
    end
end

function ArmoryTalentFrame_UpdateSpecs()
    local _, isHunterPet = HasPetUI();
    Armory:SetSpecializations("player");
    if ( isHunterPet ) then
        Armory:SetSpecializations("pet");
    end
end

function ArmoryTalentFrame_UpdateTalents()
    Armory:SetTalents();
    if ( ArmoryTalentFrame:IsVisible() ) then
        ArmoryTalentFrame_Update();
    end
end

function ArmoryTalentFrame_OnShow(self)
    Armory:SetTalents();
    Armory:SetHonorTalents();
    ArmoryTalentFrame_UpdateSpecTabs(self);
    ArmoryTalentFrame_Update();
end

local function IsActiveSpec(self, spec)
    if ( Armory.isForever ) then
        return spec == Armory:GetActiveSpecGroup();
    end
    return self.talentGroup == Armory:GetActiveSpecGroup() and spec == Armory:GetSpecialization(false, false, self.talentGroup);
end

-- Without a choice the tree is shown without ranks, below the level of the choice there is none; returns subTreeID, name, iconElementID, currencyID
local function GetShownHeroTree(specID)
    local activeTree = Armory:GetActiveTalentHeroTree(specID);
    if ( not activeTree ) then
        local heroLevel = Armory:GetTalentHeroLevel(specID);
        if ( not heroLevel or Armory:UnitLevel("player") < heroLevel ) then
            return;
        end
    end

    local index = 1;
    for i = 1, Armory:GetNumTalentHeroTrees(specID) or 0 do
        if ( Armory:GetTalentHeroTreeInfo(specID, i) == activeTree ) then
            index = i;
        end
    end
    local subTreeID, name, iconElementID, _, _, currencyID = Armory:GetTalentHeroTreeInfo(specID, index);
    return subTreeID, name, iconElementID, currencyID;
end

----------------------------------------------------------
-- Tree Functions
----------------------------------------------------------

local function GetEntryName(spellID, overrideName)
    if ( overrideName and overrideName ~= "" ) then
        return overrideName;
    end
    return spellID and C_Spell.GetSpellName(spellID) or "";
end

local function GetEntryIcon(spellID, overrideIcon)
    if ( overrideIcon and overrideIcon ~= 0 ) then
        return overrideIcon;
    end
    return spellID and select(2, C_Spell.GetSpellTexture(spellID));
end

local function GetEntryIndex(nodeID, entryID)
    for i = 1, Armory:GetNumTalentNodeEntries(nodeID) or 0 do
        if ( Armory:GetTalentNodeEntryInfo(nodeID, i) == entryID ) then
            return i;
        end
    end
    return 1;
end

local function GetButtonArt(nodeType, entryType)
    if ( nodeType == Enum.TraitNodeType.Selection ) then
        return ART_CHOICE;
    elseif ( entryType == Enum.TraitNodeEntryType.SpendCapstoneCircle ) then
        return ART_CAPSTONE_CIRCLE;
    elseif ( entryType == Enum.TraitNodeEntryType.SpendCapstoneSquare ) then
        return ART_CAPSTONE_SQUARE;
    elseif ( entryType == Enum.TraitNodeEntryType.SpendCircle or entryType == Enum.TraitNodeEntryType.SpendSmallCircle ) then
        return ART_CIRCLE;
    end
    return ART_SQUARE;
end

local function SetScaledAtlas(texture, atlas, ratio)
    local atlasInfo = C_Texture.GetAtlasInfo(atlas);
    texture:SetAtlas(atlas, false);
    if ( atlasInfo ) then
        texture:SetSize(atlasInfo.width * ratio, atlasInfo.height * ratio);
    end
end

local function SetButtonArt(button, art, state, size)
    size = floor(size * art.scale);

    button:SetSize(size, size);
    button.icon:SetSize(size * BLIZZARD_ICON_RATIO, size * BLIZZARD_ICON_RATIO);
    SetScaledAtlas(button.border, format(art.atlas, state), size / art.baseSize);

    if ( art.mask ) then
        button.iconMask:SetAtlas(art.mask, false);
        if ( not button.isMasked ) then
            button.icon:AddMaskTexture(button.iconMask);
            button.isMasked = true;
        end
    elseif ( button.isMasked ) then
        button.icon:RemoveMaskTexture(button.iconMask);
        button.isMasked = false;
    end
end

local function SetButtonEntry(button, nodeID, index, rank, maxRanks, art, size)
    local _, spellID, _, _, _, overrideIcon = Armory:GetTalentNodeEntryInfo(nodeID, index);

    button.nodeID = nodeID;
    button.entryIndex = index;
    button.spellID = spellID;
    button.rank = rank;
    button.maxRanks = maxRanks;

    local state = STATE_EMPTY;
    if ( rank >= maxRanks ) then
        state = STATE_MAXED;
    elseif ( rank > 0 ) then
        state = STATE_PARTIAL;
    end
    SetButtonArt(button, art, state, size);

    button.icon:SetTexture(GetEntryIcon(spellID, overrideIcon) or "Interface\\Icons\\INV_Misc_QuestionMark");
    button.icon:SetDesaturated(rank == 0);
    button.icon:SetAlpha((rank == 0) and 0.7 or 1);

    if ( rank > 0 and maxRanks > 1 ) then
        local color = (state == STATE_MAXED) and NORMAL_FONT_COLOR or GREEN_FONT_COLOR;
        button.rankText:SetTextColor(color.r, color.g, color.b);
        button.rankText:SetText(rank);
    else
        button.rankText:SetText("");
    end
end

local function UpdateButton(button, specID, nodeID, nodeType, nodeMaxRanks, size)
    local rank, entryID = Armory:GetTalentNodeState(specID, nodeID);

    -- A capstone always shows its first tier, the other tiers only add to it
    local isTiered = (nodeType == Enum.TraitNodeType.Tiered);
    local index = isTiered and 1 or GetEntryIndex(nodeID, entryID);
    local _, _, _, _, _, _, _, entryType = Armory:GetTalentNodeEntryInfo(nodeID, index);

    SetButtonEntry(button, nodeID, index, rank or 0, nodeMaxRanks or 1, GetButtonArt(nodeType, entryType), size);
    button.isTiered = isTiered;
    button.hasChoices = (nodeType == Enum.TraitNodeType.Selection);

    -- The ranks of all tiers together, which is more than the number of tiers
    if ( isTiered and button.rank > 0 ) then
        button.rankText:SetFormattedText("%d/%d", button.rank, button.maxRanks);
    end
end

local function GetButton(tree, index)
    if ( not buttons[index] ) then
        buttons[index] = CreateFrame("Button", nil, tree, "ArmoryTalentButtonTemplate");
    end
    return buttons[index];
end

local function ShowLine(tree, index, startButton, endButton, ratio)
    local line = lines[index];
    if ( not line ) then
        line = tree:CreateLine(nil, "ARTWORK");
        lines[index] = line;
    end

    local isActive = (startButton.rank > 0 and endButton.rank > 0);

    line:SetDrawLayer("ARTWORK", isActive and 1 or 0);
    line:SetAtlas(isActive and "talents-arrow-line-yellow" or "talents-arrow-line-gray", false);
    line:SetThickness(BLIZZARD_LINE_THICKNESS * ratio);
    line:SetStartPoint("TOPLEFT", tree, startButton.x, -startButton.y);
    line:SetEndPoint("TOPLEFT", tree, endButton.x, -endButton.y);
    line:Show();
end

-- The largest tree decides the size of a part, only a few classes have been measured so it is calculated
local function GetTreeScale(tree, width, height)
    local treeWidth, treeHeight = tree:GetSize();
    local scale = BLIZZARD_SCALE;
    if ( width > 0 ) then
        scale = min(scale, (treeWidth - TREE_MARGIN) / width);
    end
    if ( height > 0 ) then
        scale = min(scale, (treeHeight - TREE_MARGIN) / height);
    end
    return scale;
end

local function UpdateTree(tree, specID, part, heroTree)
    table.wipe(shownNodes);
    table.wipe(shownButtons);

    local minX, maxX, minY, maxY;
    for _, nodeID in ipairs(specID and Armory:GetTalentSpecNodes(specID) or {}) do
        local posX, posY, _, nodePart, subTreeID = Armory:GetTalentNodeInfo(nodeID);
        if ( nodePart == part and (not subTreeID or subTreeID == heroTree) ) then
            table.insert(shownNodes, nodeID);
            minX = min(minX or posX, posX);
            maxX = max(maxX or posX, posX);
            minY = min(minY or posY, posY);
            maxY = max(maxY or posY, posY);
        end
    end

    local size = MIN_BUTTON_SIZE;
    if ( #shownNodes > 0 ) then
        local scale = GetTreeScale(tree, maxX - minX, maxY - minY);
        local treeWidth, treeHeight = tree:GetSize();
        size = max(MIN_BUTTON_SIZE, min(MAX_BUTTON_SIZE, floor(BLIZZARD_ROW * scale * BUTTON_ROW_RATIO)));
        local offsetX = treeWidth / 2 - (minX + maxX) / 2 * scale;
        local offsetY = treeHeight / 2 - (minY + maxY) / 2 * scale;

        for i, nodeID in ipairs(shownNodes) do
            local posX, posY, nodeType, _, _, nodeMaxRanks = Armory:GetTalentNodeInfo(nodeID);
            local button = GetButton(tree, i);
            UpdateButton(button, specID, nodeID, nodeType, nodeMaxRanks, size);
            button.x = offsetX + posX * scale;
            button.y = offsetY + posY * scale;
            button:ClearAllPoints();
            button:SetPoint("CENTER", tree, "TOPLEFT", button.x, -button.y);
            button:Show();
            shownButtons[nodeID] = button;
        end
    end

    for i = #shownNodes + 1, #buttons do
        buttons[i]:Hide();
    end

    -- The stored edges are those of all specs
    local numLines = 0;
    for _, nodeID in ipairs(shownNodes) do
        for _, target in ipairs(Armory:GetTalentNodeEdges(nodeID) or {}) do
            if ( shownButtons[target] ) then
                numLines = numLines + 1;
                ShowLine(tree, numLines, shownButtons[nodeID], shownButtons[target], size / BLIZZARD_BUTTON_SIZE);
            end
        end
    end

    for i = numLines + 1, #lines do
        lines[i]:Hide();
    end
end

local function UpdateTabs(self, specName, heroName)
    local tabs = self.Tabs;
    if ( Armory.isForever ) then
        -- The three groups of the tree
        for i, tab in ipairs(tabs) do
            local _, name = Armory:GetTalentGroupInfo(i);
            tab:SetText(name or "");
        end
        heroName = select(2, Armory:GetTalentGroupInfo(TAB_HERO));
    else
        tabs[TAB_CLASS]:SetText((Armory:UnitClass("player")));
        tabs[TAB_SPEC]:SetText(specName or "");
        tabs[TAB_HERO]:SetText(heroName or "");
    end

    if ( heroName ) then
        tabs[TAB_HERO]:Show();
    else
        tabs[TAB_HERO]:Hide();
        if ( ArmoryPanelTemplates_GetSelectedTab(self) == TAB_HERO ) then
            ArmoryPanelTemplates_SetTab(self, TAB_CLASS);
        end
    end

    local totalTabWidth = 0;
    local tabWidthCache = {};
    for i, tab in ipairs(tabs) do
        tabWidthCache[i] = 0;
        if ( tab:IsShown() ) then
            ArmoryPanelTemplates_TabResize(tab, 0);
            tabWidthCache[i] = ArmoryPanelTemplates_GetTabWidth(tab);
            totalTabWidth = totalTabWidth + tabWidthCache[i];
        end
    end
    ArmoryPanelTemplates_ResizeTabsToFit(tabs, totalTabWidth, TABS_MAX_WIDTH, tabWidthCache);
end

local function UpdateStatus(self, specID, isActive)
    if ( isActive ) then
        self.statusText:SetText(GREEN_FONT_COLOR_CODE..SPEC_ACTIVE..FONT_COLOR_CODE_CLOSE);
    elseif ( specID and not Armory:TalentsForSpecExist(specID) ) then
        self.statusText:SetText(GRAY_FONT_COLOR_CODE..UNKNOWN..FONT_COLOR_CODE_CLOSE);
    else
        self.statusText:SetText("");
    end
end

local function UpdatePoints(self, specID, currencyID)
    local spent, quantity, maxQuantity;
    if ( specID and currencyID ) then
        spent, quantity, maxQuantity = Armory:GetTalentPoints(specID, currencyID);
    end
    if ( spent ) then
        self.pointsText:SetFormattedText("%d/%d", spent, maxQuantity or (spent + (quantity or 0)));
    else
        self.pointsText:SetText("");
    end
end

-- Forever: the points spent in the group of the tab
local function UpdateGroupPoints(self, specGroup, tab)
    if ( Armory:TalentsForSpecExist(specGroup) ) then
        self.pointsText:SetText(Armory:GetTalentGroupPoints(specGroup, tab));
    else
        self.pointsText:SetText("");
    end
end

local function UpdateForever(self)
    local specGroup = self.selectedSpec;

    UpdateTabs(self);

    local tab = ArmoryPanelTemplates_GetSelectedTab(self);

    self.Choice:Hide();
    UpdateTree(self.Tree, specGroup, tab);
    UpdateStatus(self, specGroup, IsActiveSpec(self, specGroup));
    UpdateGroupPoints(self, specGroup, tab);
    ArmoryTalentFrame_UpdateSpecTabStates(self);
    self.Tree.heroIcon:Hide();
end

function ArmoryTalentFrame_Update()
    local self = ArmoryTalentFrame;
    if ( Armory.isForever ) then
        UpdateForever(self);
        return;
    end

    local spec = self.selectedSpec;
    local specID, specName = Armory:GetSpecializationInfo(spec, false, nil, nil, Armory:UnitSex("player"));
    local heroTree, heroName, heroIcon, heroCurrencyID;
    if ( specID ) then
        heroTree, heroName, heroIcon, heroCurrencyID = GetShownHeroTree(specID);
    end

    UpdateTabs(self, specName, heroName);

    local tab = ArmoryPanelTemplates_GetSelectedTab(self);
    local classCurrencyID, specCurrencyID = Armory:GetTalentCurrencies();
    local currencyID = classCurrencyID;
    if ( tab == TAB_SPEC ) then
        currencyID = specCurrencyID;
    elseif ( tab == TAB_HERO ) then
        currencyID = heroCurrencyID;
    end

    self.Choice:Hide();
    UpdateTree(self.Tree, specID, TAB_PARTS[tab], heroTree);
    UpdateStatus(self, specID, IsActiveSpec(self, spec));
    UpdatePoints(self, specID, currencyID);
    ArmoryTalentFrame_UpdateSpecTabStates(self);

    if ( tab == TAB_HERO and heroIcon ) then
        self.Tree.heroIcon:SetAtlas(heroIcon, false);
        self.Tree.heroIcon:Show();
    else
        self.Tree.heroIcon:Hide();
    end
end

function ArmoryTalentFrameTab_OnClick(self)
    ArmoryPanelTemplates_SetTab(ArmoryTalentFrame, self:GetID());
    ArmoryTalentFrame_Update();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

----------------------------------------------------------
-- SpecTab Button Functions
----------------------------------------------------------

-- Forever: a tab per spec group, with the icon of the class's only spec
local function UpdateSpecGroupTabs(self)
    local numSpecGroups = Armory:GetNumSpecGroups();
    local _, _, _, icon = Armory:GetSpecializationInfo(1, false, nil, nil, Armory:UnitSex("player"));
    local names = { DUAL_SPEC_PRIMARY or TALENT_SPEC_PRIMARY, DUAL_SPEC_SECONDARY or TALENT_SPEC_SECONDARY };
    for i = 1, MAX_TALENT_SPECTABS do
        local tab = self["specTab"..i];
        if ( i <= numSpecGroups ) then
            tab.tooltip = names[i];
            tab.description = nil;
            tab.role = nil;
            tab:GetNormalTexture():SetTexture(icon);
            tab:Show();
        else
            tab:Hide();
        end
    end
end

function ArmoryTalentFrame_UpdateSpecTabs(self)
    self.selectedSpec = GetActiveSpecTab(self);
    if ( Armory.isForever ) then
        UpdateSpecGroupTabs(self);
        return;
    end

    -- demon hunters had 2 specs, druids have 4
    local numSpecs = Armory:GetNumSpecializations();
    for i = 1, MAX_TALENT_SPECTABS do
        local tab = self["specTab"..i];
        if ( i <= numSpecs ) then
            local _, name, description, icon, role = Armory:GetSpecializationInfo(i, false, nil, nil, Armory:UnitSex("player"));
            tab.tooltip = name;
            tab.description = description;
            tab.role = role;
            tab:GetNormalTexture():SetTexture(icon);
            tab:Show();
        else
            tab:Hide();
        end
    end
end

function ArmoryTalentFrame_UpdateSpecTabStates(self)
    for i = 1, MAX_TALENT_SPECTABS do
        local tab = self["specTab"..i];
        if ( i == self.selectedSpec ) then
            tab:LockHighlight();
        else
            tab:UnlockHighlight();
        end
        tab.activeIcon:SetShown(IsActiveSpec(self, i));
    end
end

function ArmoryPlayerSpecTab_OnClick(self)
    ArmoryTalentFrame.selectedSpec = self:GetID();
    ArmoryTalentFrame_Update();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function ArmoryPlayerSpecTab_OnEnter(self)
    if ( self.tooltip ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:AddLine(self.tooltip);
        if ( self.role and _G[self.role] ) then
            GameTooltip:AddLine(_G[self.role], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        end
        if ( IsActiveSpec(ArmoryTalentFrame, self:GetID()) ) then
            GameTooltip:AddLine(SPEC_ACTIVE, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
        end
        if ( self.description ) then
            GameTooltip:AddLine(self.description, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
        end
        GameTooltip:Show();
    end
end

----------------------------------------------------------
-- Talent Button Functions
----------------------------------------------------------

-- The ranks of a capstone are spent on its tiers in order, see TalentButtonCapstoneWithTrackMixin
local function SetCapstoneTooltip(self)
    local _, spellID, _, _, overrideName = Armory:GetTalentNodeEntryInfo(self.nodeID, 1);
    GameTooltip_SetTitle(GameTooltip, TALENT_BUTTON_TOOLTIP_CAPSTONE_TRACK_TITLE_FORMAT:format(GetEntryName(spellID, overrideName), self.rank, self.maxRanks));

    local remainingRanks = self.rank;
    for i = 1, Armory:GetNumTalentNodeEntries(self.nodeID) or 0 do
        local entryID, _, maxRanks = Armory:GetTalentNodeEntryInfo(self.nodeID, i);
        local spentInTier = min(remainingRanks, maxRanks or 0);
        remainingRanks = remainingRanks - spentInTier;

        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        GameTooltip_AddHighlightLine(GameTooltip, TOOLTIP_TALENT_RANK_CAPSTONE:format(i));

        local tooltipInfo = CreateBaseTooltipInfo("GetTraitEntry", entryID, max(spentInTier, 1));
        tooltipInfo.append = true;
        if ( spentInTier == 0 ) then
            tooltipInfo.linePreCall = function(tooltip, lineData)
                lineData.leftColor = DISABLED_FONT_COLOR;
            end
        end
        GameTooltip:ProcessInfo(tooltipInfo);
    end
end

local function SetEntryTooltip(self)
    local entryID, spellID, _, _, overrideName = Armory:GetTalentNodeEntryInfo(self.nodeID, self.entryIndex);
    GameTooltip_SetTitle(GameTooltip, GetEntryName(spellID, overrideName));
    GameTooltip_AddHighlightLine(GameTooltip, TALENT_BUTTON_TOOLTIP_RANK_FORMAT:format(self.rank, self.maxRanks));
    GameTooltip_AddBlankLineToTooltip(GameTooltip);
    GameTooltip:AppendInfo("GetTraitEntry", entryID, max(self.rank, 1));
end

local function ShowChoices(owner)
    local frame = ArmoryTalentFrame.Choice;
    local numChoices = Armory:GetNumTalentNodeEntries(owner.nodeID) or 0;

    for i = 1, numChoices do
        local button = choiceButtons[i];
        if ( not button ) then
            button = CreateFrame("Button", nil, frame, "ArmoryTalentButtonTemplate");
            button:SetPoint("LEFT", CHOICE_PADDING + (i - 1) * (CHOICE_BUTTON_SIZE + CHOICE_SPACING), 0);
            choiceButtons[i] = button;
        end
        local _, _, _, _, _, _, _, entryType = Armory:GetTalentNodeEntryInfo(owner.nodeID, i);
        local rank = (i == owner.entryIndex) and owner.rank or 0;
        SetButtonEntry(button, owner.nodeID, i, rank, owner.maxRanks, GetButtonArt(nil, entryType), CHOICE_BUTTON_SIZE);
        button.icon:SetAlpha(1);
        button:Show();
    end
    for i = numChoices + 1, #choiceButtons do
        choiceButtons[i]:Hide();
    end

    frame.owner = owner;
    frame:SetSize(numChoices * CHOICE_BUTTON_SIZE + (numChoices - 1) * CHOICE_SPACING + 2 * CHOICE_PADDING, CHOICE_BUTTON_SIZE + 2 * CHOICE_PADDING);
    frame:ClearAllPoints();
    frame:SetPoint("BOTTOM", owner, "TOP", 0, -2);
    frame:Show();
end

function ArmoryTalentFrameChoice_OnUpdate(self)
    if ( not (self:IsMouseOver() or self.owner:IsMouseOver()) ) then
        self:Hide();
    end
end

function ArmoryTalentFrameTalent_OnEnter(self)
    if ( self.hasChoices ) then
        ShowChoices(self);
    else
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        if ( self.isTiered ) then
            SetCapstoneTooltip(self);
        else
            SetEntryTooltip(self);
        end
        GameTooltip:Show();
    end
end

function ArmoryTalentFrameTalent_OnClick(self)
    if ( IsModifiedClick("CHATLINK") and self.spellID ) then
        local link = C_Spell.GetSpellLink(self.spellID);
        if ( link ) then
            ChatFrameUtil.InsertLink(link);
        end
    end
end
