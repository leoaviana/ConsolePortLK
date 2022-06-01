--[[
Copyright (c) 2010-2016, Hendrik "nevcairiel" Leppkes <h.leppkes@gmail.com>

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of the developer nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]

--[[
This version is modified for ConsolePort and removes the use of LibStub to make sure
ConsolePort is using a separate button registry in case other action bar addons are
simultaneously loaded. Do not copy this library for other uses.
]]

local _, ab = ...
local db = ConsolePort:GetData()
local lib = {}
ab.libs = ab.libs or {}
ab.libs.acb = lib

local UIFrameFadeIn = db.UIFrameFadeIn
local UIFrameFadeOut = db.UIFrameFadeOut

-- Lua functions
local type, error, tostring, tonumber, assert, select = type, error, tostring, tonumber, assert, select
local setmetatable, wipe, unpack, pairs, next = setmetatable, wipe, unpack, pairs, next
local str_match, format, tinsert, tremove = string.match, format, tinsert, tremove

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- Note: No WoW API function get upvalued to allow proper interaction with any addons that try to hook them.
-- GLOBALS: LibStub, CreateFrame, InCombatLockdown, ClearCursor, GetCursorInfo, GameTooltip, GameTooltip_SetDefaultAnchor
-- GLOBALS: GetBindingKey, GetBindingText, SetBinding, SetBindingClick, GetCVar, GetMacroInfo
-- GLOBALS: PickupAction, PickupItem, PickupMacro, PickupPetAction, PickupSpell, PickupCompanion, PickupEquipmentSet
-- GLOBALS: CooldownFrame_SetTimer, UIParent, IsSpellOverlayed, SpellFlyout, GetMouseFocus, SetClampedTextureRotation
-- GLOBALS: GetActionInfo, GetActionTexture, HasAction, GetActionText, GetActionCount, GetActionCooldown, IsAttackAction
-- GLOBALS: IsAutoRepeatAction, IsEquippedAction, IsCurrentAction, IsConsumableAction, IsUsableAction, IsStackableAction, IsActionInRange
-- GLOBALS: GetSpellLink, GetMacroSpell, GetSpellTexture, GetSpellCount, GetSpellCooldown, IsAttackSpell, IsCurrentSpell
-- GLOBALS: FindSpellBookSlotBySpellID, IsUsableSpell, IsConsumableSpell, IsSpellInRange, IsAutoRepeatSpell
-- GLOBALS: GetItemIcon, GetItemCount, GetItemCooldown, IsEquippedItem, IsCurrentItem, IsUsableItem, IsConsumableItem, IsItemInRange
-- GLOBALS: GetActionCharges, IsItemAction, GetSpellCharges
-- GLOBALS: RANGE_INDICATOR, ATTACK_BUTTON_FLASH_TIME, TOOLTIP_UPDATE_TIME
-- GLOBALS: DraenorZoneAbilityFrame, HasDraenorZoneAbility, GetLastDraenorSpellTexture

local LBG = ab.libs.glow

lib.eventFrame = lib.eventFrame or CreateFrame("Frame")
lib.eventFrame:UnregisterAllEvents()

lib.buttonRegistry = lib.buttonRegistry or {}
lib.activeButtons = lib.activeButtons or {}
lib.actionButtons = lib.actionButtons or {}
lib.nonActionButtons = lib.nonActionButtons or {}

local Generic = CreateFrame("CheckButton")
local Generic_MT = {__index = Generic}

local Action = setmetatable({}, {__index = Generic})
local Action_MT = {__index = Action}

local PetAction = setmetatable({}, {__index = Generic})
local PetAction_MT = {__index = PetAction}

local Spell = setmetatable({}, {__index = Generic})
local Spell_MT = {__index = Spell}

local Item = setmetatable({}, {__index = Generic})
local Item_MT = {__index = Item}

local Macro = setmetatable({}, {__index = Generic})
local Macro_MT = {__index = Macro}

local Custom = setmetatable({}, {__index = Generic})
local Custom_MT = {__index = Custom}

local type_meta_map = {
	empty  = Generic_MT,
	action = Action_MT,
	--pet    = PetAction_MT,
	spell  = Spell_MT,
	item   = Item_MT,
	macro  = Macro_MT,
	custom = Custom_MT
}

local ButtonRegistry, ActiveButtons, ActionButtons, NonActionButtons = lib.buttonRegistry, lib.activeButtons, lib.actionButtons, lib.nonActionButtons

local Update, UpdateButtonState, UpdateUsable, UpdateCount, UpdateCooldown, UpdateTooltip, UpdateNewAction, UpdatePage
local StartFlash, StopFlash, UpdateFlash, UpdateRangeTimer 
local ShowGrid, HideGrid, UpdateGrid, SetupSecureSnippets, WrapOnClick 

local InitializeEventHandler, OnEvent, ForAllButtons, OnUpdate

local DefaultConfig = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = true,
	colors = {
		range = { 0.8, 0.1, 0.1 },
		mana = { 0.5, 0.5, 1.0 }
	},
	hideElements = {
		macro = false,
		hotkey = false,
		equipped = false,
	},
	keyBoundTarget = false,
	clickOnDown = false,
}

