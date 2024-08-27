---------------------------------------------------------------
-- Utility.lua: Main radial action bar  
---------------------------------------------------------------
-- Creates an action bar that can be populated with
-- items, spells, mounts, macros, etc. The user may manually
-- assign items from container buttons inside bag frames.
-- Action buttons can grab info from cursor.

---------------------------------------------------------------
local addOn, db = ...
---------------------------------------------------------------
local ConsolePort = ConsolePort
---------------------------------------------------------------
local FadeIn, FadeOut = db.GetFaders()
local GetItemCooldown = GetItemCooldown
local InCombatLockdown = InCombatLockdown
---------------------------------------------------------------
local 	Utility, Tooltip, Animation, AniCircle = 
		ConsolePortUtilityToggle,
		ConsolePortUtilityToggle.Tooltip,
		CreateFrame('Frame', 'ConsolePortUtilityAnimation', UIParent),
		CreateFrame('Frame', 'ConsolePortUtilityAnimationCircle', UIParent)
---------------------------------------------------------------
local red, green, blue = db.Atlas.GetCC()
local colMul = 1 + ( 1 - (( red + green + blue ) / 3) )
---------------------------------------------------------------

function Animation:ShowNewAction(actionButton, autoassigned)
	-- if an item was auto-assigned, postpone its animation until the current animation has finished
	if  autoassigned and self.Group:IsPlaying() then
		local progress = self.Group:GetDuration() * self.Group:GetProgress()
		local delay = self.Group:GetDuration() - progress
		CPAPI.TimerAfter(delay, function() self:ShowNewAction(actionButton, true) end)
		return
	end
	if actionButton.isQuest then
		self.Quest:Show()
	else
		self.Quest:Hide()
	end
	local scale = Utility.frameScale or 1
	self.Icon:SetTexture(actionButton.Icon.texture)
	--self.Spell:SetSize(175, 175)
	self:ClearAllPoints()
	self:SetPoint('CENTER', actionButton)
	self:SetScale(scale)
	self:Show()
	self.Group:Stop()
	self.Group:Play()
	--FadeOut(self.Spell, 3, 0.15, 0)

	if ConsolePortUtility[actionButton:GetID()] then
		local value = ConsolePortUtility[actionButton:GetID()].value
		local binding = ConsolePort:GetFormattedBindingOwner('CLICK ConsolePortUtilityToggle:LeftButton', nil, nil, true)
		if value then
			local string = binding and ' '..binding or '.'
			if value and not tonumber(value) then
				db.Hint:DisplayMessage(format(db.TUTORIAL.HINTS.UTILITY_RING_NEWBIND, value, string), 3, -190)
			elseif binding then
				db.Hint:DisplayMessage(format(db.TUTORIAL.HINTS.UTILITY_RING_BIND, binding), 3, -190)
			end
		end
	end

	local angle = actionButton:GetAttribute('rotation')
	AniCircle:Show()
	AniCircle:SetScale(scale)
	AniCircle.Ring:SetRotation(angle)
	AniCircle.Arrow:SetRotation(angle)
	AniCircle.Runes:SetRotation(angle)
	FadeOut(AniCircle, 3, 1, 0)
end

local function AnimateOnFinished(self)
	AniCircle:Hide()
	self:GetParent():Hide()
end

-- called from secure scope (e.g. extra action button 1 appears)
function Utility:AnimateNew(button) Animation:ShowNewAction(_G[button], true) end


---------------------------------------------------------------
-- Add action to free actionbutton
---------------------------------------------------------------
local function AddAction(actionType, ID, autoassigned)
	ID = tonumber(ID) or ID
	local alreadyBound
	for id, ActionButton in pairs(Utility.Buttons) do
		alreadyBound = 	( ActionButton:GetAttribute('type') == actionType and
						( ActionButton:GetAttribute('cursorID') == ID or ActionButton:GetAttribute(actionType) == ID) ) and id
		if alreadyBound then
			break
		end
	end
	if alreadyBound and not autoassigned then
		Animation:ShowNewAction(Utility.Buttons[alreadyBound])
	elseif not alreadyBound then
		for _, ActionButton in ipairs(Utility.Buttons) do
			if not ActionButton:GetAttribute('type') then
				if actionType == 'item' then
					ActionButton:SetAttribute('cursorID', ID)
				end
				ActionButton:SetAttribute('autoassigned', autoassigned)
				ActionButton:SetAttribute('type', actionType)
				ActionButton:SetAttribute(actionType, ID)
				Animation:ShowNewAction(ActionButton, autoassigned)
				break
			end 
		end
	end
