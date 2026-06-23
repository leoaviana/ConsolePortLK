---------------------------------------------------------------
-- Nameplate.lua: Nameplate vanity modifications
---------------------------------------------------------------
-- Three execution paths:
--
--   PATH A  (CompactUnitMixin exists)
--     Hook into existing nameplate unitFrames.
--     No overlay built - Original owns the visuals.
--     We only apply ConsolePort mods: class color, NPC
--     subtitle, nameOnly, LevelFrame hide, fade-in.
--
--   PATH B  (AwesomeWotlkLib: C_NamePlate exists, no CompactUnitMixin exists)
--     Build our own compact overlay per nameplate driven by
--     NAME_PLATE_UNIT_ADDED/REMOVED events. Full feature set.
--
--   PATH C  (Standard 3.3.5a: no extras)
--     Same compact overlay as PATH B, detected via WorldFrame
--     children scan (TidyPlates method). No unit tokens so
--     threat glow and subtitle are absent.
---------------------------------------------------------------

local _, db = ...
local CPAPI  = db.CPAPI
local FadeIn = select(2, ...).GetFaders()

---------------------------------------------------------------
-- Path detection
---------------------------------------------------------------
local HAS_COMPACT_UNIT_MIXIN     = CompactUnitMixin ~= nil
local HAS_NAMEPLATE_API = C_NamePlate and C_NamePlate.GetNamePlateForUnit

---------------------------------------------------------------
-- Shared: NPC subtitle / guild scraper
---------------------------------------------------------------
local PATTERNS = {}
for _, p in ipairs({
    TOOLTIP_UNIT_LEVEL,
    TOOLTIP_UNIT_LEVEL_TYPE,
    TOOLTIP_UNIT_LEVEL_CLASS,
    TOOLTIP_UNIT_LEVEL_CLASS_TYPE,
}) do PATTERNS[#PATTERNS+1] = ('^%s$'):format(p:gsub('%%.%$?s?', '.+')) end

local SCRAPE = CreateFrame('GameTooltip', 'CPNameplateScraper', UIParent, 'GameTooltipTemplate')
local SCRAPE_LINE

local function UpdateScrapeLine()
    SCRAPE_LINE = _G[SCRAPE:GetName() .. 'TextLeft' .. (GetCVarBool('colorblindmode') and 3 or 2)]
end
UpdateScrapeLine()
SCRAPE:RegisterEvent('CVAR_UPDATE')
SCRAPE:SetScript('OnEvent', UpdateScrapeLine)

function SCRAPE:GetNPCTitle(unit)
    self:SetOwner(UIParent, 'ANCHOR_NONE')
    self:SetUnit(unit)
    local text = SCRAPE_LINE and SCRAPE_LINE:GetText()
    self:Hide()
    if not text then return end
    for _, pat in ipairs(PATTERNS) do
        if text:find(pat) then return end
    end
    return ('|cffffe00a%s|r'):format(text)
end

function SCRAPE:ScrapeUnitTitle(unit)
    if UnitIsPlayer(unit) then
        if GetCVarBool('UnitNameFriendlyPlayerName') then
            local guild = GetGuildInfo(unit)
            return guild ~= 0 and guild or nil
        end
    else
        return self:GetNPCTitle(unit)
    end
end

---------------------------------------------------------------
-- Shared: per-fontstring mod cache
---------------------------------------------------------------
local cache = {}
local function ckey(o, id) return tostring(o)..tostring(id) end
local function store(o, id, v)    local k=ckey(o,id); if not cache[k] then cache[k]=v end; return v end
local function retrieve(o, id)   return cache[ckey(o,id)] end
local function extract(o, id)    local k=ckey(o,id); local v=cache[k]; cache[k]=nil; return v end

---------------------------------------------------------------
-- Shared: settings (populated by RegisterVarCallback)
---------------------------------------------------------------
local nameOnly, showAllEnemies
local textScale, fadeInTime, useCC = 1

---------------------------------------------------------------
-- Shared: object modifier table
-- Runs against a unitFrame
-- Keys must match child names on the unitFrame.
---------------------------------------------------------------
local object = {}

function object:name(ignore, unit, _, _, isPlayer, isUnitCC)
    extract(self, 'cc')
    -- store original font size once, permanently on the object
    if not self._baseSize then
        local _, size = self:GetFont()
        self._baseSize = size
    end
    if isPlayer or isUnitCC then
        store(self, 'color', {self:GetTextColor()})
        if useCC then
            local cc = CPAPI:GetClassColor(select(2, UnitClass(unit)))
            if cc then
                store(self, 'cc', cc)
                self:SetTextColor(cc.r, cc.g, cc.b)
            end
        end
        local factor = (isUnitCC and not isPlayer) and 0.6 or 0.8
        local font, _, flags = self:GetFont()
        self:SetFont(font, self._baseSize * factor * textScale, flags)
    else
        local co = extract(self, 'color')
        if co then self:SetTextColor(unpack(co)) end
        local font, _, flags = self:GetFont()
        self:SetFont(font, self._baseSize * textScale, flags)
    end
end

function object:statusText(ignore, unit, _, _, isPlayer, isUnitCC, _, isActive)
    -- stubed, at least for now.

    --[==[]
    if not self._baseSize then
        local _, size = self:GetFont()
        self._baseSize = size
    end
    if isActive and not ignore and not isUnitCC then
        store(self, 'alpha', self:GetAlpha())
        store(self, 'anchor', {self:GetPoint()})
        self:SetAlpha(isPlayer and 0.5 or 1)
        local font, _, flags = self:GetFont()
        self:SetFont(font, self._baseSize * 0.75 * textScale, flags)
        self:ClearAllPoints()
        self:SetPoint('CENTER', 0, -4 * textScale)
        self:SetText(SCRAPE:ScrapeUnitTitle(unit))
        self:Show()
    else
        local al = extract(self, 'alpha')
        local anchor = extract(self, 'anchor')
        if al then self:SetAlpha(al) end
        local font, _, flags = self:GetFont()
        self:SetFont(font, self._baseSize * textScale, flags)
        if anchor then
            self:ClearAllPoints()
            self:SetPoint(unpack(anchor))
        end
    end
    --]==]
