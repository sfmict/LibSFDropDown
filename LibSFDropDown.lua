-----------------------------------------------------------
-- LibSFDropDown - DropDown menu for non-Blizzard addons --
-----------------------------------------------------------
local MAJOR_VERSION, MINOR_VERSION = "LibSFDropDown", 2
local lib, oldminor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end


local math, pairs, rawget, type, wipe = math, pairs, rawget, type, wipe
local CreateFrame, GetBindingKey, HybridScrollFrame_GetOffset, HybridScrollFrame_ScrollToIndex, HybridScrollFrame_Update, HybridScrollFrame_OnValueChanged, HybridScrollFrameScrollButton_OnClick, HybridScrollFrameScrollUp_OnLoad, SearchBoxTemplate_OnTextChanged, PlaySound = CreateFrame, GetBindingKey,HybridScrollFrame_GetOffset, HybridScrollFrame_ScrollToIndex, HybridScrollFrame_Update, HybridScrollFrame_OnValueChanged, HybridScrollFrameScrollButton_OnClick, HybridScrollFrameScrollUp_OnLoad, SearchBoxTemplate_OnTextChanged, PlaySound


--[[
List of button attributes
====================================================================================================
info.text = [string, function] -- The text of the button
info.value = [anything]  --  The value that is set to button.value
info.func = [function]  --  The function that is called when you click the button
info.checked = [nil, true, function]  --  Check the button if true or function returns true
info.isNotRadio = [nil, true]  --  Check the button uses radial image if false check box image if true
info.notCheckable = [nil, true]  --  Shrink the size of the buttons and don't display a check box
info.isTitle = [nil, true]  --  If it's a title the button is disabled and the font color is set to yellow
info.disabled = [nil, true]  --  Disable the button and show an invisible button that still traps the mouseover event so menu doesn't time out
info.hasArrow = [nil, true]  --  Show the expand arrow for multilevel menus
info.keepShownOnClick = [nil, true]  --  Don't hide the dropdownlist after a button is clicked
info.arg1 = [anything] -- This is the first argument used by info.func
info.arg2 = [anything] -- This is the second argument used by info.func
info.icon = [texture] -- An icon for the button
info.iconInfo = [table] -- A table that looks like {
	tCoordLeft = [0..1], -- left for SetTexCoord func
	tCoordRight = [0..1], -- right for SetTexCoord func
	tCoordTop = [0..1], -- top for SetTexCoord func
	tCoordBottom = [0..1], -- bottom for SetTexCoord func
	tSizeX = [number], -- texture width
	tSizeY = [number], -- texture height
}
info.indent = [number] -- Number of pixels to pad the button on the left side
info.remove = [function] -- The function that is called when you click the remove button
info.order = [function] -- The function that is called when you click the up or down arrow button
info.list = [table] -- The table of info buttons, if there are more than 20 buttons, a scroll frame is added
]]
local dropDownOptions = {
	"text",
	"value",
	"func",
	"checked",
	"isNotRadio",
	"notCheckable",
	"hasArrow",
	"keepShownOnClick",
	"arg1",
	"arg2",
	"icon",
	"iconInfo",
	"remove",
	"order",
	"indent",
}
local DropDownMenuButtonHeight = 16
local DropDownMenuSearchHeight = DropDownMenuButtonHeight * 20 + 26
local DROPDOWNBUTTON = nil
local defaultStyle = "backdrop"
local menuStyle = "menuBackdrop"
local menuStyles = {}


local function CreateMenuStyle(menu, name, frameFunc)
	local f = frameFunc()
	f:SetParent(menu)
	f:SetFrameLevel(f:GetFrameLevel())
	f:SetAllPoints()
	menu[name] = f
end


local function OnHide(self)
	self:Hide()
end


local function CreateDropDownMenuList(parent)
	local menu = CreateFrame("FRAME", nil, parent)
	menu:Hide()
	menu:EnableMouse(true)
	menu:SetClampedToScreen(true)
	menu:SetFrameStrata("FULLSCREEN_DIALOG")
	menu.backdrop = CreateFrame("FRAME", nil, menu, "DialogBorderDarkTemplate")
	menu.menuBackdrop = CreateFrame("FRAME", nil, menu, "TooltipBackdropTemplate")
	menu.menuBackdrop:SetAllPoints()
	for name, frameFunc in pairs(menuStyles) do
		CreateMenuStyle(menu, name, frameFunc)
	end
	menu:SetScript("OnHide", OnHide)
	return menu
end


local function DropDownMenuButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

	if not self.notCheckable then
		self._checked = not self._checked
		if self.keepShownOnClick then
			self.Check:SetShown(self._checked)
			self.UnCheck:SetShown(not self._checked)
		end
	end

	if type(self.func) == "function" then
		self:func(self.arg1, self.arg2, self._checked)
	end

	if not self.keepShownOnClick then
		DROPDOWNBUTTON:closeDropDownMenus()
	end
end


local function DropDownMenuButton_OnEnter(self)
	self.isEnter = true
	if self:IsEnabled() then self.highlight:Show() end

	local level = self:GetParent().id + 1
	if self.hasArrow and self:IsEnabled() then
		DROPDOWNBUTTON:dropDownToggle(level, self.value, self)
	else
		DROPDOWNBUTTON:closeDropDownMenus(level)
	end

	if self.remove then
		self.removeButton:SetAlpha(1)
	end
	if self.order then
		self.arrowDownButton:SetAlpha(1)
		self.arrowUpButton:SetAlpha(1)
	end
end