end


---------------------------------------------------------------
-- Manage auto-assigned items (quest items)
---------------------------------------------------------------
local function AddItemForQuestLogIndex(itemTbl, questLogIndex)
	if questLogIndex then
		local link = GetQuestLogSpecialItemInfo(questLogIndex)
		local name = link and GetItemInfo(link)
		if name then
			local _, itemID = strsplit(':', strmatch(link, 'item[%-?%d:]+'))
			if itemID then
				itemTbl[name] = itemID
			end
		end
	end
end

local function GetQuestWatchItems()
	local items = {}
	for i=1, CPAPI:GetNumQuestWatches() do
		AddItemForQuestLogIndex(items, GetQuestIndexForWatch(i))
	end
	return items
end

local function GetAutoAssignedItems()
	local items = {}
	for _, button in ipairs(Utility.Buttons) do
		local itemID = button:GetAutoAssigned()
		if itemID then
			items[itemID] = button
		end
	end
	return items
end

local function UpdateQuestItems(self)
	if not InCombatLockdown() then

		local oldItems = GetAutoAssignedItems()
		local newItems = GetQuestWatchItems()

		-- prune items that are not in the new set.
		for currItem, button in pairs(oldItems) do
			if not newItems[currItem] then
				button:SetAttribute('type', nil)
				button:SetAttribute('item', nil)
			end
		end

		-- add new items that are not already autoassigned.
		for newItemName, newItemID in pairs(newItems) do
			if not oldItems[newItemName] then
				AddAction('item', newItemID, true)
			end
		end

		self:RemoveUpdateSnippet(UpdateQuestItems)
	end
end


---------------------------------------------------------------
-- Tooltip 
---------------------------------------------------------------
function Tooltip:Refresh()
	if self.castButton then
		self:AddLine(self.castInfo:format(db.TEXTURE[self.castButton]))
	end
	self:AddLine(self.removeInfo:format(db.TEXTURE.CP_T_L3))
end

function Tooltip:OnShow()
	self.castButton = ConsolePort:GetCurrentBindingOwner('CLICK ConsolePortUtilityToggle:LeftButton')
	-- set CC backdrop
	self:SetBackdropColor(red*0.15, green*0.15, blue*0.15,  0.75)
	self:Refresh()
	FadeIn(self, 0.2, 0, 1)
end





---------------------------------------------------------------
-- Radial action button handler
---------------------------------------------------------------
-- Manages radial action buttons. These action buttons behave
-- similarly to normal action buttons, but abstracts frontend
-- so that RABs don't need to handle state updates.
-- Callbacks:
--     OnContentChanged()
--     OnContentRemoved()
---------------------------------------------------------------
ConsolePortRingButtonMixin = {}
---------------------------------------------------------------
local DROP_TYPES = {
	item = true,
	spell = true,
	macro = true,
	mount = true,
}

local TEXTURE_GETS = {
	----------------------------------
	item   = function(id) if id then return select(10, GetItemInfo(id)), select(12, GetItemInfo(id)) == 12 end end;
	spell  = function(id) if id then return select(3, GetSpellInfo(id)), nil end end;
	macro  = function(id) if id then return select(2, GetMacroInfo(id)), nil end end;
	action = function(id) if id then return GetActionTexture(id) end end;
	----------------------------------
	none = function(id) return end;
} setmetatable(TEXTURE_GETS,{__index = function(t) return t.none end})

local TRANSLATE_CURSOR_INFO = {
	----------------------------------
	item = function(self, id)
		if tonumber(id) then
			self:SetAttribute('item', GetItemInfo(id))
			return true
		end
	end;
	--companion = function(self, id)
	--	local _, _, petSpellID = GetCompanionInfo(detail)
	--	local petName = GetSpellInfo(petSpellID)
	--	self:SetAttribute("mountID", petSpellID)
	--	self:SetAttribute("type", "spell")
	--	self:SetAttribute("spell", petName)
	--	return true
	--end;
	----------------------------------
	none = function(id) return end;
} setmetatable(TRANSLATE_CURSOR_INFO,{__index = function(t) return t.none end})
---------------------------------------------------------------

----------------------------------
-- Script handlers
----------------------------------
function ConsolePortRingButtonMixin:OnLoad()
	local border = self.Border
	self.Highlight = border.Highlight
	self.Quest = border.Quest
	self.Pushed:SetParent(border)
	self.Pushed:SetDrawLayer('OVERLAY', 5)
	self.NormalTexture:SetParent(border)
	self.NormalTexture:SetDrawLayer('OVERLAY', 4)

	self.Tooltip = self:GetParent().Tooltip
	self.FadeIn, self.FadeOut = ConsolePort:GetData().GetFaders()
