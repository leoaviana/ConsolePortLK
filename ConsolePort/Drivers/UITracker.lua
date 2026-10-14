---------------------------------------------------------------
-- Widget tracking
---------------------------------------------------------------
-- Used to track and bind interface widgets to the controller.
-- Necessary since widgets might be created at a later time.

local widgetTrackers, IsFrameWidget = {}, function(frame) return (type(frame) == "table") and (type(frame[0]) == "userdata"); end 

local function CheckWidgetTrackers(self)
	if not InCombatLockdown() then
		for button, widget in pairs(widgetTrackers) do
			if IsFrameWidget(_G[widget]) then
				self:LoadInterfaceBinding(button, widget)
				widgetTrackers[button] = nil
			end
		end
		if not next(widgetTrackers) then
			self:RemoveUpdateSnippet(CheckWidgetTrackers)
		end
	end
end

function ConsolePort:AddWidgetTracker(button, action)
	widgetTrackers[button] = action
	self:AddUpdateSnippet(CheckWidgetTrackers)
end

---------------------------------------------------------------
-- Frame tracking
---------------------------------------------------------------
-- Used to track and bind addon frames to the UI cursor.
-- Necessary since all frames do not exist on ADDON_LOADED.
-- Automatically adds all special frames, i.e. closed with ESC.

local specialFrames, frameTrackers = {}, {}

local function CheckSpecialFrames(self)
	local frames = UISpecialFrames
	for i, frame in pairs(frames) do
		if not specialFrames[frame] then
			if self:AddFrame(frame) then
				specialFrames[frame] = true
			end
		end
	end
end

function ConsolePort:UpdateFrameTracker()
	CheckSpecialFrames(self)
	for frame in pairs(frameTrackers) do
		if self:AddFrame(frame) then
			frameTrackers[frame] = nil
		end
	end
end

function ConsolePort:AddFrameTracker(frame)
	if type(frame) == 'string' then frameTrackers[frame] = true end
end

function ConsolePort:IsFrameTracked(frame)
	if(frameTrackers[frame]) then
		return true
	end
end


---------------------------------------------------------------
-- Action button / action bar caching
---------------------------------------------------------------
-- Used to find action bars and action buttons from various
-- sources, to extend their hotkey functionality or cache them
-- on handlers for later manipulation.

local IGNORE_FRAMES = {}
local VALID_BUTTON_TYPE = {
	Button = true,
	CheckButton = true,
}

-- Helpers:
local function GetContainer(this)
	local visited = {}
	while this and not visited[this] do
		visited[this] = true
		local parent = this:GetParent()
		if not parent or parent == UIParent then return this end
		this = parent
	end
	return this
end

local function ValidateActionID(this)
	return this:IsProtected() and VALID_BUTTON_TYPE[this:GetObjectType()] and this:GetAttribute('action')
end

local function IsActionButton(this, action)
	return action and tonumber(action) and this:GetAttribute('type') == 'action'
end

-- Callbacks:
local function CacheActionButton(cache, this, action)
	cache[this] = action
	return false -- continue when found
end

local function CacheActionBar(cache, this, action)
	local container = GetContainer(this)
	cache[container] = container:GetName() or tostring(container)
	return true -- break when found
end

-- Scanner:
local function FindActionButtons(callback, cache, ...)
	-- Avoid recursive sibling varargs: large option panels can contain thousands
	-- of widgets, making the old traversal use quadratic memory and deep stacks.
	local pending, visited = {...}, {}
	while #pending > 0 do
		local this = pending[#pending]
		pending[#pending] = nil
		if IsFrameWidget(this) and not visited[this] and not IGNORE_FRAMES[this] then
			visited[this] = true
			local action = ValidateActionID(this)
			local stop = IsActionButton(this, action) and callback(cache, this, action)
			if not stop then
				local children = {this:GetChildren()}
				for i = 1, #children do pending[#pending + 1] = children[i] end
			end
		end
	end
	return cache
end

---------------------------------------------------------------
-- Get all buttons that look like action buttons
---------------------------------------------------------------
function ConsolePort:GetActionButtons(asTable, parent)
	local buttons = FindActionButtons(CacheActionButton, {}, parent or UIParent)
	if asTable then return buttons end
	return pairs(buttons)
end

---------------------------------------------------------------
-- Get all container frames that look like action bars
---------------------------------------------------------------
function ConsolePort:GetActionBars(asTable, parent)
	local bars = FindActionButtons(CacheActionBar, {}, parent or UIParent)
	if asTable then return bars end
	return pairs(bars)
end

function ConsolePort:SetIgnoreFrameForActionLookup(frame, enabled)
	IGNORE_FRAMES[frame] = enabled
end