end

function object:healthBar(ignore)
    CPAPI.SetShown(self, ignore)
end

function object:LevelFrame(ignore)
    CPAPI.SetShown(self, ignore)
end

function object:ClassificationFrame(_, _, _, _, _, _, _, isActive)
    if not isActive then self:Hide() end
end

function object:RunModifications(...)
    for key, modify in pairs(object) do
        local frame = self[key]
        if frame then modify(frame, ...) end
    end
end

local function ApplyModifiers(unitFrame, unit)
    if not unitFrame then return end
    local isFriend = UnitIsFriend('player', unit)
    local isTarget = UnitIsUnit('target', unit)
    local isPlayer = UnitIsPlayer(unit)
    local isUnitCC = UnitPlayerControlled(unit) and not isPlayer
    local isActive = unitFrame.name and unitFrame.name:IsShown()
    local inCombat = (showAllEnemies and UnitCanAttack('player', unit))
                  or CPAPI:UnitThreatSituation('player', unit)
    local ignore   = inCombat or not (isFriend or not isTarget)
    if not (isTarget or inCombat) then
        FadeIn(unitFrame, fadeInTime or 0, 0, 1)
    end
    object.RunModifications(unitFrame, ignore, unit, isFriend, isTarget,
                            isPlayer, isUnitCC, inCombat, isActive)
end

---------------------------------------------------------------
-- Public: SetNameOnlyForUnit
-- Called from TargetAI events for target / mouseover.
---------------------------------------------------------------

-- forward-declared; PlatesVisible defined later in PATH B/C block
local PlatesVisible
function ConsolePort:SetNameOnlyForUnit(unit)
    if not nameOnly then return end
    if UnitIsUnit('player', unit) then return end

    local plate, unitFrame

    if HAS_NAMEPLATE_API then
        plate = C_NamePlate.GetNamePlateForUnit(unit)
        if not plate then return end
        if HAS_COMPACT_UNIT_MIXIN then
            unitFrame = plate.UnitFrame or plate.unitFrame
                     or plate.nameplate or plate
        else
            unitFrame = plate.cp
        end
    else
        -- PATH C heuristic
        if PlatesVisible then
            if unit == 'target' then
                for p in pairs(PlatesVisible) do
                    if p:GetAlpha() >= 0.99 then plate = p; break end
                end
            elseif unit == 'mouseover' then
                for p in pairs(PlatesVisible) do
                    if p.cp and p.cp.rawHighlight:IsShown() then
                        plate = p; break
                    end
                end
            end
        end
        unitFrame = plate and plate.cp
    end

    if not unitFrame then return end
    if not unitFrame.name or not unitFrame.name:IsShown() then return end

    ApplyModifiers(unitFrame, unit)
    return plate
end

---------------------------------------------------------------
-- Var callbacks
---------------------------------------------------------------
ConsolePort:RegisterVarCallback('nameplateCC',
    function(v) useCC           = v end)
ConsolePort:RegisterVarCallback('nameplateFadeIn',
    function(v) fadeInTime      = v end)
ConsolePort:RegisterVarCallback('nameplateNameOnly',
    function(v) nameOnly        = v end)
ConsolePort:RegisterVarCallback('nameplateTextScale',
    function(v) textScale       = v end)
ConsolePort:RegisterVarCallback('nameplateShowAllEnemies',
    function(v) showAllEnemies  = v end)

---------------------------------------------------------------
-- PATH A: CompactUnitMixin hooks
-- Hook CompactUnitMixin.UpdateName to re-apply CC color.
-- Direct method wrap + pcall so future API changes
-- fail silently.
---------------------------------------------------------------
if HAS_COMPACT_UNIT_MIXIN then
    local orig = CompactUnitMixin.UpdateName
    if orig then
        CompactUnitMixin.UpdateName = function(self, ...)
            local ok = pcall(orig, self, ...)
            if not ok then
                CompactUnitMixin.UpdateName = orig
                return
            end
            if nameOnly and self.name and self.displayedUnit then
                if not UnitIsUnit(self.displayedUnit, 'mouseover') then
                    local cc = retrieve(self.name, 'cc')
                    --if cc then self.name:SetVertexColor(unpack(cc)) end
                end
            end
        end
    end
    -- original frame owns all visuals. Nothing more to do.
    return
end

---------------------------------------------------------------
-- PATH B / C: Our own compact nameplate overlay.
-- Frame hierarchy:
--
--   plate (engine nameplate)
--   └── cp  (our overlay, SetAllPoints on plate)
--       ├── healthBar        (StatusBar)
--       │   ├── border       (NamePlateFullBorderTemplate equivalent)
--       │   │   └── Texture  (atlas: nameplates-bar-background-white)
--       │   ├── background   (Texture, white fill behind bar)
--       │   ├── Elements     (Frame, SetAllPoints)
--       │   │   └── statusText (FontString, centered in bar)
--       │   ├── aggroHighlight (Frame)
--       │   │   └── Texture  (UI-TargetingFrame-BarFill, red, ADD)
--       │   └── selectionHighlight (Texture, BarFill, alpha .25, ADD)
--       ├── castBar          (StatusBar, hidden by default)
--       │   ├── Background   (Texture, dark)
--       │   ├── Text         (FontString)
--       │   ├── BorderShield (Texture, atlas: nameplates-InterruptShield)
--       │   ├── Icon         (Texture, spell icon)
--       │   ├── Spark        (Texture, UI-CastingBar-Spark, ADD)
--       │   └── Flash        (Texture, UI-TargetingFrame-BarFill, ADD)
--       ├── name             (FontString, above healthBar)
--       ├── ClassificationFrame (Frame, left of healthBar)
--       │   └── classificationIndicator (Texture)
--       ├── LevelFrame       (Frame, right of healthBar, hidden default)
--       │   ├── Icon         (Texture, atlas: nameplates-icon-level)
--       │   ├── Skull        (Texture, UI-TargetingFrame-Skull, hidden)
--       │   └── Text         (FontString)
--       └── RaidTargetFrame  (Frame, left of healthBar offset -15)
--           └── RaidTargetIcon (Texture, UI-RaidTargetingIcons, hidden)
---------------------------------------------------------------

