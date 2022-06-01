CPAPI = {};

local function GetClassInfo()	return UnitClass('player') end
local function GetClassFile()   return select(2, UnitClass('player')) end
local function GetClassID() 	return select(3, UnitClass('player')) end

function CPAPI:GetPlayerCastingInfo()
	-- use UnitCastingInfo on retail
	if UnitCastingInfo then
		return UnitCastingInfo('player')
	end
	-- use CastingInfo on classic
	return CastingInfo()
end

local classes = {["WARRIOR"]=1, ["PALADIN"]=2, ["HUNTER"]=3, ["ROGUE"]=4, ["PRIEST"]=5, ["DEATHKNIGHT"]=6,["SHAMAN"]=7,["MAGE"]=8,["WARLOCK"]=9,["DRUID"]=10}

function CPAPI:GetSpecialization(...)
	local vln, vlfn = UnitClass("player");  
	return classes[vlfn] or 1;
end

local function CP_GetTalentSpecInfo(isInspect)
	-- Taken from ElvUI-WOTLK

	local talantGroup = GetActiveTalentGroup(isInspect)
	local maxPoints, specIdx, specName, specIcon = 0, 0

	for i = 1, MAX_TALENT_TABS do
		local name, icon, pointsSpent = GetTalentTabInfo(i, isInspect, nil, talantGroup)
		if maxPoints < pointsSpent then
			maxPoints = pointsSpent
			specIdx = i
			specName = name
			specIcon = icon
		end
	end

	if not specName then
		specName = NONE
	end
	if not specIcon then
		specIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
	end

	return specIdx, specName, specIcon
end

function CPAPI:GetSpecializationInfo(specID)
	_, specName, _ = CP_GetTalentSpecInfo()
	return specID, specName;
end

function CPAPI:GetSpecTextureByID(ID)
	-- returns specTexture on retail
	if GetSpecializationInfoByID then
		return select(4, GetSpecializationInfoByID(ID))
	-- returns classTexture on classic
	elseif C_CreatureInfo and C_CreatureInfo.GetClassInfo then
		local classInfo = C_CreatureInfo.GetClassInfo(ID)
		if classInfo then
			return ([[Interface\ICONS\ClassIcon_%s.blp]]):format(classInfo.classFile)
		end
	end
end

function CPAPI:GetClassIcon(class)
	-- returns concatenated icons file with slicing coords
	return [[Interface\TargetingFrame\UI-Classes-Circles]], CLASS_ICON_TCOORDS[class or GetClassFile()]
end

function CPAPI:GetClassColor(class)
	return GetClassColor(class or GetClassFile())
end

function CPAPI:GetCharacterMetadata()
	-- returns specID, specName on retail
	if GetSpecializationInfo and GetSpecialization then
		return GetSpecializationInfo(GetSpecialization())
	end
	-- returns classID, localized class token on classic
	return GetClassID(), GetClassInfo()
end

function CPAPI:GetItemLevelColor(...)
	if GetItemLevelColor then
		return GetItemLevelColor(...)
	end
	return self:GetClassColor()
end

function CPAPI:GetAverageItemLevel(...)
	if GetAverageItemLevel then
		return floor(select(2, GetAverageItemLevel(...)))
	end
	return MAX_PLAYER_LEVEL
end

local CP_Atlases = { 	
	["groupfinder-button-cover"]={"Interface\\AddOns\\ConsolePort\\Textures\\Button\\Buttons.BLP", 300, 46, 0.000976562, 0.293945, 0.331055, 0.375977, false, false},
	["adventureguide-microbutton-alert"]={"Interface\\AddOns\\BlizzCompat\\Compat\\BlizzardUI\\AdventureGuideMicrobuttonAlert.BLP", 28, 28, 0.03125, 0.90625, 0.03125, 0.90625, false, false},
};

function CPAPI:GetAtlasInfo(atlasName) -- this only returns texture file path.
	if(CP_Atlases[atlasName]) then
		local c_atlasInfo = CP_Atlases[atlasName];
		return c_atlasInfo[1];
	end
	return nil;
end

function CPAPI:GetAtlas(atlas)
	--stub
end

function CPAPI:SetAtlas(TextureObject, atlas)
	if(CP_Atlases[atlas]) then
		local c_atlas = CP_Atlases[atlas];
		TextureObject:SetTexture(c_atlas[1]);
		TextureObject:SetSize(c_atlas[2], c_atlas[3]);
		TextureObject:SetTexCoord(c_atlas[4],c_atlas[5],c_atlas[6], c_atlas[7]);
	end 
end

function CPAPI:GetAtlasTexture(atlas)
	local atlas = self:GetAtlasInfo(atlas)
	return atlas
end

