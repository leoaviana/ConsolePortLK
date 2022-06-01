ConsolePortActionButtonMixin = {}

function ConsolePortActionButtonMixin:SetIcon(file)
	local icon = self.icon or self.Icon
	if icon then
		icon:SetDesaturated(not file and true or false)
		icon:SetTexture(file or [[Interface\AddOns\ConsolePort\Textures\Button\EmptyIcon]])
	end
end

function ConsolePortActionButtonMixin:ClearIcon()
	local icon = self.icon or self.Icon
	if icon then
		icon:SetDesaturated(false)
		icon:SetTexture(nil)
	end
end

function ConsolePortActionButtonMixin:SetVertexColor(...)
	local icon = self.icon or self.Icon
	local font = self:GetFontString()
	if icon then icon:SetVertexColor(...) end
	if font then font:SetVertexColor(...) end
end

function ConsolePortActionButtonMixin:ClearVertexColor()
	local icon = self.icon or self.Icon
	local font = self:GetFontString()
	if icon then icon:SetVertexColor(1, 1, 1) end
	if font then icon:SetVertexColor(1, 1, 1) end
end

function ConsolePortActionButtonMixin:ToggleShadow(enabled)
	local shadow = self.shadow or self.Shadow
	if shadow then
		if enabled == nil then
			enabled = not shadow:IsShown()
		end
		CPAPI.SetShown(shadow, enabled)
	end
end

function ConsolePortActionButtonMixin:SetCount(val, forceShow)
	local count = self.count or self.Count
	if count then
		val = tonumber(val)
		count:SetText(((val and val >  1) or forceShow) and val or '')
	end
end

--[==[

    -- the CP_OnLoadRoundCooldownFrame here is a mix of copy/paste from the post  https://www.wowinterface.com/forums/showthread.php?t=45918 
    -- (Huge thanks to semlar and Infus for the code.) and from the shine animation of the OmniCC AddOn!! thanks to https://www.curseforge.com/members/tullamods


	-- this code is needed because of cooldown frame in 3.3.5a being squared and there is no way to make it round like
    -- in newer wow builds, so I had to make some custom round cooldown frames, just to say, this was really painful to get working (kinda) and to find this 
    -- thread on the web without having the right keywords.. lol


    -- There will be (probably) visual glitches on the new cooldown frames and probably more cpu power needed to run them because they are not efficient. For this reason 
    -- they can be disabled in case people find them laggy or too buggy.

--]==]

function CP_OnLoadRoundCooldownFrame(pprt)


-- Some math stuff
local cos, sin, pi2, halfpi = math.cos, math.sin, math.rad(360), math.rad(90)
local function Transform(tx, x, y, angle, aspect) -- Translates texture to x, y and rotates about its center
    local c, s = cos(angle), sin(angle)
    local y, oy = y / aspect, 0.5 / aspect
    local ULx, ULy = 0.5 + (x - 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x - 0.5) * s) * aspect
    local LLx, LLy = 0.5 + (x - 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x - 0.5) * s) * aspect
    local URx, URy = 0.5 + (x + 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x + 0.5) * s) * aspect
    local LRx, LRy = 0.5 + (x + 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x + 0.5) * s) * aspect
    tx:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

-- Permanently pause our rotation animation after it starts playing
local function OnPlayUpdate(self)
    self:SetScript('OnUpdate', nil)
    self:Pause()
end

local function OnPlay(self)
    self:SetScript('OnUpdate', OnPlayUpdate)
end

local function SetValue(self, value)
    -- Correct invalid ranges, preferably just don't feed it invalid numbers
    if value > 1 then value = 1
    elseif value < 0 then value = 0 end

    -- Reverse our normal behavior
    if self._reverse then
        value = 1 - value
    end

    -- Determine which quadrant we're in
    local q, quadrant = self._clockwise and (1 - value) or value -- 4 - floor(value / 0.25)
    if q >= 0.75 then
        quadrant = 1
    elseif q >= 0.5 then
        quadrant = 2
    elseif q >= 0.25 then
        quadrant = 3
    else
        quadrant = 4
    end

    if self._quadrant ~= quadrant then
        self._quadrant = quadrant
        -- Show/hide necessary textures if we need to
        if self._clockwise then
			for i = 1, 4 do 
                CPAPI.SetShown(self._textures[i],i < quadrant)
            end
        else
            for i = 1, 4 do
                CPAPI.SetShown(self._textures[i],i > quadrant)
            end
        end
        -- Move scrollframe/wedge to the proper quadrant
        self._scrollframe:Hide();
        self._scrollframe:SetAllPoints(self._textures[quadrant])
        self._scrollframe:Show();
    end

    -- Rotate the things
    local rads = value * pi2
    if not self._clockwise then rads = -rads + halfpi end
    Transform(self._wedge, -0.5, -0.5, rads, self._aspect)
    self._rotation:SetDuration(0.000001)
    self._rotation:SetEndDelay(2147483647)
    self._rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
    self._rotation:SetRadians(-rads);
    self._group:Play();
