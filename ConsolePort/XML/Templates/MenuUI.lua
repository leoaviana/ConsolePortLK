---------------------------------------------------------------
-- Menu header secure code template
---------------------------------------------------------------
local ENV_DEFAULT = {
	_onload = [[
		hID = 1
		headers = newtable()
	]];
	_onshow = [[  
		control:RunFor(self, self:GetAttribute('SetHeader'), hID)
		local showHeader = self:GetAttribute('ShowHeader')
		if showHeader then control:RunFor(self, showHeader, hID) end
	]];
	_onhide = [[
		for i, header in ipairs(headers) do
			control:RunFor(self, self:GetAttribute('ClearHeader'), i)
		end
	]];
	--------------------------------
	-- @param hID : header to set, identified by ID
	SetHeader = [[ 
		local h_ID = ... 

		if(headers) then
			local header = headers[...]

			if not self:GetAttribute("ahlncnt") and headers then
				local cnt = 0;
				for i, header in pairs(headers) do
					self:SetAttribute("ahln"..i, header)
					cnt = cnt + 1;
				end
				self:SetAttribute("ahlncnt", cnt)
			else
				if(not headers) then
					header = self:GetAttribute("ahln"..h_ID)
				end
			end 
		end

		self:SetAttribute('nnpthID', h_ID) 
		self:SetAttribute('currentHeader', self:GetAttribute("ahln"..h_ID))
		self:SetAttribute('prevHeader', headers and headers[h_ID - 1] or self:GetAttribute("ahln"..(h_ID - 1)))
		self:SetAttribute('nextHeader', headers and headers[h_ID + 1] or self:GetAttribute("ahln"..(h_ID + 1)))

		if numheaders then
			self:SetAttribute('numHeaders', numheaders)
		end 

		local header = self:GetAttribute('currentHeader')

		if not header then return end
		control:CallMethod('CallMethodFromFrame', header:GetName(), 'SetButtonState', 'PUSHED')
		control:CallMethod('CallMethodFromFrame', header:GetName(), 'LockHighlight')
		header:SetAttribute('focused', true)
		control:CallMethod('CallMethodFromFrame', self:GetName(), 'OnHeaderSet', header:GetName(), header:GetID())
	]];
	-- @param hID : header to clear, identified by ID
	ClearHeader = [[
		local h_ID = ... 
		if(headers) then
			local header = headers[h_ID]

			if not self:GetAttribute("ahlncnt") and headers then
				local cnt = 0;
				for i, header in pairs(headers) do
					self:SetAttribute("ahln"..i, header)
					cnt = cnt + 1;
				end
				self:SetAttribute("ahlncnt", cnt)
			else
				if(not headers) then
					header = self:GetAttribute("ahln"..h_ID)
				end
			end
		end

		self:SetAttribute('nnpthID', h_ID) 
		self:SetAttribute('currentHeader', self:GetAttribute("ahln"..h_ID))
		self:SetAttribute('prevHeader', headers and headers[h_ID - 1] or self:GetAttribute("ahln"..(h_ID - 1)))
		self:SetAttribute('nextHeader', headers and headers[h_ID + 1] or self:GetAttribute("ahln"..(h_ID + 1)))

		if numheaders then
			self:SetAttribute('numHeaders', numheaders)
		end

		local header = self:GetAttribute('currentHeader')

		if not header then return end
		control:CallMethod('CallMethodFromFrame', header:GetName(), 'SetButtonState', 'NORMAL')
		control:CallMethod('CallMethodFromFrame', header:GetName(), 'UnlockHighlight')
		header:SetAttribute('focused', false)
	]];
	-- @param delta : increment/decrement from current hID
	ChangeHeader = [[
		local delta = ...
		local hID = self:GetAttribute("nnpthID")

		local newIndex = hID + delta
		local header = self:GetAttribute("ahln"..newIndex) 
		
		if header and header:IsShown() then
			self:SetAttribute('nnpthID', newIndex) 
			hID = newIndex
			--control:RunAttribute('_onhide')
			if(headers) then
				for i, header in ipairs(headers) do
					control:RunFor(self, self:GetAttribute('ClearHeader'), i)
				end
			else
				for i=1, self:GetAttribute('ahlncnt'), 1  do 
					control:RunFor(self, self:GetAttribute('ClearHeader'), i)
				end
			end
			--
			--control:RunAttribute('_onshow')
			control:RunFor(self, self:GetAttribute('SetHeader'), hID)
			local showHeader = self:GetAttribute('ShowHeader')
			if showHeader then control:RunFor(self, showHeader, hID) end
			--
		end
	]];
	-- @param returnHandler : secure button type (e.g. 'macrotext')
	-- @param returnValue : secure button action (e.g. '/click Button')
	-- @return (optional) clickType, clickHandler, clickValue
	OnInput = [[
		local key, down = ...
		local returnHandler, returnValue
		local current = self:GetAttribute('currentsel')
		local highestIndex =  self:GetAttribute('highestIndex')
		local bID = self:GetAttribute('nnptbID')
		local hID = self:GetAttribute('nnpthID') 
		local numheaders = self:GetAttribute('numHeaders')

		if down then
			-- Change header
			if (key == T1 and hID > 1) then
				control:RunFor(self, self:GetAttribute('ChangeHeader'), -1)
				control:RunFor(self, self:GetAttribute('SetDropdownButton'), 0, 1)
			elseif (key == T2 and hID < numheaders) then
				control:RunFor(self, self:GetAttribute('ChangeHeader'), 1)
				control:RunFor(self, self:GetAttribute('SetDropdownButton'), 0, 1)
			end

			-- Play a notification sound when inputting
			control:CallMethod('CallMethodFromFrame', self:GetName(), 'OnButtonPressed', key)
		end
	]];
}
---------------------------------------------------------------
ConsolePortMenuSecureMixin = {}
---------------------------------------------------------------