end

function ConsolePortRingButtonMixin:OnEnter()
	self:SetFocus(true)
	--self.FadeIn(self.Pushed, 0.1, self.Pushed:GetAlpha(), 1)
	--self.FadeIn(self.Highlight, 0.1, self.Highlight:GetAlpha(), 1)
	--self.FadeOut(self.NormalTexture, 0.1, self.NormalTexture:GetAlpha(), 1)
	--self.FadeOut(self.Quest, 0.1, self.Quest:GetAlpha(), 0)
end

function ConsolePortRingButtonMixin:OnLeave()
	self:SetFocus(false)
	--self.FadeOut(self.Pushed, 0.2, self.Pushed:GetAlpha(), 0)
	--self.FadeOut(self.Highlight, 0.2, self.Highlight:GetAlpha(), 0)
	--self.FadeIn(self.NormalTexture, 0.2, self.NormalTexture:GetAlpha(), 0.75)
	--self.FadeIn(self.Quest, 0.2, self.Quest:GetAlpha(), 1)
end

function ConsolePortRingButtonMixin:PreClick(button)
	if not InCombatLockdown() then
		if button == 'RightButton' then
			self:SetAttribute('type', nil)
			self.Cooldown:SetCooldown(0, 0)
			self.Count:SetText()
			ClearCursor()
		elseif DROP_TYPES[GetCursorInfo()] then
			self:SetAttribute('type', nil)
		end
	end
end

function ConsolePortRingButtonMixin:PostClick(button)
	if DROP_TYPES[GetCursorInfo()] then
		local cursorType, id,  _, spellID = GetCursorInfo()
		ClearCursor()

		if InCombatLockdown() then return end

		local newValue
		-- Convert spellID to name
		if cursorType == "spell" then
			local spellName, subSpellName = GetSpellName(id, SpellBookFrame.bookType);
			local link = GetSpellLink(spellName, subSpellName);  
			newValue = select(3, strfind(link, "spell:(%d+)")) 
		elseif cursorType == "companion" then
			local _, _, petSpellID = GetCompanionInfo(rwdt, id)  
			newValue = GetSpellInfo(petSpellID)
			self:SetAttribute("mountID", petSpellID)
			cursorType = "spell"
		end

		self:SetAttribute('type', cursorType)
		self:SetAttribute('cursorID', id)
		self:SetAttribute(cursorType, newValue or id)
	end
end


function ConsolePortRingButtonMixin:OnAttributeChanged(attribute, detail)
	-- omit on autoassigned and statehidden
	if (attribute == 'autoassigned' or attribute == 'statehidden' or attribute == 'unit') then return end
	if detail then
		-- omit on item/mount added, because they need translation first.
		if TRANSLATE_CURSOR_INFO[attribute](self, detail) then return end
		ClearCursor()
	end

	-- update the icon texture
	self:UpdateTexture()
	
	-- run callback if this button has content
	local actionType = self:GetAttribute('type')
	if actionType then
		self:OnContentChanged(actionType)
	else
		self:SetAttribute('autoassigned', nil)
		self:OnContentRemoved()
	end
end

function ConsolePortRingButtonMixin:OnTooltipUpdate(elapsed)
	self.idle = self.idle + elapsed
	if self.idle > 1 then
		local action = self:GetAttribute('type')
		if action == 'item' then
			self.Tooltip:SetOwner(self, 'ANCHOR_BOTTOM', 0, -16)
			local _, itemlink = GetItemInfo(self:GetAttribute('cursorID'))
			self.Tooltip:SetHyperlink(itemlink)
		elseif action == 'spell' then
			local id = self:GetAttribute("spell") 
			if id then
				Tooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -16) 
				if(not self:GetAttribute("mountID")) then
					local link = GetSpellLink(id)
					Tooltip:SetHyperlink(link)
				else 
					Tooltip:SetHyperlink(string.format("|cff71d5ff|Hspell:%d|h[%s]|h|r", self:GetAttribute("mountID"), id))
				end
			end
		end
		self:SetScript('OnUpdate', nil)
	end
end

----------------------------------
-- Tooltip
----------------------------------