function CPAPI:GetNumQuestWatches(...)
	return GetNumQuestWatches and GetNumQuestWatches(...) or 0
end

function CPAPI:GetNumWorldQuestWatches(...)
	return GetNumWorldQuestWatches and GetNumWorldQuestWatches(...) or 0
end

function CPAPI:GetQuestLogSpecialItemInfo(...)
	return GetQuestLogSpecialItemInfo and GetQuestLogSpecialItemInfo(...)
end

function CPAPI:UnitIsBattlePet(...)
	return UnitIsBattlePet and UnitIsBattlePet(...)
end

function CPAPI:UnitThreatSituation(...)
	return UnitThreatSituation and UnitThreatSituation(...)
end

function CPAPI:IsPlayerAtEffectiveMaxLevel() 
	return UnitLevel("player") >= MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel()];
end

function CPAPI:IsXPUserDisabled(...)
	return IsXPUserDisabled and IsXPUserDisabled(...)
end

function CPAPI:IsSpellOverlayed(...)
	return IsSpellOverlayed and IsSpellOverlayed(...)
end

function CPAPI:GetFriendshipReputation(...)
	return GetFriendshipReputation and GetFriendshipReputation(...)
end

function CPAPI:IsPartyLFG(...)
	return IsPartyLFG and IsPartyLFG(...)
end

function CPAPI:IsInLFGDungeon(...)
	return IsInLFGDungeon and IsInLFGDungeon(...)
end

function CPAPI:OpenStackSplitFrame(...)
	if OpenStackSplitFrame then
		return OpenStackSplitFrame(...)
	end
	return StackSplitFrame:OpenStackSplitFrame(...)
end

-- Project identifiers, should return true or nil (nil for dynamic table insertions)
function CPAPI:IsClassicVersion(...)
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then return true end
end

function CPAPI:IsRetailVersion(...)
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return true end
end

-- Mixin Implementation

function CPAPI.Mixin(object, ...)
	for i = 1, select("#", ...) do
		local mixin = select(i, ...);
		for k, v in pairs(mixin) do
			object[k] = v;
		end
	end

	return object;
end

function CPAPI.CreateFromMixins(...)
	return CPAPI.Mixin({}, ...)
end 

-- Object and Frame Pool

local ObjectPoolMixin = {};

function ObjectPoolMixin:OnLoad(creationFunc, resetterFunc)
	self.creationFunc = creationFunc;
	self.resetterFunc = resetterFunc;

	self.activeObjects = {};
	self.inactiveObjects = {};

	self.numActiveObjects = 0;
end

function ObjectPoolMixin:Acquire()
	local numInactiveObjects = #self.inactiveObjects;
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects];
		self.activeObjects[obj] = true;
		self.numActiveObjects = self.numActiveObjects + 1;
		self.inactiveObjects[numInactiveObjects] = nil;
		return obj, false;
	end

	local newObj = self.creationFunc(self);
	if self.resetterFunc then
		self.resetterFunc(self, newObj);
	end
	self.activeObjects[newObj] = true;
	self.numActiveObjects = self.numActiveObjects + 1;
	return newObj, true;
end

function ObjectPoolMixin:Release(obj)
	if self:IsActive(obj) then
		self.inactiveObjects[#self.inactiveObjects + 1] = obj;
		self.activeObjects[obj] = nil;
		self.numActiveObjects = self.numActiveObjects - 1;
		if self.resetterFunc then
			self.resetterFunc(self, obj);
		end

		return true;
	end

	return false;
end

function ObjectPoolMixin:ReleaseAll()
	for obj in pairs(self.activeObjects) do
		self:Release(obj);
	end
end

function ObjectPoolMixin:EnumerateActive()
	return pairs(self.activeObjects);
end

function ObjectPoolMixin:GetNextActive(current)
	return (next(self.activeObjects, current));
end

function ObjectPoolMixin:IsActive(object)
	return (self.activeObjects[object] ~= nil);
end

function ObjectPoolMixin:GetNumActive()
	return self.numActiveObjects;
end

function ObjectPoolMixin:EnumerateInactive()
	return ipairs(self.inactiveObjects);
end

function CPAPI.CreateObjectPool(creationFunc, resetterFunc)
	local objectPool = CPAPI.CreateFromMixins(ObjectPoolMixin);
	objectPool:OnLoad(creationFunc, resetterFunc);
	return objectPool;
end

local FramePoolMixin = CPAPI.CreateFromMixins(ObjectPoolMixin);

local function FramePoolFactory(framePool)
	return CreateFrame(framePool.frameType, nil, framePool.parent, framePool.frameTemplate);
end

function FramePoolMixin:OnLoad(frameType, parent, frameTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, FramePoolFactory, resetterFunc);
	self.frameType = frameType;
	self.parent = parent;
	self.frameTemplate = frameTemplate;
end

function FramePoolMixin:GetTemplate()
	return self.frameTemplate;
end

function CPAPI.FramePool_Hide(framePool, frame)
	frame:Hide();
end

function CPAPI.FramePool_HideAndClearAnchors(framePool, frame)
	frame:Hide();
	frame:ClearAllPoints();
end

function CPAPI.CreateFramePool(frameType, parent, frameTemplate, resetterFunc)
	local framePool = CPAPI.CreateFromMixins(FramePoolMixin);
	framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or CPAPI.FramePool_HideAndClearAnchors);
	return framePool;
