local _, L = ...
local db = ConsolePort:GetData()
local Button  = {}
L.Button = Button

function Button:OnHide()
	self:OnLeave()
	db.UIFrameFadeOut(self, 0.1, self:GetAlpha(), 0)
end

function Button:OnShow()
	self:Animate()
end

function Button:Animate()
	local id = self:GetID() or 1
	CPAPI.TimerAfter(id * 0.01, function()
		db.UIFrameFadeIn(self, 0.1, self:GetAlpha(), 1)
	end)
end

function Button:OnLoad()
	CPAPI.Mixin(self, ConsolePortMenuButtonMixin)  
	self.Icon = _G[self:GetName().."Icon"]
	self:SetHint(ConsolePortUIHandle, db.KEY.CROSS, ACCEPT)
	self:SetHintTriggers(true)
	self.Icon:SetTexture(self.Img)
	self:SetText(self.Desc)
	if self.OnLoadHook then
		self:OnLoadHook()
		self.OnLoadHook = nil
	end
end