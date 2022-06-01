---------------------------------------------------------------
local db = ConsolePort:GetData()
---------------------------------------------------------------
local addOn, ab = ...
---------------------------------------------------------------
local FadeIn, FadeOut = db.UIFrameFadeIn, db.UIFrameFadeOut
---------------------------------------------------------------
local Bar = ab.bar
local Lib = ab.libs.button
---------------------------------------------------------------
local Totem = CreateFrame('Button', '$parentTotem', Bar, 'SecureActionButtonTemplate, SecureHandlerBaseTemplate, SecureHandlerStateTemplate')
local Button = {}

local BUTTON_SIZE = 40
 
local GameTooltip = GameTooltip 

--if not select(2, UnitClass('player')) == 'SHAMAN' then return end

local TOTEM_COUNT

local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop

Bar.Totem = Totem
Totem:Hide()
Totem.Buttons = {}
Totem.showgrid = 0
Totem.locked = 0
Totem.mode = 'show'
Totem:SetMovable(true)
Totem:SetClampedToScreen(true)
Totem:RegisterForDrag('LeftButton')
Totem:SetScript('OnDragStart', Totem.StartMoving)
Totem:SetScript('OnDragStop', Totem.StopMovingOrSizing)
Totem:SetPoint('TOPRIGHT', 0, 50)
Totem:SetSize(64, 64)

for _, event in pairs({
	'PLAYER_ENTERING_WORLD', 
	'UPDATE_MULTI_CAST_ACTIONBAR',  
}) do Totem:RegisterEvent(event) end

Totem:RegisterForClicks('AnyUp', 'AnyDown') 

Totem.Portrait = Totem:CreateTexture(nil, 'ARTWORK')
Totem.Shadow = Totem:CreateTexture(nil, 'ARTWORK')
Totem.Border = Totem:CreateTexture(nil, 'OVERLAY')

Totem.Portrait:SetAllPoints()
Totem.Border:SetAllPoints()
Totem.Shadow:SetPoint('CENTER', 0, -5)

Totem.Border:SetTexture('Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\BigNormal') 
Totem.Shadow:SetSize(82, 82)
Totem.Shadow:SetTexture('Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\BigShadow')
Totem.Shadow:SetAlpha(0.75)  

function Button:OnEnter()
	if ( not self.tooltipName ) then
		return
	end
	local uber = GetCVar('UberTooltips')
	if ( uber == '0' ) then
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		local bindingText = GetBindingText(GetBindingKey('MULTICASTACTIONBUTTON'..self:GetID()))
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
		if (GameTooltip:SetAction(self.realbutton.action)) then
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