---------------------------------------------------------------
-- Textures
---------------------------------------------------------------
local EMPTY_TEX   = 'Interface\\Addons\\ConsolePort\\Textures\\Empty'
-- Blizzard textures present in standard WotLK client:
local TEX_BARFILL   = 'Interface\\TargetingFrame\\UI-TargetingFrame-BarFill'
local TEX_STATUSBAR = 'Interface\\TargetingFrame\\UI-StatusBar'
local TEX_SPARK     = 'Interface\\CastingBar\\UI-CastingBar-Spark'
local TEX_SKULL     = 'Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull'
local TEX_RAID      = 'Interface\\TargetingFrame\\UI-RaidTargetingIcons'
-- Atlas names:
local ATLAS_BAR_BG    = 'nameplates-bar-background-white'
local ATLAS_SHIELD    = 'nameplates-InterruptShield'
local ATLAS_LEVEL_BG  = 'nameplates-icon-level'
local ATLAS_ELITE     = 'nameplates-icon-elite-gold'
local ATLAS_RAREELITE = 'nameplates-icon-elite-silver'
-- SetAtlas is not available in standard WotLK.
-- We use SetTexture with the atlas fallback path for PATH B/C.
-- On standard WotLK these will show as blank until textures
-- are extracted and placed as standalone files.
-- Atlas data for nameplate textures
-- Format: { texturePath, width, height, left, right, top, bottom }
-- Texture files placed at: Interface\AddOns\ConsolePort\Textures\Interface\Nameplates\
local NAMEPLATE_ATLAS = {
    ['nameplates-bar-background-white'] = {
        'Interface\\AddOns\\ConsolePort\\Textures\\Interface\\Nameplates',
        254, 13, 0.00390625, 0.996094, 0.0078125, 0.109375
    },
    ['nameplates-InterruptShield'] = {
        'Interface\\AddOns\\ConsolePort\\Textures\\Interface\\Nameplates',
        14, 16, 0.929688, 0.984375, 0.234375, 0.359375
    },
    ['nameplates-icon-elite-gold'] = {
        'Interface\\AddOns\\ConsolePort\\Textures\\Interface\\Nameplates',
        37, 35, 0.00390625, 0.148438, 0.234375, 0.507812
    },
    ['nameplates-icon-elite-silver'] = {
        'Interface\\AddOns\\ConsolePort\\Textures\\Interface\\Nameplates',
        37, 35, 0.00390625, 0.148438, 0.523438, 0.796875
    },
    ['nameplates-icon-level'] = {
        'Interface\\AddOns\\ConsolePort\\Textures\\Interface\\LevelFrame',
        54, 54, 0, 0.84375, 0, 0.84375
    },
}

local function SafeSetAtlas(tex, atlas)
    local data = NAMEPLATE_ATLAS[atlas]
    if not data then return end
    local file, w, h, left, right, top, bottom = data[1], data[2], data[3], data[4], data[5], data[6], data[7]
    tex:SetTexture(file)
    tex:SetTexCoord(left, right, top, bottom)
    tex:SetSize(w, h)
end

---------------------------------------------------------------
-- Dimensions
---------------------------------------------------------------
local BAR_W, BAR_H    = 110, 4
local CAST_W, CAST_H  = 110, 8   -- castBar same width as healthBar
local LEVEL_W, LEVEL_H = 18, 18  -- LevelFrame size from XML
local CLASS_W, CLASS_H = 14, 13  -- ClassificationFrame size from XML
local RAID_W, RAID_H  = 22, 22   -- RaidTargetFrame size from XML
local NAME_FONT_H     = 11       -- SystemFont_Shadow_Med1 equivalent
local STATUS_FONT_H   = 10       -- GameFontHighlight equivalent
local LEVEL_FONT_H    = 8        -- GameFontWhiteTiny2 equivalent
local FONT            = 'Fonts\\FRIZQT__.TTF'

---------------------------------------------------------------
-- Color helpers
---------------------------------------------------------------
local C_FRIENDLY  = {0.0,  1.0,  0.0}
local C_NEUTRAL   = {1.0,  1.0,  0.0}
local C_HOSTILE   = {1.0,  0.0,  0.0}
local C_PLAYER    = {0.0,  0.44, 0.87}
local C_TAPPED    = {0.65, 0.65, 0.65}

local function GetReactionColor(r, g, b)
    if     r < .01 and b < .01 and g > .99 then return C_FRIENDLY, 'FRIENDLY', 'NPC'
    elseif r < .01 and b > .99 and g < .01 then return C_PLAYER,   'FRIENDLY', 'PLAYER'
    elseif r > .99 and b < .01 and g > .99 then return C_NEUTRAL,  'NEUTRAL',  'NPC'
    elseif r > .99 and b < .01 and g < .01 then return C_HOSTILE,  'HOSTILE',  'NPC'
    else                                         return C_PLAYER,   'HOSTILE',  'PLAYER'
    end
end

local function MatchClassColor(r, g, b)
    for _, c in pairs(RAID_CLASS_COLORS) do
        if abs(c.r-r)<.05 and abs(c.g-g)<.05 and abs(c.b-b)<.05 then return c end
    end
end