--- Create a new action button.
-- @param id Internal id of the button (not used by LibActionButton-1.0, only for tracking inside the calling addon)
-- @param name Name of the button frame to be created (not used by LibActionButton-1.0 aside from naming the frame)
-- @param header Header that drives these action buttons (if any)
function lib:CreateButton(id, name, header, config)
	local templates = "SecureActionButtonTemplate, SecureHandlerEnterLeaveTemplate, CPUIActionButtonTemplate" 
	local button = setmetatable(CreateFrame("CheckButton", name, header, templates), Generic_MT)

	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp", "AnyDown") 

	-- Frame Scripts
	button:HookScript("OnEnter", Generic.OnEnter)
	button:HookScript("OnLeave", Generic.OnLeave)
	button:HookScript("PreClick", Generic.PreClick)
	button:HookScript("PostClick", Generic.PostClick) 

	button.id = id
	button.header = header
	-- Mapping of state -> action
	button.state_types = {}
	button.state_actions = {}

	-- Store the LAB Version that created this button for debugging
	button.__LAB_Version = MINOR_VERSION

	-- just in case we're not run by a header, default to state 0
	button:SetAttribute("state", 0)

	SetupSecureSnippets(button)
	WrapOnClick(button)

	-- adjust count/stack size
	button.Count:SetFont(button.Count:GetFont(), 16, "OUTLINE")

	-- Store the button in the registry, needed for event and OnUpdate handling
	if not next(ButtonRegistry) then
		InitializeEventHandler()
	end
	ButtonRegistry[button] = true

	button:UpdateConfig(config)

	-- run an initial update
	button:UpdateAction()

	-- somewhat of a hack for the Flyout buttons to not error.
	button.action = 0

	return button
end

-- Unfortunately due to my low knowledge on SecureHandlers and such, I wasn't able to fix it, i can just comment lines that are crashing the AddOn, maybe i will fix
-- in the future? idk, so.. some features are not working like dragging out a spell from the button with your mouse, I don't find this bug to be gamebreaking because
-- you can drag spells into it so i'm not really that bothered with it.

function SetupSecureSnippets(button)
	button:Execute([[States = newtable("CTRL-SHIFT-", "CTRL-", "SHIFT-", "")]]) 
	button:SetAttribute("_custom", Custom.RunCustom)
	-- secure UpdateState(self, state)
	-- update the type and action of the button based on the state
	button:SetAttribute("UpdateState", [[
		local state = ...
		local _type = type  

		self:SetAttribute("state", state)
		local type, action = (self:GetAttribute(format("labtype-%s", state)) or "empty"), self:GetAttribute(format("labaction-%s", state))

		self:SetAttribute("type", type)
		if type ~= "empty" and type ~= "custom" then
			local action_field = (type == "pet") and "action" or type
			self:SetAttribute(action_field, action)
			self:SetAttribute("action_field", action_field)
		end
		self:SetID((type == "action" and _type(action) == "number" and action <= 12 and action) or 0) 
		if self:GetID() > 0 then 
			--control:CallMethod("ButtonContentsChanged", state, type, action + ((self:GetAttribute('actionpage') - 1) * 12))
		end
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			control:Run(onStateChanged, state, type, action)
		end
	]])

	button:SetAttribute("actionpage", 1) 

	-- this function is invoked by the header when the state changes
	button:SetAttribute("_childupdate-state", [[
		--control:RunAttribute("UpdateState", message) -- 
		control:RunFor(self, self:GetAttribute("UpdateState"), message) 
	]])
 
	button:SetAttribute("_childupdate-actionpage", [[
		self:SetAttribute('actionpage', message)
		if self:GetID() > 0 then
			local state = self:GetAttribute("state")
			local kind, value = (self:GetAttribute(format("labtype-%s", state)) or "empty"), self:GetAttribute(format("labaction-%s", state))
			--control:CallMethod("ButtonContentsChanged", state, kind, value + ((message - 1) * 12))
		end
	]])

	button:SetAttribute("_childupdate-hover", [[
		--control:CallMethod("CallMethodFromFrame", self:GetName(), "Hover", message) 
	]])

	button:SetAttribute("_onenter", [[
		control:CallMethod("SetClicks", true)
	]])

	button:SetAttribute("_onleave", [[
		control:CallMethod("SetClicks", false)
	]]) 

	-- secure PickupButton(self, kind, value, ...)
	-- utility function to place a object on the cursor
	button:SetAttribute("PickupButton", [[
		local kind, value = ...
		if kind == "empty" then
			return "clear"
		elseif kind == "action" or kind == "pet" then
			local actionType = (kind == "pet") and "petaction" or kind
			return actionType, value
		elseif kind == "spell" or kind == "item" or kind == "macro" then
			return "clear", kind, value
		else
			print("ActionButton: Unknown type: " .. tostring(kind))
			return false
		end
	]])

	button:SetAttribute("OnDragStart", [[
		if (self:GetAttribute("buttonlock") and not IsModifiedClick("PICKUPACTION")) or self:GetAttribute("disableDragNDrop") then return false end
		local state = self:GetAttribute("state")
		local type = self:GetAttribute("type")
		-- if the button is empty, we can't drag anything off it
		if type == "empty" or type == "custom" then
			return false
		end
		-- Get the value for the action attribute
		local action_field = self:GetAttribute("action_field")
		local action = self:GetAttribute(action_field)

		-- non-action fields need to change their type to empty
		if type ~= "action" and type ~= "pet" then
			self:SetAttribute(format("labtype-%s", state), "empty")
			self:SetAttribute(format("labaction-%s", state), nil)
			-- update internal state
			control:RunFor(self, self:GetAttribute("UpdateState"), state)
			-- send a notification to the insecure code
			--control:CallMethod("ButtonContentsChanged", state, "empty", nil)
		end			
		if self:GetID() > 0 then -- cp stuff
			action = action + ((self:GetAttribute('actionpage') - 1) * 12)
		end
		-- return the button contents for pickup
	 	return control:RunFor(self, self:GetAttribute("PickupButton"), type, action)
	]])

	button:SetAttribute("OnReceiveDrag", [[
		if self:GetAttribute("disableDragNDrop") then return false end
		local kind, value, subtype, extra = ...
		if not kind or not value then return false end
		local state = self:GetAttribute("state")
		local buttonType, buttonAction = self:GetAttribute("type"), nil
		if buttonType == "custom" then return false end
		-- action buttons can do their magic themself
		-- for all other buttons, we'll need to update the content now
		if buttonType ~= "action" and buttonType ~= "pet" then
			-- with "spell" types, the 4th value contains the actual spell id
			if kind == "spell" then
				if extra then
					value = extra
				else
					print("no spell id?", ...)
				end
			elseif kind == "item" and value then
				value = format("item:%d", value)
			end

			-- Get the action that was on the button before
			if buttonType ~= "empty" then
				buttonAction = self:GetAttribute(self:GetAttribute("action_field"))
			end

			-- TODO: validate what kind of action is being fed in here
			-- We can only use a handful of the possible things on the cursor
			-- return false for all those we can't put on buttons

			self:SetAttribute(format("labtype-%s", state), kind)
			self:SetAttribute(format("labaction-%s", state), value)
			-- update internal state
			control:RunFor(self, self:GetAttribute("UpdateState"), state)
			-- send a notification to the insecure code
			--control:CallMethod("ButtonContentsChanged", state, kind, value) -- for sm reason this was commented out, idk why
		else
			-- get the action for (pet-)action buttons
			buttonAction = self:GetAttribute("action")
			if self:GetID() > 0 then - cp stuffie
				buttonAction = buttonAction + ((self:GetAttribute('actionpage') - 1) * 12)
			end
		end
		return control:RunFor(self, self:GetAttribute("PickupButton"), buttonType, buttonAction)
	]])

	button:SetScript("OnDragStart", nil)
	-- Wrapped OnDragStart(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnDragStart", [[
		--return control:RunAttribute("OnDragStart") -- 
		--control:RunFor(self, self:GetAttribute("OnDragStart"))
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnDragStart", [[
		return "message", "update";
	]], [[
		--control:RunAttribute("UpdateState", self:GetAttribute("state")) -- 
		--control:RunFor(self, self:GetAttribute("UpdateState"), self:GetAttribute("state"))
	]])

	button:SetScript("OnReceiveDrag", nil)
	-- Wrapped OnReceiveDrag(self, button, kind, value, ...)
	button.header:WrapScript(button, "OnReceiveDrag", [[
		--return control:RunAttribute("OnReceiveDrag", kind, value, ...) -- 
		--control:RunFor(self, self:GetAttribute("OnReceiveDrag"), kind, value, ...)
	]])
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	button.header:WrapScript(button, "OnReceiveDrag", [[
		return "message", "update"
	]], [[
		--self:RunAttribute("UpdateState", self:GetAttribute("state"))
	    --control:RunFor(self, self:GetAttribute("UpdateState"), self:GetAttribute("state"))
	]])

	button:SetScript("OnAttributeChanged", function(self, ...)
		button:ButtonContentsChanged(...) -- probably not needed for CP
	end)