local function DropDownMenuButton_OnLeave(self)
	self.isEnter = nil
	self.highlight:Hide()
	self.removeButton:SetAlpha(0)
	self.arrowDownButton:SetAlpha(0)
	self.arrowUpButton:SetAlpha(0)
end


local function DropDownMenuButton_OnDisable(self)
	self.Check:SetDesaturated(true)
	self.Check:SetAlpha(.5)
	self.UnCheck:SetDesaturated(true)
	self.UnCheck:SetAlpha(.5)
	self.ExpandArrow:SetDesaturated(true)
	self.ExpandArrow:SetAlpha(.5)
end


local function DropDownMenuButton_OnEnable(self)
	self.Check:SetDesaturated()
	self.Check:SetAlpha(1)
	self.UnCheck:SetDesaturated()
	self.UnCheck:SetAlpha(1)
	self.ExpandArrow:SetDesaturated()
	self.ExpandArrow:SetAlpha(1)
end


local function ControlButton_OnEnter(self)
	self.icon:SetVertexColor(1, 1, 1)
	local parent = self:GetParent()
	parent:GetScript("OnEnter")(parent)
end


local function ControlButton_OnLeave(self)
	self.icon:SetVertexColor(.7, .7, .7)
	local parent = self:GetParent()
	parent:GetScript("OnLeave")(parent)
end


local function ControlButton_OnMouseDown(self)
	self.icon:SetScale(.9)
end


local function ControlButton_OnMouseUp(self)
	self.icon:SetScale(1)
end


local function RemoveButton_OnClick(self)
	local parent = self:GetParent()
	parent:remove(parent.arg1, parent.arg2)
	DROPDOWNBUTTON:closeDropDownMenus()
end


local function ArrowDownButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	local parent = self:GetParent()
	parent:order(1)
	DROPDOWNBUTTON:ddRefresh(parent:GetParent().id, DROPDOWNBUTTON.anchorFrame)
end


local function ArrowUpButton_OnClick(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	local parent = self:GetParent()
	parent:order(-1)
	DROPDOWNBUTTON:ddRefresh(parent:GetParent().id, DROPDOWNBUTTON.anchorFrame)
end


local function CreateDropDownMenuButton(parent)
	local btn = CreateFrame("BUTTON", nil, parent)
	btn:SetMotionScriptsWhileDisabled(true)
	btn:SetHeight(DropDownMenuButtonHeight)
	btn:SetNormalFontObject(GameFontHighlightSmallLeft)
	btn:SetHighlightFontObject(GameFontHighlightSmallLeft)
	btn:SetDisabledFontObject(GameFontDisableSmallLeft)
	btn:SetScript("OnClick", DropDownMenuButton_OnClick)
	btn:SetScript("OnEnter", DropDownMenuButton_OnEnter)
	btn:SetScript("OnLeave", DropDownMenuButton_OnLeave)
	btn:SetScript("OnDisable", DropDownMenuButton_OnDisable)
	btn:SetScript("OnEnable", DropDownMenuButton_OnEnable)
	btn:SetScript("OnHide", OnHide)

	btn.highlight = btn:CreateTexture(nil, "BACKGROUND")
	btn.highlight:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
	btn.highlight:Hide()
	btn.highlight:SetBlendMode("ADD")
	btn.highlight:SetAllPoints()

	btn.Check = btn:CreateTexture(nil, "ARTWORK")
	btn.Check:SetTexture("Interface/Common/UI-DropDownRadioChecks")
	btn.Check:SetSize(16, 16)
	btn.Check:SetPoint("LEFT")
	btn.Check:SetTexCoord(0, .5, .5, 1)

	btn.UnCheck = btn:CreateTexture(nil, "ARTWORK")
	btn.UnCheck:SetTexture("Interface/Common/UI-DropDownRadioChecks")
	btn.UnCheck:SetSize(16, 16)
	btn.UnCheck:SetPoint("LEFT")
	btn.UnCheck:SetTexCoord(.5, 1, .5, 1)

	btn.Icon = btn:CreateTexture(nil, "ARTWORK")
	btn.Icon:Hide()
	btn.Icon:SetSize(16, 16)

	btn.ExpandArrow = btn:CreateTexture(nil, "ARTWORK")
	btn.ExpandArrow:SetTexture("Interface/ChatFrame/ChatFrameExpandArrow")
	btn.ExpandArrow:Hide()
	btn.ExpandArrow:SetSize(16, 16)
	btn.ExpandArrow:SetPoint("RIGHT", 4, 0)

	btn:SetText(" ")
	btn.NormalText = btn:GetFontString()

	btn.removeButton = CreateFrame("BUTTON", nil, btn)
	btn.removeButton:SetAlpha(0)
	btn.removeButton:SetSize(16, 16)
	btn.removeButton:SetPoint("RIGHT", -5, 0)
	btn.removeButton:SetScript("OnEnter", ControlButton_OnEnter)
	btn.removeButton:SetScript("OnLeave", ControlButton_OnLeave)
	btn.removeButton:SetScript("OnMouseDown", ControlButton_OnMouseDown)
	btn.removeButton:SetScript("OnMouseUp", ControlButton_OnMouseUp)
	btn.removeButton:SetScript("OnClick", RemoveButton_OnClick)

	btn.removeButton.icon = btn.removeButton:CreateTexture(nil, "BACKGROUND")
	btn.removeButton.icon:SetTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up")
	btn.removeButton.icon:SetSize(16, 16)
	btn.removeButton.icon:SetPoint("CENTER")
	btn.removeButton.icon:SetVertexColor(.7, .7, .7)

	btn.arrowDownButton = CreateFrame("BUTTON", nil, btn)
	btn.arrowDownButton:SetAlpha(0)
	btn.arrowDownButton:SetSize(12, 16)
	btn.arrowDownButton:SetPoint("RIGHT", btn.removeButton, "LEFT")
	btn.arrowDownButton:SetScript("OnEnter", ControlButton_OnEnter)
	btn.arrowDownButton:SetScript("OnLeave", ControlButton_OnLeave)
	btn.arrowDownButton:SetScript("OnMouseDown", ControlButton_OnMouseDown)
	btn.arrowDownButton:SetScript("OnMouseUp", ControlButton_OnMouseUp)
	btn.arrowDownButton:SetScript("OnClick", ArrowDownButton_OnClick)

	btn.arrowDownButton.icon = btn.arrowDownButton:CreateTexture(nil, "BACKGROUND")
	btn.arrowDownButton.icon:SetTexture("Interface/BUTTONS/UI-MicroStream-Yellow")
	btn.arrowDownButton.icon:SetSize(8, 14)
	btn.arrowDownButton.icon:SetPoint("CENTER")
	btn.arrowDownButton.icon:SetTexCoord(.25, .75, 0, .875)
	btn.arrowDownButton.icon:SetVertexColor(.7, .7, .7)

	btn.arrowUpButton = CreateFrame("BUTTON", nil, btn)
	btn.arrowUpButton:SetAlpha(0)
	btn.arrowUpButton:SetSize(12, 16)
	btn.arrowUpButton:SetPoint("RIGHT", btn.arrowDownButton, "LEFT")
	btn.arrowUpButton:SetScript("OnEnter", ControlButton_OnEnter)
	btn.arrowUpButton:SetScript("OnLeave", ControlButton_OnLeave)
	btn.arrowUpButton:SetScript("OnMouseDown", ControlButton_OnMouseDown)
	btn.arrowUpButton:SetScript("OnMouseUp", ControlButton_OnMouseUp)
	btn.arrowUpButton:SetScript("OnClick", ArrowUpButton_OnClick)

	btn.arrowUpButton.icon = btn.arrowUpButton:CreateTexture(nil, "BACKGROUND")
	btn.arrowUpButton.icon:SetTexture("Interface/BUTTONS/UI-MicroStream-Yellow")
	btn.arrowUpButton.icon:SetSize(8, 14)
	btn.arrowUpButton.icon:SetPoint("CENTER")
	btn.arrowUpButton.icon:SetTexCoord(.25, .75, .875, 0)
	btn.arrowUpButton.icon:SetVertexColor(.7, .7, .7)

	return btn
end


local function DropDownMenuSearch_OnShow(self)
	self.searchBox:SetText("")
	self:updateFilters()
	HybridScrollFrame_ScrollToIndex(self.listScroll, self.index, function()
		return self.listScroll.buttonHeight
	end)
end


local function DropDownMenuSearch_OnTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self)
	self:GetParent():updateFilters()
