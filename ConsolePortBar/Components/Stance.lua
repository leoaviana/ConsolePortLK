---------------------------------------------------------------
local db = ConsolePort:GetData()
---------------------------------------------------------------
local addOn, ab = ...
---------------------------------------------------------------
local FadeIn = db.UIFrameFadeIn
---------------------------------------------------------------
local Bar = ab.bar
local Lib = ab.libs.button
---------------------------------------------------------------
local Stance = CreateFrame('Button', '$parentStance', Bar, 'SecureActionButtonTemplate, SecureHandlerBaseTemplate, SecureHandlerStateTemplate')
local Button = {}

local BUTTON_SIZE = 40
 
local GameTooltip = GameTooltip 

local STANCE_COUNT

local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop

Bar.Stance = Stance
Stance:Hide()
Stance.Buttons = {}
Stance.showgrid = 0
Stance.locked = 0
Stance.mode = 'show'
Stance:SetMovable(true)
Stance:SetClampedToScreen(true)
Stance:RegisterForDrag('LeftButton')
Stance:SetScript('OnDragStart', Stance.StartMoving)
Stance:SetScript('OnDragStop', Stance.StopMovingOrSizing)
Stance:SetPoint('TOPRIGHT', 0, 50)
Stance:SetSize(64, 64)

for _, event in pairs({
	'PLAYER_ENTERING_WORLD',
	'UPDATE_SHAPESHIFT_FORM', 
    'UPDATE_SHAPESHIFT_FORMS', 
    'SPELL_UPDATE_COOLDOWN',
}) do Stance:RegisterEvent(event) end

Stance:RegisterForClicks('AnyUp', 'AnyDown') 

Stance.Portrait = Stance:CreateTexture(nil, 'ARTWORK')
Stance.Shadow = Stance:CreateTexture(nil, 'ARTWORK')
Stance.Border = Stance:CreateTexture(nil, 'OVERLAY')

Stance.Portrait:SetAllPoints()
Stance.Border:SetAllPoints()
Stance.Shadow:SetPoint('CENTER', 0, -5)

Stance.Border:SetTexture('Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\BigNormal') 
Stance.Shadow:SetSize(82, 82)
Stance.Shadow:SetTexture('Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\BigShadow')
Stance.Shadow:SetAlpha(0.75) 

function Button:OnEnter()
	if ( not self.tooltipName ) then
		return
	end
	local uber = GetCVar('UberTooltips')
	if ( uber == '0' ) then
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		local bindingText = GetBindingText(GetBindingKey('SHAPESHIFTBUTTON'..self:GetID()))
		if (bindingText and bindingText ~= '') then
			GameTooltip:SetText(self.tooltipName..NORMAL_FONT_COLOR_CODE..' ('..bindingText..')'..FONT_COLOR_CODE_CLOSE, 1.0, 1.0, 1.0)
		else
			GameTooltip:SetText(self.tooltipName, 1.0, 1.0, 1.0)
		end
		if ( self.tooltipSubtext ) then
			GameTooltip:AddLine(self.tooltipSubtext, 0.5, 0.5, 0.5, true)
		end
		GameTooltip:Show()
		self.UpdateTooltip = nil
	else
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		if (GameTooltip:SetShapeshift(self:GetID())) then
			self.UpdateTooltip = self.OnEnter
		else
			self.UpdateTooltip = nil
		end
	end
end
 
function Button:OnSizeChanged(width, height)
	local normalX, normalY = (width * (46/32)), (height * (46/32))
	self.NormalTexture:SetSize(normalX, normalY)
	self.PushedTexture:SetSize(normalX, normalY)
end


