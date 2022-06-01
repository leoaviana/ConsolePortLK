local _, L = ...
local Menu = L.Menu
local Control = ConsolePortUI:GetControlHandle()

function Menu:OnShow()
	if UIDoFramesIntersect(self, Minimap) and Minimap:IsShown() then
		self.minimapHidden = true
		Minimap:Hide()
		MinimapCluster:Hide()
	end
end

function Menu:OnHide()
	if self.minimapHidden then
		Minimap:Show()
		MinimapCluster:Show()
		self.minimapHidden = false
	end
end 

Menu.CallMethodFromFrame = CPAPI.CallMethodFromFrame

for name, script in pairs({
	_onshow = [[
		control:RunAttribute('SetDropdownButton', 0, 1)
		--RegisterStateDriver(self, 'modifier', '[mod:shift,mod:ctrl] true; nil')
	]],
	_onhide = [[
		--UnregisterStateDriver(self, 'modifier')
	]],
	['_onstate-modifier'] = [[
		if newstate then
			for i = 1, numheaders do
				control:RunAttribute('ShowHeader', i)
			end
		else
			for i = 1, numheaders do
				if i ~= hID then
					control:RunAttribute('ClearHeader', i)
				end
			end
		end
	]],
	SetHeaderID = [[
		hID = ...
	]],
	ShowHeader = [[
		local hID = ...
		local header
		if(headers) then
			header = headers[hID]
		end 

		if not self:GetAttribute("ahlncnt") and headers then
			local cnt = 0;
			for i, header in pairs(headers) do
				self:SetAttribute("ahln"..i, header)
				cnt = cnt + 1;
			end

			self:SetAttribute("ahlncnt", cnt)
		else
			if(not header) then
				header = self:GetAttribute("ahln"..hID)
			end
		end
		
		for _, button in ipairs(newtable(header:GetChildren())) do
			local condition = button:GetAttribute('condition')
			if condition then
				local show = control:RunFor(self, condition)
				if show then 
					button:Show()
				else 
					button:Hide()
				end
			else 
				button:Show()
			end
		end
	]],
	ClearHeader = [[		 
		for _, button in ipairs(newtable(header:GetChildren())) do
			button:Hide()
		end
	]],
	SetHeader = [[
		local buttons = newtable(header:GetChildren())
		local highIndex = 0
		if header:GetAttribute('onheaderset') then
            local newVal = control:RunFor(header, header:GetAttribute('onheaderset'))
			self:SetAttribute('highestIndex', newVal) 
		else
			for _, button in pairs(buttons) do
				local condition = button:GetAttribute('condition')
				local currentID
				if condition then
					local show = control:RunFor(self, condition)
					if show then
						currentID = tonumber(button:GetID())
					end
				else
					currentID = tonumber(button:GetID())
				end
				if currentID and currentID > highIndex then
					highIndex = currentID
				end
			end
			self:SetAttribute('highestIndex', highIndex) 
		end
	]],
	SetDropdownButton = [[
		local newIndex, delta = ...
		bID = newIndex + delta 
		self:SetAttribute('nnptbID', bID)
		local current = self:GetAttribute('currentsel')
		local header = self:GetAttribute('currentHeader')
		local highestIndex = self:GetAttribute('highestIndex')

		if current then
			control:CallMethod('CallMethodFromFrame', current:GetName(), 'OnLeave')
		end
		if header then
			self:SetAttribute('currentsel', header:GetFrameRef(tostring(bID)))
			current = self:GetAttribute('currentsel')
			if current and current:IsVisible() then
				control:CallMethod('CallMethodFromFrame', current:GetName(), 'OnEnter')
			elseif bID > 1 and bID < highestIndex then
				control:RunFor(self, self:GetAttribute('SetDropdownButton'), bID, delta)
			end
		end
	]],
	OnInput = [[ 
		-- Click on a button
		if key == CROSS and current then
			control:CallMethod('CallMethodFromFrame', current:GetName(), 'SetButtonState', down and 'PUSHED' or 'NORMAL')
			if not down then
				returnHandler, returnValue = 'macrotext', '/click ' .. current:GetName()
			end

		-- Alternative clicks
		elseif key == CIRCLE and current then
			control:CallMethod('CallMethodFromFrame', current:GetName(), 'SetButtonState', down and 'PUSHED' or 'NORMAL')
			if not down then
				if current:GetAttribute('circleclick') then
					control:RunFor(current, current:GetAttribute('circleclick'))
				end
			end
		elseif key == SQUARE and current then
			control:CallMethod('CallMethodFromFrame', current:GetName(), 'SetButtonState', down and 'PUSHED' or 'NORMAL')
			if not down then
				if current:GetAttribute('squareclick') then
					control:RunFor(current, current:GetAttribute('squareclick'))
				end
			end
		elseif key == TRIANGLE and current then
			control:CallMethod('CallMethodFromFrame', current:GetName(), 'SetButtonState', down and 'PUSHED' or 'NORMAL')
			if not down then
				if current:GetAttribute('triangleclick') then
					control:RunFor(current, current:GetAttribute('triangleclick'))
				end
			end

		elseif ( key == CENTER or key == OPTIONS or key == SHARE ) and down then
			returnHandler, returnValue = 'macrotext', '/click GameMenuButtonContinue'

		-- Select button
		elseif key == UP and down and bID > 1 then
			control:RunFor(self, self:GetAttribute('SetDropdownButton'), bID, -1)
		elseif key == DOWN and down and bID < highestIndex then
			control:RunFor(self, self:GetAttribute('SetDropdownButton'), bID, 1)

		-- Select header
		elseif key == LEFT and down and hID > 1 then
			control:RunFor(self, self:GetAttribute('ChangeHeader'), -1)
			control:RunFor(self, self:GetAttribute('SetDropdownButton'), 0, 1) 
		elseif key == RIGHT and down and hID < numheaders then
			control:RunFor(self, self:GetAttribute('ChangeHeader'), 1)
			control:RunFor(self, self:GetAttribute('SetDropdownButton'), 0, 1) 

		end

		return 'macro', returnHandler, returnValue
	]],
}) do Menu:AppendSecureScript(name, script) end

Menu:HookScript('OnShow', Menu.OnShow)
Menu:HookScript('OnHide', Menu.OnHide)