end

function WrapOnClick(button) 
	button.header:WrapScript(button, "PreClick", [[
		local reticleMacro = control:RunAttribute("GetReticleMacro", self:GetAttribute("action"))
		if button == 'ControllerInput' and not down then
			if reticleMacro then
				self:SetAttribute("type", "macro")
				self:SetAttribute("macrotext", reticleMacro)
			else
				self:SetAttribute("type", "omit")
			end
		end
	]]) 
	-- Wrap OnClick, to catch changes to actions that are applied with a click on the button.
	button.header:WrapScript(button, "OnClick", [[
		if down then
			if self:GetAttribute("type") == "action" then
				local type, action = GetActionInfo(self:GetAttribute("action"))
				return nil, format("%s|%s", tostring(type), tostring(action))
			end
		end
	]], [[
		if down then -- cp?
			local type, action = GetActionInfo(self:GetAttribute("action"))
			if message ~= format("%s|%s", tostring(type), tostring(action)) then
				control:RunAttribute("UpdateState", self:GetAttribute("state")) -- return control:RunFor(self, self:GetAttribute("UpdateState"), self:GetAttribute("state"))
			end
		end
	]])
	button.header:WrapScript(button, "PostClick", [[
		self:SetAttribute("type", self:GetAttribute("action_field"))
	]]) 
end

-----------------------------------------------------------
--- utility

function lib:GetAllButtons()
	local buttons = {}
	for button in next, ButtonRegistry do
		buttons[button] = true
	end
	return buttons
end

function Generic:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end

function Generic:NewHeader(header)
	self.header = header
	self:SetParent(header)
	SetupSecureSnippets(self)
	WrapOnClick(self)
end


-----------------------------------------------------------
--- state management

function Generic:ClearStates()
	for state in pairs(self.state_types) do
		self:SetAttribute(format("labtype-%s", state), nil)
		self:SetAttribute(format("labaction-%s", state), nil)
	end
	wipe(self.state_types)
	wipe(self.state_actions)
end

