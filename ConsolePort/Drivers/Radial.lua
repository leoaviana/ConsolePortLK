---------------------------------------------------------------
-- Radial.lua: Handles radial input (left stick & movement)
---------------------------------------------------------------
local HANDLE, _, db = ConsolePortRadialHandler, ...
---------------------------------------------------------------
local DEFAULT_BINDINGS, LOCAL_BINDINGS = {
	UP    = {'W', 'UP'};
	DOWN  = {'S', 'DOWN'};
	LEFT  = {'A', 'LEFT'};
	RIGHT = {'D', 'RIGHT'};
}

local MOVEMENT = {
	DEFAULT = {
		UP    = 'MOVEFORWARD';
		DOWN  = 'MOVEBACKWARD';
		LEFT  = 'STRAFELEFT';
		RIGHT = 'STRAFERIGHT';
		HORZ  = 'CP_RADIAL_HORZ';
		VERT  = 'CP_RADIAL_VERT';
	};
	TWIRL = {
		UP    = 'MOVEFORWARD';
		DOWN  = 'MOVEBACKWARD';
		LEFT  = 'TURNLEFT';
		RIGHT = 'TURNRIGHT';
		HORZ  = 'CP_RADIAL_HORZ';
		VERT  = 'CP_RADIAL_VERT';
	};
}
---------------------------------------------------------------
local BIT = {
	-- Directions:
	UP    = 0x00000001; [0x00000001] = 'UP';
	DOWN  = 0x00000002; [0x00000002] = 'DOWN';
	LEFT  = 0x00000004; [0x00000004] = 'LEFT';
	RIGHT = 0x00000008; [0x00000008] = 'RIGHT';
	-- Axis dominant:
	HORZ  = 0x00000010; [0x00000010] = 'HORZ';
	VERT  = 0x00000020; [0x00000020] = 'VERT';
}
---------------------------------------------------------------
local RADIAL_TYPE_LARGE, RADIAL_TYPE_SMALL = 0x1, 0x2
---------------------------------------------------------------
-- Handling movement bindings setup
---------------------------------------------------------------
function HANDLE:SetMovementBindings()
	if not InCombatLockdown() then --assert(not InCombatLockdown(), 'Tried to set movement bindings in combat.')
		self:ClearOverrideBindings()
		local set, keys = self:GetLocalMovementBindings()
		local GetModifiers = ConsolePort.GetModifiers

		for direction, binding in pairs(set) do
			local keyset = keys[direction]
			if keyset then
				for i, key in pairs(keyset) do
					for modifier in GetModifiers() do
						self:SetOverrideBinding(false, modifier..key, binding)
					end
				end
			end
		end

		self:GenerateInputHandlers()
		self:Dispatch()
	end
end

function HANDLE:GetDefaultMovementBindings()
	local large = db('stickRadialType') == RADIAL_TYPE_LARGE
	DEFAULT_BINDINGS.HORZ = large and {db('stickRadialBindHorz')} or nil
	DEFAULT_BINDINGS.VERT = large and {db('stickRadialBindVert')} or nil
	return DEFAULT_BINDINGS
end

function HANDLE:GetLocalMovementBindings()
	local bindings = self:GetMovementBindings()
	if not db('stickRadialLocal') then
		return bindings, self:GetDefaultMovementBindings()
	end

	local inherited = self:CacheMovementBindings({})
	LOCAL_BINDINGS = {}
	for key, keyBit in pairs(inherited) do
		local dir = BIT[keyBit]
		local binding = bindings[dir]
		if binding then
			LOCAL_BINDINGS[dir] = LOCAL_BINDINGS[dir] or {}
			tinsert(LOCAL_BINDINGS[dir], key)
		end
	end
	return bindings, LOCAL_BINDINGS
end

function HANDLE:CacheMovementBindings(tbl)
	for _, set in pairs(MOVEMENT) do
		for idx, bind in pairs(set) do
			for i=1, select('#', GetBindingKey(bind)) do
				local key = select(i, GetBindingKey(bind))
				tbl[key] = BIT[idx]
			end
		end
	end
	return tbl
