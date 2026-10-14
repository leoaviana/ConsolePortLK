local addOn, db = ...

local CPAPI = {};
db.CPAPI = CPAPI

function CPAPI.Popup(id, settings, ...)
	if (settings and settings.whileDead == nil) then
		settings.whileDead = true; -- popup enabled while dead by default
	end
	StaticPopupDialogs[id:upper()] = settings;
	local dialog = StaticPopup_Show(id:upper(), ...)
	if dialog then
		local icon = dialog.AlertIcon or _G[dialog:GetName() .. 'AlertIcon'];
		if icon then
			local original = icon:GetTexture()
			local onHide = settings.OnHide;
			icon:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Logos\\CP")
			settings.OnHide = function(...)
				if icon then icon:SetTexture(original) end;
				if onHide then
					return onHide(...)
				end
			end;
		end
		return dialog;
	end
end


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

function CPAPI.GetSpecialization()
	local classes = {["WARRIOR"]=1, ["PALADIN"]=2, ["HUNTER"]=3, ["ROGUE"]=4, ["PRIEST"]=5, ["DEATHKNIGHT"]=6,["SHAMAN"]=7,["MAGE"]=8,["WARLOCK"]=9,["DRUID"]=10}
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

function CPAPI.GetSpecializationInfo(specID)
	local _, specName = CP_GetTalentSpecInfo()
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
    local c = class and RAID_CLASS_COLORS[class]
    if c then return RAID_CLASS_COLORS[class] end
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
	return RAID_CLASS_COLORS[select(2, UnitClass("player"))]
end

function CPAPI:GetAverageItemLevel(...)
	if GetAverageItemLevel then
		return floor(select(2, GetAverageItemLevel(...)))
	end
	return MAX_PLAYER_LEVEL
end