function Generic:SetState(state, kind, action)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	-- we allow a nil kind for setting a empty state
	if not kind then kind = "empty" end
	if not type_meta_map[kind] then
		error("SetStateAction: unknown action type: " .. tostring(kind), 2)
	end
	if kind ~= "empty" and action == nil then
		error("SetStateAction: an action is required for non-empty states", 2)
	end
	if kind ~= "custom" and action ~= nil and type(action) ~= "number" and type(action) ~= "string" or (kind == "custom" and type(action) ~= "table") then
		error("SetStateAction: invalid action data type, only strings and numbers allowed", 2)
	end

	if kind == "item" then
		if tonumber(action) then
			action = format("item:%s", action)
		else
			local itemString = str_match(action, "^|c%x+|H(item[%d:]+)|h%[")
			if itemString then
				action = itemString
			end
		end
	end

	self.state_types[state] = kind
	self.state_actions[state] = action
	self:UpdateState(state)
end

function Generic:UpdateState(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	self:SetAttribute(format("labtype-%s", state), self.state_types[state])
	self:SetAttribute(format("labaction-%s", state), self.state_actions[state])
	if state ~= tostring(self:GetAttribute("state")) then return end
	if self.header then
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("UpdateState"), frame:GetAttribute("state"))
		]])
	else
	-- TODO
	end
	self:UpdateAction()
end

function Generic:GetAction(state)
	if not state then state = self:GetAttribute("state") end
	state = tostring(state)
	return self.state_types[state] or "empty", self.state_actions[state]
end

function Generic:UpdateAllStates()
	for state in pairs(self.state_types) do
		self:UpdateState(state)
	end
end

function Generic:ButtonContentsChanged(state, kind, value)
	state = tostring(state)
	self.state_types[state] = kind or "empty"
	self.state_actions[state] = value
	self:UpdateAction(self)
end

function Generic:DisableDragNDrop(flag)
	if InCombatLockdown() then
		error("LibActionButton-1.0: You can only toggle DragNDrop out of combat!", 2)
	end
	if flag then
		self:SetAttribute("disableDragNDrop", true) 
	else
		self:SetAttribute("disableDragNDrop", nil) 
	end
end  
function Generic:UpdateAlpha()
	UpdateCooldown(self)
end

-----------------------------------------------------------
--- frame scripts

-- copied (and adjusted) from SecureHandlers.lua
local function PickupAny(kind, target, detail, ...)
	if kind == "clear" then
		ClearCursor()
		kind, target, detail = target, detail, ...
	end

	if kind == 'action' then
		PickupAction(target)
	elseif kind == 'item' then
		PickupItem(target)
	elseif kind == 'macro' then
		PickupMacro(target)
	elseif kind == 'petaction' then
		PickupPetAction(target)
	elseif kind == 'spell' then
		PickupSpell(target)
	elseif kind == 'companion' then
		PickupCompanion(target, detail)
	elseif kind == 'equipmentset' then
		PickupEquipmentSet(target)
	end
end

function Generic:OnEnter() 
	self.header:FadeIn(self.header:GetAlpha())
	self:FadeIn() 
	if self.config.tooltip ~= "disabled" and (self.config.tooltip ~= "nocombat" or not InCombatLockdown()) then
		UpdateTooltip(self)
	end
-- no keybound stuff.
	if self._state_type == "action" and self.NewActionTexture then
		--lib.ACTION_HIGHLIGHT_MARKS[self._state_action] = false
		UpdateNewAction(self)
	end
end

function Generic:OnLeave() 
	if self.header:GetAttribute('hidesafe') and not InCombatLockdown() then
		self.header:FadeOut(self.header:GetAlpha())
	end
	self:FadeOut() 
	GameTooltip:Hide()
	--self:SetScript('OnUpdate', nil)
end

-- Insecure drag handler to allow clicking on the button with an action on the cursor
-- to place it on the button. Like action buttons work.
function Generic:PreClick()
	if self._state_type == "action" or self._state_type == "pet"
	   or InCombatLockdown() or self:GetAttribute("disableDragNDrop")  
	then
		return
	end
	-- check if there is actually something on the cursor
	local kind, value, subtype = GetCursorInfo()
	if not (kind and value) then return end
	self._old_type = self._state_type
	if self._state_type and self._state_type ~= "empty" then
		self._old_type = self._state_type
		self:SetAttribute("type", "empty")
		--self:SetState(nil, "empty", nil)
	end
	self._receiving_drag = true
end

local function formatHelper(input)
	if type(input) == "string" then
		return format("%q", input)
	else
		return tostring(input)
	end
end

function Generic:PostClick(button) 
	UpdateButtonState(self)
	if self._receiving_drag and not InCombatLockdown() then
		if self._old_type then
			self:SetAttribute("type", self._old_type)
			self._old_type = nil
		end
		local oldType, oldAction = self._state_type, self._state_action
		local kind, data, subtype = GetCursorInfo()
		self.header:SetFrameRef("updateButton", self)
		self.header:Execute(format([[
			local frame = self:GetFrameRef("updateButton")
			control:RunFor(frame, frame:GetAttribute("OnReceiveDrag"), %s, %s, %s)
			control:RunFor(frame, frame:GetAttribute("UpdateState"), %s)
		]], formatHelper(kind), formatHelper(data), formatHelper(subtype), formatHelper(self:GetAttribute("state"))))
		PickupAny("clear", oldType, oldAction)
	end
	self._receiving_drag = nil
end

-- WOTLK Workaround, Custom CallMethod to be called from the LOCAL_CTRL:CallMethod.. 

Generic.CallMethodFromFrame = CPAPI.CallMethodFromFrame
	 
--

-----------------------------------------------------------
--- configuration

local function merge(target, source, default)
	for k,v in pairs(default) do
		if type(v) ~= "table" then
			if source and source[k] ~= nil then
				target[k] = source[k]
			else
				target[k] = v
			end
		else
			if type(target[k]) ~= "table" then target[k] = {} else wipe(target[k]) end
			merge(target[k], type(source) == "table" and source[k], v)
		end
	end
	return target