function ConsolePortMenuSecureMixin:StartEnvironment()
	for attribute, body in pairs(ENV_DEFAULT) do
		self:SetAttribute(attribute, body)
	end
	self:Execute(self:GetAttribute('_onload'))
	self.StartEnvironment = nil
end

---------------------------------------------------------------
-- @param config : table {
-- 	@param name : parentKey 
--	@param id   : (optional) numeric order ID
-- 	@param text : (optional) displayed on item
-- 	@param click : (optional) secure on click script
-- 	@param wireFrame : (optional) child wire frame
--
-- 	@param type : (optional) frame type
--	@param templates : (optional) frame templates
--	@param redraw : (optional) redraw the menu
-- 	@param init   : (optional) init function
-- }
-- @return header : frame object
function ConsolePortMenuSecureMixin:AddHeader(config)
	local object = ConsolePortUI:BuildFrame(self, {
		[config.name] = {
			ID = config.id or self:GetNumHeaders() + 1;
			Type  = config.type or 'CheckButton';
			Text  = config.text;
			Setup = config.templates or {
				'SecureHandlerBaseTemplate';
				'SecureHandlerClickTemplate';
				'CPUIListCategoryTemplate';
			};
			SetAttribute = {'_onclick', config.click};
			[1] = config.wireFrame;
		};
	})
	if (type(config.init) == 'function') then
		config.init(object, self)
	end
	if config.redraw then
		self:DrawIndex()
	end
	return object
end