local CP_Atlases = { 	
	["groupfinder-button-cover"]={"Interface\\AddOns\\ConsolePort\\Textures\\Button\\Buttons.BLP", 300, 46, 0.000976562, 0.2939453125, 0.600, 0.6401953125, false, false},
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

function CPAPI.NewTimer(delay, func)
    local cancelled = false
    CPAPI.TimerAfter(delay, function()
        if not cancelled then
            func()
        end
    end)
    return {
        Cancel = function() cancelled = true end
    }
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






-- OmniCC style cooldown text for ConsolePortBar, adapted from OmniCC by Shestak and Nevcairiel (https://www.wowinterface.com/downloads/info25099-OmniCC.html)

CPAPI.CPCC = CPAPI.CPCC or {}

local CPCC = CPAPI.CPCC

CPCC.db = {
    enabled = true,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 24,
    fontFlags = "OUTLINE",
    minDuration = 1.5,      -- ignore shorter cooldowns (GCD etc)
    decimalThreshold = 0,   -- v90: whole-number cooldown text only
    colorThresholds = {     -- (seconds) : color
        red = 2,
        yellow = 5,
    },
    popOnFinish = true,     -- scale pop when cooldown finishes
    popScale = 1.6,
    popDuration = 0.25,     -- seconds for pop animation
}

-- Internal tables
CPCC.texts = CPCC.texts or {}   
CPCC.meta = CPCC.meta or {} 

-- v90: diagnostic only; records Blizzard logout refusal state without changing behavior.
do
    local logoutProbe = CreateFrame("Frame")
    logoutProbe:RegisterEvent("UI_ERROR_MESSAGE")
    logoutProbe:SetScript("OnEvent", function(self, event, msg)
        local text = tostring(msg or "")
        local lower = string.lower(text)
        if (ERR_CANT_LOG_OUT and text == ERR_CANT_LOG_OUT) or string.find(lower, "log out", 1, true) or string.find(lower, "logout", 1, true) then
            if not ConsolePortSettings then return end
            ConsolePortSettings.LogoutDiagnostic = {
                message=text, time=date and date("%Y-%m-%d %H:%M:%S") or tostring(GetTime()),
                lockdown=InCombatLockdown and InCombatLockdown() and true or false,
                combat=UnitAffectingCombat and UnitAffectingCombat("player") and true or false,
                dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") and true or false,
                taxi=UnitOnTaxi and UnitOnTaxi("player") and true or false,
                speed=GetUnitSpeed and GetUnitSpeed("player") or nil,
                falling=IsFalling and IsFalling() and true or false or nil,
            }
        end
    end)
end


-- v99: diagnostics must never create ConsolePortSettings at file-load time.
-- LoadSettings() uses a nil ConsolePortSettings table to detect a genuine first run
-- and launch the controller/setup wizard.  Diagnostic storage is initialized lazily
-- only after the settings table exists.

local function formatTime(s, satellite)
    if s <= 0 or s > 3600 then return "" end
    -- v90: compact OmniCC-style whole-unit rounding, no decimals. The one-hour
    -- ceiling is represented as 1h, then transitions naturally to 59m.
    if s >= 3570 then
        return "1h"
    elseif s < 59.5 then
        local seconds = math.floor(s + 0.5)
        return seconds > 0 and string.format("%d", seconds) or ""
    else
        return string.format("%dm", math.floor(s / 60 + 0.5))
    end
end

local function IsLiveSatellite(parent, fallback)
    -- v66: during modifier transitions CPCCSatellite can be stale for one
    -- render pass. Derive inactive-modifier status from the button itself when
    -- possible so the font never flashes at main-button size.
    local owner = parent and parent.CPCCOwner
    local button = owner or parent
    if button and button.mod and button.mod ~= "" then
        local currentModifier = (button.header and button.header.GetAttribute and button.header:GetAttribute("state"))
            or (ConsolePort and ConsolePort.GetCurrentModifier and ConsolePort:GetCurrentModifier())
            or ""
        return button.mod ~= currentModifier
    end
    return fallback and true or false
end

local function PositionCooldownText(holder, parent, satellite)
    local fs = holder and holder.fontstring
    if not fs then return end

    fs:ClearAllPoints()
    if not satellite then
        fs:SetPoint("CENTER", holder, "CENTER", 0, 0)
        return
    end

    local owner = parent and (parent.CPCCOwner or parent)
    -- v106: square Minimal/Triple satellites are full square children, not
    -- radial slices. Their countdown belongs at the exact center of the child.
    if owner and owner.isSquareMode then
        -- v108: anchor square countdowns to the action child itself. The CPCC
        -- holder/cooldown frame may carry its own offsets or stale geometry.
        fs:SetPoint("CENTER", owner, "CENTER", 0, 0)
        return
    end
    local orientation = owner and owner.orientation
    local mod = owner and owner.mod
    if not mod and owner and owner.GetAttribute then
        mod = owner:GetAttribute("modifier")
    end

    -- v70: Default's SHIFT/CTRL satellites occupy opposing radial slices.
    -- Move the text toward the center of its own slice rather than shrinking
    -- it globally. Offset is owner-relative so it scales with layouts/UI scale.
    local w = (owner and owner.GetWidth and owner:GetWidth()) or 0
    local h = (owner and owner.GetHeight and owner:GetHeight()) or 0
    local dx, dy = 0, 0
    local amountX = w * 0.055
    local amountY = h * 0.055

    -- v71: LT/SHIFT was moving toward the main button in v70. RT/CTRL
    -- direction was correct, so reverse LT only and leave RT untouched.
    local side = (mod == "SHIFT-" and -1) or (mod == "CTRL-" and -1) or 0
    if side ~= 0 then
        if orientation == "down" then
            dy = side * amountY
        elseif orientation == "up" then
            dy = -side * amountY
        elseif orientation == "left" then
            dx = side * amountX
        elseif orientation == "right" then
            dx = -side * amountX
        end
    end

    fs:SetPoint("CENTER", holder, "CENTER", dx, dy)
end

local function FitCooldownText(holder, parent, text, satellite)
    local fs = holder and holder.fontstring
    if not fs or not parent or not text or text == "" then return end

    -- v67: preserve the renderer role for its lifetime. An inactive-bar
    -- satellite must remain satellite-sized during the brief handoff where its
    -- modifier becomes active; it will be hidden immediately afterward. The
    -- newly active button has its own main cooldown renderer.
    satellite = satellite and true or false
    PositionCooldownText(holder, parent, satellite)

    local owner = parent.CPCCOwner
    local width = (owner and owner.GetWidth and owner:GetWidth()) or parent.CPCCOwnerWidth or (parent.GetWidth and parent:GetWidth()) or 0
    local height = (owner and owner.GetHeight and owner:GetHeight()) or parent.CPCCOwnerHeight or (parent.GetHeight and parent:GetHeight()) or 0
    if width <= 0 or height <= 0 then return end

    -- v61: true auto-fit-to-box. There are no digit-count or suffix-specific
    -- font rules. Define the visible text box, start deliberately oversized,
    -- then reduce until the actual rendered FontString fits both dimensions.
    --
    -- The secure modifier wrapper in Default is larger than the visible
    -- satellite artwork, so correct only the satellite's visual footprint.
    local visualScale = satellite and 1.0 or 1.0
    local visualW = width * visualScale
    local visualH = height * visualScale

    -- v112: dynamic-fit pass. Use the same 70% envelope for
    -- both roles. Each renderer still measures against its own bordered button
    -- dimensions.
    local fitRatio = 0.70
    local boxW = visualW * fitRatio
    local boxH = visualH * fitRatio

    -- Begin above any plausible final size. The result is determined entirely
    -- by measured rendered width/height, not by character count.
    local size = math.max(12, math.floor(visualH * 1.20 + 0.5))
    local minSize = 8

    fs:SetText(text)
    while size > minSize do
        fs:SetFont(CPCC.db.font, size, CPCC.db.fontFlags)
        local sw = fs:GetStringWidth() or 0
        local sh = fs:GetStringHeight() or 0
        if sw <= boxW and sh <= boxH then
            break
        end
        size = size - 1
    end
    fs:SetFont(CPCC.db.font, size, CPCC.db.fontFlags)
end

local function chooseColor(remaining)
    if remaining <= CPCC.db.colorThresholds.red then
        return 1, 0.12, 0.12 -- red-ish
    elseif remaining <= CPCC.db.colorThresholds.yellow then
        return 1, 0.95, 0.12 -- yellow-ish
    else
        return 1, 1, 1 -- white
    end
end

local function ResolveCooldownTarget(target)
    if type(target) == "string" then
        return target, _G[target]
    elseif type(target) == "table" and target.GetName then
        local name = target:GetName()
        return name, target
    end
    return nil, nil
end

function CPCC:CreateTextFor(target)
    local name, parent = ResolveCooldownTarget(target)
    if not name or not parent then return nil end
    if self.texts[name] then return self.texts[name] end

    -- v104: cooldown targets may be made transparent to suppress Blizzard's
    -- radial swipe. Parent CPCC text to the visual action-button owner instead
    -- so that transparency never hides our countdown with the swipe.
    local visualParent = parent.CPCCOwner or parent
    local holder = CreateFrame("Frame", name .. "OmniTextHolder", visualParent)
    holder:SetAllPoints(visualParent)
    holder:SetFrameLevel(visualParent:GetFrameLevel() + 10)

    local fs = holder:CreateFontString(nil, "OVERLAY")
    fs:SetFont(self.db.font, self.db.fontSize, self.db.fontFlags)
    fs:SetPoint("CENTER", holder, "CENTER", 0, 0)
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    fs:SetAlpha(1)
    fs:Show()

    self.texts[name] = holder
    holder.fontstring = fs
    self.meta[name] = self.meta[name] or { start = 0, duration = 0, visible = false, pop = 0, popTimer = 0, baseScale = 1 }
    return holder
end

function CPCC:StartCooldown(target, start, duration)
    if not self.db.enabled or not start or not duration then return end
    local name, parent = ResolveCooldownTarget(target)
    if not name or not parent then return end
    if duration <= self.db.minDuration then
        self:StopCooldown(name)
        return
    end

    local holder = self:CreateTextFor(parent)
    if not holder then return end

    local meta = self.meta[name]
    -- v69: satellite is a one-way promotion while a renderer is visible.
    -- A renderer that started on the active bar may legitimately become an
    -- inactive-bar satellite later, so main -> satellite must be allowed.
    -- The reverse transition must never be rendered: when that modifier
    -- becomes active, the outgoing satellite stays satellite-sized until the
    -- action-button hide path removes it.
    local requestedSatellite
    if parent.CPCCSatellite ~= nil then
        requestedSatellite = parent.CPCCSatellite and true or false
    else
        requestedSatellite = IsLiveSatellite(parent, false)
    end
    if not meta.visible then
        meta.satellite = requestedSatellite
    elseif requestedSatellite then
        meta.satellite = true
    end

    -- v102: restore the proven front overlay.  Minimal satellites intentionally
    -- sit in front of the primary button so the countdown is never obscured.
    -- The Blizzard swipe is suppressed separately by the action-button path.
    if holder.SetFrameLevel and parent.GetFrameLevel then
        local owner = parent.CPCCOwner or parent
        local squareMain = owner and owner.isSquareMode and not meta.satellite
        -- v110: square main countdown stays above its own button/swipe but
        -- below every Minimal satellite. Satellite countdowns retain the high
        -- front overlay needed to win LT/RT/LT+RT overlap.
        holder:SetFrameLevel(parent:GetFrameLevel() + (squareMain and 1 or 10))
    end

    -- v64/v68: while inactive-bar cooldown text is visible, suppress the LT/RT
    -- modifier glyph(s) on that satellite so the cooldown number has a clean
    -- center. Remember only labels that were actually shown so StopCooldown
    -- can restore the previous visual state.
    if not meta.visible then meta.hiddenHotkeys = nil end
    if meta.satellite and not meta.visible then
        local hidden = {}
        for i = 1, 2 do
            local hotkey = parent["hotkey"..i]
            if hotkey and hotkey.IsShown and hotkey:IsShown() then
                hidden[i] = true
                hotkey:Hide()
            end
        end
        if next(hidden) then meta.hiddenHotkeys = hidden end

    end

    meta.start = start
    meta.duration = duration
    meta.visible = true
    meta.pop = 0
    meta.popTimer = 0
    holder:SetScale(meta.baseScale or 1)
    holder:Show()
    if self.driver then self.driver:Show() end
end

function CPCC:StopCooldown(target)
    local name = ResolveCooldownTarget(target)
    if not name then return end
    local holder = self.texts[name]
    local meta = self.meta[name]
    if holder and meta then
        holder:Hide()

        -- Restore only modifier labels hidden by v64 for this cooldown.
        if meta.hiddenHotkeys then
            local _, parent = ResolveCooldownTarget(target)
            if parent then
                for i in pairs(meta.hiddenHotkeys) do
                    local hotkey = parent["hotkey"..i]
                    if hotkey then hotkey:Show() end
                end
            end
            meta.hiddenHotkeys = nil
        end
        meta.visible = false
        meta.start = 0
        meta.duration = 0
        meta.pop = 0
        meta.popTimer = 0
    end
end

function CPCC:OnUpdate(target, elapsed)
    if not self.db.enabled then return end
    local name = ResolveCooldownTarget(target)
    if not name then return end
    local holder = self.texts[name]
    local meta = self.meta[name]
    if not holder or not meta then return end
    local fs = holder.fontstring
    if not fs then return end
    if not meta.visible or meta.duration <= 0 then
        if holder:IsShown() then holder:Hide() end
        return
    end

    local now = GetTime()
    local remaining = (meta.start + meta.duration) - now

    if remaining <= 0 then
        -- v69: use the full stop path so modifier labels and any satellite
        -- visual state are reconciled even if the cooldown expires while the
        -- game is backgrounded and no action-button refresh occurs.
        fs:SetText("")
        self:StopCooldown(name)

        -- A satellite action button can otherwise remain visually parked until
        -- mouseover/reload if its own cooldown state was not refreshed while
        -- backgrounded. Force its inactive-cooldown visibility off at expiry.
        local parent = holder:GetParent()
        local owner = parent and (parent.CPCCOwner or parent)
        if meta.satellite and owner and owner.SetOnCooldown then
            owner:SetOnCooldown(false)
        end
        return
    end

    local text = formatTime(remaining, meta.satellite)
    FitCooldownText(holder, holder:GetParent(), text, meta.satellite)

    -- v50 diagnostic: capture compact, deduplicated geometry samples silently.
    -- Keep the four role/layout buckets and record representative digit counts.
    local parent = holder:GetParent()
    local _, fontSize = fs:GetFont()
    local w = parent and parent.GetWidth and parent:GetWidth() or 0
    local h = parent and parent.GetHeight and parent:GetHeight() or 0
    local square = ConsolePortBarSetup and ConsolePortBarSetup.useSquareButtons and 1 or 0
    local layout = square == 1 and "MIN" or "DEF"
    local role = meta.satellite and "SAT" or "MAIN"
    local digits = string.len(tostring(text))
    local bucket = layout .. "_" .. role .. "_" .. tostring(digits)
    local diag
    if ConsolePortSettings then
        ConsolePortSettings.CPCCDiagnostic = ConsolePortSettings.CPCCDiagnostic or {}
        diag = ConsolePortSettings.CPCCDiagnostic
    end
    if diag and not diag[bucket] then
        local owner = parent and parent.CPCCOwner
        local ow = (owner and owner.GetWidth and owner:GetWidth()) or (parent and parent.CPCCOwnerWidth) or 0
        local oh = (owner and owner.GetHeight and owner:GetHeight()) or (parent and parent.CPCCOwnerHeight) or 0
        diag[bucket] = string.format("%s %s len%d target=%s frame=%.1fx%.1f owner=%.1fx%.1f font=%.1f text=%s",
            layout, role, digits, tostring(name), w, h, ow, oh, fontSize or 0, tostring(text))
    end

    local r, g, b = chooseColor(remaining)
    fs:SetTextColor(r, g, b)
end

-- One lightweight, throttled updater drives cooldown text in every bar mode.
-- The previous implementation depended on the round-cooldown spinner's OnUpdate,
-- which meant square/slice modes had no reliable text driver and mixed frame objects
-- with string keys in the cooldown tables.
CPCC.driver = CPCC.driver or CreateFrame("Frame")
CPCC.driver.elapsed = 0
CPCC.driver:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.05 then return end
    local tick = self.elapsed
    self.elapsed = 0
    local active = false
    for name, meta in pairs(CPCC.meta) do
        if meta.visible then
            active = true
            CPCC:OnUpdate(name, tick)
        end
    end
    if not active then self:Hide() end
end)
CPCC.driver:Hide()

-- v51 diagnostic is captured silently in ConsolePort SavedVariables.
-- Enable / Disable API
function CPCC:Enable()
    self.db.enabled = true
end

function CPCC:Disable()
    self.db.enabled = false
    if self.driver then self.driver:Hide() end
    for name, holder in pairs(self.texts) do
        if holder then holder:Hide() end
        if self.meta[name] then self.meta[name].visible = false end
    end
end

--[==[

    The RoundCooldown functions here is copy/paste from the post  https://www.wowinterface.com/forums/showthread.php?t=45918 
	(Huge thanks to semlar, zork and Infus for the code.) and from the shine animation of the OmniCC AddOn!! thanks to https://www.curseforge.com/members/tullamods

	Cooldown animations on 3.3.5a are squared and there is no way to make it round (no SetMask function available) like
    in newer wow builds, so I had to find a way on how to make custom round cooldown and this is the result of my research.
--]==]

function CPAPI.RoundCooldown_OnLoad(self)
	if(not self:GetParent().roundcd) then
		self:GetParent().roundcd = self
	end

    local cos, sin, pi2, halfpi = math.cos, math.sin, math.rad(360), math.rad(90)
    
    local function Transform(tx, x, y, angle, aspect)
        local c, s = cos(angle), sin(angle)
        local y, oy = y / aspect, 0.5 / aspect
        local ULx, ULy = 0.5 + (x - 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x - 0.5) * s) * aspect
        local LLx, LLy = 0.5 + (x - 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x - 0.5) * s) * aspect
        local URx, URy = 0.5 + (x + 0.5) * c - (y - oy) * s, (oy + (y - oy) * c + (x + 0.5) * s) * aspect
        local LRx, LRy = 0.5 + (x + 0.5) * c - (y + oy) * s, (oy + (y + oy) * c + (x + 0.5) * s) * aspect
        tx:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
    end

    local function OnPlayUpdate(self)
        self:SetScript('OnUpdate', nil)
        self:Pause()
    end

    local function OnPlay(self)
        self:SetScript('OnUpdate', OnPlayUpdate)
    end

    local function SetValue(self, value)
        if value > 1 then value = 1
        elseif value < 0 then value = 0 end

        if self._reverse then
            value = 1 - value
        end

        -- Early exit: don't recalculate if value hasn't meaningfully changed
        -- Threshold of ~0.002 means ~0.7 degrees, imperceptible visually
        local lastValue = self._lastValue
        if lastValue and math.abs(value - lastValue) < 0.002 then return end
        self._lastValue = value

        local q = self._clockwise and (1 - value) or value
        local quadrant
        if q >= 0.75 then quadrant = 1
        elseif q >= 0.5 then quadrant = 2
        elseif q >= 0.25 then quadrant = 3
        else quadrant = 4 end

        if self._quadrant ~= quadrant then
            self._quadrant = quadrant
            local textures = self._textures
            if self._clockwise then
                for i = 1, 4 do CPAPI.SetShown(textures[i], i < quadrant) end
            else
                for i = 1, 4 do CPAPI.SetShown(textures[i], i > quadrant) end
            end
            self._scrollframe:SetAllPoints(textures[quadrant])
        end

        local rads = value * pi2
        if not self._clockwise then rads = -rads + halfpi end
        Transform(self._wedge, -0.5, -0.5, rads, self._aspect)
        self._rotation:SetRadians(-rads)
    end

    local function SetClockwise(self, clockwise)
        self._clockwise = clockwise
    end

    local function SetReverse(self, reverse)
        self._reverse = reverse
    end

    local function OnSizeChanged(self, width, height)
        self._wedge:SetSize(width, height)
        self._aspect = width / height
    end

    local function CreateTextureFunction(func)
        return function(self, ...)
            local textures = self._textures
            for i = 1, 4 do
                local tx = textures[i]
                tx[func](tx, ...)
            end
            self._wedge[func](self._wedge, ...)
        end
    end

    local TextureFunctions = {
        SetTexture   = CreateTextureFunction('SetTexture'),
        SetBlendMode = CreateTextureFunction('SetBlendMode'),
        SetVertexColor = CreateTextureFunction('SetVertexColor'),
    }

    local function CreateSpinner(parent)
        local spinner = CreateFrame('Frame', nil, parent)

        local scrollframe = CreateFrame('ScrollFrame', nil, spinner)
        scrollframe:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
        scrollframe:SetPoint('TOPRIGHT')
        spinner._scrollframe = scrollframe

        local scrollchild = CreateFrame('frame', nil, scrollframe)
        scrollframe:SetScrollChild(scrollchild)
        scrollchild:SetAllPoints(scrollframe)

        local wedge = scrollchild:CreateTexture()
        wedge:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
        spinner._wedge = wedge

        local trTexture = spinner:CreateTexture()
        trTexture:SetPoint('BOTTOMLEFT', spinner, 'CENTER')
        trTexture:SetPoint('TOPRIGHT')
        trTexture:SetTexCoord(0.5, 1, 0, 0.5)

        local brTexture = spinner:CreateTexture()
        brTexture:SetPoint('TOPLEFT', spinner, 'CENTER')
        brTexture:SetPoint('BOTTOMRIGHT')
        brTexture:SetTexCoord(0.5, 1, 0.5, 1)

        local blTexture = spinner:CreateTexture()
        blTexture:SetPoint('TOPRIGHT', spinner, 'CENTER')
        blTexture:SetPoint('BOTTOMLEFT')
        blTexture:SetTexCoord(0, 0.5, 0.5, 1)

        local tlTexture = spinner:CreateTexture()
        tlTexture:SetPoint('BOTTOMRIGHT', spinner, 'CENTER')
        tlTexture:SetPoint('TOPLEFT')
        tlTexture:SetTexCoord(0, 0.5, 0, 0.5)

        spinner._textures  = {trTexture, brTexture, blTexture, tlTexture}
        spinner._quadrant  = nil
        spinner._clockwise = true
        spinner._reverse   = false
        spinner._aspect    = 1
        spinner._lastValue = nil  -- cache for delta check
        spinner:HookScript('OnSizeChanged', OnSizeChanged)

        for method, func in pairs(TextureFunctions) do
            spinner[method] = func
        end

        spinner.SetClockwise = SetClockwise
        spinner.SetReverse   = SetReverse
        spinner.SetValue     = SetValue

        local group    = wedge:CreateAnimationGroup()
        local rotation = group:CreateAnimation('Rotation')
        spinner._rotation = rotation
        spinner._group    = group
        rotation:SetDuration(0)
        rotation:SetEndDelay(1)
        rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
        group:SetScript('OnPlay', OnPlay)
        group:Play()
        return spinner
    end

    self.spinner = CreateSpinner(self:GetParent())
    self.spinner:SetAllPoints()
    self.spinner:SetTexture("Interface\\AddOns\\ConsolePortBar\\Textures\\cooldown")
    self.spinner:SetClockwise(false)
    self.spinner:SetReverse(true)
    self.spinner:SetAlpha(0)

    local spinner   = self.spinner
    local updateFrame = CreateFrame('Frame')
    spinner.f = updateFrame

    local function OnUpdate(f, elapsed)
		local button = self:GetParent()
		if (button and button.isSquareMode) or (button and (not button.isSquareMode and button._sliceMaskContainer)) then 
			-- Stop the spinner and exit
			if f.timespent then f.timespent = nil end
			return  
		end
		
        local ts = f.timespent
        if ts == nil then return end

        ts = ts + elapsed
        if ts >= f.duration then
            f.timespent = nil
            if f.cooldownFrame:IsShown() then
                f.endanimation.Start()
            end

           	CPCC:StopCooldown(self)
            return
        end
        f.timespent = ts
        spinner:SetValue(ts / f.duration)
    end

    updateFrame:SetScript('OnUpdate', OnUpdate)

    local function endanimation_OnFinished(self)
        local parent = self:GetParent()
        if parent:IsShown() then parent:Hide() end
    end

    local function CreateShineAnimation(endanimationFrame)
        local g = endanimationFrame:CreateAnimationGroup()
        g:SetLooping('NONE')
        g:SetScript('OnFinished', endanimation_OnFinished)

        local startTrans = g:CreateAnimation('Alpha')
        startTrans:SetChange(-1)
        startTrans:SetDuration(0)
        startTrans:SetOrder(0)

        local grow = g:CreateAnimation('Scale')
        grow:SetOrigin('CENTER', 0, 0)
        grow:SetDuration(0.8/2)
        grow:SetOrder(1)

        local brighten = g:CreateAnimation('Alpha')
        brighten:SetChange(1)
        brighten:SetDuration(0.8/2)
        brighten:SetOrder(1)

        local shrink = g:CreateAnimation('Scale')
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

    self.endanimation = CreateFrame('Frame', nil, self:GetParent())
    self.endanimation:Hide()
    self.endanimation:SetScript('OnHide', endAnimOnHide)
    self.endanimation:SetAllPoints()
    self.endanimation.animation = CreateShineAnimation(self.endanimation)
    self.endanimation.Start = function() CooldownEndAnimStart(self.endanimation) end

    updateFrame.endanimation  = self.endanimation
    updateFrame.cooldownFrame = _G[self:GetParent():GetName() .. "Cooldown"]

    local icon = self.endanimation:CreateTexture(nil, 'OVERLAY')
    icon:SetPoint('CENTER')
    icon:SetBlendMode('ADD')
    icon:SetAllPoints(self.endanimation)
    icon:SetTexture("Interface\\Cooldown\\star4")