end

-- CTime After function replacement
local CP_TimerAfterFrame = nil
local CP_TimerAfterTable = {};

function CPAPI.TimerAfter(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
	  return false;
	end
	if (CP_TimerAfterFrame == nil) then
	  CP_TimerAfterFrame = CreateFrame("Frame","CP_TimerAfterFrame", UIParent);
	  CP_TimerAfterFrame:SetScript("onUpdate",function (self,elapse)
		local count = #CP_TimerAfterTable;
		local i = 1;
		while(i<=count) do
		  local waitRecord = tremove(CP_TimerAfterTable,i);
		  local d = tremove(waitRecord,1);
		  local f = tremove(waitRecord,1);
		  local p = tremove(waitRecord,1);
		  if(d>elapse) then
			tinsert(CP_TimerAfterTable,i,{d-elapse,f,p});
			i = i + 1;
		  else
			count = count - 1;
			f(unpack(p));
		  end
		end
	  end);
	end
	tinsert(CP_TimerAfterTable,{delay,func,{...}});
	return true;
end 

-- Convenience functions
function CPAPI.SetShown(frame, boolean)
	if(boolean) then
	frame:Show()
	else
	frame:Hide()
	end -- lol
end

local cpBagsOpen = false;
function CPAPI.ToggleAllBags()
	CloseAllBags(); -- try to close bags if open.
	if not cpBagsOpen then
		cpBagsOpen = OpenAllBags()
	else
		CloseAllBags()
		cpBagsOpen = false;
	end 
end

function CPAPI.SetEnabled(button, boolean)
	if (boolean) then
	button:Enable()
	else
	button:Disable()
	end
end

function CPAPI.GetScaledCursorPosition()
	local uiScale = UIParent:GetEffectiveScale();
	local x, y = GetCursorPosition();
	return x / uiScale, y / uiScale;
end

-- callmethod workaround


local function CPAPICallMethodInner(frame, methodName, ...)
    local method = frame[methodName];
    -- Ensure code isn't run securely
    forceinsecure();
    if (type(method) ~= "function") then
        error("Invalid method '" .. methodName .. "'");
        return;
    end
    method(frame, ...); 
end

function CPAPI:CallMethodFromFrame(srcframe, methodName, ...)
	local frame = _G[srcframe]   
	if (not frame) then
		error("Invalid control handle");
		return;
	end
	if (type(methodName) ~= "string") then
		error("Method name must be a string");
		return;
	end
	-- Use a pcall wrapper here to ensure that execution continues
	-- regardless
	local ok, err =
		securecall(pcall, CPAPICallMethodInner, frame, methodName, scrub(...));
	if (err) then
		--SoftError(err);
	end
end

-- SoundKit

local CP_SOUNDKIT = {
    ["GS_CHARACTER_SELECTION_ENTER_WORLD"] = 809,
    ["IG_SPELLBOOK_OPEN"] = 829,
    ["IG_SPELLBOOK_CLOSE"] = 830,
    ["IG_MAINMENU_OPTION_CHECKBOX_ON"] = 856,
    ["IG_MAINMENU_OPTION_CHECKBOX_OFF"] = 857,
    ["ACHIEVEMENT_MENU_OPEN"] = 13832,
    ["ACHIEVEMENT_MENU_CLOSE"] = 13833
};

function CPAPI.GetSound(sound)
	return CP_SOUNDKIT[sound]
end

-- Frame wrapper, provide backwards compat in widgets
CPAPI.FrameMixin = {
	SetBackdrop = function(self, ...)
		if BackdropTemplateMixin then
			if not self.OnBackdropLoaded then 
				CPAPI.Mixin(self, BackdropTemplateMixin)
				self:HookScript('OnSizeChanged', self.OnBackdropSizeChanged)
			end
			BackdropTemplateMixin.SetBackdrop(self, ...)
		else
			getmetatable(self).__index.SetBackdrop(self, ...)
		end
	end;
};

function CPAPI.CreateFrame(...)
	return CPAPI.Mixin(CreateFrame(...), CPAPI.FrameMixin)
end