end

local function SetClockwise(self, clockwise)
    self._clockwise = clockwise
end

local function SetReverse(self, reverse)
    self._reverse = reverse
end

local function OnSizeChanged(self, width, height)
    self._wedge:SetSize(width, height) -- it's important to keep this texture sized correctly
    self._aspect = width / height -- required to calculate the texture coordinates
end

-- Creates a function that calls a method on all textures at once
local function CreateTextureFunction(func, self, ...)
    return function(self, ...)
        for i = 1, 4 do
            local tx = self._textures[i]
            tx[func](tx, ...)
        end
        self._wedge[func](self._wedge, ...)
    end
end

-- Pass calls to these functions on our frame to its textures
local TextureFunctions = {
	SetTexture = CreateTextureFunction('SetTexture'), 
    SetBlendMode = CreateTextureFunction('SetBlendMode'),
    SetVertexColor = CreateTextureFunction('SetVertexColor'),
}

local function CreateSpinner(parent)
    local spinner = CreateFrame('Frame', nil, parent)

    -- ScrollFrame clips the actively animating portion of the spinner
    local scrollframe = CreateFrame('ScrollFrame', nil, spinner)
    scrollframe:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
    scrollframe:SetPoint('TOPRIGHT')
    spinner._scrollframe = scrollframe

    local scrollchild = CreateFrame('frame', nil, scrollframe)
    scrollframe:SetScrollChild(scrollchild)
    scrollchild:SetAllPoints(scrollframe)

    -- Wedge thing
    local wedge = scrollchild:CreateTexture()
    wedge:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
    spinner._wedge = wedge

    -- Top Right
    local trTexture = spinner:CreateTexture()
    trTexture:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
    trTexture:SetPoint('TOPRIGHT')
    trTexture:SetTexCoord(0.5, 1, 0, 0.5)

    -- Bottom Right
    local brTexture = spinner:CreateTexture()
    brTexture:SetPoint('TOPLEFT', spinner, 'CENTER')
    brTexture:SetPoint('BOTTOMRIGHT')
    brTexture:SetTexCoord(0.5, 1, 0.5, 1)

    -- Bottom Left
    local blTexture = spinner:CreateTexture()
    blTexture:SetPoint('TOPRIGHT', spinner, 'CENTER')
    blTexture:SetPoint('BOTTOMLEFT')
    blTexture:SetTexCoord(0, 0.5, 0.5, 1)

    -- Top Left
    local tlTexture = spinner:CreateTexture()
    tlTexture:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
    tlTexture:SetPoint('TOPLEFT')
    tlTexture:SetTexCoord(0, 0.5, 0, 0.5)

    -- /4|1\ -- Clockwise texture arrangement
    -- \3|2/ --

    spinner._textures = {trTexture, brTexture, blTexture, tlTexture}
    spinner._quadrant = nil -- Current active quadrant
    spinner._clockwise = true -- fill clockwise
    spinner._reverse = false -- Treat the provided value as its inverse, eg. 75% will display as 25%
    spinner._aspect = 1 -- aspect ratio, width / height of spinner frame
    spinner:HookScript('OnSizeChanged', OnSizeChanged)

    for method, func in pairs(TextureFunctions) do
        spinner[method] = func
    end

    spinner.SetClockwise = SetClockwise
    spinner.SetReverse = SetReverse
    spinner.SetValue = SetValue

    local group = wedge:CreateAnimationGroup()
    group:SetScript('OnFinished', function() group:Play() end);
    local rotation = group:CreateAnimation('Rotation')
    spinner._rotation = rotation
    spinner._group = group;
    return spinner