end

function CPAPI.RoundCooldown_OnSetCooldown(self, start, duration)
    local roundcd = self:GetParent().roundcd

	local button = self:GetParent()
    if (button and button.isSquareMode) then 
        self:SetAlpha(1)
        if roundcd and roundcd.spinner then roundcd.spinner:SetAlpha(0) end
        if CPCC.db.enabled then CPCC:StartCooldown(self, start, duration) end
        return
	elseif button and (not button.isSquareMode and button._sliceMaskContainer)  then 
        if roundcd and roundcd.spinner then roundcd.spinner:SetAlpha(0) end
		ConsolePortBar.SliceMask:StartCooldown(button, start, duration)

		-- v56: restore the proven Default/slice CPCC target used by v26: the
		-- action button itself. Later sizing work moved this to the tiny internal
		-- cooldown frame, while the hide path continued addressing the button.
		-- Keep the proven render target and layer the new dynamic fitter on it.
		if CPCC.db.enabled then
			button.CPCCOwner = button
			button.CPCCOwnerWidth = button:GetWidth()
			button.CPCCOwnerHeight = button:GetHeight()
			button.CPCCOwnerScale = button:GetScale() or 1
			local showModifierCooldown = ConsolePortBarSetup and ConsolePortBarSetup.showmodifiercooldowns
			local currentModifier = (button.header and button.header:GetAttribute('state')) or ConsolePort:GetCurrentModifier() or ''
			button.CPCCSatellite = showModifierCooldown and button.mod and button.mod ~= '' and button.mod ~= currentModifier and true or false
			CPCC:StartCooldown(button, start, duration)
		end
		return
    end
    
    local f = roundcd.spinner.f
    f.start = start
    f.duration = duration
    roundcd.spinner._lastValue = nil
    roundcd.spinner:SetAlpha(1)
    f.timespent = GetTime() - start

    if CPCC.db.enabled then
        if roundcd then
            CPCC:CreateTextFor(roundcd)
            CPCC:StartCooldown(roundcd, start, duration)
        end
    end
