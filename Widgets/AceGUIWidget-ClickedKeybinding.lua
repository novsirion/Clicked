--[[-----------------------------------------------------------------------------
Clicked Keybinding Widget
Set Keybindings in the Config UI. Allowing for left mouse button and right
mouse buttons to be bound.

This file was copied from AceGUIWidget-Keybinding.lua. All modifications
to this file have been prepended by comment blocks as follows:
-- CLICKED MODIFICATION 
-- original: <original code>

When updating this file to the latest version of AceGUIWidget-Keybinding.lua,
the code inside of those blocks should remain -- or be updated to be compatible
with the new version.

Use a diff tool to compare the differences between the files, or re-apply the
modifications manually after updating.
-------------------------------------------------------------------------------]]
-- CLICKED MODIFICATION 
-- original: local Type, Version = "Keybinding", 26
local Type, Version = "ClickedKeybinding", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown = IsShiftKeyDown, IsControlKeyDown, IsAltKeyDown
local CreateFrame, UIParent = CreateFrame, UIParent

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: NOT_BOUND

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]

local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

local function Keybinding_OnClick(frame, button)
	-- CLICKED MODIFICATION 
	-- original: if button == "LeftButton" or button == "RightButton" then
	if button == "LeftButton" then
		local self = frame.obj
		-- CLICKED MODIFICATION 
		-- original: <nothing>
		local passed = GetTime() - (self.lastClickTime or 0)
		
		-- CLICKED MODIFICATION 
		-- original: if self.waitingForKey then
		-- CLICKED MODIFICATION 
		-- original: frame:EnableKeyboard(false)
		-- CLICKED MODIFICATION 
		-- original: frame:EnableMouseWheel(false)
		-- CLICKED MODIFICATION 
		-- original: self.msgframe:Hide()
		-- CLICKED MODIFICATION 
		-- original: frame:UnlockHighlight()
		-- CLICKED MODIFICATION 
		-- original: self.waitingForKey = nil
		-- CLICKED MODIFICATION 
		-- original: else
		if not self.waitingForKey and passed > 0.01 then
			frame:EnableKeyboard(true)
			frame:EnableMouseWheel(true)
			self.msgframe:Show()
			frame:LockHighlight()
			self.waitingForKey = true
		end
	end
	AceGUI:ClearFocus()
end

local ignoreKeys = {
	-- CLICKED MODIFICATION 
	-- original: ["BUTTON1"] = true, ["BUTTON2"] = true,
	["UNKNOWN"] = true,
	["LSHIFT"] = true, ["LCTRL"] = true, ["LALT"] = true,
	["RSHIFT"] = true, ["RCTRL"] = true, ["RALT"] = true,
}
local function Keybinding_OnKeyDown(frame, key)
	local self = frame.obj
	if self.waitingForKey then
		local keyPressed = key
		if keyPressed == "ESCAPE" then
			keyPressed = ""
		else
			if ignoreKeys[keyPressed] then return end
			if IsShiftKeyDown() then
				keyPressed = "SHIFT-"..keyPressed
			end
			if IsControlKeyDown() then
				keyPressed = "CTRL-"..keyPressed
			end
			if IsAltKeyDown() then
				keyPressed = "ALT-"..keyPressed
			end
		end

		frame:EnableKeyboard(false)
		frame:EnableMouseWheel(false)
		self.msgframe:Hide()
		frame:UnlockHighlight()
		self.waitingForKey = nil
		-- CLICKED MODIFICATION 
		-- original: <nothing>
		self.lastClickTime = GetTime()

		if not self.disabled then
			self:SetKey(keyPressed)
			self:Fire("OnKeyChanged", keyPressed)
		end
	end
end

local function Keybinding_OnMouseDown(frame, button)
	-- CLICKED MODIFICATION 
	-- original: if button == "LeftButton" or button == "RightButton" then
	if button == "LeftButton" then
		-- CLICKED MODIFICATION 
		-- original: return
		button = "BUTTON1"
	-- CLICKED MODIFICATION 
	-- original: <nothing>
	elseif button == "RightButton" then
		-- CLICKED MODIFICATION 
		-- original: <nothing>
        button = "BUTTON2"
    elseif button == "MiddleButton" then
		button = "BUTTON3"
	elseif button == "Button4" then
		button = "BUTTON4"
	elseif button == "Button5" then
		button = "BUTTON5"
	end
	Keybinding_OnKeyDown(frame, button)
end