function Stance:UpdateButtons() 
	local RADIAN_FRACTION = rad( 360 / (3 - 2) )
	local Mixin = db.table.mixin
    Stance.Buttons = {}

    

	for i=1, STANCE_COUNT do
		local x, y, r = 0, 0, 60 -- xOffset, yOffset, radius
		local angle = (i+3) * RADIAN_FRACTION
		local ptx, pty = x + r * math.cos( angle ), y + r * math.sin( angle )

		local name = addOn..'Stance'..i
		local button = CreateFrame('CheckButton', name, Stance, 'SecureActionButtonTemplate, CPModPetActionButtonTemplate') 
		button:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonDown', 'MiddleButtonUp')
		button:SetAttribute('action', i)
		button:SetID(i)
		button:SetScript('OnEnter', nil) 

		Mixin(button, ConsolePortActionButtonMixin)
 
		button.cooldown = _G[name..'Cooldown'];
		button.Shine = _G[name..'Shine']
		button.NormalTexture = _G[name..'NormalTexture2']
        
		button.NormalTexture:SetTexture('Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\PetNormal')
		button.NormalTexture:ClearAllPoints()
		button.NormalTexture:SetPoint('CENTER', 0, 0)
 
		button.PushedTexture = button:GetPushedTexture()
		button.HighlightTexture = button:GetHighlightTexture()
		button.CheckedTexture = button:GetCheckedTexture()

		button.PushedTexture:SetTexture('Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\PetPushed')
		button.PushedTexture:ClearAllPoints()
		button.PushedTexture:SetPoint('CENTER', 0, 0)

		button.HighlightTexture:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Button\\Hilite')
		button.HighlightTexture:SetAllPoints()

		button.CheckedTexture:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Button\\Hilite')
		button.CheckedTexture:SetAllPoints()
 
		Mixin(button, Button)

		
		button.HotkeyIcon = button:CreateTexture(nil, 'BORDER')
		button.HotkeyIcon:SetSize(32, 32)
		button.HotkeyIcon:SetPoint('BOTTOM', button, 'CENTER', 0, 0)
		button.HotkeyIcon:SetTexture(db.ICONS['CP_T'.. i])
		button.HotkeyIcon:Hide()

        if(STANCE_COUNT == 1) then
            button:SetPoint('BOTTOM', 0, -12)
        elseif(STANCE_COUNT == 2) then
            button:SetPoint(i == 1 and 'BOTTOMLEFT' or 'BOTTOMRIGHT', i == 1 and 4 or -4, -12)
        elseif(STANCE_COUNT == 3) then
            if(i < 3) then
                button:SetPoint(i == 1 and 'BOTTOMLEFT' or 'BOTTOMRIGHT', i == 1 and 4 or -4, -12)
            else
                button:SetPoint('TOP', 0, 12)
            end
        else
            if(i < 3) then
                button:SetPoint(i == 1 and 'BOTTOMLEFT' or 'BOTTOMRIGHT', i == 1 and 4 or -4, -12)
            else
                button:SetPoint(i == 3 and 'TOPLEFT' or 'TOPRIGHT', i == 3 and 4 or -4, 12)
            end
        end
        
		button:SetSize(28, 28)
		
		Stance.Buttons[i] = button 
	end
end

Stance:HookScript('OnShow', function(self)
    self:UpdateButtons()
	self:Update() 
	FadeIn(self, 0.2, 0, 1)
    self:SetupEverything()
end)

Stance:HookScript('OnHide', function(self)
	--
end)

Stance:SetScript('OnEvent', function(self, event, ...)
	local arg1 = ...
	if event == 'UPDATE_SHAPESHIFT_FORM' then 
		self:Update()
    elseif event == 'UPDATE_SHAPESHIFT_FORMS' or event == 'PLAYER_ENTERING_WORLD' then
		-- reloads stance frame completely
		STANCE_COUNT = GetNumShapeshiftForms();
		
		if(IsShaman) then
			--print("something")
		end 

		if(STANCE_COUNT > 0) then			
        	self:UpdateButtons()
        	self:Update()
        	self:SetupEverything()
			self:Show();
		end
	elseif event == 'SPELL_UPDATE_COOLDOWN' then
		if(STANCE_COUNT > 0) then
			self:UpdateCooldowns()
		end
	end 
end)