end


local function DropDownMenuSearch_Update(self)
	self:GetParent():refresh()
end


local function DropDownScrollFrame_CreateButtons(self)
	local scrollChild = self.scrollChild
	local button = CreateDropDownMenuButton(scrollChild)
	button:SetPoint("TOPLEFT")
	self.buttons = {button}
	self.buttonHeight = button:GetHeight()
	local numButtons = math.ceil(self:GetHeight() / self.buttonHeight)

	for i = 2, numButtons do
		button = CreateDropDownMenuButton(scrollChild)
		button:SetPoint("TOPLEFT", self.buttons[i - 1], "BOTTOMLEFT")
		self.buttons[#self.buttons + 1] = button
	end

	local childHeight = numButtons * self.buttonHeight
	scrollChild:SetWidth(self:GetWidth())
	scrollChild:SetHeight(childHeight)
	self:SetVerticalScroll(0)
	self:UpdateScrollChildRect()

	local scrollBar = self.scrollBar
	scrollBar:SetMinMaxValues(0, childHeight)
	scrollBar.buttonHeight = self.buttonHeight
	scrollBar:SetValueStep(self.buttonHeight)
	scrollBar:SetStepsPerPage(numButtons - 2)
	scrollBar:SetValue(0)
end


local DropDownMenuSearchMixin = {}


function DropDownMenuSearchMixin:reset()
	self.index = 1
	self.width = 0
	wipe(self.buttons)
	return self
end


function DropDownMenuSearchMixin:getEntryWidth()
	return self.width
end


do
	local deleteStr, len = {
		{"|?|c%x%x%x%x%x%x%x%x", 10},
		{"|?|r", 2},
	}
	local function compareFunc(s)
		return #s == len and "" or s
	end
	local function find(text, str)
		for i = 1, #deleteStr do
			local ds = deleteStr[i]
			len = ds[2]
			text = text:gsub(ds[1], compareFunc)
		end
		return text:lower():find(str, 1, true)
	end


	function DropDownMenuSearchMixin:updateFilters()
		local text = self.searchBox:GetText():trim():lower()

		wipe(self.filtredButtons)
		for i = 1, #self.buttons do
			local btn = self.buttons[i]
			if #text == 0 or find(type(btn.text) == "function" and btn.text() or btn.text, text) then
				self.filtredButtons[#self.filtredButtons + 1] = btn
			end
		end

		self:refresh()
	end
end


function DropDownMenuSearchMixin:refresh()
	local scrollFrame = self.listScroll
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local numButtons = #self.filtredButtons

	for i = 1, #scrollFrame.buttons do
		local btn = scrollFrame.buttons[i]
		local index = i + offset

		if index <= numButtons then
			local info = self.filtredButtons[index]
			for i = 1, #dropDownOptions do
				local opt = dropDownOptions[i]
				btn[opt] = info[opt]
			end

			btn._text = btn.text

			if btn._text then
				if type(btn._text) == "function" then btn._text = btn._text() end
				btn:SetText(btn._text)
			else
				btn:SetText("")
			end

			if info.remove then
				btn.removeButton:Show()
			else
				btn.removeButton:Hide()
			end

			if info.order then
				btn.arrowDownButton:Show()
				btn.arrowUpButton:Show()
			else
				btn.arrowDownButton:Hide()
				btn.arrowUpButton:Hide()
			end

			if btn.icon then
				btn.Icon:SetTexture(btn.icon)
				if btn.iconInfo then
					local iInfo = btn.iconInfo
					btn.Icon:SetSize(btn.iconInfo.tSizeX or DropDownMenuButtonHeight, btn.iconInfo.tSizeY or DropDownMenuButtonHeight)
					btn.Icon:SetTexCoord(iInfo.tCoordLeft or 0, iInfo.tCoordRight or 1, iInfo.tCoordTop or 0, iInfo.tCoordBottom or 1)
				else
					btn.Icon:SetSize(DropDownMenuButtonHeight, DropDownMenuButtonHeight)
					btn.Icon:SetTexCoord(0, 1, 0, 1)
				end
				btn.Icon:Show()
			else
				btn.Icon:Hide()
			end

			local indent = btn.indent or 0
			if btn.notCheckable then
				btn.Check:Hide()
				btn.UnCheck:Hide()
				if btn.icon then
					btn.Icon:SetPoint("LEFT", indent, 0)
					indent = indent + btn.Icon:GetWidth() + 2
				end
				btn.NormalText:SetPoint("LEFT", indent, 0)
			else
				btn.Check:SetPoint("LEFT", indent, 0)
				btn.UnCheck:SetPoint("LEFT", indent, 0)
				if btn.icon then
					btn.Icon:SetPoint("LEFT", 20 + indent, 0)
					indent = indent + btn.Icon:GetWidth() + 2
				end
				btn.NormalText:SetPoint("LEFT", 20 + indent, 0)

				if info.isNotRadio then
					btn.Check:SetTexCoord(0, .5, 0, .5)
					btn.UnCheck:SetTexCoord(.5, 1, 0, .5)
				else
					btn.Check:SetTexCoord(0, .5, .5, 1)
					btn.UnCheck:SetTexCoord(.5, 1, .5, 1)
				end

				btn._checked = btn.checked
				if type(btn._checked) == "function" then btn._checked = btn:_checked() end

				btn.Check:SetShown(btn._checked)
				btn.UnCheck:SetShown(not btn._checked)
			end

			if btn.isEnter then
				btn:GetScript("OnEnter")(btn)
			end

			btn:SetWidth(self:GetWidth() - 25)
			btn:Show()
		else
			btn:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, scrollFrame.buttonHeight * numButtons, scrollFrame:GetHeight())
end


function DropDownMenuSearchMixin:addButton(info)
	local button = {}
	for i = 1, #dropDownOptions do
		local opt = dropDownOptions[i]
		button[opt] = info[opt]
	end
	self.buttons[#self.buttons + 1] = button

	local btn = self.listScroll.buttons[1]
	if btn then
		if info.text then
			btn:SetText(type(info.text) == "function" and info.text() or info.text)
			local width = btn.NormalText:GetWidth() + 50

			if info.indent then
				width = width + info.indent
			end

			if info.notCheckable then
				width = width - 20
			elseif not info.isNotRadio then
				local checked = info.checked
				if type(checked) == "function" then checked = checked(info) end
				if checked then self.index = #self.buttons end
			end

			if info.remove then
				width = width + 16
			end

			if info.order then
				width = width + 24
			end

			if self.width < width then
				self.width = width
			end
		end
	end
end


local function CreateDropDownMenuSearch(i)
	local f = CreateFrame("FRAME")
	f:Hide()
	f:SetHeight(DropDownMenuSearchHeight)
	f:SetScript("OnShow", DropDownMenuSearch_OnShow)
	f:SetScript("OnHide", OnHide)

	f.searchBox = CreateFrame("EditBox", MAJOR_VERSION.."SearchBox"..i, f, "SearchBoxTemplate")
	f.searchBox:SetMaxLetters(40)
	f.searchBox:SetHeight(20)
	f.searchBox:SetPoint("TOPLEFT", 5, -3)
	f.searchBox:SetPoint("TOPRIGHT", 1, 0)
	f.searchBox:SetScript("OnTextChanged", DropDownMenuSearch_OnTextChanged)

	f.listScroll = CreateFrame("ScrollFrame", MAJOR_VERSION.."ScrollFrame"..i, f, "HybridScrollFrameTemplate")
	f.listScroll:SetSize(30, DropDownMenuSearchHeight - 26)
	f.listScroll:SetPoint("TOPLEFT", f.searchBox, "BOTTOMLEFT", -5, -3)
	f.listScroll:SetPoint("BOTTOMRIGHT", -30, 3)

	f.listScroll.scrollBar = CreateFrame("SLIDER", nil, f.listScroll)
	local scrollBar = f.listScroll.scrollBar
	scrollBar.doNotHide = true
	scrollBar:SetSize(20, 0)
	scrollBar:SetPoint("TOPLEFT", f.listScroll, "TOPRIGHT", 10, -18)
	scrollBar:SetPoint("BOTTOMLEFT", f.listScroll, "BOTTOMRIGHT", 10, 15)
	scrollBar:SetScript("OnValueChanged", HybridScrollFrame_OnValueChanged)

	scrollBar:SetThumbTexture("Interface/Buttons/UI-ScrollBar-Knob")
	scrollBar.thumbTexture = scrollBar:GetThumbTexture()
	scrollBar.thumbTexture:SetBlendMode("ADD")
	scrollBar.thumbTexture:SetSize(21, 24)
	scrollBar.thumbTexture:SetTexCoord(.125, .825, .125, .825)

	scrollBar.trackBG = scrollBar:CreateTexture(nil, "BACKGROUND")
	scrollBar.trackBG:SetPoint("TOPLEFT", 1, 0)
	scrollBar.trackBG:SetPoint("BOTTOMRIGHT")
	scrollBar.trackBG:SetColorTexture(0, 0, 0, .15)

	scrollBar.UpButton = CreateFrame("BUTTON", nil, scrollBar)
	scrollBar.UpButton:SetSize(18, 16)
	scrollBar.UpButton:SetPoint("BOTTOM", scrollBar, "TOP", 1, -2)
	scrollBar.UpButton:SetNormalAtlas("UI-ScrollBar-ScrollUpButton-Up")
	scrollBar.UpButton:SetPushedAtlas("UI-ScrollBar-ScrollUpButton-Down")
	scrollBar.UpButton:SetDisabledAtlas("UI-ScrollBar-ScrollUpButton-Disabled")
	scrollBar.UpButton:SetHighlightAtlas("UI-ScrollBar-ScrollUpButton-Highlight")
	scrollBar.UpButton:SetScript("OnClick", HybridScrollFrameScrollButton_OnClick)
	HybridScrollFrameScrollUp_OnLoad(scrollBar.UpButton)

	scrollBar.DownButton = CreateFrame("BUTTON", nil, scrollBar)
	scrollBar.DownButton:SetSize(18, 16)
	scrollBar.DownButton:SetPoint("TOP", scrollBar, "BOTTOM", 1, 1)
	scrollBar.DownButton:SetNormalAtlas("UI-ScrollBar-ScrollDownButton-Up")
	scrollBar.DownButton:SetPushedAtlas("UI-ScrollBar-ScrollDownButton-Down")
	scrollBar.DownButton:SetDisabledAtlas("UI-ScrollBar-ScrollDownButton-Disabled")
	scrollBar.DownButton:SetHighlightAtlas("UI-ScrollBar-ScrollDownButton-Highlight")
	scrollBar.DownButton:SetScript("OnClick", HybridScrollFrameScrollButton_OnClick)
	HybridScrollFrameScrollDown_OnLoad(scrollBar.DownButton)

	f.listScroll.update = DropDownMenuSearch_Update
	DropDownScrollFrame_CreateButtons(f.listScroll)

	f.buttons = {}
	f.filtredButtons = {}
	for k, v in pairs(DropDownMenuSearchMixin) do
		f[k] = v
	end

	return f
end


local dropDownMenusList = setmetatable({}, {
	__index = function(self, key)
		local frame = CreateDropDownMenuList(key == 1 and UIParent or self[key - 1])
		frame.id = key
		frame.searchFrames = {}
		frame.buttonsList = setmetatable({}, {
			__index = function(self, key)
				local button = CreateDropDownMenuButton(frame)
				button:SetPoint("RIGHT", -15, 0)
				self[key] = button
				return button
			end,
		})
		self[key] = frame
		return frame
	end,
})


local function ContainsMouse()
	for i = 1, #dropDownMenusList do
		local menu = dropDownMenusList[i]
		if menu:IsShown() and menu:IsMouseOver() then
			return true
		end
	end
	return false
end


local function ContainsFocus()
	local focus = GetMouseFocus()
	return focus and focus.SFNoGlobalMouseEvent
end


local menu1 = dropDownMenusList[1]
-- CLOSE ON ESC
menu1:SetScript("OnKeyDown", function(self, key)
	if key == GetBindingKey("TOGGLEGAMEMENU") then
		self:Hide()
		self:SetPropagateKeyboardInput(false)
	else
		self:SetPropagateKeyboardInput(true)
	end
end)
-- CLOSE WHEN CLICK ON A FREE PLACE
menu1:SetScript("OnEvent", function(self, event, button)
	if (button == "LeftButton" or button == "RightButton")
	and not (ContainsFocus() or ContainsMouse()) then
		self:Hide()
	end
end)
menu1:SetScript("OnShow", function(self)
	self:Raise()
	self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end)
menu1:SetScript("OnHide", function(self)
	self:Hide()
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end)


local function MenuReset(menu)
	menu.width = 0
	menu.height = 15
	menu.numButtons = 0
	wipe(menu.searchFrames)
end


local DropDownButtonMixin = {}


function DropDownButtonMixin:ddSetSelectedValue(value, level, anchorFrame)
	self.selectedValue = value
	self:ddRefresh(level, anchorFrame)
end


function DropDownButtonMixin:ddSetSelectedText(text, icon, iconInfo)
	self.Text:SetText(text)
	if icon then
		self.Icon:Show()
		self.Icon:SetTexture(icon)
		if iconInfo then
			self.Icon:SetSize(iconInfo.tSizeX or DropDownMenuButtonHeight, iconInfo.tSizeY or DropDownMenuButtonHeight)
			self.Icon:SetTexCoord(iconInfo.tCoordLeft or 0, iconInfo.tCoordRight or 1, iconInfo.tCoordTop or 0, iconInfo.tCoordBottom or 1)
		else
			self.Icon:SetSize(DropDownMenuButtonHeight, DropDownMenuButtonHeight)
			self.Icon:SetTexCoord(0, 1, 0, 1)
		end
		self.Text:SetPoint("LEFT", self.Left, "RIGHT", self.Icon:GetWidth() - 2, 2)
		self.Icon:SetPoint("RIGHT", self.Text, "RIGHT", -math.min(self.Text:GetStringWidth(), self.Text:GetWidth()) - 1, -1)
	else
		self.Icon:Hide()
		self.Text:SetPoint("LEFT", self.Left, "RIGHT", 0, 2)
	end
end


function DropDownButtonMixin:ddSetInitFunc(initFunction)
	self.initialize = initFunction
end


function DropDownButtonMixin:ddInitialize(level, value, initFunction)
	if type(level) == "function" then
		initFunction = level
		level = nil
		value = nil
	elseif type(value) == "function" then
		initFunction = value
		value = nil
	end
	level = level or 1
	menu = dropDownMenusList[level]
	menu.anchorFrame = self
	MenuReset(dropDownMenusList[level])
	self:ddSetInitFunc(initFunction)
	initFunction(self, level, value)
	menu:Show()
	menu:Hide()
end


function DropDownButtonMixin:ddSetDisplayMode(displayMode)
	self.displayMode = displayMode
end


function DropDownButtonMixin:ddSetAutoSetText(enabled)
	self.dropDownSetText = enabled
end


function DropDownButtonMixin:ddHideWhenButtonHidden(frame)
	if frame then
		frame:HookScript("OnHide", function() self:onHide() end)
	else
		self:HookScript("OnHide", self.onHide)
	end
end


function DropDownButtonMixin:dropDownToggle(level, value, anchorFrame, xOffset, yOffset)
	if not level then level = 1 end
	local menu = dropDownMenusList[level]

	if menu:IsShown() then
		menu:Hide()
		if level == 1 and menu.anchorFrame == anchorFrame then return end
	end
	menu.anchorFrame = anchorFrame

	if not xOffset or not yOffset then
		xOffset = -5
		yOffset = 5
	end

	MenuReset(menu)
	self:initialize(level, value)

	menu.width = menu.width + 30
	menu.height = menu.height + 15
	if menu.width < 60 then menu.width = 60 end
	if menu.height < 46 then menu.height = 46 end
	menu:SetSize(menu.width, menu.height)

	if level == 1 then
		DROPDOWNBUTTON = self
		menu:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", xOffset, yOffset)
	else
		if GetScreenWidth() - anchorFrame:GetRight() - 2 < menu.width then
			menu:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -2, 14)
		else
			menu:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 2, 14)
		end
	end

	menu.backdrop:Hide()
	menu.menuBackdrop:Hide()
	for name in pairs(menuStyles) do
		menu[name]:Hide()
	end
	local style
	if DROPDOWNBUTTON.displayMode == "menu" then
		style = menuStyle
	elseif menu[DROPDOWNBUTTON.displayMode] then
		style = DROPDOWNBUTTON.displayMode
	else
		style = defaultStyle
	end
	menu[style]:Show()

	menu:Show()