---------------------------------------------------------------
-- Registry
---------------------------------------------------------------
PlatesVisible = {}  -- assigned here so SetNameOnlyForUnit can see it
local Plates      = {}
local GUIDToPlate = {}
local numChildren = -1
local InCombat    = false
local HasTarget   = false

---------------------------------------------------------------
-- Raw WotLK nameplate detection (TidyPlates method)
---------------------------------------------------------------
local function IsRawNameplate(frame)
    local r = frame:GetRegions()
    return r
        and r:GetObjectType() == 'Texture'
        and r:GetTexture() == 'Interface\\TargetingFrame\\UI-TargetingFrame-Flash'
end

---------------------------------------------------------------
-- Build overlay
---------------------------------------------------------------

-- based on tidyplates
local function CreateStatusBar(parent, frameLevel)
    local frame = CreateFrame('Frame', nil, parent)
    frame.Value, frame.MinVal, frame.MaxVal, frame.Orientation = 1, 0, 1, 'HORIZONTAL'
    frame.Bar = frame:CreateTexture(nil, 'ARTWORK')

    local function UpdateBar(self)
        local range = self.MaxVal - self.MinVal
        local value = self.Value - self.MinVal
        local dim   = self.Dim or 1
        local frac  = (range > 0 and value > 0 and range >= value) and (value / range) or 0.01
        if self.Orientation == 'VERTICAL' then
            self.Bar:SetHeight(dim * frac)
            self.Bar:SetTexCoord(0, 1, 1 - frac, 1)
        else
            self.Bar:SetWidth(dim * frac)
            self.Bar:SetTexCoord(0, frac, 0, 1)
        end
    end

    local function UpdateSize(self)
        self.Dim = self.Orientation == 'VERTICAL' and self:GetHeight() or self:GetWidth()
        UpdateBar(self)
    end

    frame.Bar:SetPoint('TOPLEFT')
    frame.Bar:SetPoint('BOTTOMLEFT')

    function frame:SetStatusBarTexture(tex)  self.Bar:SetTexture(tex) end
    function frame:GetStatusBarTexture()     return self.Bar end
    function frame:SetStatusBarColor(r,g,b,a) self.Bar:SetVertexColor(r,g,b,a or 1) end
    function frame:GetStatusBarColor()       return self.Bar:GetVertexColor() end
    function frame:SetValue(v)
        if v >= self.MinVal and v <= self.MaxVal then self.Value = v end
        UpdateBar(self)
    end
    function frame:GetValue()                return self.Value end
    function frame:SetMinMaxValues(lo, hi)
        if not (lo and hi) then return end
        if hi > lo then self.MinVal, self.MaxVal = lo, hi
        else             self.MinVal, self.MaxVal = 0, 1 end
        if self.Value > self.MaxVal then self.Value = self.MaxVal
        elseif self.Value < self.MinVal then self.Value = self.MinVal end
        UpdateBar(self)
    end
    function frame:GetMinMaxValues()         return self.MinVal, self.MaxVal end
    function frame:SetOrientation(o)
        self.Bar:ClearAllPoints()
        if o == 'VERTICAL' then
            self.Orientation = 'VERTICAL'
            self.Bar:SetPoint('BOTTOMLEFT')
            self.Bar:SetPoint('BOTTOMRIGHT')
        else
            self.Orientation = 'HORIZONTAL'
            self.Bar:SetPoint('TOPLEFT')
            self.Bar:SetPoint('BOTTOMLEFT')
        end
        UpdateSize(self)
    end

    frame:SetScript('OnSizeChanged', UpdateSize)
    if frameLevel then frame:SetFrameLevel(frameLevel) end
    return frame
end


