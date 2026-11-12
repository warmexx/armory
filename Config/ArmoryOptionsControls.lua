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

local _G = _G;
local table, next = table, next;
local getmetatable = getmetatable;
local error = error;
local tostring = tostring;


ArmoryOptionControlBaseMixin = {}

function ArmoryOptionControlBaseMixin:Register(panel)
    local key = self:GetKey();

    if ( key ) then
        self.entry = Armory.options[key];
        self.tooltipText = _G[key.."_TOOLTIP"];

        local text = _G[key.."_TEXT"];
        if ( text ) then
            self:SetLabel(Armory:Proper(text));
        end
    end

    self.panel = panel;
    self.panel:RegisterControl(self);
end

function ArmoryOptionControlBaseMixin:Embed(parent)
    parent.entry = self.entry;
    parent.tooltipText = self.tooltipText;
    parent.panel = self.panel;
end

function ArmoryOptionControlBaseMixin:GetPanel()
    return self.panel;
end

function ArmoryOptionControlBaseMixin:SetupDependency(dependency, invert)
    self.dependentInvert = invert;
    self.dependency = dependency;

    dependency.dependentControls = dependency.dependentControls or {};
    table.insert(dependency.dependentControls, self);
end

function ArmoryOptionControlBaseMixin:IsDependent()
    return self.dependency ~= nil;
end

function ArmoryOptionControlBaseMixin:HasDependencies()
    return self.dependentControls ~= nil and #self.dependentControls > 0;
end

function ArmoryOptionControlBaseMixin:GetDependentControls()
    return self.dependentControls or {};
end

function ArmoryOptionControlBaseMixin:EnableDependentControl(enable)
    if ( self.dependency:ShouldDisable() ) then
        self:Disable();
        return;
    end

    if ( enable ) then
        if ( self:IsDependent() and (self.dependency.disabled or self.dependentInvert) ) then
            self:Disable();
        else
            self:Enable();
        end
    else
        if ( self.dependentInvert ) then
            self:Enable();
        else
            self:Disable();
        end
    end
end

function ArmoryOptionControlBaseMixin:Enable()
    if ( getmetatable(self).__index.Enable ) then
        getmetatable(self).__index.Enable(self);
    end
    self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
    self.disabled = false;
end

function ArmoryOptionControlBaseMixin:Disable()
    if ( getmetatable(self).__index.Disable ) then
        getmetatable(self).__index.Disable(self);
    end
    self.Text:SetTextColor(GRAY_FONT_COLOR:GetRGB());
    self.disabled = true;
end

function ArmoryOptionControlBaseMixin:SetLabel(text)
    self.Text:SetText(text);
end

function ArmoryOptionControlBaseMixin:GetKey()
    error("Implement GetKey");
end

function ArmoryOptionControlBaseMixin:SetDefaultValue(value)
    self.defaultValue = value;
end

function ArmoryOptionControlBaseMixin:GetDefaultValue()
    return self.defaultValue or (self.entry and self.entry.default) or nil;
end

function ArmoryOptionControlBaseMixin:GetValue()
    if ( not self:IsInitialized() ) then
        if ( self.entry and self.entry.get ) then
            self.value = self.entry.get();
        else
            self.value = self:GetDefaultValue();
        end
    end
    return self.value;
end

function ArmoryOptionControlBaseMixin:SetValue(value)
    self.value = value;
    if ( self.entry and self.entry.set ) then
        self.entry.set(self.value);
    end
end

function ArmoryOptionControlBaseMixin:ShouldDisable()
    return self.entry and self.entry.disabled and self.entry.disabled(self);
end

function ArmoryOptionControlBaseMixin:Initialize()
    if ( not self.init ) then
        self.origValue = self:GetValue();
        self.init = true;
    end
end

function ArmoryOptionControlBaseMixin:IsInitialized()
    return self.init;
end

function ArmoryOptionControlBaseMixin:IsDirty()
    if ( self.value == nil or self.origValue == nil ) then
        return false;
    end
    return self.value ~= self.origValue;