local function Keybinding_OnMouseWheel(frame, direction)
	local button
	if direction >= 0 then
		button = "MOUSEWHEELUP"
	else
		button = "MOUSEWHEELDOWN"
	end
	Keybinding_OnKeyDown(frame, button)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:SetWidth(200)
		self:SetLabel("")
		self:SetKey("")
		self.waitingForKey = nil
		self.msgframe:Hide()
		self:SetDisabled(false)
		self.button:EnableKeyboard(false)
		self.button:EnableMouseWheel(false)
	end,

	-- ["OnRelease"] = nil,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.button:Disable()
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.button:Enable()
			self.label:SetTextColor(1,1,1)
		end
	end,

	["SetKey"] = function(self, key)
		if (key or "") == "" then
			self.button:SetText(NOT_BOUND)
			self.button:SetNormalFontObject("GameFontNormal")
		else
			self.button:SetText(key)
			self.button:SetNormalFontObject("GameFontHighlight")
		end
	end,

	["GetKey"] = function(self)
		local key = self.button:GetText()
		if key == NOT_BOUND then
			key = nil
		end
		return key
	end,

	["SetLabel"] = function(self, label)
		self.label:SetText(label or "")
		if (label or "") == "" then
			self.alignoffset = nil
			self:SetHeight(24)
		else
			self.alignoffset = 30
			self:SetHeight(44)
		end
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function keybindingMsgFixWidth(frame)
	frame:SetWidth(frame.msg:GetWidth() + 10)
	frame:SetScript("OnUpdate", nil)
end

local function Constructor()
	local name = "AceGUI30KeybindingButton" .. AceGUI:GetNextWidgetNum(Type)

	local frame = CreateFrame("Frame", nil, UIParent)
	local button = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")

	button:EnableMouse(true)
	button:EnableMouseWheel(false)
	button:RegisterForClicks("AnyDown")
	button:SetScript("OnEnter", Control_OnEnter)
	button:SetScript("OnLeave", Control_OnLeave)
	button:SetScript("OnClick", Keybinding_OnClick)
	button:SetScript("OnKeyDown", Keybinding_OnKeyDown)
	button:SetScript("OnMouseDown", Keybinding_OnMouseDown)
	button:SetScript("OnMouseWheel", Keybinding_OnMouseWheel)
	button:SetPoint("BOTTOMLEFT")
	button:SetPoint("BOTTOMRIGHT")
	button:SetHeight(24)
	button:EnableKeyboard(false)

	local text = button:GetFontString()
	text:SetPoint("LEFT", 7, 0)
	text:SetPoint("RIGHT", -7, 0)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("TOPLEFT")
	label:SetPoint("TOPRIGHT")
	label:SetJustifyH("CENTER")
	label:SetHeight(18)

	local msgframe = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	msgframe:SetHeight(30)
	msgframe:SetBackdrop(ControlBackdrop)
	msgframe:SetBackdropColor(0,0,0)
	msgframe:SetFrameStrata("FULLSCREEN_DIALOG")
	msgframe:SetFrameLevel(1000)
	msgframe:SetToplevel(true)

	local msg = msgframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	-- CLICKED MODIFICATION 
	-- original: msg:SetText("Press a key to bind, ESC to clear the binding or click the button again to cancel.")
	msg:SetText("Press a key to bind, or ESC to clear the binding.")
	msgframe.msg = msg
	msg:SetPoint("TOPLEFT", 5, -5)
	msgframe:SetScript("OnUpdate", keybindingMsgFixWidth)
	msgframe:SetPoint("BOTTOM", button, "TOP")
	msgframe:Hide()

	-- CLICKED MODIFICATION 
	-- original: <nothing>
	if IsAddOnLoaded("AddOnSkins") and AddOnSkins then
		-- CLICKED MODIFICATION 
		-- original: <nothing>
		local AS = unpack(AddOnSkins)

		-- CLICKED MODIFICATION 
		-- original: <nothing>
		AS:SkinButton(button)
		-- CLICKED MODIFICATION 
		-- original: <nothing>
		AS:SkinFrame(msgframe)

		-- CLICKED MODIFICATION 
		-- original: <nothing>
		msg:ClearAllPoints()
		-- CLICKED MODIFICATION 
		-- original: <nothing>
		msg:SetPoint("CENTER")
	-- CLICKED MODIFICATION 
	-- original: <nothing>
	end

	local widget = {
		button      = button,
		label       = label,
		msgframe    = msgframe,
		frame       = frame,
		alignoffset = 30,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	button.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)