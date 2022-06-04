-- Only for compatibility purposes, animations will not work.

CPAnimatedStatusBarMixin = {};

local DEFAULT_ACCUMULATION_TIMEOUT_SEC = .1;

function CPAnimatedStatusBarMixin:OnLoad()
	if self:GetStatusBarTexture() then
		self:GetStatusBarTexture():SetDrawLayer("BORDER");
	end
	self.OnFinishedCallback = function(...) self:OnAnimFinished(...); end;
	self.OnSetStatusBarAnimUpdateCallback = function(...) self:OnSetStatusBarAnimUpdate(...); end;
	self.accumulationTimeoutInterval = DEFAULT_ACCUMULATION_TIMEOUT_SEC;
	self.matchLevelOnFirstWrap = true;
	self.matchBarValueToAnimation = false;   

	self:SetScript("OnUpdate", self.OnUpdate);

	self:Reset();
end

function CPAnimatedStatusBarMixin:Reset()
	self.pendingReset = true;
end

function CPAnimatedStatusBarMixin:SetMatchLevelOnFirstWrap(matchLevelOnFirstWrap)
	self.matchLevelOnFirstWrap = matchLevelOnFirstWrap;
end

function CPAnimatedStatusBarMixin:GetMatchLevelOnFirstWrap()
	return self.matchLevelOnFirstWrap;
end

-- If set to false then the status bar's value will immediately pop to the end and the animation will cover it, otherwise the bar's value will smoothly animate under the leading edge
function CPAnimatedStatusBarMixin:SetMatchBarValueToAnimation(matchBarValueToAnimation)
	self.matchBarValueToAnimation = matchBarValueToAnimation;
end

function CPAnimatedStatusBarMixin:GetMatchBarValueToAnimation()
	return self.matchBarValueToAnimation;
end

function CPAnimatedStatusBarMixin:SetOnAnimatedValueChangedCallback(animatedValueChangedCallback)
	self.animatedValueChangedCallback = animatedValueChangedCallback;
end

function CPAnimatedStatusBarMixin:SetDeferAnimationCallback(deferAnimationCallback)
	self.DeferAnimation = deferAnimationCallback;
end

function CPAnimatedStatusBarMixin:GetOnAnimatedValueChangedCallback()
	return self.animatedValueChangedCallback;
end

function CPAnimatedStatusBarMixin:SetAnimatedTextureColors(r, g, b)
	-- stub
end

-- Instead of using SetMinMaxValues or SetValue use this method instead
-- Optionally specify level for wrappable status bars like for XP or rep,
--	this will allow the animation to correctly reach the end of the bar and wrap back around
function CPAnimatedStatusBarMixin:SetAnimatedValues(value, min, max, level)
	if self.pendingValue ~= value then
		self.pendingValue = value;
		self:MarkDirty();
	end
	if self.pendingMin ~= min or self.pendingMax ~= max then
		self.pendingMin = min;
		self.pendingMax = max;
		self:MarkDirty();
	end
	if level and self.level ~= level then
		self.pendingLevel = level;
		self:MarkDirty();
	end
end

function CPAnimatedStatusBarMixin:MarkDirty(instant)
	self.accumulationTimeout = instant and 0 or self.accumulationTimeoutInterval;
end

function CPAnimatedStatusBarMixin:GetTargetValue()
	if self.pendingValue then
		return self.pendingValue;
	end
	return self.targetValue or self:GetValue();
end

-- Discrete value
function CPAnimatedStatusBarMixin:GetAnimatedValue()
	return self.animatedValue or self:GetValue();
end

function CPAnimatedStatusBarMixin:GetContinuousAnimatedValue()
	return self.continuousAnimatedValue or self:GetValue();
end

function CPAnimatedStatusBarMixin:OnUpdate(elapsed)
	if not self:IsAnimating() and self.accumulationTimeout and (not self.DeferAnimation or not self.DeferAnimation()) then
		if self.pendingReset then
			self:ProcessChangesInstantly();
			self.accumulationTimeout = nil;
		elseif self.accumulationTimeout <= elapsed then
			self:ProcessChanges();
			self.accumulationTimeout = nil;
		else
			self.accumulationTimeout = self.accumulationTimeout - elapsed;
		end
	end
end

function CPAnimatedStatusBarMixin:IsAnimating()
	return false --self.Anim:IsPlaying();
end