end


function DropDownButtonMixin:ddRefresh(level, anchorFrame)
	if not level then level = 1 end
	if not anchorFrame then anchorFrame = self end
	local menu = dropDownMenusList[level]

	for i = 1, #menu.buttonsList do
		local button = menu.buttonsList[i]
		if button:IsShown() then
			if type(button.text) == "function" then
				button._text = button.text()
				button:SetText(button._text)
			end

			if not button.notCheckable then
				if type(button.checked) == "function" then
					button._checked = button:checked()
				elseif button.checked == nil then
					button._checked = button.value == self.selectedValue
				end
				button.Check:SetShown(button._checked)
				button.UnCheck:SetShown(not button._checked)

				if self.dropDownSetText and button._checked and menu.anchorFrame == anchorFrame then
					self:ddSetSelectedText(button._text, button.icon, button.iconInfo)
				end
			end
		else
			break
		end
	end

	for i = 1, #menu.searchFrames do
		local searchFrame = menu.searchFrames[i]
		if searchFrame:IsShown() then
			searchFrame:refresh()
			if self.dropDownSetText and menu.anchorFrame == anchorFrame then
				for j = 1, #searchFrame.buttons do
					local button = searchFrame.buttons[j]
					local checked = button.checked
					if type(checked) == "function" then
						checked = checked(button)
					elseif checked == nil then
						checked = button.value == self.selectedValue
					end
					if checked then
						local text = button.text
						if type(text) == "function" then text = text() end
						self:ddSetSelectedText(text, button.icon, button.iconInfo)
					end
				end
			end
		end
	end