end

function HANDLE:GetCurrentMovementBindings() return LOCAL_BINDINGS or DEFAULT_BINDINGS end
function HANDLE:GetMovementBindings() return db('turnCharacter') and MOVEMENT.TWIRL or MOVEMENT.DEFAULT end

HANDLE.SetOverrideBinding = SetOverrideBinding
HANDLE.ClearOverrideBindings = ClearOverrideBindings
ConsolePort:RegisterCallback('OnNewBindings', HANDLE.SetMovementBindings, HANDLE)


---------------------------------------------------------------
-- Radial detection
---------------------------------------------------------------
local RADIAL_DETC_SMALL = bit.bor(BIT.UP, BIT.DOWN, BIT.LEFT, BIT.RIGHT)
local RADIAL_DETC_LARGE = bit.bor(RADIAL_DETC_SMALL, BIT.HORZ, BIT.VERT)
---------------------------------------------------------------
local RADIAL_DETC = {
	W = BIT.UP;    UP    = BIT.UP;
	S = BIT.DOWN;  DOWN  = BIT.DOWN; 
	A = BIT.LEFT;  LEFT  = BIT.LEFT;
	D = BIT.RIGHT; RIGHT = BIT.RIGHT;
	-----------------------------------
	H = BIT.HORZ; V = BIT.VERT;
}
---------------------------------------------------------------
function HANDLE:DetectType(input)
	assert(type(input) == 'table', 'Radial input data must be in table form.')
	local radialLocal = self:CacheBindsForRadialDetect()
	local bits, customDetected = 0x0
	for i, key in ipairs(input) do
		customDetected = radialLocal[key] and not RADIAL_DETC[key]
		bits = bit.bor(bits, radialLocal[key] or 0x0)
	end
	return self:GetTypeFromBits(bits), customDetected
end

function HANDLE:CacheBindsForRadialDetect()
	return self:CacheMovementBindings(db.table.copy(RADIAL_DETC))
end

function HANDLE:GetTypeFromBits(bits)
	return  bits == RADIAL_DETC_LARGE and RADIAL_TYPE_LARGE or
			bits == RADIAL_DETC_SMALL and RADIAL_TYPE_SMALL
end

function HANDLE:GetIndexSize()
	return self.size or 8
end

function HANDLE:GetStepSize()
	return self.step or 45
end

function HANDLE:SetTypeMultiplier(multiplier)
	if ( multiplier == 0x0 ) then return self:SetAttribute('locked', true) end
	self.step = 22.5 * multiplier
	self.size = 360 / self.step
	self:SetAttribute('locked', false)
	self:SetMovementBindings()
end

ConsolePort:RegisterVarCallback('stickRadialType', HANDLE.SetTypeMultiplier, HANDLE)

---------------------------------------------------------------
-- Radial environment (rings)
---------------------------------------------------------------
local ANGLE_IDX_ONE = 90;
local BITS_TO_ANGLE_SECURE = ([[
	-----------------------------------
	( $UP   + $LEFT  + $HORZ ) =  22.5;
	( $UP   + $LEFT  + $VERT ) =  67.5;
	( $UP   + $RIGHT + $VERT ) = 112.5;
	( $UP   + $RIGHT + $HORZ ) = 157.5;
	-----------------------------------
	( $DOWN + $RIGHT + $HORZ ) = 202.5;
	( $DOWN + $RIGHT + $VERT ) = 247.5;
	( $DOWN + $LEFT  + $VERT ) = 292.5;
	( $DOWN + $LEFT  + $HORZ ) = 337.5;
	-----------------------------------
	( $UP   + $LEFT  )         =  45.0;
	( $UP   + $RIGHT )         = 135.0;
	( $DOWN + $RIGHT )         = 225.0;
	( $DOWN + $LEFT  )         = 315.0;
	-----------------------------------
	( $LEFT  )                 =   0.0;
	( $UP    )                 =  90.0;
	( $RIGHT )                 = 180.0;
	( $DOWN  )                 = 270.0;
	-----------------------------------
]]) :gsub('%s+',' '):gsub('%-+', '')
	:gsub('%(','if'):gsub('%)','then'):gsub('%$', '')
	:gsub('%+', 'and'):gsub('%=', 'return'):gsub(';', ' end')
	:gsub('UP', "self:GetAttribute('KEYUP')"):gsub('DOWN', "self:GetAttribute('KEYDOWN')")
	:gsub('LEFT', "self:GetAttribute('KEYLEFT')"):gsub('RIGHT', "self:GetAttribute('KEYRIGHT')")
	:gsub('HORZ', "self:GetAttribute('KEYHORZ')"):gsub('VERT', "self:GetAttribute('KEYVERT')");