end

function ArmoryOptionControlBaseMixin:SetToDefault()
    self:SetValue(self:GetDefaultValue());
end

function ArmoryOptionControlBaseMixin:Reset()
    self.init = false;
end

function ArmoryOptionControlBaseMixin:GetOriginalValue()
    return self.origValue;
end

function ArmoryOptionControlBaseMixin:Refresh()
    self:SetValue(self:GetValue());
end

function ArmoryOptionControlBaseMixin:OnLoad()
    self:Register(self:GetParent());
end

function ArmoryOptionControlBaseMixin:OnEnter()
    if ( self.tooltipText ) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
    end
end

function ArmoryOptionControlBaseMixin:OnLeave()
    GameTooltip:Hide();
end

function ArmoryOptionControlBaseMixin:OnCommit()
end


ArmoryOptionsCheckButtonTemplateMixin = CreateFromMixins(ArmoryOptionControlBaseMixin);

function ArmoryOptionsCheckButtonTemplateMixin:Refresh()
    self:SetChecked(self:GetValue());

    if ( self:ShouldDisable() ) then
        self:Disable();
    elseif ( not self:IsDependent() ) then
        self:Enable();
    end

    for _, control in next, self:GetDependentControls() do
        control:EnableDependentControl(self:GetChecked());
        if ( control:HasDependencies() ) then
            if ( not control:IsEnabled() ) then
                for _, dependentControl in next, control:GetDependentControls() do
                    dependentControl:Disable();
                end
            else
                control:Refresh();
            end
        end
    end
end

function ArmoryOptionsCheckButtonTemplateMixin:OnClick()
    local checked = self:GetChecked();

    self:SetValue(checked);
    self:Refresh();

    if ( checked ) then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    end
end


ArmoryOptionsColorTemplateMixin = CreateFromMixins(ArmoryOptionControlBaseMixin)

function ArmoryOptionsColorTemplateMixin:ColorSetter(setter)
    self.colorSet = setter;
end

function ArmoryOptionsColorTemplateMixin:ColorGetter(getter)
    self.colorGet = getter;
end

function ArmoryOptionsColorTemplateMixin:Enable()
    ArmoryOptionControlBaseMixin.Enable(self);
    self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
    self.Swatch:Enable();
end

function ArmoryOptionsColorTemplateMixin:Disable()
    ArmoryOptionControlBaseMixin.Disable(self);
    self.Swatch:Disable();
end

function ArmoryOptionsColorTemplateMixin:GetKey()
    return nil;
end

function ArmoryOptionsColorTemplateMixin:GetDefaultValue()
    return CreateColor(self.colorGet(true));
end

function ArmoryOptionsColorTemplateMixin:GetValue()
    if ( not self:IsInitialized() ) then
        self.value = CreateColor(self.colorGet());
    end
    return self.value;
end

function ArmoryOptionsColorTemplateMixin:SetValue(value)
    self.value = value;
    if ( value ) then
        self.colorSet(value:GetRGB());
        self.Swatch.NormalTexture:SetVertexColor(value:GetRGB());
    end
end

function ArmoryOptionsColorTemplateMixin:IsDirty()
    return not self.value:IsEqualTo(self.origValue);
end

function ArmoryOptionsColorTemplateMixin:OnClick()
    local info = ArmoryDropDownMenu_CreateInfo();

    info.r, info.g, info.b = self:GetValue():GetRGB();
    info.swatchFunc = function()
        self:SetValue(CreateColor(ColorPickerFrame:GetColorRGB()));
    end;
    info.cancelFunc = function()
        self:SetValue(CreateColor(ColorPickerFrame:GetPreviousValues()));
    end;

    ColorPickerFrame:SetupColorPickerAndShow(info);
end


ArmoryOptionsPanelButtonTemplateMixin = {};

function ArmoryOptionsPanelButtonTemplateMixin:SetTooltipText(text)
    self.tooltipText = text;