function Stance:Update()
	local stanceActionButton, stanceActionIcon, stanceActionShine
	for i, stanceActionButton in pairs(self.Buttons) do
		stanceActionIcon = stanceActionButton.icon
        stanceActionShine = stanceActionButton.Shine 

		local texture, name, isActive, isCastable = GetShapeshiftFormInfo(i)
		if ( not isToken ) then
		    SetPortraitToTexture(stanceActionButton.icon, texture or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
			stanceActionButton.tooltipName = name
		else 
			SetPortraitToTexture(stanceActionButton.icon, _G[texture] or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
			stanceActionButton.tooltipName = _G[name]
		end 

		if not stanceActionButton.isHooked then
        	stanceActionButton:HookScript("OnClick", function (self, button, down)
				local _, _, isActive, _ = GetShapeshiftFormInfo(self:GetID())
				self.isHooked = true;
        	    if isActive then
    	            self:SetChecked(true)
	            else 
                	self:SetChecked(false)
            	end
        	end)
		end

		if ( isActive ) then 
            if texture then SetPortraitToTexture(self.Portrait, texture) else SetPortraitTexture(self.Portrait, 'player') end  
            AutoCastShine_AutoCastStart(stanceActionShine)
			stanceActionButton:SetChecked(true)
		else 
            AutoCastShine_AutoCastStop(stanceActionShine)
			stanceActionButton:SetChecked(false)
		end  
	end
	self:UpdateCooldowns()
end

function Stance:UpdateCooldowns()
	for i=1, STANCE_COUNT, 1 do
		local button = Stance.Buttons[i]
		local cooldown = button.cooldown
		local start, duration, enable = GetShapeshiftFormCooldown(i)
		CooldownFrame_SetTimer(cooldown, start, duration, enable)
		
		-- Update tooltip
		if ( GameTooltip:GetOwner() == button ) then
			button:OnEnter()
		end
	end
end

function Stance:OnControlPet(hasControl)
	if hasControl then
		self.Buttons[1].HotkeyIcon:Show()
		self.Buttons[2].HotkeyIcon:Show()
	else

		self.Buttons[1].HotkeyIcon:Hide()
		self.Buttons[2].HotkeyIcon:Hide()
	end
end 

function Stance:SetupEverything() -- Wheel setup
	Stance:Execute([[
		Bar = self
		---------------------------------------------------------------
		TARGET_PET = 'LeftButton'
		TOGGLE_MENU = 'RightButton'
		CONTROL_PET = 'MiddleButton'
		---------------------------------------------------------------
		BUTTONS = newtable()
		---------------------------------------------------------------
		KEYS = newtable()
		BINDINGS = newtable()
		---------------------------------------------------------------
		INDEX = 0
		---------------------------------------------------------------
		KEYS.UP 	= false		KEYS.W 		= false
		KEYS.LEFT 	= false		KEYS.A 		= false
		KEYS.DOWN 	= false		KEYS.S 		= false
		KEYS.RIGHT 	= false		KEYS.D 		= false
		---------------------------------------------------------------
		OnKey = [=[
			if self:IsVisible() then
				local key, down = ...
				-----------------------------
				if BUTTON then
					BUTTON:SetWidth(40)
					BUTTON:SetHeight(40)
				end
				-----------------------------
				if down then
					if key == 'UP' then
						KEYS.DOWN = false
						KEYS.UP = true
					elseif key == 'DOWN' then
						KEYS.UP = false
						KEYS.DOWN = true
					elseif key == 'LEFT' then
						KEYS.RIGHT = false
						KEYS.LEFT = true
					elseif key == 'RIGHT' then
						KEYS.LEFT = false
						KEYS.RIGHT = true
					end
				else
					KEYS[key] = false
				end
				-----------------------------
				INDEX = 
					( KEYS.UP and KEYS.RIGHT 	) and 2 or -- Up/right
					( KEYS.DOWN and KEYS.RIGHT 	) and 4 or -- Down/right
					( KEYS.DOWN and KEYS.LEFT 	) and 6 or -- Down/left
					( KEYS.UP and KEYS.LEFT 	) and 8 or -- Up/left
					( KEYS.UP 					) and 1 or -- Up
					( KEYS.RIGHT 				) and 3 or -- Right
					( KEYS.DOWN 				) and 5 or -- Down
					( KEYS.LEFT 				) and 7 or 0 -- Left || none
				-----------------------------
				self:SetAttribute('index', INDEX)
				BUTTON = BUTTONS[INDEX]
				if BUTTON then
					BUTTON:SetWidth(50)
					BUTTON:SetHeight(50)
				end
				-----------------------------
			end
		]=]
		SetBindingClick = [=[
			local binding, owner, ID = ...
			self:SetBindingClick(true, binding, owner, ID)
			self:SetBindingClick(true, 'CTRL-'..binding, owner, ID)
			self:SetBindingClick(true, 'SHIFT-'..binding, owner, ID)
			self:SetBindingClick(true, 'CTRL-SHIFT-'..binding, owner, ID)
		]=]
	]])

	Stance:WrapScript(Stance, 'PreClick', [[
		self:SetAttribute('type', nil)

		-- Target pet on regular click
		-----------------------------
		if button == TARGET_PET then
			if not down then
				self:SetAttribute('type', 'target')
			end
		-----------------------------

		-- Show unit menu on right click
		-----------------------------	
		elseif button == TOGGLE_MENU then
			if not down then
				self:SetAttribute('type', 'togglemenu')
			end
		-----------------------------

		-- Pet control
		-----------------------------
		elseif button == CONTROL_PET then
			-----------------------------
			-- Enable
			-----------------------------
			if down then
				for binding, keyID in pairs(BINDINGS) do
					control:Run(SetBindingClick, binding, self:GetFrameRef(keyID):GetName(), 'MiddleButton')
				end

				-- Attack / follow buttons
				-----------------------------
				local key1 = GetBindingKey('CP_T1')
				local key2 = GetBindingKey('CP_T2')

				if key1 then control:Run(SetBindingClick, key1, 'ConsolePortBarPet1', 'LeftButton') end
				if key2 then control:Run(SetBindingClick, key2, 'ConsolePortBarPet2', 'LeftButton') end
				-----------------------------

				-- Signal the insecure changes
				control:CallMethod('OnControlPet', true)
			-----------------------------
			-- Disable
			-----------------------------
			else
				if BUTTON then
					self:SetAttribute('type', 'macro')
					self:SetAttribute('macrotext', ('/click %s'):format(BUTTON:GetName()))
					BUTTON:SetWidth(40)
					BUTTON:SetHeight(40)
					BUTTON = nil
				end
				self:ClearBindings()
				control:CallMethod('OnControlPet', false)
			end
		end
	]])

	Stance:WrapScript(Stance, 'OnHide', [[
		self:ClearBindings()
	]])
 
 	-- Set these buttons to handle the input for the ring.
     local catchnil = CreateFrame('CheckButton', '', nil) 
     local actionButtons = {
		[Stance.Buttons[1] or catchnil] = 'UP',
		[Stance.Buttons[2] or catchnil] = 'RIGHT',
		[Stance.Buttons[3] or catchnil] = 'DOWN',
		[Stance.Buttons[4] or catchnil] = 'LEFT',
	}

	for button, keyID in pairs(actionButtons) do
		button:SetAttribute('keyID', keyID)
		Stance:SetFrameRef(keyID, button)
		Stance:WrapScript(button, 'PreClick', [[
			self:SetAttribute('type', nil) 
			if button == 'LeftButton' or button == 'RightButton' then
				self:SetAttribute('type', 'macro')
				self:SetAttribute('macrotext', ('/click %s'):format("ShapeshiftButton"..self:GetID()))
			else
				control:Run(OnKey, self:GetAttribute('keyID'), down)
			end
		]])
	end

	-- Define the inputs to control the pet ring
	local buttons = {
		['UP'] 		= {'W', 'UP'},
		['LEFT'] 	= {'A', 'LEFT'},
		['DOWN'] 	= {'S', 'DOWN'},
		['RIGHT'] 	= {'D', 'RIGHT'},
	}

	for direction, keys in pairs(buttons) do
		for _, key in pairs(keys) do
			Stance:Execute(format([[
				BINDINGS.%s = '%s'
			]], key, direction))
		end
	end
 
end