end

function CPAPI.RoundCooldown_OnShowCooldown(self)
	local button = self:GetParent()
    if (button and button.isSquareMode) then  
        self:SetAlpha(1)
		return
	elseif button and (not button.isSquareMode and button._sliceMaskContainer)  then
		return
	end

    self:GetParent().roundcd.spinner:SetAlpha(1)
    CPCC:CreateTextFor(self:GetParent().roundcd)
end

function CPAPI.RoundCooldown_OnHideCooldown(self)
	local button = self:GetParent()
    if (button and button.isSquareMode) then 
        CPCC:StopCooldown(self)
		return
	elseif button and (not button.isSquareMode and button._sliceMaskContainer)  then
		ConsolePortBar.SliceMask:StopCooldown(button)
    	CPCC:StopCooldown(button:GetName())
		return
	end

    self:GetParent().roundcd.spinner:SetAlpha(0)
    CPCC:StopCooldown(self:GetParent().roundcd)
end

------------------------------------------------------------------------------------
-- Custom client workarounds
------------------------------------------------------------------------------------
CPAPI.CustomFrames = CPAPI.CustomFrames or {}

CPAPI.CustomFrames.Ascension = {
    ["SpellButton1"]   = "AscensionSpellbookFrameContentSpellsSpellButton1",
    ["SpellBookFrame"] = "AscensionSpellbookFrame",
    ["SpellBookOwner"] = "AscensionSpellbookFrameContentSpells",
}

-- Check if the client running is a customized client
function CPAPI.IsCustomClient()
    if AscensionTimer and GetAscensionDonationPoints then
        return "Ascension"
    end
    return nil
end

-- Get the custom frame by name, returns nil if not found or not a custom client.
function CPAPI.GetCustomFrame(name)
    local client = CPAPI.IsCustomClient()
    if not client then return nil end

    local frames = CPAPI.CustomFrames[client]
    return frames and _G[frames[name]] or nil
end