---------------------------------------------------------------

function HANDLE:GetAngleForIndex(index)
	return ((ANGLE_IDX_ONE + ((index - 1) * self:GetStepSize())) % 360)
end

function HANDLE:GetIndexForAngle(angle)
	local step, size = self:GetStepSize(), self:GetIndexSize()
	if (angle % step) > 0 then return end
	local index = (((angle % 360) / step) - (ANGLE_IDX_ONE / step) + 1)
	return (index < 0 and index + size) or (index > 0 and index) or (size)
end

function HANDLE:GetDirectionForKey(key)
	for direction, set in pairs(self:GetCurrentMovementBindings()) do
		for _, setkey in ipairs(set) do
			if (setkey == key) then
				return direction
			end
		end
	end
end

---------------------------------------------------------------
local ENV_RADIAL = {
	---------------------------------------------------------------
	['bits'] = BITS_TO_ANGLE_SECURE;
	['onkey'] = [[
		local key, down = ... 
		self:SetAttribute(tostring('KEY'..key), down and true or nil) 

		local newindex = control:RunFor(self, self:GetAttribute('bits'))
		local index = tostring(newindex)
		self:SetAttribute('index', index)
		--control:RunAttribute('_setindex', control:RunAttribute('_bits'))

		control:CallMethod('CallMethodFromFrame', self:GetName(), 'OnButtonFocused', index)

		local button = self:GetFrameRef(index)
		if button then
			self:SetBindingClick(true, 'BUTTON1', button, 'RightButton')
		else
			self:ClearBinding('BUTTON1')
		end
	]];
	---------------------------------------------------------------
	['_getsize'] = [[
		return self:GetAttribute('size') or 0
	]];
	---------------------------------------------------------------
	['_getindex'] = [[
		local index = self:GetAttribute('index')
		return tostring(index)
	]];
	---------------------------------------------------------------
	['_setindex'] = [[
		local index = ...
		local newindex = tostring(index)
		self:SetAttribute('index', newindex)
		return newindex
	]];
	---------------------------------------------------------------
	['_onstate-cursor'] = [[
		control:RunAttribute('_oncursor', newstate)
	]];
	---------------------------------------------------------------
	['_onstate-extrabar'] = [[
		control:RunAttribute('_onextrabar', newstate)
	]];
	---------------------------------------------------------------
	['_preclick'] = [[
		self:ClearBinding('BUTTON1')
		control:RunAttribute('_onuse', down)
		self:SetAttribute('type', nil) 
		 
		if not down then
			local button = self:GetFrameRef(control:RunAttribute('_getindex'))
			if button then
				local actionType = button:GetAttribute('type')
				local actionID   = actionType and button:GetAttribute(actionType)
				if actionID then
					self:SetAttribute('type', actionType)
					self:SetAttribute(actionType, actionID)
				end
			end
			control:RunAttribute('_setindex', nil)
		end
	]];
	---------------------------------------------------------------
	['_onuse'] = [[
		self:SetAttribute('toggled', ...)

		if self:GetAttribute('toggled') then
			control:RunFor(HANDLE, HANDLE:GetAttribute('hBind'), self:GetName())
			self:Show()
		else
			control:RunFor(HANDLE, HANDLE:GetAttribute('hClear'), self:GetName())
			self:Hide()
			control:RunAttribute('_oncursor', nil)
			wipe(BIT)
		end
	]];
	---------------------------------------------------------------
	['_oncursor'] = [[
		local hasItem = ...
		local hide = not hasItem and not self:GetAttribute('toggled')
		if hasItem or hide then
			if hasItem then
				self:Show()
			elseif hide then
				self:Hide()
			end

			for i=1, control:RunAttribute('_getsize') do
				local button = self:GetFrameRef(tostring(i))
				if button and not button:GetAttribute('type') then
					button:SetAlpha(0.5)
				end
			end
		end
	]];
	---------------------------------------------------------------
	['_ondoubleclick'] = [[
		control:RunAttribute('_onuse', true)
		control:RunAttribute('_oncursor', true)
	]];
	---------------------------------------------------------------
	['_driver-cursor'] = '[cursor] true; nil';
	['_driver-extrabar'] = '[extrabar] true; nil';
}