function ConsolePortMenuSecureMixin:UpdateHeaderIndex(forceCount)
	self.headers = forceCount and {} or self.headers or {}
	if ( #self.headers < 1 or forceCount ) then
		self:SetAttribute('headerwidth', 0)
		for _, child in ipairs({self:GetChildren()}) do
			local id = child:GetID()
			if child:IsObjectType('CheckButton') and id > 0 then
				self.headers[id] = child
				local width = child:GetWidth()
				if width > self:GetAttribute('headerwidth') then
					self:SetAttribute('headerwidth', width)
				end
			end
		end
	end
	return self.headers
end

function ConsolePortMenuSecureMixin:GetMinHeaderWidth()
	return self:GetAttribute('headerwidth') or 0
end

function ConsolePortMenuSecureMixin:GetNumHeaders(forceCount)
	return #self:UpdateHeaderIndex(forceCount)
end

function ConsolePortMenuSecureMixin:IterateHeaders(forceCount)
	return ipairs(self:UpdateHeaderIndex(forceCount))
end

function ConsolePortMenuSecureMixin:DrawIndex(headerFunc)
	local numHeaders = self:GetNumHeaders(true)
	local headerWidth = self:GetMinHeaderWidth()
	local startingPoint = -((headerWidth*numHeaders)/2 - headerWidth/2)

	self:Execute(format('numheaders = %s', numHeaders))

	for id, header in self:IterateHeaders() do
		header:ClearAllPoints()
		header:SetPoint('CENTER', startingPoint + (headerWidth * (id-1)), 0)

		self:SetFrameRef('newheader', header)
		self:Execute([[
			local newheader = self:GetFrameRef('newheader')
			headers[newheader:GetID()] = newheader
		]])

		if ( type(headerFunc) == 'function' ) then
			headerFunc(header, self)
		end
	end
end

---------------------------------------------------------------
-- Secure environment script handling

function ConsolePortMenuSecureMixin:SetSecureScript(attribute, body, asPrefix, asSuffix)
	if asPrefix then self:PrependSecureScript(attribute, body)
	elseif asSuffix then self:AppendSecureScript(attribute, body)
	else self:SetAttribute(attribute, body) end
end

function ConsolePortMenuSecureMixin:PrependSecureScript(attribute, body)
	local suffix = self:GetAttribute(attribute)
	self:SetAttribute(attribute, (suffix and body .. suffix) or body)
end

function ConsolePortMenuSecureMixin:AppendSecureScript(attribute, body)
	local prefix = self:GetAttribute(attribute)
	self:SetAttribute(attribute, (prefix and prefix .. body) or body)
end

---------------------------------------------------------------
-- Overridden by ConsolePortMenuArtMixin

function ConsolePortMenuSecureMixin:OnHeaderSet()
	-- called from secure env
end

function ConsolePortMenuSecureMixin:OnButtonPressed()
	-- called from secure env
end



---------------------------------------------------------------
-- Menu art header template: unified art template for menus
---------------------------------------------------------------
ConsolePortMenuArtMixin = {}

function ConsolePortMenuArtMixin:SetClassGradient(object, alpha)
	local cc = ConsolePortUI.Media.CC
	local gBase, gMulti, gAlpha = .3, 1.1, alpha or 0.5

	object:SetGradientAlpha('HORIZONTAL',
		(cc.r + gBase) * gMulti, (cc.g + gBase) * gMulti, (cc.b + gBase) * gMulti, gAlpha,
		1 - (cc.r - gBase) * gMulti, 1 - (cc.g - gBase) * gMulti, 1 - (cc.b - gBase) * gMulti, gAlpha)
end

function ConsolePortMenuArtMixin:LoadArt()
	local db = ConsolePort:GetData()
	local nR, nG, nB = db.Atlas.GetNormalizedCC()

	self.Art:SetVertexColor(nR, nG, nB, 1)
	self.Decor.TopLine:SetVertexColor(nR, nG, nB, 1)
	self:SetClassGradient(self.BG)

	self.BG:Show()
	self.Art:Show()
	self.GlowLeft:Show()
	self.GlowRight:Show()

	self.FadeIn, self.FadeOut = db.GetFaders()

	self:HookScript('OnShow', self.OnShowPlay)
	self:HookScript('OnSizeChanged', self.OnAspectRatioChanged)
	self:HookScript('OnUpdate', self.OnArtUpdate)
	self:OnAspectRatioChanged()
	self.LoadArt = nil
end

local LS_HEIGHT = 1080
local abs = math.abs
local artDisplays = {
	[[Interface\GLUES\LOADINGSCREENS\LoadScreenNorthrendWide]];
	[[Interface\GLUES\LOADINGSCREENS\LoadScreenKalimdorWide]];
	[[Interface\GLUES\LOADINGSCREENS\LoadScreenEasternKingdomWide]];
	[[Interface\GLUES\LOADINGSCREENS\LoadScreenIcecrownCitadel]];
	[[Interface\GLUES\LOADINGSCREENS\LoadScreenOutlandWide]];
}

function ConsolePortMenuArtMixin:OnArtUpdate(elapsed)
	self.artTicker = self.artTicker + elapsed
	if self.artTicker > 0.025 then
		local half, pan, base = self.halfY, self.pxPan, self.pxBase
		local isAtTop = pan - half < 0
		local isAtBottom = pan + half > LS_HEIGHT

		if isAtTop or isAtBottom then
			pan = isAtTop and half or (LS_HEIGHT - half)
			self.artIndex = self.artIndex >= #artDisplays and 1 or self.artIndex + 1
			self.Art:SetTexture(artDisplays[self.artIndex])
			self.panDelta = self.panDelta * -1
		else
			pan = pan + self.panDelta
		end

		local alpha = (((abs(abs(base - pan) - base) / base) ^ 1.25) - .6)
		if alpha >= 0 then
			self.Art:SetAlpha(alpha)
			self.Art:SetTexCoord(0, 1, (pan - half) / LS_HEIGHT, (pan + half) / LS_HEIGHT)
		end
		self.pxPan = pan
		self.artTicker = 0
	end
end

function ConsolePortMenuArtMixin:OnAspectRatioChanged()
	local x, y = self:GetSize()
	local scale = (UIParent:GetHeight() / LS_HEIGHT)
	self.halfY =  (y / scale / 2)
	self.pxBase = (LS_HEIGHT / 2)
	self.pxPan = LS_HEIGHT - (self.halfY)
	self.panDelta = -0.5
	self.artIndex = 1
	self.artTicker = 0
	self.Art:SetAlpha(0)
end


function ConsolePortMenuArtMixin:OnHeaderSet(id)
	self.Flair:ClearAllPoints()
	local header = type(id) == 'string' and _G[id] or id
	if header then
		if header.OnFocusAnim then
			header.OnFocusAnim:Play()
		end
		self.FadeOut(self.Flair, 0.5, 1, .25)
		self.Flair:SetPoint('BOTTOMLEFT', header, 'BOTTOMLEFT')
		self.Flair:SetPoint('BOTTOMRIGHT', header, 'BOTTOMRIGHT')
		self.Flair:SetHeight(64)
		self.Flair:Show()
	end
end

function ConsolePortMenuArtMixin:OnShowPlay()
	self.FadeIn(self.Emblem, 0.5, 0, 1)
end

function ConsolePortMenuArtMixin:OnButtonPressed()
	PlaySound(CPAPI.GetSound("IG_MAINMENU_OPTION_CHECKBOX_ON"))
end

---------------------------------------------------------------
ConsolePortLineSheenMixin = {}

function ConsolePortLineSheenMixin:SetDirection(direction, multiplier)
	assert(type(direction) == 'string', 'LineGlow:SetDirection("LEFT" or "RIGHT", multiplier)');
	assert(type(multiplier) == 'number', 'LineGlow:SetDirection("LEFT" or "RIGHT", multiplier)');
	if direction == 'LEFT' then
		self.OnShowAnim.LineSheenTranslation:SetOffset(-230 * multiplier, 0)
	elseif direction == 'RIGHT' then
		self.OnShowAnim.LineSheenTranslation:SetOffset(230 * multiplier, 0)
	end
end

function ConsolePortLineSheenMixin:OnShow()
	self.OnShowAnim:Play()
end

function ConsolePortLineSheenMixin:OnHide()
	self.OnShowAnim:Stop()
end