end

function Generic:UpdateConfig(config)
	if config and type(config) ~= "table" then
		error("LibActionButton-1.0: UpdateConfig requires a valid configuration!", 2)
	end
	local oldconfig = self.config
	if not self.config then self.config = {} end
	-- merge the two configs
	merge(self.config, config, DefaultConfig)

	UpdateUsable(self) 

	if self.config.hideElements.macro then
		self.Name:Hide()
	else
		self.Name:Show()
	end
 
	Update(self, true)
 
end

-----------------------------------------------------------
--- event handler

function ForAllButtons(method, onlyWithAction)
	assert(type(method) == "function")
	for button in next, (onlyWithAction and ActiveButtons or ButtonRegistry) do
		method(button)
	end
end

function InitializeEventHandler()
	lib.eventFrame:SetScript("OnEvent", OnEvent)
	lib.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
	lib.eventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
	--lib.eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	--lib.eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	lib.eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	lib.eventFrame:RegisterEvent("UPDATE_BINDINGS")
	lib.eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
	lib.eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")
	lib.eventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
	lib.eventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
	lib.eventFrame:RegisterEvent("START_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	lib.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	lib.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
	lib.eventFrame:RegisterEvent("COMPANION_UPDATE")
	lib.eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	lib.eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
	lib.eventFrame:RegisterEvent("PET_STABLE_UPDATE")
	lib.eventFrame:RegisterEvent("PET_STABLE_SHOW")

	-- With those two, do we still need the ACTIONBAR equivalents of them?
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	lib.eventFrame:RegisterEvent("SPELL_UPDATE_USABLE")
	lib.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

	lib.eventFrame:Show()
	lib.eventFrame:SetScript("OnUpdate", OnUpdate)
end

function OnEvent(frame, event, arg1, ...)
	if (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") or event == "LEARNED_SPELL_IN_TAB" then
		local tooltipOwner = GameTooltip:GetOwner()
		if ButtonRegistry[tooltipOwner] then
			tooltipOwner:SetTooltip()
		end
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		for button in next, ButtonRegistry do
			if button._state_type == "action" and (arg1 == 0 or arg1 == tonumber(button._state_action)) then
				Update(button)
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_SHAPESHIFT_FORM" then
		ForAllButtons(Update) 
	elseif event == "ACTIONBAR_SHOWGRID" then
		ShowGrid()
	elseif event == "ACTIONBAR_HIDEGRID" then
		HideGrid() 
	elseif event == "PLAYER_TARGET_CHANGED" then
		UpdateRangeTimer()
	elseif (event == "ACTIONBAR_UPDATE_STATE") or
		((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (arg1 == "player")) or
		((event == "COMPANION_UPDATE") and (arg1 == "MOUNT")) then
		ForAllButtons(UpdateButtonState, true)
	elseif event == "ACTIONBAR_UPDATE_USABLE" then
		for button in next, ActionButtons do
			UpdateUsable(button)
		end
	elseif event == "SPELL_UPDATE_USABLE" then
		for button in next, NonActionButtons do
			UpdateUsable(button)
		end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		for button in next, ActionButtons do
			UpdateCooldown(button)
			if GameTooltip:GetOwner() == button then
				UpdateTooltip(button)
			end
		end
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		for button in next, NonActionButtons do
			UpdateCooldown(button)
			if GameTooltip:GetOwner() == button then
				UpdateTooltip(button)
			end
		end
	elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE" then
		ForAllButtons(UpdateButtonState, true)
	elseif event == "PLAYER_ENTER_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StartFlash(button)
			end
		end
	elseif event == "PLAYER_LEAVE_COMBAT" then
		for button in next, ActiveButtons do
			if button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "START_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button:IsAutoRepeat() then
				StartFlash(button)
			end
		end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		for button in next, ActiveButtons do
			if button.flashing == 1 and not button:IsAttack() then
				StopFlash(button)
			end
		end
	elseif event == "PET_STABLE_UPDATE" or event == "PET_STABLE_SHOW" then
		ForAllButtons(Update)
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		for button in next, ActiveButtons do
			if button._state_type == "item" then
				Update(button)
			end
		end
	end
end

local flashTime = 0
local rangeTimer = -1
function OnUpdate(_, elapsed)
	flashTime = flashTime - elapsed
	rangeTimer = rangeTimer - elapsed
	-- Run the loop only when there is something to update
	if rangeTimer <= 0 or flashTime <= 0 then
		for button in next, ActiveButtons do
			-- Flashing
			if button.flashing == 1 and flashTime <= 0 then
				if button.Flash:IsShown() then
					button.Flash:Hide()
				else
					button.Flash:Show()
				end
			end

			-- Range
			if rangeTimer <= 0 then
				local inRange = button:IsInRange()
				local oldRange = button.outOfRange
				button.outOfRange = (inRange == false)
				if oldRange ~= button.outOfRange then
					UpdateUsable(button) -- only update, no hotkey stuff
				end
			end
		end

		-- Update values
		if flashTime <= 0 then
			flashTime = flashTime + ATTACK_BUTTON_FLASH_TIME
		end
		if rangeTimer <= 0 then
			rangeTimer = TOOLTIP_UPDATE_TIME
		end
	end
end

function ShowGrid() -- i believe thisx does not matter after all
	for button in next, ButtonRegistry do
		if button:IsShown() then
			button:SetShowGrid(true)
		end
	end
end

function HideGrid()
	for button in next, ButtonRegistry do
		button:SetShowGrid(false)
	end
end

-----------------------------------------------------------
--- KeyBound integration

function Generic:GetBindingAction()
	return self.config.keyBoundTarget or "CLICK "..self:GetName()..":LeftButton"
end

function Generic:GetHotkey()
	local name = "CLICK "..self:GetName()..":LeftButton"
	local key = GetBindingKey(self.config.keyBoundTarget or name)
	if not key and self.config.keyBoundTarget then
		key = GetBindingKey(name)
	end
	if key then
		return key 
	end
end

local function getKeys(binding, keys)
	keys = keys or ""
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey, "KEY_")
	end
	return keys
end

function Generic:GetBindings()
	local keys, binding

	if self.config.keyBoundTarget then
		keys = getKeys(self.config.keyBoundTarget)
	end

	keys = getKeys("CLICK "..self:GetName()..":LeftButton")

	return keys
end

function Generic:SetKey(key)
	if self.config.keyBoundTarget then
		SetBinding(key, self.config.keyBoundTarget)
	else
		SetBindingClick(key, self:GetName(), "LeftButton")
	end
end

local function clearBindings(binding)
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

function Generic:ClearBindings()
	if self.config.keyBoundTarget then
		clearBindings(self.config.keyBoundTarget)
	end
	clearBindings("CLICK "..self:GetName()..":LeftButton")
end

-----------------------------------------------------------
--- button management
 
function Generic:SetClicks(mouseover)
	if mouseover then
		self:RegisterForClicks("AnyUp")
	else
		self:RegisterForClicks("AnyUp", "AnyDown")
	end
end

function Generic:Hover(isEnabled)
	self.forceShow = isEnabled
	if self.isMainButton then return end
	if isEnabled then
		self:FadeIn(1)
	else
		self:FadeOut(0)
	end
end

function Generic:SetShowGrid(isEnabled)
	if self.isMainButton then return end
	self.showGrid = isEnabled
	if isEnabled then
		self:FadeIn(1, 0)
	else
		self:FadeOut(0, 0)
	end
end

function Generic:SetGlowing(isEnabled, instantAlpha)
	self.isGlowing = isEnabled
	if self.isMainButton then return end
	if isEnabled then
		self:FadeIn(1, instantAlpha and 0 or 0.2)
	else
		self:FadeOut(0, instantAlpha and 0 or 0.2) 
	end
end

function Generic:SetOnCooldown(isEnabled, instantAlpha)
	self.isOnCooldown = isEnabled
	if self.isMainButton then return end
	if isEnabled then
		self:FadeIn(1, instantAlpha and 0 or 0.2)
	else
		self:FadeOut(0, instantAlpha and 0 or 0.2) 
	end
end

function Generic:FadeIn(newAlpha, speed)
	UIFrameFadeIn(self, speed or 0.2, self:GetAlpha(), newAlpha or 1)
end

function Generic:FadeOut(newAlpha, speed)
	if not self.isMainButton and not self.isGlowing and not self.isOnCooldown and not self.forceShow and not self.showGrid then
		UIFrameFadeOut(self, speed or 0.2, self:GetAlpha(), newAlpha or 0)
	end
end 

function Generic:UpdateAction(force)
	local type, action = self:GetAction()
	if force or (type ~= self._state_type) or (action ~= self._state_action) then
		-- type changed, update the metatable
		if force or (self._state_type ~= type) then
			local meta = type_meta_map[type] or type_meta_map.empty
			setmetatable(self, meta)
			self._state_type = type
		end
		self._state_action = action
		Update(self)
	end
end

function Update(self)
	if self:HasAction() then
		ActiveButtons[self] = true
		if self._state_type == "action" then
			ActionButtons[self] = true
			NonActionButtons[self] = nil
		else
			ActionButtons[self] = nil
			NonActionButtons[self] = true
		end
		UpdateButtonState(self)
		UpdateUsable(self)
		UpdateCooldown(self)
		UpdateFlash(self)
		UpdatePage(self) 
	else
		ActiveButtons[self] = nil
		ActionButtons[self] = nil
		NonActionButtons[self] = nil
		self.cooldown:Hide()
		self:SetChecked(0) 
 
		self.isGlowing = false
		self.isOnCooldown = false
		self:FadeOut()
		UpdateUsable(self)
		UpdatePage(self)
	end

	-- Add a green border if button is an equipped item
	if self:IsEquipped() and not self.config.hideElements.equipped then
		self.Border:SetVertexColor(0, 1.0, 0, 0.35)
		self.Border:Show()
	else
		self.Border:Hide()
	end

	-- Update Action Text
	if not self:IsConsumableOrStackable() then
		self.Name:SetText(self:GetActionText())
	else
		self.Name:SetText("")
	end

	-- Update icon and hotkey 
	local texture = self:GetTexture()
	if texture then   
		self.rangeTimer = - 1 -- only this line, nothing else
	else
		self.cooldown:Hide() -- only these two lines, nothing else.
		self.rangeTimer = nil
	end
 
	self.icon:SetDesaturated(not texture and true or false)
	SetPortraitToTexture(self.icon, texture or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]])   

	UpdateCount(self)

	UpdateNewAction(self)

	if GameTooltip:GetOwner() == self then
		UpdateTooltip(self)
	end

	-- this could've been a spec change, need to call OnStateChanged for action buttons, if present
	if not InCombatLockdown() and self._state_type == "action" then
		local onStateChanged = self:GetAttribute("OnStateChanged")
		if onStateChanged then
			self.header:SetFrameRef("updateButton", self)
			self.header:Execute(([[
				local frame = self:GetFrameRef("updateButton")
				control:RunFor(frame, frame:GetAttribute("OnStateChanged"), %s, %s, %s)
			]]):format(formatHelper(self:GetAttribute("state")), formatHelper(self._state_type), formatHelper(self._state_action)))
		end
	end