end
 

pprt.spinner = CreateSpinner(pprt:GetParent())
pprt.spinner:SetAllPoints()
pprt.spinner:SetTexture("Interface\\AddOns\\ConsolePortBar\\Textures\\cooldown")

pprt.spinner:SetClockwise(false)
pprt.spinner:SetReverse(true) 
pprt.spinner:SetAlpha(0) -- Hide without losing events, such a simple thing that I only figured after reading OmniCC code. (i'm new to this.)
pprt.spinner.f = CreateFrame('Frame')
pprt.spinner.f:SetScript('OnUpdate', CP_OnUpdateRCooldown)





---------------------------------------- End Cooldown Animation Stuff ----------------------------------------------------------

local function endanimation_OnFinished(self)
    local parent = self:GetParent() 
    if parent:IsShown() then
        parent:Hide()
    end
end

local function CreateShineAnimation(endanimationFrame)
    local g = endanimationFrame:CreateAnimationGroup()
    g:SetLooping('NONE')
    g:SetScript('OnFinished', endanimation_OnFinished)

    --start the animation as completely transparent
    local startTrans = g:CreateAnimation('Alpha')
    startTrans:SetChange(-1)
    startTrans:SetDuration(0)
    startTrans:SetOrder(0)

    local grow = g:CreateAnimation('Scale')
    grow:SetOrigin('CENTER', 0, 0)
    --grow:SetScale(1.3,1.3)
    grow:SetDuration(0.8/2)
    grow:SetOrder(1)

    local brighten = g:CreateAnimation('Alpha')
    brighten:SetChange(1)
    brighten:SetDuration(0.8/2)
    brighten:SetOrder(1)

    local shrink = g:CreateAnimation('Scale')
    --shrink:SetOrigin('CENTER', 0, 0)
    --shrink:SetScale(-1.3, -1.3)
    shrink:SetDuration(0.8/2)
    shrink:SetOrder(2)

    local fade = g:CreateAnimation('Alpha')
    fade:SetChange(-1)
    fade:SetDuration(0.8/2)
    fade:SetOrder(2) 
    return g
end 


local function endAnimOnHide(self)  
	self.animation:Finish()
	self:Hide()
end

local function CooldownEndAnimStart(self)
	if not self.animation:IsPlaying() then
		self:Show()
		self.animation:Play()
	end
end


pprt.endanimation = CreateFrame('Frame', nil, pprt:GetParent()); pprt.endanimation:Hide()
pprt.endanimation:SetScript('OnHide', endAnimOnHide)
pprt.endanimation:SetAllPoints()

pprt.endanimation.animation = CreateShineAnimation(pprt.endanimation)
pprt.endanimation.Start = function() CooldownEndAnimStart(pprt.endanimation) end

local icon = pprt.endanimation:CreateTexture(nil, 'OVERLAY')
icon:SetPoint('CENTER')
icon:SetBlendMode('ADD')
icon:SetAllPoints(pprt.endanimation)
icon:SetTexture("Interface\\Cooldown\\star4") 

 
end 

function CP_OnUpdateRCooldown(self, elapsed) 
    if(self.timespent ~= nil) then
        self.timespent = self.timespent + elapsed
        if self.timespent >= self.duration then
            self.timespent = nil
            if(_G[_G[self.parentname]:GetParent():GetName().."Cooldown"]:IsShown()) then
                _G[self.parentname].endanimation.Start()
            end
            return;
        end
        local value = self.timespent / self.duration 
        _G[self.parentname].spinner:SetValue(value)
    end
end

function CP_OnSetRCooldownForCooldown(self, start, duration)
    local parentname = self:GetParent():GetName().."RCooldown"
    f = _G[parentname].spinner.f  
    --if(f.duration ~= duration) then -- means it's already running
    f.start = start
    f.parentname = parentname
    f.duration = duration
    _G[f.parentname].spinner:SetAlpha(1)
    f.timespent = GetTime() - start
    --end
end

function CP_OnShowCooldown(self)
    local parentname = self:GetParent():GetName().."RCooldown"
    _G[parentname].spinner:SetAlpha(1) 
end

function CP_OnHideCooldown(self)
    local parentname = self:GetParent():GetName().."RCooldown"
    _G[parentname].spinner:SetAlpha(0) -- Hide without losing events 
end