local function BuildOverlay(plate)
    local fl = plate:GetFrameLevel()

    -- Raw WotLK nameplate regions (fixed order)
    local threatglow, healthborder, castborder, castnostop,
          spellicon, highlight, rawName, rawLevel,
          dangerskull, raidicon, eliteicon = plate:GetRegions()

    -- Raw bars
    local rawHP, rawCast = plate:GetChildren()

    -- Read classification BEFORE zeroing anything
    local classification = 'none'
    if dangerskull:IsShown()  then classification = 'worldboss'
    elseif eliteicon:IsShown() then classification = 'elite' end

    -- Zero all default Blizzard visuals
    for _, region in ipairs({threatglow, highlight, healthborder, castborder,
            castnostop, dangerskull, eliteicon, spellicon}) do
        region:SetTexCoord(0, 0, 0, 0)
    end
    raidicon:SetAlpha(0)
    rawName:SetWidth(0.01)
    rawLevel:SetWidth(0.01)
    rawHP:SetStatusBarTexture(EMPTY_TEX)
    rawCast:SetStatusBarTexture(EMPTY_TEX)

    -------------------------------------------------------
    -- cp: our overlay container, mirrors UnitFrame button
    -------------------------------------------------------
    local cp = CreateFrame('Frame', nil, plate)
    cp:SetAllPoints(plate)
    cp:SetFrameLevel(fl + 2)

    -------------------------------------------------------
    -- healthBar  (StatusBar)
    -------------------------------------------------------
    local healthBar = CreateStatusBar(cp, fl + 3)
    healthBar:SetSize(BAR_W, BAR_H)
    healthBar:SetPoint('BOTTOM', cp, 'BOTTOM', 0, 8)
    healthBar:SetStatusBarTexture(TEX_BARFILL)

    -- background (white texture behind bar)
    local hpBg = healthBar:CreateTexture(nil, 'BORDER')
    hpBg:SetAllPoints()
    hpBg:SetTexture(1, 1, 1, 1)
    hpBg:SetVertexColor(0.15, 0.15, 0.15, 1)
    healthBar.background = hpBg

    -- mouseover highlight, sized to our bar
    local mouseoverHL = healthBar:CreateTexture(nil, 'ARTWORK')
    mouseoverHL:SetTexture(TEX_BARFILL)
    mouseoverHL:SetAlpha(0.15)
    mouseoverHL:SetBlendMode('ADD')
    mouseoverHL:SetAllPoints(healthBar)
    mouseoverHL:Hide()
    healthBar.mouseoverHL = mouseoverHL
    cp.mouseoverHL = mouseoverHL

    -- Texture uses atlas nameplates-bar-background-white
    -- positioned at -1,1 / 1,-1 around healthBar
    local borderFrame = CreateFrame('Frame', nil, healthBar)
    borderFrame:SetPoint('TOPLEFT',     healthBar, -1,  1)
    borderFrame:SetPoint('BOTTOMRIGHT', healthBar,  1, -1)
    borderFrame:SetFrameLevel(fl + 5)

    local borderTex = borderFrame:CreateTexture(nil, 'BACKGROUND')
    borderTex:SetPoint('TOPLEFT',     borderFrame, -1,  1)
    borderTex:SetPoint('BOTTOMRIGHT', borderFrame,  1, -1)
    SafeSetAtlas(borderTex, ATLAS_BAR_BG)
    borderTex:SetVertexColor(0, 0, 0, 0.5)
    borderFrame.Texture = borderTex

    -- SetVertexColor proxy so CompactUnitMixin border color calls work
    function borderFrame:SetVertexColor(r, g, b, a)
        self.Texture:SetVertexColor(r, g, b, a)
    end

    healthBar.border = borderFrame

    -- Elements frame (SetAllPoints on healthBar, holds statusText)
    local elements = CreateFrame('Frame', nil, healthBar)
    elements:SetAllPoints()
    elements:SetFrameLevel(fl + 4)

    local statusText = elements:CreateFontString(nil, 'OVERLAY')
    statusText:SetFont(FONT, STATUS_FONT_H, 'OUTLINE')
    statusText:SetPoint('CENTER', elements, 'CENTER', 0, 1)
    statusText:SetJustifyH('CENTER')
    statusText:SetTextColor(1, 1, 1)
    elements.statusText = statusText
    healthBar.Elements = elements

    -- selectionHighlight (BarFill, alpha .25, ADD blend, anchored to healthBar)
    local selectionHL = healthBar:CreateTexture(nil, 'ARTWORK')
    selectionHL:SetTexture(TEX_BARFILL)
    selectionHL:SetAlpha(0.25)
    selectionHL:SetBlendMode('ADD')
    selectionHL:SetAllPoints(healthBar)
    selectionHL:Hide()
    healthBar.selectionHighlight = selectionHL

    -- aggroHighlight frame (anchored to healthBar, BarFill red ADD)
    local aggroFrame = CreateFrame('Frame', nil, healthBar)
    aggroFrame:SetPoint('TOPLEFT',     healthBar)
    aggroFrame:SetPoint('BOTTOMRIGHT', healthBar)
    aggroFrame:SetFrameLevel(fl + 4)

    local aggroTex = aggroFrame:CreateTexture(nil, 'OVERLAY')
    aggroTex:SetTexture(TEX_BARFILL)
    aggroTex:SetAllPoints()
    aggroTex:SetBlendMode('ADD')
    aggroTex:SetVertexColor(1, 0, 0)
    aggroTex:Hide()
    aggroFrame.Texture = aggroTex
    healthBar.aggroHighlight = aggroFrame

    -------------------------------------------------------
    -- castBar  (StatusBar, hidden by default)
    -- Anchored TOP of healthBar BOTTOM with offset -3
    -------------------------------------------------------
    local castBar = CreateStatusBar(cp, fl + 3)
    castBar:SetSize(CAST_W, CAST_H)
    castBar:SetPoint('TOP', healthBar, 'BOTTOM', 0, -3)
    castBar:SetStatusBarTexture(TEX_STATUSBAR)
    castBar:SetStatusBarColor(1, 0.7, 0)
    castBar:Hide()

    local castBg = castBar:CreateTexture(nil, 'BACKGROUND')
    castBg:SetAllPoints()
    castBg:SetTexture(0.2, 0.2, 0.2, 0.85)
    castBar.Background = castBg

    local castText = castBar:CreateFontString(nil, 'OVERLAY')
    castText:SetFont(FONT, CAST_H - 1, 'OUTLINE')
    castText:SetSize(0, 16)
    castText:SetPoint('CENTER', castBar, 'CENTER', 0, 0)
    castText:SetJustifyH('CENTER')
    castText:SetTextColor(1, 1, 1)
    castBar.Text = castText

    local shieldIcon = castBar:CreateTexture(nil, 'OVERLAY')
    shieldIcon:SetSize(10, 12)
    shieldIcon:SetPoint('CENTER', castBar, 'LEFT', -2, -1)
    SafeSetAtlas(shieldIcon, ATLAS_SHIELD)
    shieldIcon:Hide()
    castBar.BorderShield = shieldIcon

    local castIcon = castBar:CreateTexture(nil, 'OVERLAY')
    castIcon:SetSize(10, 10)
    castIcon:SetPoint('LEFT', castBar, 'LEFT', -2, -1)
    castIcon:Hide()
    castBar.Icon = castIcon

    local castSpark = castBar:CreateTexture(nil, 'OVERLAY')
    castSpark:SetSize(16, 16)
    castSpark:SetPoint('CENTER', castBar, 'CENTER', 0, 0)
    castSpark:SetTexture(TEX_SPARK)
    castSpark:SetBlendMode('ADD')
    castBar.Spark = castSpark

    local castFlash = castBar:CreateTexture(nil, 'OVERLAY')
    castFlash:SetAllPoints()
    castFlash:SetTexture(TEX_BARFILL)
    castFlash:SetBlendMode('ADD')
    castBar.Flash = castFlash

    -------------------------------------------------------
    -- name  (FontString, SystemFont_Shadow_Med1 equiv)
    -- Anchored BOTTOM of healthBar TOP with y=4 (from XML)
    -------------------------------------------------------
    local nameText = cp:CreateFontString(nil, 'BORDER')
    nameText:SetFont(FONT, NAME_FONT_H, 'OUTLINE')
    nameText:SetPoint('BOTTOM', healthBar, 'TOP', 0, 4)
    nameText:SetJustifyH('CENTER')
    nameText:SetWordWrap(false)
    nameText:SetWidth(BAR_W + 20)

    -------------------------------------------------------
    -- ClassificationFrame  (left of healthBar)
    -- Size 14x13, holds classificationIndicator texture
    -------------------------------------------------------
    local classFrame = CreateFrame('Frame', nil, cp)
    classFrame:SetSize(CLASS_W, CLASS_H)
    classFrame:SetPoint('RIGHT', healthBar, 'LEFT', 0, 0)
    classFrame:SetFrameLevel(fl + 6) -- HIGH strata equivalent

    local classIndicator = classFrame:CreateTexture(nil, 'OVERLAY')
    classIndicator:SetAllPoints()
    classFrame.classificationIndicator = classIndicator
    classFrame:Hide()

    -------------------------------------------------------
    -- LevelFrame  (right of healthBar, hidden by default)
    -- Size 18x18, anchored LEFT of healthBar RIGHT x=-1
    -- Contains: Icon (atlas nameplates-icon-level),
    --           Skull (UI-TargetingFrame-Skull),
    --           Text (FontString)
    -------------------------------------------------------
    local levelFrame = CreateFrame('Frame', nil, cp)
    levelFrame:SetSize(LEVEL_W, LEVEL_H)
    levelFrame:SetPoint('LEFT', healthBar, 'RIGHT', -1, 0)
    levelFrame:SetFrameLevel(fl + 4)
    levelFrame:Hide()

    local levelIcon = levelFrame:CreateTexture(nil, 'ARTWORK')
    levelIcon:SetAllPoints()
    SafeSetAtlas(levelIcon, ATLAS_LEVEL_BG)
    levelFrame.Icon = levelIcon

    local levelSkull = levelFrame:CreateTexture(nil, 'OVERLAY')
    levelSkull:SetSize(12, 12)
    levelSkull:SetPoint('CENTER', levelFrame, 'CENTER')
    levelSkull:SetTexture(TEX_SKULL)
    levelSkull:Hide()
    levelFrame.Skull = levelSkull

    local levelText = levelFrame:CreateFontString(nil, 'OVERLAY')
    levelText:SetFont(FONT, LEVEL_FONT_H, 'OUTLINE')
    levelText:SetPoint('CENTER', levelFrame, 'CENTER', 0, 0)
    levelText:SetJustifyH('CENTER')
    levelFrame.Text = levelText

    -------------------------------------------------------
    -- RaidTargetFrame  (left of healthBar, offset -15)
    -- Size 22x22, holds RaidTargetIcon texture
    -------------------------------------------------------
    local raidFrame = CreateFrame('Frame', nil, cp)
    raidFrame:SetSize(RAID_W, RAID_H)
    raidFrame:SetPoint('RIGHT', healthBar, 'LEFT', -15, 0)
    raidFrame:SetFrameLevel(fl + 4)

    local raidIcon = raidFrame:CreateTexture(nil, 'ARTWORK')
    raidIcon:SetTexture(TEX_RAID)
    raidIcon:SetAllPoints()
    raidIcon:Hide()
    raidFrame.RaidTargetIcon = raidIcon

    -------------------------------------------------------
    -- questIcon  (above name, hidden by default)
    -------------------------------------------------------
    local questIcon = cp:CreateTexture(nil, 'ARTWORK')
    questIcon:SetPoint('BOTTOM', nameText, 'TOP', 0, 2)
    questIcon:Hide()
    cp.questIcon = questIcon

    -------------------------------------------------------
    -- Store on plate.cp for easy access during updates, and to avoid :GetChildren() calls.
    -------------------------------------------------------
    cp.healthBar           = healthBar
    cp.castBar             = castBar
    cp.name                = nameText
    cp.statusText          = statusText    -- inside healthBar.Elements
    cp.ClassificationFrame = classFrame
    cp.LevelFrame          = levelFrame
    cp.RaidTargetFrame     = raidFrame
    cp.selectionHighlight  = selectionHL
    cp.aggroHighlight      = aggroFrame

    -- Raw refs for reading Blizzard data
    cp.rawHP        = rawHP
    cp.rawCast      = rawCast
    cp.rawName      = rawName
    cp.rawLevel     = rawLevel
    cp.rawRaidicon  = raidicon
    cp.rawHighlight = highlight
    cp.rawDangerskull = dangerskull
    cp.rawEliteicon   = eliteicon

    -- State
    cp.classification = classification
    cp.unitToken      = nil
    cp.guid           = nil

    plate.cp = cp