end
 
function UpdateButtonState(self)
	if self:IsCurrentlyActive() or self:IsAutoRepeat() then
		self:SetChecked(1)
	else
		self:SetChecked(0)
	end
end

function UpdateUsable(self)
	-- TODO: make the colors configurable
	-- TODO: allow disabling of the whole recoloring
	if self.outOfRange then
		self.icon:SetVertexColor(unpack(self.config.colors.range))
	else
		local isUsable, notEnoughMana = self:IsUsable()
		if isUsable then
			self.icon:SetVertexColor(1, 1, 1)
			--self.NormalTexture:SetVertexColor(1.0, 1.0, 1.0)
		elseif notEnoughMana then
			self.icon:SetVertexColor(unpack(self.config.colors.mana))
			--self.NormalTexture:SetVertexColor(0.5, 0.5, 1.0)
		else
			self.icon:SetVertexColor(0.4, 0.4, 0.4)
			--self.NormalTexture:SetVertexColor(1.0, 1.0, 1.0)
		end
	end
end

function UpdateCount(self)
	if not self:HasAction() then
		self.Count:SetText("")
		return
	end
	if self:IsConsumableOrStackable() then
		local count = self:GetCount()
		if count > (self.maxDisplayCount or 9999) then
			self.Count:SetText("*")
		else
			self.Count:SetText(count)
		end
	else
		self.Count:SetText("")
	end
