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

local ROW_HEIGHT = 16;
local LIST_FULL_HEIGHT = 128;

ARMORY_MAX_TRADE_SKILL_REAGENTS = 8;
ARMORY_TRADE_SKILL_TEXT_WIDTH = 270;
ARMORY_TRADE_SKILL_SKILLUP_TEXT_WIDTH = 30;
ARMORY_SUB_SKILL_BAR_WIDTH = 60;

ArmoryTradeSkillTypePrefix = {
	optimal = " [+++] ",
	medium  = " [++] ",
	easy	= " [+] ",
	trivial = " ", 
	header  = " "
}

ArmoryTradeSkillTypeColor = {
    optimal = { r = 1.00, g = 0.50, b = 0.25,	font = GameFontNormalLeftOrange };
    medium  = { r = 1.00, g = 1.00, b = 0.00,	font = GameFontNormalLeftYellow };
    easy	= { r = 0.25, g = 0.75, b = 0.25,	font = GameFontNormalLeftLightGreen };
    trivial = { r = 0.50, g = 0.50, b = 0.50,	font = GameFontNormalLeftGrey };
    header  = { r = 1.00, g = 0.82, b = 0,		font = GameFontNormalLeft };
};


----------------------------------------------------------
-- TradeSkillFrame Mixin
----------------------------------------------------------

ArmoryTradeSkillFrameMixin = {}

function ArmoryTradeSkillFrameMixin:OnLoad()
    self.RecipeList:SetRecipeChangedCallback(function(...) self:OnRecipeChanged(...) end);

    self:RegisterEvent("TRADE_SKILL_SHOW");
    self:RegisterEvent("TRADE_SKILL_CLOSE");
    self:RegisterEvent("CRAFT_SHOW");
    self:RegisterEvent("CRAFT_CLOSE");
end