function ConsolePortRingButtonMixin:SetFocus(enabled)
	if self.Tooltip then
		if enabled then
			self.idle = 0
			self:SetScript('OnUpdate', self.OnTooltipUpdate)
		else
			if self.Tooltip:IsOwned(self) then
				self.Tooltip:Hide()
			end
			self:SetScript('OnUpdate', nil)
		end
	end
end

----------------------------------
-- Button data
----------------------------------

function ConsolePortRingButtonMixin:SetCooldown(time, cooldown, enable)
	if time and cooldown then
		self.onCooldown = true
		self.Cooldown:SetCooldown(time, cooldown, enable)
	else
		self.onCooldown = false
		self.Cooldown:SetCooldown(0, 0)
	end
end

function ConsolePortRingButtonMixin:SetCharges(charges) 
	self.Count:SetText(charges)
end

function ConsolePortRingButtonMixin:SetUsable(isUsable)
	local vxc = isUsable and 1 or 0.5
	self.Icon:SetVertexColor(vxc, vxc, vxc)
end

function ConsolePortRingButtonMixin:UpdateState()
	local action = self:GetAttribute('type')
	self:UpdateTexture(action) 

	if action == 'item' then
		local item = self:GetAttribute('item')
		if item then
			local count = GetItemCount(item)
			local _, _, maxStack = select(6, GetItemInfo(item))
			self:SetCooldown(GetItemCooldown(self:GetAttribute('cursorID')))
			self:SetUsable(IsUsableItem(item))
			self:SetCharges(maxStack and maxStack > 1 and (count or 0))
		end
	elseif action == 'spell' then
		local spellID = self:GetAttribute('spell')
		if spellID then
			local spellName = GetSpellInfo(spellID)
			if(IsConsumableSpell(spellName)) then
				self:SetCharges(GetSpellCount(spellName))
			end
			self:SetUsable(IsUsableSpell(spellName))
			self:SetCooldown(GetSpellCooldown(spellID))
		end
	elseif action == 'action' then
		local actionID = self:GetAttribute('action')
		if actionID then
			self:SetUsable(IsUsableAction(actionID))
			self:SetCooldown(GetActionCooldown(actionID))
		end
	end
end

function ConsolePortRingButtonMixin:GetAutoAssigned()
	return self:GetAttribute('item') and self:GetAttribute('autoassigned')
end

----------------------------------
-- Icon and quest icon
----------------------------------
function ConsolePortRingButtonMixin:SetTexture(actionType, actionValue)
	local texture, isQuest = TEXTURE_GETS[actionType](actionValue)
	if texture then
		self.Icon.texture = texture
		self.Icon:SetTexture(texture)		
		SetPortraitToTexture(self.Icon, texture)
		self:SetAlpha(1)
		self.Icon:SetVertexColor(1, 1, 1)
	else
		self.Icon.texture = nil
		self.Icon:SetTexture(nil)
		self:SetAlpha(0.5)
	end
	self.isQuest = isQuest
	if(self.Quest) then
		CPAPI.SetShown(self.Quest, isQuest)
	end
end

function ConsolePortRingButtonMixin:UpdateTexture(action, val)
	action = action or self:GetAttribute('type')
	val = val or (action and self:GetAttribute(action))
	self:SetTexture(action, val)
end



---------------------------------------------------------------
-- Ring maangement 
---------------------------------------------------------------

function Utility:Initialize(ctype, ctemplate, cmixin)
	if self:GetAttribute('initialized') then return end
	----------------------------------
	self.cmixin = cmixin;
	self.ctype  = ctype or 'Button';
	self.ctemplate = ctemplate or 'ConsolePortRingButtonTemplate';
	----------------------------------
	self.HANDLE = ConsolePortRadialHandler
	self.HANDLE:RegisterFrame(self)
	----------------------------------
	self:WrapScript(self, 'PreClick', self:GetAttribute('_preclick'))
	self:WrapScript(self, 'OnDoubleClick', self:GetAttribute('_ondoubleclick'))
	----------------------------------
	self:SetAttribute('initialized', true)
end

function Utility:Disable()
	if not self:GetAttribute('initialized') then return end
	----------------------------------
	self:UnwrapScript(self, 'PreClick')
	self:UnwrapScript(self, 'OnDoubleClick')
	----------------------------------
	self:SetAttribute('initialized', false)
end

function Utility:Refresh()
	local size = self.HANDLE:GetIndexSize()
	self:SetAttribute('size', size)
	self:SetAttribute('fraction', rad(360 / size))

	self.Buttons = self.Buttons or {}
	self:Recall()
	self:Draw(size)

	self:OnRefresh(size)