end

---------------------------------------------------------------
-- Per-frame visual update
---------------------------------------------------------------
local function UpdateRaidTarget(plate)
    local cp   = plate.cp
    local icon = cp.RaidTargetFrame.RaidTargetIcon
    -- With unit token (PATH B):
    if cp.unitToken then
        local idx = GetRaidTargetIndex(cp.unitToken)
        if idx and not UnitIsUnit('player', cp.unitToken) then
            SetRaidTargetIconTexture(icon, idx)
            icon:Show()
        else
            icon:Hide()
        end
        return
    end
    -- PATH C fallback: use raw raidicon coords
    if cp.rawRaidicon:IsShown() then
        local ux, uy = cp.rawRaidicon:GetTexCoord()
        icon:SetTexCoord(ux, ux+0.25, uy, uy+0.25)
        icon:Show()
    else
        icon:Hide()
    end
end

local function UpdatePlate(plate)
    local cp  = plate.cp
    local raw = cp.rawHP

    -- Health bar values
    local lo, hi = raw:GetMinMaxValues()
    cp.healthBar:SetMinMaxValues(lo, hi)
    cp.healthBar:SetValue(raw:GetValue())

    -- Bar color (reaction/class from raw color, TidyPlates method)
    local r, g, b   = raw:GetStatusBarColor()
    local isTapped  = r > .85 and g > .85 and b > .85 and r < .96
    if isTapped then
        cp.healthBar:SetStatusBarColor(unpack(C_TAPPED))
    else
        local col, _, unitType = GetReactionColor(r, g, b)
        if unitType == 'PLAYER' then
            local cc = MatchClassColor(r, g, b)
            if cc then cp.healthBar:SetStatusBarColor(cc.r, cc.g, cc.b)
            else       cp.healthBar:SetStatusBarColor(unpack(col)) end
        else
            cp.healthBar:SetStatusBarColor(unpack(col))
        end
    end

    -- mouseover highlight
    if cp.rawHighlight:IsShown() then
        cp.mouseoverHL:Show()
    else
        cp.mouseoverHL:Hide()
    end

    if not nameOnly then
        cp.healthBar:Show()
    else
        local r, g, b = raw:GetStatusBarColor()
        local _, reaction, unitType = GetReactionColor(r, g, b)
        local isFriendlyNPC = reaction == 'FRIENDLY' and unitType == 'NPC'
        CPAPI.SetShown(cp.healthBar, not isFriendlyNPC)
    end

    -- Name
    local name = cp.rawName:GetText()
    if name then
        cp.name:SetText(name)
        -- match name color to health bar reaction color
        if isTapped then
            cp.name:SetTextColor(unpack(C_TAPPED))
        else
            local col, _, unitType = GetReactionColor(r, g, b)
            if unitType == 'PLAYER' then
                local cc = MatchClassColor(r, g, b)
                if cc then cp.name:SetTextColor(cc.r, cc.g, cc.b)
                else       cp.name:SetTextColor(unpack(col)) end
            else
                cp.name:SetTextColor(unpack(col)) 
            end
        end
    end

    if not cp.unitToken then
        if cp.rawDangerskull:IsShown() then
            cp.classification = 'worldboss'
        elseif cp.rawEliteicon:IsShown() then
            cp.classification = 'elite'
        else
            cp.classification = 'none'
        end
    end

    -- LevelFrame: show/hide and populate Text + Skull
    local cl = cp.classification
    if not nameOnly then
        if cl == 'worldboss' then
            cp.LevelFrame:Show()
            cp.LevelFrame.Text:SetText('')
            cp.LevelFrame.Skull:Show()
        else
            local levelStr = cp.rawLevel:GetText()
            if levelStr then
                cp.LevelFrame.Skull:Hide()
                cp.LevelFrame.Text:SetText(levelStr)
                local lr, lg, lb = cp.rawLevel:GetTextColor()
                cp.LevelFrame.Text:SetTextColor(lr, lg, lb)
                cp.LevelFrame:Show()
            else
                cp.LevelFrame.Skull:Show()
                cp.LevelFrame.Text:SetText('')
                cp.LevelFrame:Show()
            end
        end
    else
        cp.LevelFrame:Hide()
    end

    -- ClassificationFrame
    if cl == 'elite' or cl == 'rareelite' then
        SafeSetAtlas(cp.ClassificationFrame.classificationIndicator,
            cl == 'elite' and ATLAS_ELITE or ATLAS_RAREELITE)
        cp.ClassificationFrame:Show()
    else
        cp.ClassificationFrame:Hide()
    end

    -- Raid target icon
    UpdateRaidTarget(plate)

    -- Selection highlight (target = full alpha when others dimmed)
    if HasTarget and plate:GetAlpha() >= 0.99 then
        cp.selectionHighlight:Show()
    else
        cp.selectionHighlight:Hide()
    end

    -- Cast bar (mirror raw)
    local rc = cp.rawCast
    if rc:IsShown() then
        local clo, chi = rc:GetMinMaxValues()
        cp.castBar:SetMinMaxValues(clo, chi)
        cp.castBar:SetValue(rc:GetValue())
        cp.castBar:Show()
    else
        cp.castBar:Hide()
    end


    if nameOnly and cp.unitToken then
        local unit = cp.unitToken
        local isFriend  = UnitIsFriend('player', unit)
        local isTarget  = UnitIsUnit('target', unit)
        local isPlayer  = UnitIsPlayer(unit)
        local isUnitCC  = UnitPlayerControlled(unit) and not isPlayer
        local inCombat  = (showAllEnemies and UnitCanAttack('player', unit))
                    or CPAPI:UnitThreatSituation('player', unit)
        local ignore    = inCombat or not (isFriend or not isTarget)
        local isActive  = cp.name and cp.name:IsShown()

        object.name(cp.name, ignore, unit, nil, nil, isPlayer, isUnitCC)
        object.ClassificationFrame(cp.ClassificationFrame, ignore, unit, nil,
                                    nil, nil, nil, nil, isActive)
    end