end

 
function UpdatePage(self)
	if self:GetAction() == 'action' then
		local page = self:GetAttribute('actionpage')
		local action = self:GetAttribute('action')
		if (page and action) and (page > 1) and (page < 7) then
			if action <= NUM_ACTIONBAR_BUTTONS then
				self.Page:Show()
				self.Page:SetText(page)
				return
			end
		end
	end
	self.Page:Hide()
end 

function UpdateCooldown(self)
	local start, duration, enable = self:GetCooldown()
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
end

function StartFlash(self)
	self.flashing = 1
	flashTime = 0
	UpdateButtonState(self)
end

function StopFlash(self)
	self.flashing = 0
	self.Flash:Hide()
	UpdateButtonState(self)
end

function UpdateFlash(self)
	if (self:IsAttack() and self:IsCurrentlyActive()) or self:IsAutoRepeat() then
		StartFlash(self)
	else
		StopFlash(self)
	end
end

function UpdateTooltip(self)
	if (GetCVar("UberTooltips") == "1") then
		GameTooltip_SetDefaultAnchor(GameTooltip, self);
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	if self:SetTooltip() then
		self.UpdateTooltip = UpdateTooltip
	else
		self.UpdateTooltip = nil
	end
 
	local currentModifier = self.isMainButton and ConsolePort:GetCurrentModifier() or self.mod
	local bindingString = ConsolePort:GetFormattedButtonCombination(self.plainID, currentModifier, 20, true)
	if bindingString and GameTooltip:IsVisible() then
		local title = GameTooltipTextRight1
		title:SetText(bindingString)
		title:Show()
		GameTooltip:Show()
	end  
end 

function UpdateNewAction(self)
	-- special handling for "New Action" markers
	if self.NewActionTexture then
		if self._state_type == "action" then -- and lib.ACTION_HIGHLIGHT_MARKS[self._state_action] then
			self.NewActionTexture:Show()
			UIFrameFadeOut(self.NewActionTexture, 10, 1, 0) -- cp i believe, i don't really know
		else
			self.NewActionTexture:Hide()
		end
	end
end

function UpdateRangeTimer()
	rangeTimer = -1
end

local function GetSpellIdByName(spellName)
	if not spellName then return end
	local spellLink = GetSpellLink(spellName)
	if spellLink then
		return tonumber(spellLink:match("spell:(%d+)"))
	end
	return nil
end

-----------------------------------------------------------
--- WoW API mapping
--- Generic Button
Generic.HasAction               = function(self) return nil end
Generic.GetActionText           = function(self) return "" end
Generic.GetTexture              = function(self) return nil end
Generic.GetCount                = function(self) return 0 end
Generic.GetCooldown             = function(self) return 0, 0, 0 end
Generic.IsAttack                = function(self) return nil end
Generic.IsEquipped              = function(self) return nil end
Generic.IsCurrentlyActive       = function(self) return nil end
Generic.IsAutoRepeat            = function(self) return nil end
Generic.IsUsable                = function(self) return nil end
Generic.IsConsumableOrStackable = function(self) return nil end
Generic.IsUnitInRange           = function(self, unit) return nil end
Generic.IsInRange               = function(self)
	local unit = self:GetAttribute("unit")
	if unit == "player" then
		unit = nil
	end
	local val = self:IsUnitInRange(unit)
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	return val
end
Generic.SetTooltip              = function(self) return nil end
Generic.GetSpellId              = function(self) return nil end