end

----------------------------------
-- Button loops
----------------------------------
function Utility:Recall()
	for i, button in ipairs(self.Buttons) do
		button:ClearAllPoints()
		button:Hide()
	end
end

function Utility:Draw(numButtons)
	for i=1, numButtons do
		self:SpawnButtonAtIndex(i)
	end
end

function Utility:ClearFocus()
	for i, button in ipairs(self.Buttons) do
		button:OnLeave()
	end
end

----------------------------------
-- Button spawns
----------------------------------
local CENTER_OFFSET = 180

function Utility:GetFraction()
	return self:GetAttribute('fraction')
end

function Utility:GetButtonFromAngle(angle)
	return self:GetAttribute(angle)
end

function Utility:SpawnButtonAtIndex(i)
	local angle  =  self.HANDLE:GetAngleForIndex(i)
	local rotate =  (i - 1) * self:GetFraction()
	local button =  self:GetButtonFromAngle(angle) or
					CreateFrame(self.ctype, '$parent'..self.ctype..i, self, self.ctemplate)

	
	if(not button.ismxin) then
		CPAPI.Mixin(button, ConsolePortRingButtonMixin)
		button.ismxin = true
	end

	button:SetPoint('CENTER', -(CENTER_OFFSET * cos(angle)), CENTER_OFFSET * sin(angle))
	button:SetAttribute('rotation', -rotate)
	button:SetAttribute('angle', angle)
	button:SetID(i)
	button:Show()

	self.Buttons[i] = button
	self:SetAttribute(angle, button)
	self:SetFrameRef(tostring(i), button)
	self:SetFrameRef(tostring(angle), button)
	self:OnNewButton(button, i, angle, rotate)
		 
	button:SetScript("OnLoad", button.OnLoad)
	button:OnLoad()
	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)
	button:SetScript("PreClick", button.PreClick)
	button:SetScript("PostClick", button.PostClick)
	button:SetScript("OnAttributeChanged", button.OnAttributeChanged)
end

----------------------------------
-- State drivers
----------------------------------
function Utility:SetCursorDrop(enabled)
	local call = enabled and RegisterStateDriver or UnregisterStateDriver
	--call(self, 'cursor', self:GetAttribute('_driver-cursor'))
end

function Utility:SetExtraButtonDrop(enabled)
	local call = enabled and RegisterStateDriver or UnregisterStateDriver
	--call(self, 'extrabar', self:GetAttribute('_driver-extrabar'))
end

----------------------------------
-- Rotation handler
----------------------------------
local abs = math.abs

function Utility:SetRotation(value)
	if not value then return end
	self:OnNewRotation(value)
end

function Utility:SetNewRotationValue(anglenew)
	self.anglenew = anglenew
	if self.anglecur then
		local diff = abs(anglenew) - abs(self.anglecur)
		-- Case: lap reset, causing rotation in wrong direction in upperleft quadrant
		-- Solution: reverse delta and rotate in from a negative value
		if abs(diff) > 1 then
			self.anglecur = anglenew - ((diff > 0 and 1 or -1) * self:GetAttribute('fraction'))
		end
		return true -- if rotation is required
	end
	self.anglecur = anglenew
	self:SetRotation(anglenew)
end


function Utility:OnEvent(event, ...) 
	if (event == 'QUEST_ACCEPTED' or 
		event == 'QUEST_POI_UPDATE' or 
		event == 'QUEST_WATCH_LIST_CHANGED') and self.autoExtra then
		ConsolePort:RunOOC(UpdateQuestItems)
	end
	for _, ActionButton in ipairs(self.Buttons) do
		ActionButton:UpdateState()
	end
end