------------------------------
local INPUTS, FRAMES = {}, {}
------------------------------
HANDLE:SetAttribute('hBind', [[
	local frame = self:GetFrameRef(...) 
	if frame then
		for i=1, self:GetAttribute('inputs') do
			local input = self:GetFrameRef(tostring(i))
			local name = input:GetName()
			local key = input:GetAttribute('key')
			input:SetAttribute('ref', ...)

			input:SetBindingClick(true, key, name)
			input:SetBindingClick(true, 'CTRL-'..key, name)
			input:SetBindingClick(true, 'SHIFT-'..key, name)
			input:SetBindingClick(true, 'CTRL-SHIFT-'..key, name)
		end
	end
]])

HANDLE:SetAttribute('hClear', [[
	for i=1, self:GetAttribute('inputs') do
		local input = self:GetFrameRef(tostring(i))
		input:ClearBindings()
	end
]])

function HANDLE:Dispatch()
	for frame in pairs(FRAMES) do
		if frame.Refresh then frame:Refresh() end
	end
end

local function IsValidFrame(frame)
    return (type(frame) == "table") and (type(frame[0]) == "userdata");
end


function HANDLE:RegisterFrame(frame, id)
	assert(IsValidFrame(frame), 'Invalid frame registered on radial handler.')
	self:SetFrameRef(id or frame:GetName(), frame)
	frame:SetFrameRef('HANDLE', self)
	frame:Execute([[HANDLE = self:GetFrameRef('HANDLE'); BIT = newtable()]])
	FRAMES[frame] = true

	for script, body in pairs(ENV_RADIAL) do 
		frame:SetAttribute(script, body)
	end

	if frame.Refresh and not self:GetAttribute('locked') then
		frame:Refresh()
	end
end


local function ControlCallMethodInner(frame, methodName, ...)
    local method = frame[methodName];
    -- Ensure code isn't run securely
    forceinsecure();
    if (type(method) ~= "function") then
        error("Invalid method '" .. methodName .. "'");
        return;
    end
    method(frame, ...); 
end


function HANDLE:CreateInputHandler()
	local index = self:GetAttribute('inputs') + 1
	local input = INPUTS[index]
	if not input then
		input = CreateFrame('BUTTON', '$parentInput'..index, self, 'SecureHandlerClickTemplate')
		input:RegisterForClicks('LeftButtonDown', 'LeftButtonUp')

		input.CallMethodFromFrame = CPAPI.CallMethodFromFrame

		input:SetAttribute('_onclick', [[ control:RunFor(self:GetParent():GetFrameRef(self:GetAttribute('ref')), self:GetParent():GetFrameRef(self:GetAttribute('ref')):GetAttribute('onkey'), self:GetAttribute('bit'), down) ]])
		INPUTS[index] = input
	end
	self:SetFrameRef(tostring(index), input)
	self:SetAttribute('inputs', index)
	return input
end

function HANDLE:GenerateInputHandlers()
	self:SetAttribute('inputs', 0)
	local bindings = self:GetCurrentMovementBindings()
	for direction, keys in pairs(bindings) do
		for _, key in ipairs(keys) do
			local input = self:CreateInputHandler()
			input:SetAttribute('key', key)
			input:SetAttribute('bit', direction)
		end
	end
end