function Totem:UpdateButtons() 
	local RADIAN_FRACTION = rad( 360 / (4 - 2) )
	local Mixin = db.table.mixin
    Totem.Buttons = {}

	for i=1, 12 do
		local x, y, r = 0, 0, 60 -- xOffset, yOffset, radius
		local angle = (i+3) * RADIAN_FRACTION
		local ptx, pty = x + r * math.cos( angle ), y + r * math.sin( angle )
 
		local backButton = _G["MultiCastSlotButton"..(i % 4 == 0 and 4 or i % 4)]   

		if i < 5 then
			backButton:ClearAllPoints()
			backButton:SetParent(Totem)
		end

		local name = addOn..'Totem'..i
		local button = CreateFrame('CheckButton', name, backButton, 'SecureActionButtonTemplate, CPModPetActionButtonTemplate') 
		button:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonDown', 'MiddleButtonUp') 
		button:SetAttribute('action', i)
		button:SetID(i)
		button:SetScript('OnEnter', nil) 
		button:HookScript('OnEnter', function(self) MultiCastSlotButton_OnEnter(backButton) end)
		button:HookScript('OnLeave', function(self) MultiCastSlotButton_OnLeave(backButton) end)

		CPAPI.Mixin(button, ConsolePortActionButtonMixin)
		
		button.realbutton = _G["MultiCastActionButton"..i] 
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
 
		CPAPI.Mixin(button, Button)

		
		button.HotkeyIcon = button:CreateTexture(nil, 'BORDER')
		button.HotkeyIcon:SetSize(32, 32)
		button.HotkeyIcon:SetPoint('BOTTOM', button, 'CENTER', 0, 0)
		button.HotkeyIcon:SetTexture(db.ICONS['CP_T'.. i])
		button.HotkeyIcon:Hide() 
        

        if(i < 3) then
            backButton:SetPoint(i == 1 and 'BOTTOMLEFT' or 'BOTTOMRIGHT', i == 1 and 4 or -4, -12)
			button:SetPoint(i == 1 and 'BOTTOMLEFT' or 'BOTTOMRIGHT', i == 1 and 0 or 0, 0)
		elseif (i > 2 and i < 5) then
            backButton:SetPoint(i == 3 and 'TOPLEFT' or 'TOPRIGHT', i == 3 and 4 or -4, 12)
			button:SetPoint(i == 3 and 'TOPLEFT' or 'TOPRIGHT', i == 3 and 0 or 0, 0)
		elseif (i > 4 and i < 8) then 
			button:SetPoint(i == 5 and 'BOTTOMLEFT' or 'BOTTOMRIGHT', i == 5 and 0 or 0, 0)
			button:Hide()
		elseif (i > 7 and i < 11) then 
			button:SetPoint(i == 8 and 'TOPLEFT' or 'TOPRIGHT', i == 8 and 0 or 0, 0) 
			button:Hide()
		elseif (i > 10) then  
			button:SetPoint(i == 11 and 'TOPLEFT' or 'TOPRIGHT', i == 11 and 0 or 0, 0)
			button:Hide()
        end
        
		backButton:SetSize(28, 28)
		button:SetSize(28, 28)
 
		local overrideSetPoint = backButton.SetPoint 
		backButton.SetPoint = nil 
		hooksecurefunc(backButton, "SetPoint", function(self, point, x, y)
			if(self:GetName() == "MultiCastSlotButton1" or self:GetName() == "MultiCastSlotButton2") then
				overrideSetPoint(self, self:GetName() == "MultiCastSlotButton1" and 'BOTTOMLEFT' or 'BOTTOMRIGHT', self:GetName() == "MultiCastSlotButton1" and 4 or -4, -12)
			else
				overrideSetPoint(self, self:GetName() == "MultiCastSlotButton3" and 'TOPLEFT' or 'TOPRIGHT', self:GetName() == "MultiCastSlotButton3" and 4 or -4, 12)
			end 
		end) 
		backButton.SetParent = function () return end

		Totem.Buttons[i] = button  
	end  

 	MultiCastSummonSpellButton:ClearAllPoints();
	MultiCastSummonSpellButton:SetParent(Totem);
	MultiCastSummonSpellButton:SetPoint('LEFT', -12, 0) 

	MultiCastRecallSpellButton:ClearAllPoints();
	MultiCastRecallSpellButton:SetParent(Totem);
	MultiCastRecallSpellButton:SetPoint('RIGHT', 12, 0)
	MultiCastRecallSpellButton:SetScript("OnEvent", nil)
	
	MultiCastRecallSpellButton.SetParent = function () return end;
	MultiCastRecallSpellButton.SetPoint = function () return end; 
end

function Totem:UpdateAll()  
	self:UpdateButtons()
	self:Update() 
    self:SetupEverything()
end 