function Utility:OnButtonFocused(index)
	local button = self:GetAttribute(index)
	local focused = self.oldID and self:GetAttribute(self.oldID)
	if  focused then
		focused:OnLeave()
	end
	if 	button and button:IsVisible() then
		button:OnEnter()

		if self:SetNewRotationValue(button:GetAttribute('rotation')) then
			FadeOut(self.Spell, 1, self.Spell:GetAlpha(), 0)
		else
			FadeIn(self.Spell, 0.2, self.Spell:GetAlpha(), 0.15)
		end

		if button:GetAttribute('type') then
			FadeIn(self.Runes, 3, self.Runes:GetAlpha(), 1)
			FadeIn(self.Ring, 0.2, self.Ring:GetAlpha(), 1)
		else
			FadeOut(self.Ring, 0.5, self.Ring:GetAlpha(), 0)
			FadeOut(self.Runes, 0.5, self.Runes:GetAlpha(), 0)
		end

		self.Gradient:Show()
		self.Gradient:ClearAllPoints()
		self.Gradient:SetPoint('CENTER', button, 'CENTER', 0, 0)
		FadeIn(self.Gradient, 0.2, self.Gradient:GetAlpha(), 1)
		FadeIn(self.Arrow, 0.2, self.Arrow:GetAlpha(), 1)

		self.Spell:Show()
		self.Spell:ClearAllPoints()
		self.Spell:SetPoint('CENTER', button, 0, 0)
	else
		FadeOut(self.Runes, 0.2, self.Runes:GetAlpha(), 0)
		FadeOut(self.Arrow, 0.2, self.Arrow:GetAlpha(), 0)
		FadeOut(self.Ring, 0.1, self.Ring:GetAlpha(), 0)

		self.anglenew = nil
		self.anglecur = nil

		self.Gradient:SetAlpha(0)
		self.Gradient:ClearAllPoints()
		self.Gradient:Hide()

		self.Spell:ClearAllPoints()
		self.Spell:Hide()
	end
	self.oldID = index
end

function Utility:DisplayHints(elapsed)
	self.hintTimer = self.hintTimer + elapsed
	if self.hintTimer > 5 then
		local binding = ConsolePort:GetFormattedBindingOwner('CLICK ConsolePortUtilityToggle:LeftButton', nil, nil, true)
		if binding then
			if self:GetAttribute('toggled') then
				db.Hint:DisplayMessage(format(db.TUTORIAL.HINTS.UTILITY_RING_DOUBLE, binding), 4, -190)
			else
				db.Hint:DisplayMessage(format(db.TUTORIAL.HINTS.UTILITY_RING_BIND, binding), 4, -190)
			end
		else
			db.Hint:DisplayMessage(db.CUSTOMBINDS.CP_UTILITYBELT)
		end
		self.hasHints = nil
	end
end

local ANI_SPEED, ANI_SMOOTH, ANI_INF = 1.5, 1.4, 0.005

function Utility:OnUpdateDisplay(elapsed)
	-- flatten and update rotation angle
	local new, cur = self.anglenew, self.anglecur
	if cur ~= new then
		local dist = new - cur
		local flat = abs(dist / ANI_SPEED) ^ ANI_SMOOTH
		local diff = cur + (dist < 0 and -flat or flat)
		----------------------------------
		self.anglecur = abs(abs(diff)-abs(new)) < ANI_INF and new or diff
		----------------------------------
	end
	self:SetRotation(self.anglecur)

	if self.hasHints then
		self:DisplayHints(elapsed)
	end
end

function Utility:OnShow()
	self.anglecur = nil
	self.anglenew = nil
	Animation:Hide()
	AniCircle:Hide()
	--self.Spell:SetSize(175, 175)
	FadeOut(self.Ring, 0, 0, 0)
	FadeOut(self.Arrow, 0, 0, 0)
	FadeOut(self.Runes, 0, 0, 0)
	self.hintTimer = 0
	self.hasHints = true
end

function Utility:OnHide()
	self:ClearFocus()
	self.anglecur = nil
	self.anglenew = nil
	self.Gradient:SetAlpha(0)
	self.Gradient:ClearAllPoints()
	self.Gradient:Hide()
--	self.Spell:Hide()
end

Utility:SetAttribute('_onextrabar', [[
	local extraID = 169
	local size = control:RunAttribute('_getsize')
	if newstate then
		for i=1, size do
			local button = self:GetFrameRef(tostring(i))
			if 	button:GetAttribute('type') == 'action' and button:GetAttribute('action') == extraID then
				control:CallMethod('AnimateNew', button:GetName())
				return
			end
		end
		for i=1, size do
			local button = self:GetFrameRef(tostring(i))
			if 	not button:GetAttribute('type') then
				button:SetAlpha(1)
				button:SetAttribute('type', 'action')
				button:SetAttribute('action', extraID)
				control:CallMethod('AnimateNew', button:GetName())
				return
			end
		end
	else
		for i=1, size do
			local button = self:GetFrameRef(tostring(i))
			if 	button:GetAttribute('type') == 'action' and button:GetAttribute('action') == extraID then
				button:SetAlpha(0.5)
				button:SetAttribute('type', nil)
				button:SetAttribute('action', nil)
			end
		end
	end
]])

