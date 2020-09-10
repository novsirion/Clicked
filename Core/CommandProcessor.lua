Clicked.COMMAND_ACTION_TARGET = "target"
Clicked.COMMAND_ACTION_MENU = "menu"
Clicked.COMMAND_ACTION_MACRO = "macro"

local macroFrameHandlers = {}

local function GetCommandAttributeIdentifier(command, isClickCastCommand)
	-- separate modifiers from the actual binding
	local prefix, suffix = command.keybind:match("^(.-)([^%-]+)$")
	local buttonIndex = suffix:match("^BUTTON(%d+)$")

	-- remove any trailing dashes (shift- becomes shift, ctrl- becomes ctrl, etc.)
	if prefix:sub(-1, -1) == "-" then
		prefix = prefix:sub(1, -2)
	end

	-- convert the parts to lowercase so it fits the attribute naming style
	prefix = prefix:lower()
	suffix = suffix:lower()

	if buttonIndex ~= nil and (isClickCastCommand or buttonIndex ~= nil) then
		suffix = buttonIndex
	elseif buttonIndex ~= nil then
		suffix = "clicked-mouse-" .. tostring(prefix) .. tostring(buttonIndex)
		prefix = ""
	else
		suffix = "clicked-button-" .. tostring(prefix) .. tostring(suffix)
		prefix = ""
	end

	return prefix, suffix, buttonIndex ~= nil
end

local function CreateStateDriverAttribute(frame, state, condition)
	frame:SetAttribute("_onstate-" .. state, [===[
		if newstate == "enabled" then
			self:RunAttribute("clicked-clear-binding")
		else
			self:RunAttribute("clicked-register-binding")
		end
	]===])

	RegisterStateDriver(frame, state, condition)
end

local function GetFrameHandler(index)
	if index > #macroFrameHandlers then
		frame = CreateFrame("Button", "ClickedMacroFrameHandler" .. index, UIParent, "SecureActionButtonTemplate,SecureHandlerStateTemplate,SecureHandlerShowHideTemplate")
		frame:Hide()

		-- set required data first
		frame:SetAttribute("clicked-registered", false)
		frame:SetAttribute("clicked-can-enable", true)
		frame:SetAttribute("clicked-keybind", "")
		frame:SetAttribute("clicked-id", "")

		-- register OnShow and OnHide handlers to ensure bindings are registered
		frame:SetAttribute("_onshow", [[ self:RunAttribute("clicked-register-binding") ]])
		frame:SetAttribute("_onhide", [[ self:RunAttribute("clicked-clear-binding") ]])

		-- attempt to register a binding, this will also check if the binding
		-- is currently allowed to be active (e.g. not in a vehicle or pet battle)
		frame:SetAttribute("clicked-register-binding", [===[
			if not self:IsShown() then
				return
			end

			if self:GetAttribute("state-petbattle") == "enabled" then
				return
			end

			if self:GetAttribute("state-vehicle") == "enabled" or self:GetAttribute("state-vehicleui") == "enabled" then
				return
			end

			if self:GetAttribute("state-possessbar") == "enabled" then
				return
			end

			local keybind = self:GetAttribute("clicked-keybind")
			local id = self:GetAttribute("clicked-id")

			self:SetBindingClick(true, keybind, self, id)
		]===])

		-- unregister a binding
		frame:SetAttribute("clicked-clear-binding", [===[
			local keybind = self:GetAttribute("clicked-keybind")
			self:ClearBinding(keybind)
		]===])

		if Clicked.WOW_MAINLINE_RELEASE then
			CreateStateDriverAttribute(frame, "vehicle", "[@vehicle,exists] enabled; disabled")
			CreateStateDriverAttribute(frame, "vehicleui", "[vehicleui] enabled; disabled")
			CreateStateDriverAttribute(frame, "possessbar", "[possessbar] enabled; disabled")
			CreateStateDriverAttribute(frame, "petbattle", "[petbattle] enabled; disabled")
		end

		table.insert(macroFrameHandlers, frame)
	end

	return macroFrameHandlers[index]
end

-- Note: This is a secure function and may not be called during combat
function Clicked:ProcessCommands(commands)
	if InCombatLockdown() then
		return
	end

	local newClickCastFrameKeybindings = {}
	local newClickCastFrameAttributes = {}
	local nextMacroFrameHandler = 1

	for _, command in ipairs(commands) do
		local isHoverCastBinding = command.mode == self.TARGETING_MODE_HOVERCAST
		local prefix, suffix, isMouseButton = GetCommandAttributeIdentifier(command, isHoverCastBinding)

		if isHoverCastBinding or isMouseButton then
			local keybind = {
				key = command.keybind,
				identifier = suffix
			}

			self:CreateCommandAttributes(newClickCastFrameAttributes, command, prefix, suffix)

			if not isMouseButton then
				table.insert(newClickCastFrameKeybindings, keybind)
			end
		end

		if not isHoverCastBinding then
			local frame = GetFrameHandler(nextMacroFrameHandler)
			local attributes = {}

			nextMacroFrameHandler = nextMacroFrameHandler + 1

			self:CreateCommandAttributes(attributes, command, prefix, suffix)
			self:SetPendingFrameAttributes(frame, attributes)
			self:ApplyAttributesToFrame(frame)

			frame:SetAttribute("clicked-keybind", command.keybind)
			frame:SetAttribute("clicked-id", suffix)
			frame:Show()
		end
	end

	self:UpdateClickCastHeader(newClickCastFrameKeybindings)
	self:UpdateClickCastFrames(newClickCastFrameAttributes)

	for i = nextMacroFrameHandler, #macroFrameHandlers do
		local frame = macroFrameHandlers[i]

		frame:Hide()
		frame:SetAttribute("clicked-keybind", "")
		frame:SetAttribute("clicked-id", "")

		self:ApplyAttributesToFrame(frame)
	end
end