end

---------------------------------------------------------------
-- Threat (requires unit token — PATH B only)
---------------------------------------------------------------
local function UpdateThreat(plate)
    local cp   = plate.cp
    local unit = cp.unitToken
    local tex  = cp.aggroHighlight.Texture
    if not unit or not UnitExists(unit) or not InCombat then
        tex:Hide(); return
    end
    local reaction = UnitReaction and UnitReaction('player', unit)
    if not reaction or reaction > 4 then tex:Hide(); return end
    if UnitDetailedThreatSituation then
        local _, status = UnitDetailedThreatSituation('player', unit)
        if status and status > 0 then
            tex:SetVertexColor(GetThreatStatusColor(status))
            tex:Show(); return
        end
    end
    tex:Hide()
end

---------------------------------------------------------------
-- Apply overlay to one plate (once per plate lifetime)
---------------------------------------------------------------
local function ApplyNameplate(plate)
    if Plates[plate] then return end
    Plates[plate] = true
    BuildOverlay(plate)

    local cp = plate.cp

    cp.rawHP:HookScript('OnShow', function()
        PlatesVisible[plate] = true
        UpdatePlate(plate)
    end)
    cp.rawHP:HookScript('OnHide', function()
        PlatesVisible[plate] = nil
        cp.castBar:Hide()
        if cp.guid then GUIDToPlate[cp.guid] = nil; cp.guid = nil end
    end)
    cp.rawHP:HookScript('OnValueChanged', function()
        if PlatesVisible[plate] then UpdatePlate(plate) end
    end)
    cp.rawCast:HookScript('OnShow', function()
        if PlatesVisible[plate] then UpdatePlate(plate) end
    end)
    cp.rawCast:HookScript('OnHide', function()
        cp.castBar:Hide()
    end)
    cp.rawCast:HookScript('OnValueChanged', function()
        if PlatesVisible[plate] and cp.castBar:IsShown() then
            local lo, hi = cp.rawCast:GetMinMaxValues()
            cp.castBar:SetMinMaxValues(lo, hi)
            cp.castBar:SetValue(cp.rawCast:GetValue())
        end
    end)

    if cp.rawHP:IsShown() then
        PlatesVisible[plate] = true
        UpdatePlate(plate)
    end