---------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------
local function OnButtonContentChanged(self, actionType)
	ConsolePortUtility[self:GetID()] = {
		action = actionType;
		value = self:GetAttribute(actionType);
		cursorID = self:GetAttribute('cursorID');
		mountID = self:GetAttribute('mountID');
		autoassigned = self:GetAttribute('autoassigned');
	} 
	self:UpdateState()
end

local function OnButtonContentRemoved(self)
	ConsolePortUtility[self:GetID()] = nil
end


function Utility:OnNewButton(button, index, angle, rotation)
	--button.Cooldown:SetSwipeColor(db.Atlas.GetNormalizedCC())
	button.Pushed:SetVertexColor(red, green, blue, 1)

	button.OnContentChanged = OnButtonContentChanged
	button.OnContentRemoved = OnButtonContentRemoved
	self:SetAttribute(tostring(angle), button)
end

function Utility:OnNewRotation(value)
	self.Ring:SetRotation(value)
	self.Arrow:SetRotation(value)
	self.Runes:SetRotation(value)
end

function Utility:OnRefresh(size)
	for index, info in pairs(ConsolePortUtility) do
		local actionButton = self.Buttons[index]
		if actionButton and info.action then
			actionButton:SetAttribute('autoassigned', info.autoassigned)
			actionButton:SetAttribute('type', info.action)
			actionButton:SetAttribute('cursorID', info.cursorID)
			actionButton:SetAttribute("mountID", info.mountID)
			actionButton:SetAttribute(info.action, info.value)
			actionButton:Show()
		end
	end

	self.autoExtra = db.Settings.autoExtra
	self.frameScale = db.Settings.utilityRingScale or 1
	self:SetScale(self.frameScale)

	self.Runes:SetSize(448 + (8 * size), 448 + (8 * size))
	self.Full:SetTexture([[Interface\AddOns\ConsolePort\Textures\Utility\UtilityGlow]]..size)

	if self.autoExtra then
		ConsolePort:RunOOC(UpdateQuestItems)
	end

	self:SetCursorDrop(true)
	self:SetExtraButtonDrop(self.autoExtra)
	
	for _, event in pairs({
		'ACTIONBAR_UPDATE_COOLDOWN',
		'ACTIONBAR_UPDATE_STATE',
		'ACTIONBAR_UPDATE_USABLE',
		'BAG_UPDATE',
		'BAG_UPDATE_COOLDOWN',
		'QUEST_ACCEPTED',
		'QUEST_POI_UPDATE',
		'QUEST_WATCH_LIST_CHANGED',
		'SPELL_UPDATE_COOLDOWN',
		'SPELL_UPDATE_CHARGES',
		'SPELL_UPDATE_USABLE',
	}) do pcall(self.RegisterEvent, self, event) end
end


---------------------------------------------------------------
function ConsolePort:AddUtilityAction(actionType, value)
	if actionType and value then
		AddAction(actionType, value)
	end
end

function ConsolePort:SetupUtilityRing()
	if not InCombatLockdown() and Utility:GetAttribute("initialized") ~= true then 
		Utility:UnregisterAllEvents()
		Utility:Initialize()
		self:RemoveUpdateSnippet(self.SetupUtilityRing) 
	end
end



---------------------------------------------------------------

Utility.Gradient:SetVertexColor(red * colMul, green * colMul, blue * colMul)
Utility.Full:SetVertexColor(red * 1.5, green * 1.5, blue * 1.5)
Utility.Ring:SetVertexColor(red * colMul, green * colMul, blue * colMul)
Utility.Arrow:SetVertexColor(red * 1.25, green * 1.25, blue * 1.25)
---------------------------------------------------------------
Utility:HookScript('OnHide', Utility.OnHide)
Utility:HookScript('OnShow', Utility.OnShow)
Utility:HookScript('OnEvent', Utility.OnEvent)
Utility:HookScript('OnUpdate', Utility.OnUpdateDisplay)
---------------------------------------------------------------