end

function ArmoryOptionsPanelButtonTemplateMixin:OnLoad()
end

function ArmoryOptionsPanelButtonTemplateMixin:OnEnter()
    ArmoryOptionControlBaseMixin.OnEnter(self);
end

function ArmoryOptionsPanelButtonTemplateMixin:OnLeave()
    ArmoryOptionControlBaseMixin.OnLeave(self);
end

function ArmoryOptionsPanelButtonTemplateMixin:OnClick()
end


ArmoryOptionsDropDownTemplateMixin = CreateFromMixins(ArmoryOptionControlBaseMixin);

function ArmoryOptionsDropDownTemplateMixin:GetKey(text)
    return nil;
end

function ArmoryOptionsDropDownTemplateMixin:SetTooltipText(text)
    self.tooltipText = text;
end

function ArmoryOptionsDropDownTemplateMixin:SetLabel(value)
    self.Label:SetText(value)
end

function ArmoryOptionsDropDownTemplateMixin:SetSelectedValue(value)
    self:SetValue(value);
end

function ArmoryOptionsDropDownTemplateMixin:SetValue(value)
    self.value = value;
    ArmoryDropDownMenu_SetSelectedValue(self, value);
end

function ArmoryOptionsDropDownTemplateMixin:GetValue()
    if ( not self:IsInitialized() ) then
        self.value = self:GetDefaultValue();
    end
    return self.value
end

function ArmoryOptionsDropDownTemplateMixin:Disable()
    ArmoryDropDownMenu_DisableDropDown(self)
end

function ArmoryOptionsDropDownTemplateMixin:Enable()
    ArmoryDropDownMenu_EnableDropDown(self);
end

function ArmoryOptionsDropDownTemplateMixin:Initialize()
    ArmoryDropDownMenu_Initialize(self, function()
        local info = ArmoryDropDownMenu_CreateInfo();

        info.owner = ARMORY_DROPDOWNMENU_OPEN_MENU;
        info.func = function(button) self:SetSelectedValue(button.value) end;

        self:AddButtons(info);
    end);
    ArmoryOptionControlBaseMixin.Initialize(self);
end

function ArmoryOptionsDropDownTemplateMixin:AddButtons(info)
    error("Implement AddButtons");
end


ArmoryOptionsSliderTemplateMixin = CreateFromMixins(ArmoryOptionControlBaseMixin);

function ArmoryOptionsSliderTemplateMixin:Register(parent)
    ArmoryOptionControlBaseMixin.Register(self, parent);

    self:SetMinMaxValues(self.entry.minValue, self.entry.maxValue);
    self:SetValueStep(self.entry.valueStep);

    BackdropTemplateMixin.OnBackdropLoaded(self);
end

function ArmoryOptionsSliderTemplateMixin:SetValue(value)
    getmetatable(self).__index.SetValue(self, value);
    ArmoryOptionControlBaseMixin.SetValue(self, value);
end

function ArmoryOptionsSliderTemplateMixin:Enable()
	getmetatable(self).__index.Enable(self);
	self.Text:SetVertexColor(NORMAL_FONT_COLOR:GetRGB());
	self.Low:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB());
	self.High:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB());
end

function ArmoryOptionsSliderTemplateMixin:Disable()
	getmetatable(self).__index.Disable(self);
	self.Text:SetVertexColor(GRAY_FONT_COLOR:GetRGB());
	self.Low:SetVertexColor(GRAY_FONT_COLOR:GetRGB());
	self.High:SetVertexColor(GRAY_FONT_COLOR:GetRGB());
end

function ArmoryOptionsSliderTemplateMixin:OnShow()
    self.Low:SetText(tostring(self.entry.minValue));
    self.High:SetText(tostring(self.entry.maxValue));
end

function ArmoryOptionsSliderTemplateMixin:OnValueChanged(value)
    if ( not value ) then
        return;
    end
    ArmoryOptionControlBaseMixin.SetValue(self, value);
end