function ArmoryTradeSkillFrameMixin:OnEvent(event, ...)
    local isCraft = event:sub(1, 4) == "CRAFT";
    if ( not Armory:CanHandleEvents() ) then
        return;
    elseif ( event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" ) then
        self.isOpen = true;
        Armory:PullTradeSkillItems(isCraft);
    elseif ( event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" ) then
        self.isOpen = false;
    end

    if ( not Armory:GetConfigExtendedTradeSkills() ) then
        Armory:Execute(function() self:Update(isCraft) end);
    end
end

function ArmoryTradeSkillFrameMixin:OnShow()
    ArmoryDropDownMenu_Initialize(self.FilterDropDown, function(...) self:InitFilterMenu(...) end, "MENU");
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
end

function ArmoryTradeSkillFrameMixin:OnHide()
	PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function ArmoryTradeSkillFrameMixin:Update(isCraft)
    local currentSkill, modeChanged;

    Armory:UnregisterTradeSkillUpdateEvents();
    currentSkill, modeChanged = Armory:UpdateTradeSkill(isCraft);
    Armory:RegisterTradeSkillUpdateEvents();

    if ( Armory.character == Armory.player ) then
        if ( self.lastTradeSkill == currentSkill and self:IsShown() ) then
            if ( modeChanged ) then
                self:Refresh();
            else
                self:SetSelectedRecipe(self:GetSelectedRecipe());
            end
        end
        
        ArmoryFrame_UpdateLineTabs();
    end
end

function ArmoryTradeSkillFrameMixin:SetSelectedRecipe(id)
    self.RecipeList:SetSelectedRecipe(id);
    self:RefreshDisplay();
end

function ArmoryTradeSkillFrameMixin:GetSelectedRecipe()
    return self.RecipeList:GetSelectedRecipe();
end

function ArmoryTradeSkillFrameMixin:RefreshDisplay()
    local numTradeSkills = Armory:GetNumTradeSkills();

    -- If no tradeskills
    if ( numTradeSkills == 0 ) then
        self.ExpandButtonFrame.CollapseAllButton:Disable();
        self.DetailsFrame:Clear()
    else
        self.ExpandButtonFrame.CollapseAllButton:Enable();
    end

    self.SearchBox:Show();

    self.RecipeList:RefreshDisplay();

    self:RefreshSkillTitleAndRank();
    
    self:RefreshExpandButtonFrame(numTradeSkills);
end

function ArmoryTradeSkillFrameMixin:Refresh()
    self.lastTradeSkill = Armory:GetTradeSkillLine();

    self:ClearFilters();
    self.RecipeList:OnDataSourceChanging();

    ArmoryCloseDropDownMenus();
    ArmoryCloseChildWindows();
    ShowUIPanel(self);
    
    self:OnDataSourceChanged();

    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:OnDataSourceChanged()
    self:RefreshSkillTitleAndRank();
    self:UpdateLayout();

    self.RecipeList:OnDataSourceChanged();
end

function ArmoryTradeSkillFrameMixin:ClearFilters()
    Armory:SetOnlyShowMakeableRecipes(false);
    Armory:SetOnlyShowSkillUpRecipes(false);
    Armory:SetTradeSkillItemLevelFilter(0, 0);
    Armory:SetTradeSkillItemNameFilter("");
    self.SearchBox:SetText("");

    self:ClearSlotFilter();
    
    ArmoryCloseDropDownMenus();

    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:ClearSlotFilter()
    Armory:SetTradeSkillSubClassFilter(0);
    Armory:SetTradeSkillInvSlotFilter(0);
end

function ArmoryTradeSkillFrameMixin:SetSlotFilter(inventorySlotIndex, subClassIndex)
    self:ClearSlotFilter();
    
    if ( inventorySlotIndex ) then
        Armory:SetTradeSkillInvSlotFilter(inventorySlotIndex);
    end
    
    if ( subClassIndex ) then
        Armory:SetTradeSkillSubClassFilter(subClassIndex);
    end
    
    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:RefreshSkillTitleAndRank()
    local skillLineName, skillLineRank, skillLineMaxRank = Armory:GetTradeSkillLine();
    local color = ArmoryTradeSkillTypeColor[skillType];

    self.TitleText:SetFormattedText(TRADE_SKILL_TITLE, skillLineName);

    -- Set statusbar info
    self.RankFrame:SetStatusBarColor(0.0, 0.0, 1.0, 0.5);
    self.RankFrame.Background:SetVertexColor(0.0, 0.0, 0.75, 0.5);
    self.RankFrame:SetMinMaxValues(0, skillLineMaxRank);
    self.RankFrame:SetValue(skillLineRank);
    self.RankFrame.SkillRank:SetFormattedText(TRADESKILL_RANK, skillLineRank, skillLineMaxRank);
end

function ArmoryTradeSkillFrameMixin:RefreshExpandButtonFrame(numTradeSkills)

    -- Set the expand/collapse all button texture
    local numHeaders = 0;
    local notExpanded = 0;
    for i = 1, numTradeSkills, 1 do
        local tradeSkillInfo = Armory:GetTradeSkillInfo(i);
        if ( tradeSkillInfo.name and tradeSkillInfo.type == "header" ) then
            numHeaders = numHeaders + 1;
            if ( tradeSkillInfo.collapsed ) then
                notExpanded = notExpanded + 1;
            end
        end
    end
    
    -- If all headers are not expanded then show collapse button, otherwise show the expand button
    if ( notExpanded ~= numHeaders ) then
        self.ExpandButtonFrame.CollapseAllButton.isCollapsed = nil;
        self.ExpandButtonFrame.CollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
    else
        self.ExpandButtonFrame.CollapseAllButton.isCollapsed = 1;
        self.ExpandButtonFrame.CollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
    end

    -- If has headers show the expand all button
    if ( numHeaders > 0 ) then
        self.ExpandButtonFrame:Show();
    else
        self.ExpandButtonFrame:Hide();
    end

    self.RecipeList.hasHeaders = numHeaders > 0;
    self.RecipeList:UpdateSkillButtonIndent();
end

function ArmoryTradeSkillFrameMixin:OnRecipeChanged(id)
	self.DetailsFrame:SetSelectedRecipe(self.RecipeList:GetSelectedRecipe());
end

function ArmoryTradeSkillFrameMixin:OnSearchTextChanged(searchBox)
    SearchBoxTemplate_OnTextChanged(searchBox);

    local text, minLevel, maxLevel = Armory:GetTradeSkillItemFilter(searchBox:GetText());
    local refresh1 = Armory:SetTradeSkillItemNameFilter(text);
    local refresh2 = Armory:SetTradeSkillItemLevelFilter(minLevel, maxLevel);

    if ( refresh1 or refresh2 ) then
        self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
    end
end

function ArmoryTradeSkillFrameMixin:CollapseAllButtonClicked(button)
    if ( button.isCollapsed ) then
        button.isCollapsed = nil;
        Armory:ExpandTradeSkillSubClass(0);
    else
        button.isCollapsed = 1;
        Armory:CollapseTradeSkillSubClass(0);
    end
    
    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
end

function ArmoryTradeSkillFrameMixin:InitFilterMenu(dropdown, level)
	local info = ArmoryDropDownMenu_CreateInfo();
	if ( level == 1 ) then
		--[[ Only show makeable recipes ]]--
		info.text = CRAFT_IS_MAKEABLE;
		info.func = function() 
			Armory:SetOnlyShowMakeableRecipes(not Armory:GetOnlyShowMakeableRecipes());
		    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
		end;

		info.keepShownOnClick = true;
		info.checked = Armory:GetOnlyShowMakeableRecipes();
		info.isNotRadio = true;
		ArmoryDropDownMenu_AddButton(info, level)
		
		--[[ Only show recipes that provide skill ups ]]--
		info.text = TRADESKILL_FILTER_HAS_SKILL_UP;
		info.func = function() 
			Armory:SetOnlyShowSkillUpRecipes(not Armory:GetOnlyShowSkillUpRecipes());
		    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
		end;
		info.keepShownOnClick = true;
		info.checked = Armory:GetOnlyShowSkillUpRecipes();
		info.isNotRadio = true;
		ArmoryDropDownMenu_AddButton(info, level);
		
		info.checked = 	nil;
		info.isNotRadio = nil;
		info.func = nil;
		info.notCheckable = true;
		info.keepShownOnClick = true;
		info.hasArrow = true;	
		
        --[[ Filter recipes by inventory slot ]]--
        if ( Armory:GetTradeSkillInvSlots() ) then
            info.text = TRADESKILL_FILTER_SLOTS;
            info.value = 1;
            ArmoryDropDownMenu_AddButton(info, level);
        end

        --[[ Filter recipes by parent category ]]--	
        if ( Armory:GetTradeSkillSubClasses() ) then
            info.text = TRADESKILL_FILTER_CATEGORY;
            info.value = 2;
            ArmoryDropDownMenu_AddButton(info, level);
        end
	
	elseif ( level == 2 ) then
		--[[ Inventory slots ]]--	
		if ARMORY_DROPDOWNMENU_MENU_VALUE == 1 then
			local inventorySlots = { Armory:GetTradeSkillInvSlots() };
			for i, inventorySlot in ipairs(inventorySlots) do
				info.text = inventorySlot;
				info.func = function() self:SetSlotFilter(i, nil); end;
				info.notCheckable = true;
				info.hasArrow = false;
				info.keepShownOnClick = true;
				ArmoryDropDownMenu_AddButton(info, level);
			end
		elseif ( ARMORY_DROPDOWNMENU_MENU_VALUE == 2 ) then
            -- [[ Sub classes ]]--	
			local subClasses = { Armory:GetTradeSkillSubClasses() };
			for i, subClass in ipairs(subClasses) do
				info.text = subClass;
				info.func = function() self:SetSlotFilter(nil, i); end;
				info.notCheckable = true;
				info.hasArrow = false;
				info.keepShownOnClick = true;
				ArmoryDropDownMenu_AddButton(info, level);
			end
        end
        
	end
end

function ArmoryTradeSkillFrameMixin:UpdateLayout()
   if ( self.RecipeList.extended ) then
        self.ExpandButtonFrame:Show();
    else
        self.ExpandButtonFrame:Hide();
    end
end


----------------------------------------------------------
-- TradeSkillRecipeList Mixin
----------------------------------------------------------

ArmoryTradeSkillRecipeListMixin = {}

function ArmoryTradeSkillRecipeListMixin:OnLoad()
	HybridScrollFrame_CreateButtons(self, "ArmoryTradeSkillSkillButtonTemplate", 0, 0);
	self.update = self.RefreshDisplay;
	self.stepSize = ROW_HEIGHT * 2;
end

function ArmoryTradeSkillRecipeListMixin:OnDataSourceChanging()
    self.extended = select(2, Armory:GetNumTradeSkills());
    self:SetSelectedRecipe(nil);
    for i, tradeSkillButton in ipairs(self.buttons) do
        tradeSkillButton:Clear();
    end
    self:Refresh();
end

function ArmoryTradeSkillRecipeListMixin:OnDataSourceChanged()
    self.scrollBar:SetValue(0);
	self.selectedSkill = nil;
	self:UpdateLayout();
	self:Refresh();
end

function ArmoryTradeSkillRecipeListMixin:OnHeaderButtonClicked(categoryButton, categoryInfo)
    local id = categoryButton:GetID();
    if ( categoryInfo.collapsed ) then
        Armory:ExpandTradeSkillSubClass(id);
    else
        Armory:CollapseTradeSkillSubClass(id);
    end
    
    self:Refresh();
end

function ArmoryTradeSkillRecipeListMixin:OnRecipeButtonClicked(recipeButton, recipeInfo)
	self:SetSelectedRecipe(recipeButton:GetID());
end

function ArmoryTradeSkillRecipeListMixin:SetSelectedRecipe(id)
    if ( not id or id <= Armory:GetNumTradeSkills() ) then
        self.selectedSkill = id;
        self:RefreshDisplay();
        if ( self.recipeChangedCallback ) then
            self.recipeChangedCallback(id);
        end
        return true;
    end
    return false;
end

function ArmoryTradeSkillRecipeListMixin:GetSelectedRecipe()
    return self.selectedSkill or 1;
end

function ArmoryTradeSkillRecipeListMixin:UpdateFilterBar()
	local filters = nil;
	if ( Armory:GetOnlyShowMakeableRecipes() ) then
		filters = filters or {};
		filters[#filters + 1] = CRAFT_IS_MAKEABLE;
	end
	
	if ( Armory:GetOnlyShowSkillUpRecipes() ) then 
		filters = filters or {};
		filters[#filters + 1] = TRADESKILL_FILTER_HAS_SKILL_UP;
	end

    local subClassFilter = Armory:GetTradeSkillSubClassFilter();
	if ( subClassFilter ) then
		local categoryName = subClassFilter;
		filters = filters or {};
		filters[#filters + 1] = categoryName;
	end
	
	local invSlotFilter = Armory:GetTradeSkillInvSlotFilter();
	if ( invSlotFilter ) then
		filters = filters or {};
		filters[#filters + 1] = invSlotFilter;
	end

    if ( filters ) then
        self.FilterBar.Text:SetFormattedText("%s: %s", FILTER, table.concat(filters, PLAYER_LIST_DELIMITER));
    end

    self.filtered = filters ~= nil;
    
	self:UpdateLayout();
end

function ArmoryTradeSkillRecipeListMixin:RefreshReagentCost()
    if ( IsAddOnLoaded("GFW_ReagentCost") ) then
        local itemLink = Armory:GetTradeSkillItemLink(self.selectedSkill);
        if ( not (itemLink and FRC_Config.Enabled and FRC_PriceSource) ) then
            return;
        end
        local enchantLink = itemLink:match("(enchant:%d+)");
        local itemID = itemLink:match("item:(%d+)");
        local identifier;
        if ( itemID ) then
            itemID = tonumber(itemID);
            identifier = itemID;
        elseif ( enchantLink ) then
            identifier = enchantLink;
        else
            return;
        end

        local materialsTotal, confidenceScore = FRC_MaterialsCost(skillLineName, identifier);
        local costText = GFWUtils.LtY("(Total cost: ");
        if ( materialsTotal == nil ) then
            if ( not IsAddOnLoaded(FRC_PriceSource) ) then
                costText = costText .. GFWUtils.Gray("["..FRC_PriceSource.." not loaded]");
            else
                costText = costText .. GFWUtils.Gray("Unknown [insufficient data]");
            end
        else
            costText = costText .. GFWUtils.TextGSC(materialsTotal) ..GFWUtils.Gray(" Confidence: "..confidenceScore.."%");
        end
        costText = costText ..GFWUtils.LtY(")");

        self.Contents.ReagentLabel:SetText(SPELL_REAGENTS.." "..costText);
        self.Contents.ReagentLabel:Show();
    end
end

function ArmoryTradeSkillRecipeListMixin:RefreshDisplay()
    self:UpdateFilterBar();

    local numTradeSkills = Armory:GetNumTradeSkills();
    local skillOffset = HybridScrollFrame_GetOffset(self);

	for i, skillButton in ipairs(self.buttons) do
        local skillIndex = i + skillOffset;

        skillButton = self.buttons[i];
        skillButton:SetID(skillIndex);
        
        local info = Armory:GetTradeSkillInfo(skillIndex);
        
        if ( info and info.name and skillIndex <= numTradeSkills ) then
            skillButton:SetUp(info);

			if ( info.type == "recipe" ) then
                skillButton:SetSelected(self:GetSelectedRecipe() == skillIndex);
			end
        else
            skillButton:Clear();
        end
    end

    self:RefreshReagentCost();
    self:UpdateSkillButtonIndent();

	HybridScrollFrame_Update(self, numTradeSkills * ROW_HEIGHT, self:GetHeight());
end

function ArmoryTradeSkillRecipeListMixin:Refresh()
    self:SetSelectedRecipe(Armory:GetFirstTradeSkill());
    self:RefreshDisplay();
end

function ArmoryTradeSkillRecipeListMixin:SetRecipeChangedCallback(recipeChangedCallback)
	self.recipeChangedCallback = recipeChangedCallback;
end

function ArmoryTradeSkillRecipeListMixin:UpdateSkillButtonIndent()
    if ( self.hasHeaders ) then
        -- If has headers then move all the names to the right
	    for i, skillButton in ipairs(self.buttons) do
            skillButton.Text:SetPoint("TOPLEFT", skillButton, "TOPLEFT", 23, 0);
        end
    else
        -- If no headers then move all the names to the left
	    for i, skillButton in ipairs(self.buttons) do
            skillButton.Text:SetPoint("TOPLEFT", skillButton, "TOPLEFT", 3, 0);
        end
    end
end

function ArmoryTradeSkillRecipeListMixin:UpdateLayout()
    if ( self.filtered ) then
        self.FilterBar:SetPoint("TOPLEFT", "ArmoryTradeSkillFrame", "TOPLEFT", 22, -96);
        self.FilterBar:Show();
        
        self:SetHeight(LIST_FULL_HEIGHT - ROW_HEIGHT);
        self:SetPoint("TOPRIGHT", "ArmoryTradeSkillFrame", "TOPRIGHT", -64, -96 - ROW_HEIGHT);
        self.scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 1, -14 + ROW_HEIGHT);
    else
        self.FilterBar:Hide();

        self:SetHeight(LIST_FULL_HEIGHT);
        self:SetPoint("TOPRIGHT", "ArmoryTradeSkillFrame", "TOPRIGHT", -64, -96);
        self.scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 1, -14);
    end
end


----------------------------------------------------------
-- TradeSkillButton Mixin
----------------------------------------------------------

ArmoryTradeSkillButtonMixin = {};

local scanned = {};
local function GetNumAvailable(id)
    local numAvailable = 0;
    table.wipe(scanned);
    if ( Armory:HasInventory() ) then
        for i = 1, Armory:GetTradeSkillNumReagents(id) do
            local reagentLink = Armory:GetTradeSkillReagentItemLink(id, i);
            if ( reagentLink ) then
                local _, _, reagentCount = Armory:GetTradeSkillReagentInfo(id, i);
                if ( reagentCount and reagentCount > 0 ) then
                    table.insert(scanned, floor(Armory:ScanInventory(reagentLink, true) / reagentCount));
                end
            end
        end
        if ( #scanned > 0 ) then
            numAvailable = scanned[1];
            for i = 2, #scanned do
                if ( scanned[i] < numAvailable ) then
                    numAvailable = scanned[i];
                end
            end
        end
    end
    table.wipe(scanned);
    return numAvailable;
end

function ArmoryTradeSkillButtonMixin:SetBaseColor(color)
    self:SetNormalFontObject(color.font);
    self.Text:SetVertexColor(color.r, color.g, color.b);
    self.Count:SetVertexColor(color.r, color.g, color.b);
    self.SelectedTexture:SetVertexColor(color.r, color.g, color.b)

    self.r = color.r;
    self.g = color.g;
    self.b = color.b;
    self.font = color.font;
end

function ArmoryTradeSkillButtonMixin:SetUp(tradeSkillInfo)
    self.tradeSkillInfo = tradeSkillInfo;

    local textWidth = ARMORY_TRADE_SKILL_TEXT_WIDTH;
    self:GetNormalTexture():SetPoint("LEFT", 3, 0);
    self:GetDisabledTexture():SetPoint("LEFT", 3, 0);
    self:GetHighlightTexture():SetPoint("LEFT", 3, 0);

    if ( tradeSkillInfo.type == "header" ) then
        self:SetUpHeader(textWidth, tradeSkillInfo);
    else
        self:SetUpRecipe(textWidth, tradeSkillInfo);
    end

    self:Show();
end

function ArmoryTradeSkillButtonMixin:Clear()
    self.isHeader = nil;
    self.isSelected = nil;
    self:Hide();
end

function ArmoryTradeSkillButtonMixin:SetUpHeader(textWidth, tradeSkillInfo)
    self.isHeader = true;
	self:SetAlpha(1.0);

    self:SetBaseColor(ArmoryTradeSkillTypeColor[tradeSkillInfo.type]);

    self.Text:SetWidth(textWidth);
    self:SetText(tradeSkillInfo.name);
    self.Count:SetText("");

    if ( tradeSkillInfo.collapsed ) then
        self:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
    else
        self:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
    end
    self.Highlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");

    self.SelectedTexture:Hide();
    self:UnlockHighlight()
    self.isSelected = false;
end

function ArmoryTradeSkillButtonMixin:SetUpRecipe(textWidth, tradeSkillInfo)
    self.isHeader = false;

    local usedWidth = 0;

    self:SetBaseColor(ArmoryTradeSkillTypeColor[tradeSkillInfo.difficulty]);

    local skillNamePrefix = ENABLE_COLORBLIND_MODE == "1" and ArmoryTradeSkillTypePrefix[tradeSkillInfo.difficulty] or " ";

    self:SetNormalTexture("");
    self.Highlight:SetTexture("");

    self.Text:SetWidth(0);
    self.Text:SetFormattedText("%s%s", skillNamePrefix, tradeSkillInfo.name);
    local numAvailable = max(tradeSkillInfo.numAvailable, GetNumAvailable(self:GetID()));
    if ( numAvailable == 0 ) then
        self.Count:SetText("");
        textWidth = textWidth - usedWidth;
    else
        self.Count:SetFormattedText("[%d]", numAvailable);

        local nameWidth = self.Text:GetWidth();
        local countWidth = self.Count:GetWidth();

        if ( nameWidth + 2 + countWidth > textWidth - usedWidth ) then
            textWidth = textWidth - 2 - countWidth - usedWidth;
        else
            textWidth = 0;
        end
    end

    self.Text:SetWidth(textWidth);   
end

function ArmoryTradeSkillButtonMixin:SetSelected(selected)
    if ( selected ) then
        self.SelectedTexture:Show();

        self.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
        self.Count:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

        self:LockHighlight();
        self.isSelected = true;
    else
        self.SelectedTexture:Hide();
        self:UnlockHighlight();
        self.isSelected = false;
    end
end

function ArmoryTradeSkillButtonMixin:OnMouseEnter()
    self.Count:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

    self.Text:SetFontObject(GameFontHighlightLeft);
    self.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
end

function ArmoryTradeSkillButtonMixin:OnMouseLeave()
    if ( not self.isSelected ) then
        self.Count:SetVertexColor(self.r, self.g, self.b);

        self.Text:SetFontObject(self.font);
        self.Text:SetVertexColor(self.r, self.g, self.b);
    end
end


----------------------------------------------------------
-- TradeSkillDetails Mixin
----------------------------------------------------------

ArmoryTradeSkillDetailsMixin = {}

function ArmoryTradeSkillDetailsMixin:SetSelectedRecipe(id)
    self.selectedRecipe = id;
    self.hasReagentDataByIndex = {};
    self:Refresh();
end

local SPACING_BETWEEN_LINES = 11;
function ArmoryTradeSkillDetailsMixin:RefreshDisplay()
    local recipeInfo = self.selectedRecipe and Armory:GetTradeSkillInfo(self.selectedRecipe);
	if ( recipeInfo and recipeInfo.type == "recipe" ) then
        self.Contents.RecipeName:SetText(recipeInfo.name);

        local recipeLink = GetTradeSkillItemLink(self.selectedRecipe);
        local productQuality = Armory:GetQualityFromLink(recipeLink);
        if ( productQuality ) then
            self.Contents.RecipeName:SetTextColor(GetItemQualityColor(productQuality));
        else
            self.Contents.RecipeName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
        end

        SetItemButtonQuality(self.Contents.ResultIcon, recipeInfo.productQuality, recipeLink);

        self.Contents.ResultIcon:SetNormalTexture(recipeInfo.icon);
        Armory:SetItemLink(self.Contents.ResultIcon, Armory:GetTradeSkillItemLink(self.selectedRecipe));

        local minMade, maxMade = Armory:GetTradeSkillNumMade(self.selectedRecipe);
        if ( maxMade > 1 ) then
            if ( minMade == maxMade ) then
                self.Contents.ResultIcon.Count:SetText(minMade);
            else
                self.Contents.ResultIcon.Count:SetFormattedText("%d-%d", minMade, maxMade);
            end
            if ( self.Contents.ResultIcon.Count:GetWidth() > 39 ) then
                self.Contents.ResultIcon.Count:SetFormattedText("~%d", math.floor(Lerp(minMade, maxMade, .5)));
            end
        else
            self.Contents.ResultIcon.Count:SetText("");
        end

        local hasRequirements;
        local requiredToolsString = Armory:GetTradeSkillTools(self.selectedRecipe);
        if ( requiredToolsString and requiredToolsString ~= "" ) then
            self.Contents.RequirementText:SetText(BuildColoredListString(requiredToolsString));
            hasRequirements = true;
        else
            local requiredTotems = Armory:GetTradeSkillSpellFocus(self.selectedRecipe);
            if ( requiredTotems and requiredTotems ~= "" ) then
    		    self.Contents.RequirementText:SetText(BuildColoredListString(requiredTotems));
                hasRequirements = true;
            elseif ( requiredLevel and requiredLevel > 0 ) then
                self.Contents.RequirementText:SetFormattedText(TRAINER_REQ_LEVEL, requiredLevel);
                hasRequirements = true;
            end
        end
        if ( hasRequirements ) then
            self.Contents.RequirementLabel:Show();
            self.Contents.RecipeCooldown:SetPoint("TOP", self.Contents.RequirementText, "BOTTOM", 0, -SPACING_BETWEEN_LINES);
        else
            self.Contents.RequirementLabel:Hide();
            self.Contents.RequirementText:SetText("");
            self.Contents.RecipeCooldown:SetPoint("TOP", self.Contents.RequirementText, "BOTTOM", 0, 0);
        end

        self.Contents.ReagentLabel:SetPoint("TOPLEFT", self.Contents.RecipeCooldown, "BOTTOMLEFT", 0, -SPACING_BETWEEN_LINES);
        self.Contents.RecipeCooldown:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
        if ( not recipeInfo.cooldown ) then
            self.Contents.RecipeCooldown:SetText("");
            self.Contents.ReagentLabel:SetPoint("TOPLEFT", self.Contents.RecipeCooldown, "BOTTOMLEFT", 0, 0);
        elseif ( recipeInfo.cooldown > 60 * 60 * 24 ) then	--Cooldown is greater than 1 day.
            self.Contents.RecipeCooldown:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(recipeInfo.cooldown, true, false, 1, true));
        else
            self.Contents.RecipeCooldown:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(recipeInfo.cooldown));
        end

        local numReagents = Armory:GetTradeSkillNumReagents(self.selectedRecipe);

        if ( numReagents > 0 ) then
            self.Contents.ReagentLabel:Show();
        else
            self.Contents.ReagentLabel:Hide();
        end

        for reagentIndex = 1, numReagents do
            local reagentName, reagentTexture, reagentCount, playerReagentCount = Armory:GetTradeSkillReagentInfo(self.selectedRecipe, reagentIndex);
            local reagentButton = self.Contents.Reagents[reagentIndex];

            reagentButton:Show();

            if ( not self.hasReagentDataByIndex[reagentIndex] ) then
                if ( not reagentName or not reagentTexture ) then
                    reagentButton.Icon:SetTexture("");
                    reagentButton.Name:SetText("");
                else
                    reagentButton.Icon:SetTexture(reagentTexture);
                    reagentButton.Name:SetText(reagentName);

                    self.hasReagentDataByIndex[reagentIndex] = true;
                    Armory:SetItemLink(reagentButton, Armory:GetTradeSkillReagentItemLink(self.selectedRecipe, reagentIndex));
                end
            end
            
            if ( Armory:HasInventory() ) then
                -- use count from inventory
                playerReagentCount = Armory:ScanInventory(reagentButton.link, true);

                if ( playerReagentCount < reagentCount ) then
                    reagentButton.Icon:SetVertexColor(0.5, 0.5, 0.5);
                    reagentButton.Name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
                else
                    reagentButton.Icon:SetVertexColor(1.0, 1.0, 1.0);
                    reagentButton.Name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
                end

                local playerReagentCountAbbreviated = AbbreviateNumbers(playerReagentCount);
                reagentButton.Count:SetFormattedText(TRADESKILL_REAGENT_COUNT, playerReagentCountAbbreviated, reagentCount);
                --fix text overflow when the reagentButton count is too high
                if ( math.floor(reagentButton.Count:GetStringWidth()) > math.floor(reagentButton.Icon:GetWidth() + .5) ) then 
                    --round count width down because the leftmost number can overflow slightly without looking bad
                    --round icon width because it should always be an int, but sometimes it's a slightly off float
                    reagentButton.Count:SetFormattedText("%s\n/%s", playerReagentCountAbbreviated, reagentCount);
                end
            else
                reagentButton.Count:SetText(reagentCount.." ");
            end
        end

        for reagentIndex = numReagents + 1, #self.Contents.Reagents do
            local reagentButton = self.Contents.Reagents[reagentIndex];
            reagentButton:Hide();
        end
        
		self:Show();
    else
        self:Clear();
    end
end

function ArmoryTradeSkillDetailsMixin:Refresh()
    self:RefreshDisplay();
end

function ArmoryTradeSkillDetailsMixin:Clear()
    self:Hide();
end

function ArmoryTradeSkillDetailsMixin:OnResultClicked(resultButton)
    if ( IsModifiedClick("CHATLINK") and resultButton.link ) then
        HandleModifiedItemClick(resultButton.link);
    end
end

function ArmoryTradeSkillDetailsMixin:OnResultMouseEnter(resultButton)
    if ( self.selectedRecipe ~= 0 ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        Armory:SetTradeSkillItem(self.selectedRecipe);
    end
end

function ArmoryTradeSkillDetailsMixin:OnReagentMouseEnter(reagentButton)
	GameTooltip:SetOwner(reagentButton, "ANCHOR_TOPLEFT");
    Armory:SetTradeSkillItem(self.selectedRecipe, reagentButton.reagentIndex);
end

function ArmoryTradeSkillDetailsMixin:OnReagentClicked(reagentButton)
    if ( IsModifiedClick("CHATLINK") and reagentButton.link ) then
        HandleModifiedItemClick(reagentButton.link);
    end
end

----------------------------------------------------------
local function UpdateWhenClosing(closeFunc, isCraft)
    if ( not ArmoryTradeSkillFrame.isOpen or ArmoryTradeSkillFrame.closing ) then
        return;
    end

    ArmoryTradeSkillFrame.closing = true;
    
    if ( Armory:GetConfigExtendedTradeSkills() ) then
        ArmoryTradeSkillFrame:Update(isCraft);
    end

    closeFunc();

    ArmoryTradeSkillFrame.closing = false;
    ArmoryTradeSkillFrame.isOpen = false;
end

local Orig_CloseCraft = CloseCraft;
function CloseCraft()
    UpdateWhenClosing(Orig_CloseCraft, true);
end

local Orig_CloseTradeSkill = CloseTradeSkill;
function CloseTradeSkill()
    UpdateWhenClosing(Orig_CloseTradeSkill, false);
end

function ArmoryTradeSkillFrame_Show()
    ArmoryTradeSkillFrame:Refresh();
end

function ArmoryTradeSkillFrame_Hide()
    HideUIPanel(ArmoryTradeSkillFrame);
end