---------------------------------------------------------------
Animation:SetSize(64, 64)
Animation:SetFrameStrata('TOOLTIP')
Animation.Group = Animation:CreateAnimationGroup()
---------------------------------------------------------------
Animation.Icon = Animation:CreateTexture(nil, 'ARTWORK')
Animation.Quest = Animation:CreateTexture(nil, 'OVERLAY')
Animation.Border = Animation:CreateTexture(nil, 'OVERLAY')
Animation.Scale = Animation.Group:CreateAnimation('Scale')
Animation.Fade = Animation.Group:CreateAnimation('Alpha')
---------------------------------------------------------------
--Animation.Scale:SetToScale(1, 1)
--Animation.Scale:SetFromScale(2, 2)
Animation.Scale:SetDuration(0.5)
Animation.Scale:SetSmoothing('IN')
--Animation.Fade:SetFromAlpha(1)
--Animation.Fade:SetToAlpha(0)
Animation.Fade:SetSmoothing('OUT')
Animation.Fade:SetStartDelay(3)
Animation.Fade:SetDuration(0.2)
---------------------------------------------------------------
Animation.Border:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Button\\Normal')
Animation.Border:SetAlpha(1)
Animation.Border:SetAllPoints(Animation)
---------------------------------------------------------------
Animation.Icon:SetSize(64, 64)
Animation.Icon:SetPoint('CENTER', 0, 0)
--Animation.Icon:SetMask('Interface\\AddOns\\ConsolePort\\Textures\\Button\\Mask')
---------------------------------------------------------------
Animation.Quest:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\QuestButton')
Animation.Quest:SetPoint('CENTER', 0, 0)
Animation.Quest:SetSize(64, 64)
---------------------------------------------------------------
Animation.Gradient = Animation:CreateTexture(nil, 'BACKGROUND')
Animation.Gradient:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Window\\Circle')
Animation.Gradient:SetBlendMode('ADD')
Animation.Gradient:SetVertexColor(red, green, blue, 1)
Animation.Gradient:SetPoint('CENTER', 0, 0)
Animation.Gradient:SetSize(512, 512)	
---------------------------------------------------------------
Animation.Shadow = Animation:CreateTexture(nil, 'BACKGROUND')
Animation.Shadow:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Button\\NormalShadow')
Animation.Shadow:SetSize(82, 82)
Animation.Shadow:SetPoint('CENTER', 0, -6)
Animation.Shadow:SetAlpha(0.75)
---------------------------------------------------------------
Animation.Spell = CreateFrame('PlayerModel', nil, Animation)
Animation.Spell:SetFrameStrata('TOOLTIP')
Animation.Spell:SetPoint('CENTER', Animation.Icon, 'CENTER', -4, 0)
Animation.Spell:SetSize(176, 176)
Animation.Spell:SetAlpha(0)
--Animation.Spell:SetDisplayInfo(66673) --(42486)
--Animation.Spell:SetCamDistanceScale(2)
Animation.Spell:SetFrameLevel(1)
---------------------------------------------------------------
Animation.Group:SetScript('OnFinished', AnimateOnFinished)
---------------------------------------------------------------
AniCircle:SetPoint('CENTER', 0, 0)
AniCircle:SetSize(512, 512)
AniCircle:Hide()
---------------------------------------------------------------

---------------------------------------------------------------
AniCircle.Ring = AniCircle:CreateTexture(nil, 'OVERLAY', nil, 2)
AniCircle.Ring:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Utility\\UtilityCircle')
AniCircle.Ring:SetVertexColor(red * colMul, green * colMul, blue * colMul)
AniCircle.Ring:SetPoint('CENTER', 0, 0)
AniCircle.Ring:SetSize(512, 512)
--AniCircle.Ring:SetAlpha(0)
AniCircle.Ring:SetRotation(0)
AniCircle.Ring:SetBlendMode('ADD')
---------------------------------------------------------------
AniCircle.Arrow = AniCircle:CreateTexture(nil, 'OVERLAY')
AniCircle.Arrow:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Utility\\UtilityArrow')
AniCircle.Arrow:SetVertexColor(red * 1.25, green * 1.25, blue * 1.25)
AniCircle.Arrow:SetPoint('CENTER', 0, 0)
AniCircle.Arrow:SetSize(512, 512)
--AniCircle.Arrow:SetAlpha(0)
AniCircle.Arrow:SetRotation(0)
---------------------------------------------------------------
AniCircle.Runes = AniCircle:CreateTexture(nil, 'OVERLAY')
AniCircle.Runes:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Utility\\UtilityRunes')
AniCircle.Runes:SetPoint('CENTER', 0, 0)
AniCircle.Runes:SetSize(512, 512)
--AniCircle.Runes:SetAlpha(0)
AniCircle.Runes:SetRotation(0)
---------------------------------------------------------------

---------------------------------------------------------------
Tooltip:SetScript('OnShow', Tooltip.OnShow)
Tooltip.castInfo = db.TOOLTIP.UTILITY_RELEASE
Tooltip.removeInfo = db.TOOLTIP.UTILITY_REMOVE
---------------------------------------------------------------