Totem:HookScript('OnShow', function(self)
   -- self:UpdateAll()
	FadeIn(self, 0.2, 0, 1) 
	
	MultiCastFlyoutFrame:SetParent(UIParent);
	MultiCastFlyoutFrame.SetParent = function () return end


	MultiCastFlyoutFrame:HookScript("OnHide", function()
		_G["MultiCastSlotButton3"]:Show()
		_G["MultiCastSlotButton4"]:Show() 
		FadeIn(Totem, 0.4, 0.3, 1)
	 end)

	hooksecurefunc("MultiCastSummonSpellButton_Update", function() Totem:Update() end)
	hooksecurefunc("MultiCastFlyoutFrame_ToggleFlyout", function(self, type, parent) 

		_G["MultiCastSlotButton3"]:Show()
		_G["MultiCastSlotButton4"]:Show() 

		FadeOut(Totem, 0.4, 1, 0.3) 
 
		self.typeBak = type 
		self.parentBak = parent 

		if(self.parentBak) then
			if (self.parentBak:GetName() == "MultiCastSlotButton1" or self.parentBak:GetName() == "MultiCastSlotButton2") then
				(self.parentBak:GetName() == "MultiCastSlotButton1" and _G["MultiCastSlotButton3"] or _G["MultiCastSlotButton4"]):Hide()
			end 
		end	
	end)  
	hooksecurefunc("MultiCastFlyoutButton_OnClick", function(self)   
		if(self:GetParent().typeBak == "slot") then
			local actionid = ActionButton_CalculateAction(self:GetParent().parentBak.actionButton)  

			self.typeBak = nil;
			self.parentBak = nil;

			--		Call of The		Earth,Button	Fire,Button 	Water,Button 	Air,Button
			--		Elements 		134,1	 		133,2	 		135,3	  		136,4
			--		Ancestors 		138,5 			137,6 			139,7 			140,8
			--		Spirits 		142,9 			141,10 			143,11 			144,12
  
			if(actionid == 133 or actionid == 134) then
				Totem:Update(actionid == 134 and 1 or 2, self.spellId)
			elseif(actionid == 135 or actionid == 136) then
				Totem:Update(actionid == 135 and 3 or 4, self.spellId)
			elseif(actionid == 137 or actionid == 138) then
				Totem:Update(actionid == 138 and 5 or 6, self.spellId) 
			elseif(actionid == 139 or actionid == 140) then
				Totem:Update(actionid == 139 and 7 or 8, self.spellId)
			elseif(actionid == 141 or actionid == 142) then
				Totem:Update(actionid == 142 and 9 or 10, self.spellId)
			elseif(actionid == 143 or actionid == 144) then
				Totem:Update(actionid == 143 and 11 or 12, self.spellId)
			end 
		end
	end)   
end)

Totem:HookScript('OnHide', function(self)
	--
end)

Totem:SetScript('OnEvent', function(self, event, ...)
	local arg1 = ...
	if event == 'UPDATE_MULTI_CAST_ACTIONBAR' then 
		self:Update()
    elseif event == 'PLAYER_ENTERING_WORLD' then
		-- reloads Totem frame completely
		TOTEM_COUNT = MultiCastActionBarFrame.numActiveSlots; 	
		if TOTEM_COUNT > 0 then	
        	self:UpdateButtons()
       		self:Update()
        	self:SetupEverything()
			self:Show(); 
		end 
	end
end)