-----------------------------------------------------------
--- Action Button
Action.HasAction               = function(self) return HasAction(self._state_action) end
Action.GetActionText           = function(self) return GetActionText(self._state_action) end
Action.GetTexture              = function(self) return GetActionTexture(self._state_action) end
Action.GetCount                = function(self) return GetActionCount(self._state_action) end
Action.GetCooldown             = function(self) return GetActionCooldown(self._state_action) end
Action.IsAttack                = function(self) return IsAttackAction(self._state_action) end
Action.IsEquipped              = function(self) return IsEquippedAction(self._state_action) end
Action.IsCurrentlyActive       = function(self) return IsCurrentAction(self._state_action) end
Action.IsAutoRepeat            = function(self) return IsAutoRepeatAction(self._state_action) end
Action.IsUsable                = function(self) return IsUsableAction(self._state_action) end
Action.IsConsumableOrStackable = function(self) return IsConsumableAction(self._state_action) or IsStackableAction(self._state_action) end
Action.IsUnitInRange           = function(self, unit) return IsActionInRange(self._state_action, unit) end
Action.SetTooltip              = function(self) return GameTooltip:SetAction(self._state_action) end
Action.GetSpellId              = function(self)
	local actionType, id, subType, globalID = GetActionInfo(self._state_action)
	if actionType == "spell" then
		return globalID
	elseif actionType == "macro" then
		return GetSpellIdByName(GetMacroSpell(id))
	end
end

-----------------------------------------------------------
--- Spell Button
Spell.HasAction               = function(self) return true end
Spell.GetActionText           = function(self) return "" end
Spell.GetTexture              = function(self) return GetSpellTexture(self._state_action) end
Spell.GetCount                = function(self) return GetSpellCount(self._state_action) end
Spell.GetCooldown             = function(self) return GetSpellCooldown(self._state_action) end
Spell.IsAttack                = function(self) return IsAttackSpell(FindSpellBookSlotBySpellID(self._state_action), "spell") end -- needs spell book id as of 4.0.1.13066
Spell.IsEquipped              = function(self) return nil end
Spell.IsCurrentlyActive       = function(self) return IsCurrentSpell(self._state_action) end
Spell.IsAutoRepeat            = function(self) return IsAutoRepeatSpell(FindSpellBookSlotBySpellID(self._state_action), "spell") end -- needs spell book id as of 4.0.1.13066
Spell.IsUsable                = function(self) return IsUsableSpell(self._state_action) end
Spell.IsConsumableOrStackable = function(self) return IsConsumableSpell(self._state_action) end
Spell.IsUnitInRange           = function(self, unit) return IsSpellInRange(FindSpellBookSlotBySpellID(self._state_action), "spell", unit) end -- needs spell book id as of 4.0.1.13066
Spell.SetTooltip              = function(self) return GameTooltip:SetSpellByID(self._state_action) end
Spell.GetSpellId              = function(self) return self._state_action end

-----------------------------------------------------------
--- Item Button
local function getItemId(input)
	return input:match("^item:(%d+)")
end

Item.HasAction               = function(self) return true end
Item.GetActionText           = function(self) return "" end
Item.GetTexture              = function(self) return GetItemIcon(self._state_action) end
Item.GetCount                = function(self) return GetItemCount(self._state_action, nil, true) end
Item.GetCooldown             = function(self) return GetItemCooldown(getItemId(self._state_action)) end
Item.IsAttack                = function(self) return nil end
Item.IsEquipped              = function(self) return IsEquippedItem(self._state_action) end
Item.IsCurrentlyActive       = function(self) return IsCurrentItem(self._state_action) end
Item.IsAutoRepeat            = function(self) return nil end
Item.IsUsable                = function(self) return IsUsableItem(self._state_action) end
Item.IsConsumableOrStackable = function(self) return IsConsumableItem(self._state_action) end
Item.IsUnitInRange           = function(self, unit) return IsItemInRange(self._state_action, unit) end
Item.SetTooltip              = function(self) return GameTooltip:SetHyperlink(self._state_action) end
Item.GetSpellId              = function(self) return nil end

-----------------------------------------------------------
--- Macro Button
-- TODO: map results of GetMacroSpell/GetMacroItem to proper results
Macro.HasAction               = function(self) return true end
Macro.GetActionText           = function(self) return (GetMacroInfo(self._state_action)) end
Macro.GetTexture              = function(self) return (select(2, GetMacroInfo(self._state_action))) end
Macro.GetCount                = function(self) return 0 end
Macro.GetCooldown             = function(self) return 0, 0, 0 end
Macro.IsAttack                = function(self) return nil end
Macro.IsEquipped              = function(self) return nil end
Macro.IsCurrentlyActive       = function(self) return nil end
Macro.IsAutoRepeat            = function(self) return nil end
Macro.IsUsable                = function(self) return nil end
Macro.IsConsumableOrStackable = function(self) return nil end
Macro.IsUnitInRange           = function(self, unit) return nil end
Macro.SetTooltip              = function(self) return nil end
Macro.GetSpellId              = function(self) return nil end

-----------------------------------------------------------
--- Custom Button
Custom.HasAction               = function(self) return true end
Custom.GetActionText           = function(self) return "" end
Custom.GetTexture              = function(self) return self._state_action.texture end
Custom.GetCount                = function(self) return 0 end
Custom.GetCooldown             = function(self) return 0, 0, 0 end
Custom.IsAttack                = function(self) return nil end
Custom.IsEquipped              = function(self) return nil end
Custom.IsCurrentlyActive       = function(self) return nil end
Custom.IsAutoRepeat            = function(self) return nil end
Custom.IsUsable                = function(self) return true end
Custom.IsConsumableOrStackable = function(self) return nil end
Custom.IsUnitInRange           = function(self, unit) return nil end
Custom.SetTooltip              = function(self) return GameTooltip:SetText(self._state_action.tooltip) end
Custom.GetSpellId              = function(self) return nil end
Custom.RunCustom               = function(self, unit, button) return self._state_action.func(self, unit, button) end

-----------------------------------------------------------