end

---------------------------------------------------------------
-- PATH B: event-based (AwesomeWotlkLib)
---------------------------------------------------------------
local function InitEventTracking()
    local f = CreateFrame('Frame')
    f:RegisterEvent('NAME_PLATE_UNIT_ADDED')
    f:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
    f:SetScript('OnEvent', function(self, event, unit)
        if event == 'NAME_PLATE_UNIT_ADDED' then
            local plate = C_NamePlate.GetNamePlateForUnit(unit)
            if not plate then return end
            ApplyNameplate(plate)
            local cp = plate.cp
            cp.unitToken = unit
            -- Refine classification with real unit data
            local cl = UnitClassification(unit)
            if     cl == 'worldboss'  then cp.classification = 'worldboss'
            elseif cl == 'rareelite'  then cp.classification = 'rareelite'
            elseif cl == 'elite'      then cp.classification = 'elite'
            else                           cp.classification = 'none' end
            local guid = UnitGUID(unit)
            if guid then
                cp.guid = guid
                GUIDToPlate[guid] = plate
                if db.guidToUnit then db.guidToUnit[guid] = unit end
            end
            UpdatePlate(plate)
            UpdateThreat(plate)
        elseif event == 'NAME_PLATE_UNIT_REMOVED' then
            local plate = C_NamePlate.GetNamePlateForUnit(unit)
            if plate and plate.cp then
                local cp = plate.cp
                if cp.guid then
                    GUIDToPlate[cp.guid] = nil
                    if db.guidToUnit then db.guidToUnit[cp.guid] = nil end
                    cp.guid = nil
                end
                cp.unitToken = nil
                PlatesVisible[plate] = nil
            end
        end
    end)
end

---------------------------------------------------------------
-- PATH C: WorldFrame scan (standard 3.3.5a)
---------------------------------------------------------------
local function InitScanTracking()
    local f = CreateFrame('Frame', nil, WorldFrame)
    f:SetScript('OnUpdate', function()
        local cur = WorldFrame:GetNumChildren()
        if cur == numChildren then return end
        numChildren = cur
        for _, child in ipairs({WorldFrame:GetChildren()}) do
            if not Plates[child] and IsRawNameplate(child) then
                ApplyNameplate(child)
            end
        end
    end)
end

---------------------------------------------------------------
-- Tick: refresh all visible plates ~20fps
---------------------------------------------------------------
local tickFrame   = CreateFrame('Frame')
local tickElapsed = 0
tickFrame:SetScript('OnUpdate', function(self, elapsed)
    tickElapsed = tickElapsed + elapsed
    if tickElapsed < 0.05 then return end
    tickElapsed = 0
    for plate in pairs(PlatesVisible) do
        UpdatePlate(plate)
        if plate.cp.unitToken then UpdateThreat(plate) end
    end
end)
tickFrame:Hide()

---------------------------------------------------------------
-- Events
---------------------------------------------------------------
local evtFrame = CreateFrame('Frame')
evtFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
evtFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
evtFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
evtFrame:RegisterEvent('PLAYER_TARGET_CHANGED')
evtFrame:RegisterEvent('RAID_TARGET_UPDATE')
if UnitDetailedThreatSituation then
    evtFrame:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE')
end

evtFrame:SetScript('OnEvent', function(self, event)
    if event == 'PLAYER_ENTERING_WORLD' then
        if db('enableNameplates') == false then
            return
        end
        if HAS_NAMEPLATE_API then InitEventTracking()
        else                       InitScanTracking() end
        tickFrame:Show()
    elseif event == 'PLAYER_REGEN_DISABLED' then
        InCombat = true
        for plate in pairs(PlatesVisible) do UpdatePlate(plate) end
    elseif event == 'PLAYER_REGEN_ENABLED' then
        InCombat = false
        for plate in pairs(PlatesVisible) do
            plate.cp.aggroHighlight.Texture:Hide()
            UpdatePlate(plate)
        end
    elseif event == 'PLAYER_TARGET_CHANGED' then
        HasTarget = UnitExists('target') and true or false
        for plate in pairs(PlatesVisible) do UpdatePlate(plate) end
    elseif event == 'RAID_TARGET_UPDATE' then
        for plate in pairs(PlatesVisible) do UpdateRaidTarget(plate) end
    elseif event == 'UNIT_THREAT_SITUATION_UPDATE' then
        for plate in pairs(PlatesVisible) do
            if plate.cp.unitToken then UpdateThreat(plate) end
        end
    end
end)