function Totem:Update(index, spellId)
	local stanceActionButton, stanceActionIcon, stanceActionShine
	if(not index) then
		local calltotemtex = _G['MultiCastSummonSpellButtonIcon']:GetTexture() 
		if calltotemtex then SetPortraitToTexture(self.Portrait, calltotemtex) else SetPortraitTexture(self.Portrait, 'player') end 
		
		for i, stanceActionButton in pairs(self.Buttons) do
			if (MultiCastActionBarFrame.currentPage == 1) then
				if i < 5 then
					stanceActionButton:Show()
				else
					stanceActionButton:Hide()
				end
			elseif(MultiCastActionBarFrame.currentPage == 2) then
				if( i > 4 and i < 9) then
					stanceActionButton:Show()
				else
					stanceActionButton:Hide()
				end
			else
				if(i > 8) then
					stanceActionButton:Show()
				else
					stanceActionButton:Hide();
				end
			end
			stanceActionIcon = stanceActionButton.icon
        	stanceActionShine = stanceActionButton.Shine  
			isCdHooked = stanceActionButton.isCdHooked

			local texture = _G[stanceActionButton.realbutton:GetName()..'Icon']:GetTexture()

			if ( not isToken ) then 
		    	SetPortraitToTexture(stanceActionButton.icon, texture or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
				stanceActionButton.tooltipName = stanceActionButton.realbutton:GetName();
			else 
				SetPortraitToTexture(stanceActionButton.icon, _G[texture] or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
				stanceActionButton.tooltipName = _G[name]
			end 
  

			if(not isCdHooked) then
				hooksecurefunc(_G[stanceActionButton.realbutton:GetName().."Cooldown"], "SetCooldown", function(self, start, duration)
					CooldownFrame_SetTimer(stanceActionButton.cooldown, start, duration, 1)
					if ( GameTooltip:GetOwner() == stanceActionButton ) then
						stanceActionButton:OnEnter()
					end
				end)
				stanceActionButton.isCdHooked = true
			end  
		end
	else
		stanceActionButton = self.Buttons[index]
		stanceActionIcon = stanceActionButton.icon
        stanceActionShine = stanceActionButton.Shine
		isCdHooked = stanceActionButton.isCdHooked  
		local texture = _G[stanceActionButton.realbutton:GetName()..'Icon']:GetTexture()
		if ( not isToken ) then 
	    	SetPortraitToTexture(stanceActionButton.icon, texture or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
			stanceActionButton.tooltipName = stanceActionButton.realbutton:GetName();
		else 
			SetPortraitToTexture(stanceActionButton.icon, _G[texture] or [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
			stanceActionButton.tooltipName = _G[name]
		end 

		if(spellId and spellId == 0) then
			SetPortraitToTexture(stanceActionButton.icon, [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]) 
			stanceActionButton.tooltipName = stanceActionButton.realbutton:GetName();
		end

		if(not isCdHooked) then
			hooksecurefunc(_G[stanceActionButton.realbutton:GetName().."Cooldown"], "SetCooldown", function(self, start, duration)
				CooldownFrame_SetTimer(stanceActionButton.cooldown, start, duration, 1)
				if ( GameTooltip:GetOwner() == stanceActionButton ) then
					stanceActionButton:OnEnter()
				end
			end)
			stanceActionButton.isCdHooked = true
		end
	end 
end 


function Totem:SetupEverything()
	Totem:Execute([[
		Bar = self 
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
	]])

	Totem:WrapScript(Totem, 'PreClick', [[
		 
	]])

	Totem:WrapScript(Totem, 'OnHide', [[
		self:ClearBindings()
	]])
 
 	-- placebo
     local catchnil = CreateFrame('CheckButton', '', nil) 
     local actionButtons = {
		[Totem.Buttons[1] or catchnil] = 'UP',
		[Totem.Buttons[2] or catchnil] = 'RIGHT',
		[Totem.Buttons[3] or catchnil] = 'DOWN',
		[Totem.Buttons[4] or catchnil] = 'LEFT',
		[Totem.Buttons[5] or catchnil] = 'UP',
		[Totem.Buttons[6] or catchnil] = 'RIGHT',
		[Totem.Buttons[7] or catchnil] = 'DOWN',
		[Totem.Buttons[8] or catchnil] = 'LEFT',
		[Totem.Buttons[9] or catchnil] = 'UP',
		[Totem.Buttons[10] or catchnil] = 'RIGHT',
		[Totem.Buttons[11] or catchnil] = 'DOWN',
		[Totem.Buttons[12] or catchnil] = 'LEFT',
	}

	for button, keyID in pairs(actionButtons) do
		button:SetAttribute('keyID', keyID)
		Totem:SetFrameRef(keyID, button)
		Totem:WrapScript(button, 'PreClick', [[
			self:SetAttribute('type', nil) 
			if button == 'LeftButton' or button == 'RightButton' then
				self:SetAttribute('type', 'macro')
				self:SetAttribute('macrotext', ('/click %s'):format("MultiCastActionButton"..self:GetID())) 
			end
		]])
	end 
 
end