function CPAnimatedStatusBarMixin:ProcessChangesInstantly()
	self.pendingReset = false;
	if self.pendingMin or self.pendingMax then
		self:SetMinMaxValues(self.pendingMin, self.pendingMax);
		self.pendingMin = nil;
		self.pendingMax = nil;
	end
	if self.pendingLevel then
		self.level = self.pendingLevel;
		self.pendingLevel = nil;
	end
	if self.pendingValue then
		self:SetValue(self.pendingValue);
		self.pendingValue = nil;
		self:OnValueChanged();
	end
end

local function GetPercentageBetween(min, max, value)
	if max == min then
		return 0;
	end
	return (value - min) / (max - min);
end

function CPAnimatedStatusBarMixin:ProcessChanges()
	local levelIsIncreasing = false;
	if self.pendingLevel then
		if not self.level then
			-- Assume that it was already on the pending level, do nothing special
			self.level = self.pendingLevel;
			self.pendingLevel = nil;
		elseif self.pendingLevel > self.level then
			-- Going up some levels
			--levelIsIncreasing = true;
		elseif self.pendingLevel == self.level then
			-- Same level now, start from nothing
			self.pendingLevel = nil;
		else
			-- Unleveling, just instantly reset everything
			return self:ProcessChangesInstantly();
		end
	end
	if not levelIsIncreasing and (self.pendingMin or self.pendingMax) then
		local min, max = self:GetMinMaxValues();
		local oldRange = max - min;
		local newRange = self.pendingMax - self.pendingMin;
		if oldRange ~= 0 and newRange ~= 0 and oldRange ~= newRange then
			local ratio = oldRange / newRange;
			local currentValue = self:GetValue();
			self:SetMinMaxValues(self.pendingMin, self.pendingMax);
			self:SetValue(currentValue * ratio);
			self.animatedValue = nil;
			self.continuousAnimatedValue = nil;
			self:OnValueChanged();
		else
			self:SetMinMaxValues(self.pendingMin, self.pendingMax);
		end
		self.pendingMin = nil;
		self.pendingMax = nil;
	end

	local min, max = self:GetMinMaxValues();

	local newValue;
	if levelIsIncreasing then
		newValue = max;
	elseif self.pendingValue then
		newValue = self.pendingValue;
		self.pendingValue = nil;
	else
		return;
	end

	local oldValue = self:GetValue();
	if not levelIsIncreasing and oldValue == newValue then return; end
	
	if newValue > max then
		newValue = max;
	end

	local oldValueAsPercent = GetPercentageBetween(min, max, oldValue);
	local deltaAsPercent = GetPercentageBetween(min, max, newValue) - oldValueAsPercent;

	self.animatedValue = nil;
	self.continuousAnimatedValue = nil;

	-- No backward animations
	if deltaAsPercent < 0 then
		self:SetValue(newValue);
		self:OnValueChanged();
		return;
	end

	self.startValue = oldValue;
	self.targetValue = newValue;
	self.levelIsIncreasing = levelIsIncreasing;

	self:OnAnimFinished()
end 

function CPAnimatedStatusBarMixin:SetupAnimationGroupForValueChange(animationGroup, startingPercent, percentChange)
	-- stub
end

function CPAnimatedStatusBarMixin:SetupAnimationForValueChange(anim, startingPercent, percentChange)
	-- stub
end

function CPAnimatedStatusBarMixin:OnSetStatusBarAnimUpdate(anim, elapsed)
	-- stub
end

function CPAnimatedStatusBarMixin:OnValueChanged()
	if self.animatedValueChangedCallback then
		self.animatedValueChangedCallback(self, self:GetAnimatedValue());
	end
end

function CPAnimatedStatusBarMixin:OnAnimFinished()
	if self.levelIsIncreasing then
		if self.matchLevelOnFirstWrap then
			self.level = self.pendingLevel;
		else
			self.level = self.level + 1;
		end
		self:SetValue(0); 
		self:MarkDirty(true);
		self:OnValueChanged();
	else
		self:SetValue(self.targetValue);
		self:OnValueChanged();
	end	

	self.levelIsIncreasing = nil;
	self.targetValue = nil;
	self.animatedValue = nil;
	self.continuousAnimatedValue = nil;
	self.startValue = nil;
end

function CPAnimatedStatusBarMixin:AcquireTileTemplate()
	-- stub
end

function CPAnimatedStatusBarMixin:ReleaseAllTileTemplate()
	-- stub
end 

function CPAnimatedStatusBarMixin:StartTilingAnimation(startingPercent, percentChange)
	-- stub
end