end


function DropDownButtonMixin:closeDropDownMenus(level)
	local menu = rawget(dropDownMenusList, level or 1)
	if menu then menu:Hide() end
end


function DropDownButtonMixin:onHide()
	if self == DROPDOWNBUTTON then
		self:closeDropDownMenus()
	end
end


function DropDownButtonMixin:ddAddButton(info, level)
	if not level then level = 1 end
	local width = 0
	local menu = dropDownMenusList[level]

	if info.list then
		if #info.list > 20 then
			local searchFrame = self:getDropDownSearchFrame()
			searchFrame:SetParent(menu)
			searchFrame:SetPoint("TOPLEFT", 15, -menu.height)
			searchFrame:SetPoint("RIGHT", -15, 0)
			searchFrame.listScroll.ScrollChild.id = level

			for i = 1, #info.list do
				searchFrame:addButton(info.list[i])
			end

			width = searchFrame:getEntryWidth()
			if menu.width < width then menu.width = width end
			searchFrame:Show()

			menu.searchFrames[#menu.searchFrames + 1] = searchFrame
			menu.height = menu.height + DropDownMenuSearchHeight
		else
			for i = 1, #info.list do
				self:ddAddButton(info.list[i], level)
			end
		end
		return
	end

	menu.numButtons = menu.numButtons + 1
	local button = menu.buttonsList[menu.numButtons]
	button:SetDisabledFontObject(GameFontDisableSmallLeft)
	button:Enable()

	for i = 1, #dropDownOptions do
		local opt = dropDownOptions[i]
		button[opt] = info[opt]
	end

	if info.isTitle then
		button:SetDisabledFontObject(GameFontNormalSmallLeft)
	end

	if info.disabled or info.isTitle then
		button:Disable()
	end

	button._text = info.text
	if button._text then
		if type(button._text) == "function" then button._text = button._text() end
		button:SetText(button._text)
		button.NormalText:Show()
	else
		button:SetText("")
	end
	width = width + button.NormalText:GetWidth()

	if info.remove then
		button.removeButton:Show()
		width = width + 16
	else
		button.removeButton:Hide()
	end

	if info.order then
		button.arrowDownButton:Show()
		button.arrowUpButton:Show()
		width = width + 24
	else
		button.arrowDownButton:Hide()
		button.arrowUpButton:Hide()
	end

	if info.icon then
		button.Icon:SetTexture(info.icon)
		if info.iconInfo then
			local iInfo = info.iconInfo
			button.Icon:SetSize(iInfo.tSizeX or DropDownMenuButtonHeight, iInfo.tSizeY or DropDownMenuButtonHeight)
			button.Icon:SetTexCoord(iInfo.tCoordLeft or 0, iInfo.tCoordRight or 1, iInfo.tCoordTop or 0, iInfo.tCoordBottom or 1)
		else
			button.Icon:SetSize(DropDownMenuButtonHeight, DropDownMenuButtonHeight)
			button.Icon:SetTexCoord(0, 1, 0, 1)
		end

		if info.iconOnly then
			button.Icon:SetPoint("RIGHT")
			button.NormalText:Hide()
		else
			button.Icon:ClearAllPoints()
			button.NormalText:Show()
			width = width + button.Icon:GetWidth() + 2
		end
		button.Icon:Show()
	else
		button.Icon:Hide()
	end

	local indent = button.indent or 0
	width = width + indent

	if info.notCheckable then
		button.Check:Hide()
		button.UnCheck:Hide()
		if info.icon then
			button.Icon:SetPoint("LEFT", indent, 0)
			indent = indent + button.Icon:GetWidth() + 2
		end
		button.NormalText:SetPoint("LEFT", indent, 0)
	else
		button.Check:SetPoint("LEFT", indent, 0)
		button.UnCheck:SetPoint("LEFT", indent, 0)
		if info.icon then
			button.Icon:SetPoint("LEFT", 20 + indent, 0)
			indent = indent + button.Icon:GetWidth() + 2
		end
		button.NormalText:SetPoint("LEFT", 20 + indent, 0)
		width = width + 30

		if info.isNotRadio then
			button.Check:SetTexCoord(0, .5, 0, .5)
			button.UnCheck:SetTexCoord(.5, 1, 0, .5)
		else
			button.Check:SetTexCoord(0, .5, .5, 1)
			button.UnCheck:SetTexCoord(.5, 1, .5, 1)
		end

		button._checked = info.checked
		if type(button._checked) == "function" then
			button._checked = button:_checked()
		elseif info.checked == nil then
			button._checked = button.value == self.selectedValue
		end

		button.Check:SetShown(button._checked)
		button.UnCheck:SetShown(not button._checked)
	end

	if info.hasArrow then
		width = width + 12
	end
	button.ExpandArrow:SetShown(info.hasArrow)

	button:SetPoint("TOPLEFT", 15, -menu.height)
	button:Show()

	menu.height = menu.height + DropDownMenuButtonHeight
	if menu.width < width then menu.width = width end
end


function DropDownButtonMixin:ddAddSeparator(level)
	local info = {
		disabled = true,
		notCheckable = true,
		iconOnly = true,
		icon = "Interface/Common/UI-TooltipDivider-Transparent",
		iconInfo = {
			tSizeX = 0,
			tSizeY = 8,
		},
	}
	self:ddAddButton(info, level)
end


local dropDownSearchFrames = {}
function DropDownButtonMixin:getDropDownSearchFrame()
	for i = 1, #dropDownSearchFrames do
		local frame = dropDownSearchFrames[i]
		if not frame:IsShown() then return frame:reset() end
	end
	local i = #dropDownSearchFrames + 1
	local frame = CreateDropDownMenuSearch(i)
	dropDownSearchFrames[i] = frame
	return frame:reset()
end


local libMeta = {
	__metatable = "access denied",
	__index = {}
}
setmetatable(lib, libMeta)
local libMethods = libMeta.__index


function libMethods:IterateMenus()
	return ipairs(dropDownMenusList)
end


function libMethods:iterateMenuButtons(level)
	local menu = rawget(dropDownMenusList, level or 1)
	if menu then
		local buttons = {}
		for i = 1, #menu.buttonsList do
			buttons[i] = menu.buttonsList[i]
		end
		for i = 1, #menu.searchFrames do
			local searchFrame = menu.searchFrames[i]
			for j = 1, #searchFrame.buttons do
				buttons[#buttons + 1] = searchFrame.buttons[j]
			end
		end
		return ipairs(buttons)
	end
end


function libMethods:CreateMenuStyle(name, frameFunc)
	if type(frameFunc) == "function" then
		for i = 1, #dropDownMenusList do
			CreateMenuStyle(dropDownMenusList[i], name, frameFunc)
		end
		menuStyles[name] = frameFunc
	end
end


function libMethods:SetDefaultStyle(name)
	if menuStyles[name] then
		defaultStyle = name
	end
end


function libMethods:SetMenuStyle(name)
	if menuStyles[name] then
		menuStyle = name
	end
end


function libMethods:SetMixin(btn)
	for k, v in pairs(DropDownButtonMixin) do
		btn[k] = v
	end
	btn.SFNoGlobalMouseEvent = true
	return btn
end


do
	local function SetEnabled(self, enabled)
		self.Button:SetEnabled(enabled)
		self.Icon:SetDesaturated(not enabled)
		local color = enabled and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
		self.Text:SetTextColor(color:GetRGB())
	end


	local function Enable(self)
		SetEnabled(self, true)
	end


	local function Disable(self)
		SetEnabled(self, false)
	end


	local function Button_OnClick(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		local parent = self:GetParent()
		parent:dropDownToggle(1, nil, parent)
	end


	function libMethods:CreateButtonOriginal(parent, width)
		self.CreateButtonOriginal = nil

		local btn = CreateFrame("FRAME", nil, parent)
		btn:SetSize(width or 135, 24)
		self:SetMixin(btn)
		btn.SFNoGlobalMouseEvent = nil
		btn:ddSetAutoSetText(true)
		btn:ddHideWhenButtonHidden()
		btn.SetEnabled = SetEnabled
		btn.Enable = Enable
		btn.Disable = Disable

		btn.Left = btn:CreateTexture(nil, "BACKGROUND")
		btn.Left:SetTexture("Interface/Glues/CharacterCreate/CharacterCreate-LabelFrame")
		btn.Left:SetSize(25, 64)
		btn.Left:SetPoint("LEFT", -15, 0)
		btn.Left:SetTexCoord(0, .1953125, 0, 1)

		btn.Right = btn:CreateTexture(nil, "BACKGROUND")
		btn.Right:SetTexture("Interface/Glues/CharacterCreate/CharacterCreate-LabelFrame")
		btn.Right:SetSize(25, 64)
		btn.Right:SetPoint("RIGHT", 15, 0)
		btn.Right:SetTexCoord(.8046875, 1, 0, 1)

		btn.Middle = btn:CreateTexture(nil, "BACKGROUND")
		btn.Middle:SetTexture("Interface/Glues/CharacterCreate/CharacterCreate-LabelFrame")
		btn.Middle:SetHeight(64)
		btn.Middle:SetPoint("LEFT", btn.Left, "RIGHT")
		btn.Middle:SetPoint("RIGHT", btn.Right, "LEFT")
		btn.Middle:SetTexCoord(.1953125, .8046875, 0, 1)

		btn.Text = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		btn.Text:SetWordWrap(false)
		btn.Text:SetJustifyH("RIGHT")
		btn.Text:SetPoint("LEFT", btn.Left, "RIGHT", 0, 2)
		btn.Text:SetPoint("RIGHT", btn.Right, "LEFT", -17, 2)

		btn.Icon = btn:CreateTexture(nil, "ARTWORK")

		btn.Button = CreateFrame("BUTTON", nil, btn)
		btn.Button:SetMotionScriptsWhileDisabled(true)
		btn.Button:SetSize(26, 26)
		btn.Button:SetPoint("RIGHT", btn.Right, "LEFT", 9, 1)
		btn.Button:SetNormalTexture("Interface/ChatFrame/UI-ChatIcon-ScrollDown-Up")
		btn.Button:SetPushedTexture("Interface/ChatFrame/UI-ChatIcon-ScrollDown-Down")
		btn.Button:SetDisabledTexture("Interface/ChatFrame/UI-ChatIcon-ScrollDown-Disabled")
		btn.Button:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight")
		btn.Button:GetHighlightTexture():SetBlendMode("ADD")
		btn.Button.SFNoGlobalMouseEvent = true
		btn.Button:SetScript("OnClick", Button_OnClick)

		return btn
	end
	libMethods.CreateButton = libMethods.CreateButtonOriginal
end


do
	local function OnClick(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self:dropDownToggle(1, nil, self, self:GetWidth() - 18, self:GetHeight() / 2 + 6)
	end


	function libMethods:CreateStreatchButtonOriginal(parent, width, height, wrap)
		self.CreateStreatchButtonOriginal = nil

		local btn = CreateFrame("BUTTON", nil, parent, "UIMenuButtonStretchTemplate")
		if width then btn:SetWidth(width) end
		if height then btn:SetHeight(height) end
		if wrap == nil then wrap = false end
		self:SetMixin(btn)
		btn:ddSetDisplayMode("menu")
		btn:ddHideWhenButtonHidden()
		btn:SetScript("OnClick", OnClick)

		btn.Icon = btn:CreateTexture(nil, "ARTWORK")
		btn.Icon:SetTexture("Interface/ChatFrame/ChatFrameExpandArrow")
		btn.Icon:SetSize(10, 12)
		btn.Icon:SetPoint("RIGHT", -5, 0)

		btn:SetText(" ")
		btn.Text = btn:GetFontString()
		btn.Text:SetWordWrap(wrap)
		btn.Text:ClearAllPoints()
		btn.Text:SetPoint("TOP", 0, -4)
		btn.Text:SetPoint("BOTTOM", 0, 4)
		btn.Text:SetPoint("LEFT", 4, 0)
		btn.Text:SetPoint("RIGHT", -15, 0)

		return btn
	end
	libMethods.CreateStreatchButton = libMethods.CreateStreatchButtonOriginal
end