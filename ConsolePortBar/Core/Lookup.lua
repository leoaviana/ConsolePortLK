local addOn, ab = ...
local db = ConsolePort:GetData()
local CPAPI = db.CPAPI

local r, g, b = ConsolePort:GetData().Atlas.GetNormalizedCC()
--------------------------------------------------------
local defaultIcons
do  local custom = [[Interface\AddOns\ConsolePortBar\Textures\Icons\%s]]
	local customcp = [[Interface\AddOns\ConsolePort\Textures\Icons\%s]]
	local client = [[Interface\Icons\%s]]
	local isRetail = CPAPI:IsRetailVersion()
	defaultIcons = {
	----------------------------
	JUMP = custom:format('Jump'), 
	TOGGLERUN = custom:format('Run'),
	OPENALLBAGS = custom:format('Bags'),
	TOGGLEGAMEMENU = custom:format('Menu'),
	TOGGLEWORLDMAP = custom:format('Map'),
	----------------------------
	TARGETNEARESTENEMY = custom:format('Target'),
	TARGETPREVIOUSENEMY = custom:format('Target'),
	TARGETSCANENEMY = custom:format('Target'),
	TARGETNEARESTFRIEND = custom:format('Target'),
	TARGETPREVIOUSFRIEND = custom:format('Target'),
	TARGETNEARESTENEMYPLAYER = custom:format('Target'),
	TARGETPREVIOUSENEMYPLAYER = custom:format('Target'),
	TARGETNEARESTFRIENDPLAYER = custom:format('Target'),
	TARGETPREVIOUSFRIENDPLAYER = custom:format('Target'),
	----------------------------
	TARGETPARTYMEMBER1 = isRetail and client:format('Achievement_PVP_A_01'),
	TARGETPARTYMEMBER2 = isRetail and client:format('Achievement_PVP_A_02'),
	TARGETPARTYMEMBER3 = isRetail and client:format('Achievement_PVP_A_03'),
	TARGETPARTYMEMBER4 = isRetail and client:format('Achievement_PVP_A_04'),
	TARGETSELF = isRetail and client:format('Achievement_PVP_A_05'),
	TARGETPET = client:format('Spell_Hunter_AspectOfTheHawk'),
	----------------------------
	ATTACKTARGET = client:format('Ability_SteelMelee'),
	STARTATTACK  = client:format('Ability_SteelMelee'),
	PETATTACK    = client:format('ABILITY_HUNTER_INVIGERATION'),
	FOCUSTARGET  = client:format('Ability_Hunter_MasterMarksman'),
	----------------------------
	['CLICK ConsolePortFocusButton:LeftButton']      = client:format('VAS_RaceChange'),
	['CLICK ConsolePortEasyMotionButton:LeftButton'] = custom:format('Group'),
	['CLICK ConsolePortRaidCursorToggle:LeftButton'] = custom:format('Group'),
	['CLICK ConsolePortRaidCursorFocus:LeftButton']  = custom:format('Group'),
	['CLICK ConsolePortRaidCursorTarget:LeftButton'] = custom:format('Group'),
	['CLICK ConsolePortUtilityToggle:LeftButton']    = custom:format('Ring'),
	['CLICK ConsolePortTotemToggle:LeftButton']		 = customcp:format('Totems'),
	----------------------------
	}
end
--------------------------------------------------------
local classArt = {
	WARRIOR 	= {1, 1},
	PALADIN 	= {1, 2},
	DRUID 		= {1, 3},
	DEATHKNIGHT = {1, 4},
	----------------------------
	MAGE 		= {2, 1},
	HUNTER 		= {2, 2},
	ROGUE 		= {2, 3},
	WARLOCK 	= {2, 4},
	----------------------------
	SHAMAN 		= {3, 1},
	PRIEST 		= {3, 2},
	DEMONHUNTER = {3, 3},
	MONK 		= {3, 4},
}
--------------------------------------------------------
local defaultReticleSpellIDs = {
	DEATHKNIGHT = {
		43265, 49936, 49937, 49938, 	  					-- Death and Decay
	},
	DRUID = {
		16914, 17401, 17402, 27012, 48467,					-- Hurricane
		33831,												-- Force of Nature
	},
	HUNTER = {
		60192, 									 			-- Freezing Arrow
		1510, 14294, 14925, 27022, 58431, 58434, 			-- Volley
		1543, 												-- Flare
	},
	MAGE = {
		2120, 2121, 8422, 8423, 10215, 10216, 27086, 42925, -- Flamestrike
		10, 6141, 8427, 10185, 10187, 27085, 42940,			-- Blizzard
	},
	WARLOCK = {
		5740, 6219, 11667, 11678, 27212, 47819, 47820, 		-- Rain of Fire
	},
}
--------------------------------------------------------

function ab:GetBindingIcon(binding) 
    local customIcon = ConsolePort:GetUtilityRingIcon(binding)
    if customIcon then
        return customIcon
    end

    -- Fallback to default icons if no custom icon is found
    return ab.manifest.BindingIcons[binding]
end

function ab:CreateManifest()
	if type(ConsolePortBarManifest) ~= 'table' then
		ConsolePortBarManifest = {
			ReticleSpells = ab:GetReticleSpellManifest(),
			BindingIcons = defaultIcons,
		}
	elseif type(ConsolePortBarManifest.BindingIcons) ~= 'table' then
		ConsolePortBarManifest.BindingIcons = defaultIcons
	end
	defaultIcons = nil
	ab.manifest = ConsolePortBarManifest
	return ConsolePortBarManifest
end

function ab:GetCover(class)
	local art = class and classArt[class]
	if not class and not art then
		art = classArt[select(2, UnitClass('player'))]
	end
	if art then
		local index, px = unpack(art)
		return [[Interface\AddOns\]]..addOn..[[\Textures\Covers\]]..index, 
				{0, 1, (( px - 1 ) * 256 ) / 1024, ( px * 256 ) / 1024 }
	end
end

function ab:GetBackdrop()
	return {
		edgeFile 	= 'Interface\\AddOns\\'..addOn..'\\Textures\\BarEdge',
		edgeSize 	= 32,
		insets 		= {left = 16, right = 16,	top = 16, bottom = 16}
	}
end

function ab:GetDefaultButtonLayout(button)
	local layout = {
		-- official rc2 native shoulder defaults
		CP_T3 = {point = {'LEFT', 456, 56}, dir = 'right', size = 64},
		CP_T4 = {point = {'RIGHT', -456, 56}, dir = 'left', size = 64},
		CP_T1 = {point = {'LEFT', 396, 16}, dir = 'down', size = 64},
		CP_T2 = {point = {'RIGHT', -396, 16}, dir = 'down', size = 64},
		---
		CP_L_LEFT 	= {point = {'LEFT', 176, 56}, dir = 'left', size = 64},
		CP_L_RIGHT 	= {point = {'LEFT', 306, 56}, dir = 'right', size = 64},
		CP_L_UP 	= {point = {'LEFT', 240, 100}, dir = 'up', size = 64},
		CP_L_DOWN 	= {point = {'LEFT', 240, 16}, dir = 'down', size = 64},
		---
		CP_R_LEFT 	= {point = {'RIGHT', -306, 56}, dir = 'left', size = 64},
		CP_R_RIGHT 	= {point = {'RIGHT', -176, 56}, dir = 'right', size = 64},
		CP_R_UP 	= {point = {'RIGHT', -240, 100}, dir = 'up', size = 64},
		CP_R_DOWN 	= {point = {'RIGHT', -240, 16}, dir = 'down', size = 64},
	}
	if button ~= nil then
		return layout[button]
	else
		return layout
	end
end

function ab:GetReticleSpellManifest()
	local reticleSpells = {}
	for class, classSpells in pairs(defaultReticleSpellIDs) do
		reticleSpells[class] = reticleSpells[class] or {}
		for _, spellID in pairs(classSpells) do
			local localizedSpellName = GetSpellInfo(spellID) 
			if localizedSpellName then
				reticleSpells[class][spellID] = localizedSpellName
			end
		end
	end
	defaultReticleSpellIDs = nil
	return reticleSpells
end

function ab:GetPresets()
	return {
		Default = ab:GetDefaultSettings(),
		Orthodox = {
			scale = 0.9,
			width = 1100,
			watchbars = true,
			showline = true,
			lock = true,
			enablecooldowntext = true,
			showmodifiercooldowns = true,
			hiddenbarcooldowns = '10',
			layout = {
				CP_L_RIGHT = {dir = 'right', point = {'LEFT', 330, 9}, size = 64},
				CP_L_LEFT = {dir = 'left', point = {'LEFT', 80, 9}, size = 64},
				CP_L_DOWN = {dir = 'down', point = {'LEFT', 165, 9}, size = 64},
				CP_L_UP = {dir = 'up', point = {'LEFT', 250, 9}, size = 64},
				CP_R_RIGHT = {dir = 'right', point = {'RIGHT', -80, 9}, size = 64},
				CP_R_LEFT = {dir = 'left', point = {'RIGHT', -330, 9}, size = 64},
				CP_R_DOWN = {dir = 'down', point = {'RIGHT', -250, 9}, size = 64},
				CP_R_UP = {dir = 'up', point = {'RIGHT', -165, 9}, size = 64},
				-- Keep absent/unchecked at runtime; retain official Orthodox first-enable geometry.
				CP_T3 = {dir = 'right', point = {'LEFT', 440, 9}, size = 64, hidden = true},
				CP_T4 = {dir = 'left', point = {'RIGHT', -440, 9}, size = 64, hidden = true},
				CP_T1 = {dir = 'up', point = {'LEFT', 405, 75}, size = 64},
				CP_T2 = {dir = 'up', point = {'RIGHT', -405, 75}, size = 64},
			},
		},
		Roleplay = {
			scale = 0.9,
			width = 1100,
			watchbars = true,
			showline = true,
			showart = true,
			lock = true,
			enablecooldowntext = true,
			showmodifiercooldowns = true,
			hiddenbarcooldowns = '10',
			layout = ab:GetDefaultButtonLayout(),
		},
		["Crossbar: Minimal"] = {
			scale = 1,
			width = 1100,
			watchbars = true,
			showline = false,
			lock = true,
			enablecooldowntext = true,
			showmodifiercooldowns = true,
			hiddenbarcooldowns = '10',
			useSquareButtons = true,
			layout = {
				-- RIGHT CLUSTER (Face Buttons)
				-- Base Y increased to 50 to clear the EXP bar
				CP_R_LEFT    = {dir = 'left',  point = {'BOTTOM',  100, 75}, size = 45}, 
				CP_R_RIGHT   = {dir = 'right', point = {'BOTTOM',  200, 75}, size = 45}, 
				CP_R_UP      = {dir = 'up',    point = {'BOTTOM',  150, 100}, size = 45}, 
				CP_R_DOWN    = {dir = 'down',  point = {'BOTTOM',  150, 50}, size = 45}, 
				
				-- Actual bumpers only. Modifier-only trigger entries are intentionally
				-- omitted so skipped L1/R1-style controls do not reappear as bar buttons.
				-- LB (CP_T1) belongs on the left; RB (CP_T2) belongs on the right.
				CP_T1        = {dir = 'down',  point = {'BOTTOM',  -30, 50}, size = 45},
				-- v143: modifier-only shoulder controls retain the official rc2
				-- Minimal geometry even while unchecked. Checking one for the first
				-- time therefore has real preset values instead of 64/CENTER/0/0.
				CP_T3        = {dir = 'up',    point = {'BOTTOM',  -30, 100}, size = 45, hidden = true},
				CP_T4        = {dir = 'up',    point = {'BOTTOM',   30, 100}, size = 45, hidden = true},

				-- LEFT CLUSTER (D-Pad)
				CP_L_LEFT    = {dir = 'left',  point = {'BOTTOM', -200, 75}, size = 45}, 
				CP_L_RIGHT   = {dir = 'right', point = {'BOTTOM', -100, 75}, size = 45}, 
				CP_L_UP      = {dir = 'up',    point = {'BOTTOM', -150, 100}, size = 45}, 
				CP_L_DOWN    = {dir = 'down',  point = {'BOTTOM', -150, 50}, size = 45}, 
				
				CP_T2        = {dir = 'down',  point = {'BOTTOM',   30, 50}, size = 45}, 
			},
		}, 

		["Crossbar: Triple"] = {
			scale = 1,
			width = 1100,
			watchbars = true,
			showline = false,
			lock = true,
			enablecooldowntext = true,
			showmodifiercooldowns = true,
			hiddenbarcooldowns = '10',
			useSquareButtons = true,
			isTriple = true,
			dividers = {
				['DIVIDER_LEFT'] = {
					point = {'BOTTOM', -170, 95},
					breadth   = 130,   -- taller line
					depth     = 300,   -- wide glow spread
					rotation  = 90,
					thickness = 2,
					intensity = 12,    -- softer glow
					opacity = {
						focus  = 'M1',
						idle   = nil,
						hidden = 'M2',
					},
				},
				['DIVIDER_RIGHT'] = {
					point = {'BOTTOM', 172, 95},
					breadth   = 130,
					depth     = 300,
					rotation  = 270,
					thickness = 2,
					intensity = 12,
					opacity = {
						focus  = 'M2',
						idle   = nil,
						hidden = 'M1',
					},
				},
				['DIVIDER_CENTER_L'] = {
					point = {'BOTTOM', -168, 95},
					breadth   = 130,
					depth     = 300,
					rotation  = 270,
					thickness = 2,
					intensity = 12,
					opacity = {
						focus  = 'M0',   -- bright on NOMOD
						idle   = nil,
						hidden = 'M1,M2',   -- hide on SHIFT 
					},
				},
				['DIVIDER_CENTER_R'] = {
					point = {'BOTTOM', 170, 95},
					breadth   = 130,
					depth     = 300,
					rotation  = 90,
					thickness = 2,
					intensity = 12,
					opacity = {
						focus  = 'M0',
						idle   = nil,
						hidden = 'M1,M2', 
					},
				},
			},
			layout = {
				-- LEFT DIAMOND (SHIFT) - Centered at -400 (Moved from -350)
				CP_L_UP_SHIFT     = {point={'BOTTOM', -400, 100}, size=45},
				CP_L_DOWN_SHIFT   = {point={'BOTTOM', -400, 50},  size=45},
				CP_L_LEFT_SHIFT   = {point={'BOTTOM', -450, 75},  size=45},
				CP_L_RIGHT_SHIFT  = {point={'BOTTOM', -350, 75},  size=45},
				-- Left Face (Shift)
				CP_R_UP_SHIFT     = {point={'BOTTOM', -250, 100}, size=45},
				CP_R_DOWN_SHIFT   = {point={'BOTTOM', -250, 50},  size=45},
				CP_R_LEFT_SHIFT   = {point={'BOTTOM', -300, 75},  size=45},
				CP_R_RIGHT_SHIFT  = {point={'BOTTOM', -200, 75},  size=45},


				-- v115 retail-reference order: LB, LT, RT, RB (outer bumpers, inner triggers).
				CP_T1 = {point = {'BOTTOM', -75, 215}, size=45, scale=0.8, static=true}, -- LB
				CP_T3 = {point = {'BOTTOM', -25, 215}, size=45, scale=0.8, static=true, hidden=true}, -- LT visual carrier
				CP_T4 = {point = {'BOTTOM',  25, 215}, size=45, scale=0.8, static=true, hidden=true}, -- RT visual carrier
				CP_T2 = {point = {'BOTTOM',  75, 215}, size=45, scale=0.8, static=true}, -- RB

				-- CENTER DIAMOND (NOMOD/BOTH) - Stays at 0
				CP_L_UP           = {point={'BOTTOM', -75, 100}, size=45},
				CP_L_DOWN         = {point={'BOTTOM', -75, 50},  size=45},
				CP_L_LEFT         = {point={'BOTTOM', -125, 75}, size=45},
				CP_L_RIGHT        = {point={'BOTTOM', -25, 75},  size=45},
				CP_R_UP           = {point={'BOTTOM',  75, 100}, size=45},
				CP_R_DOWN         = {point={'BOTTOM',  75, 50},  size=45},
				CP_R_LEFT         = {point={'BOTTOM',  25, 75},  size=45},
				CP_R_RIGHT        = {point={'BOTTOM',  125, 75}, size=45},

				-- RIGHT DIAMOND (CTRL) - Centered at 400 (Moved from 350)
				CP_L_UP_CTRL      = {point={'BOTTOM',  250, 100}, size=45},
				CP_L_DOWN_CTRL    = {point={'BOTTOM',  250, 50},  size=45},
				CP_L_LEFT_CTRL    = {point={'BOTTOM',  200, 75},  size=45},
				CP_L_RIGHT_CTRL   = {point={'BOTTOM',  300, 75},  size=45},
				-- Right Face (Ctrl)
				CP_R_UP_CTRL      = {point={'BOTTOM',  400, 100}, size=45},
				CP_R_DOWN_CTRL    = {point={'BOTTOM',  400, 50},  size=45},
				CP_R_LEFT_CTRL    = {point={'BOTTOM',  350, 75},  size=45},
				CP_R_RIGHT_CTRL   = {point={'BOTTOM',  450, 75},  size=45},
			},
		}
	}
end

-- v142: Resolve first-enable geometry from the active preset rather than
-- falling back to generic Default coordinates.  Existing hidden entries always
-- retain their own saved geometry; this is only for a binding that has never
-- existed in the active layout.
function ab:GetPresetButtonLayout(presetName, button)
	if not button then return end
	local presets = self:GetPresets()
	local preset = presetName and presets[presetName]
	local data = preset and preset.layout and preset.layout[button]
	if data then
		return db.table.copy(data)
	end
	return db.table.copy(self:GetDefaultButtonLayout(button))
end

function ab:GetRGBColorFor(element, default)
	local cfg = ab.cfg or {}
	local defaultColors = {
		art 	= {1, 1, 1, 1},
		tint 	= {r, g, b, 1},
		border 	= {1, 1, 1, 1},
		swipe 	= {r, g, b, 1},
		exp 	= {r, g, b, 1},
	}
	if default then
		if defaultColors[element] then
			return unpack(defaultColors[element])
		end
	end
	local current = {
		art 	= cfg.artRGB or defaultColors.art,
		tint 	= cfg.tintRGB or defaultColors.tint,
		border 	= cfg.borderRGB or defaultColors.border,
		swipe 	= cfg.swipeRGB or defaultColors.swipe,
		exp 	= cfg.expRGB or defaultColors.exp,
	}
	if current[element] then
		return unpack(current[element])
	end
end
function ab:GetDefaultSettings()
	return 	{
		scale = 0.9,
		width = 1100,
		watchbars = true,
		showline = true,
		lock = true,
		flashart = true,
		enablecooldowntext = true,
		showmodifiercooldowns = true,
			hiddenbarcooldowns = '10',
		layout = ab:GetDefaultButtonLayout()
	}
end

function ab:GetColorGradient(red, green, blue)
	local gBase = 0.15
	local gMulti = 1.2
	local startAlpha = 0.25
	local endAlpha = 0
	local gradient = {
		'VERTICAL',
		(red + gBase) * gMulti, (green + gBase) * gMulti, (blue + gBase) * gMulti, startAlpha,
		1 - (red + gBase) * gMulti, 1 - (green + gBase) * gMulti, 1 - (blue + gBase) * gMulti, endAlpha,
	}
	return unpack(gradient)
end

function ab:GetBooleanSettings(otherCFG)
	local cfg = otherCFG or ab.cfg or {}
	local L = ab.data.ACTIONBAR
	return {
		{	desc = L.CFG_LOCK,
			cvar = 'lock',
			toggle = cfg.lock,
		},
		{	desc = L.CFG_LOCKPET,
			cvar = 'lockpet',
			toggle = cfg.lockpet,
		},
		{	desc = L.CFG_SHOWALLBUTTONS,
			cvar = 'showbuttons',
			toggle = cfg.showbuttons,
		},
		{	desc = L.CFG_HIDEINCOMBAT,
			cvar = 'combathide',
			toggle = cfg.combathide,
		},
		{	desc = L.CFG_HIDEPETINCOMBAT,
			cvar = 'combatpethide',
			toggle = cfg.combatpethide,
		},
		{	desc = L.CFG_HIDEOUTOFCOMBAT,
			cvar = 'hidebar',
			toggle = cfg.hidebar,
		},
		{	desc = L.CFG_DISABLEPET,
			cvar = 'hidepet',
			toggle = cfg.hidepet,
		},
		{	desc = L.CFG_DISABLERETICLE,
			cvar = 'disablecastonrelease',
			toggle = cfg.disablecastonrelease,
		},
		{	desc = L.CFG_DISABLEDND,
			cvar = 'disablednd',
			toggle = cfg.disablednd,
		},

		{	desc = L.CFG_QUICKMENU,
			cvar = 'quickMenu',
			toggle = cfg.quickMenu,
		},
		{	desc = L.CFG_WATCHBAR_OFF,
			cvar = 'hidewatchbars',
			toggle = cfg.hidewatchbars,
		},
		{	desc = L.CFG_WATCHBAR_ALPHA,
			cvar = 'watchbars',
			toggle = cfg.watchbars,
		},
		{	desc = L.CFG_DISABLE_ICONS,
			cvar = 'hideIcons',
			toggle = cfg.hideIcons,
		},
		{	desc = L.CFG_DISABLE_MINIS,
			cvar = 'hideModifiers',
			toggle = cfg.hideModifiers,
		},
		{	desc = L.CFG_OLD_BORDERS,
			cvar = 'classicBorders',
			toggle = cfg.classicBorders,
		},
		{	desc = L.CFG_MOUSE_ENABLE,
			cvar = 'mousewheel',
			toggle = cfg.mousewheel,
		},
		{	desc = L.CFG_CAST_DEFAULT,
			cvar = 'defaultCastBar',
			toggle = cfg.defaultCastBar,
		},
		{	desc = L.CFG_CAST_NOHOOK,
			cvar = 'disableCastBarHook',
			toggle = cfg.disableCastBarHook,
		},
		{	desc = L.CFG_ART_UNDERLAY,
			cvar = 'showart',
			toggle = cfg.showart,
		},
		{	desc = L.CFG_ART_BLEND,
			cvar = 'blendart',
			toggle = cfg.blendart,
		},
		{	desc = L.CFG_ART_FLASH,
			cvar = 'flashart',
			toggle = cfg.flashart,
		},
		{	desc = L.CFG_ART_SMALL,
			cvar = 'smallart',
			toggle = cfg.smallart,
		},
		{	desc = L.CFG_ART_TINT,
			cvar = 'showline',
			toggle = cfg.showline,
		},
		{	desc = L.CFG_COLOR_RAINBOW,
			cvar = 'rainbow',
			toggle = cfg.rainbow,
		},
	}
end

function ab:SetRainbowScript(on) 
	local f = ab.bar
	if on then
		local reg, pairs = ab.libs.registry, pairs
		local __cb, __bg, __bl, __wb = CastingBarFrame, f.BG, f.BottomLine, f.WatchBarContainer
		local t, i, p, c, w, m = 0, 0, 0, 128, 127, 180
		local hz = (math.pi*2) / m
		local r, g, b
		f:SetScript('OnUpdate', function(self, e)
			t = t + e
			if t > 0.1 then
				i = i + 1
				r = (math.sin((hz * i) + 0 + p) * w + c) / 255
				g = (math.sin((hz * i) + 2 + p) * w + c) / 255
				b = (math.sin((hz * i) + 4 + p) * w + c) / 255
				if i > m then
					i = i - m
				end
				__cb:SetStatusBarColor(r, g, b)
				__wb:SetMainBarColor(r, g, b)
				__bg:SetGradientAlpha(ab:GetColorGradient(r, g, b))
				__bl:SetVertexColor(r, g, b)
				for _, rap in pairs(reg) do
					--rap:SetSwipeColor(r, g, b, 1)
				end
				t = 0
			end
		end)
	else
		f:SetScript('OnUpdate', nil)
	end
end

function ab:SetArtUnderlay(enabled, flashOnProc)
	local bar = ab.bar
	local cfg = ab.cfg
	if enabled then
		local art, coords = self:GetCover()
		if art and coords then
			local artScale = cfg.smallart and .75 or 1
			bar.CoverArt:SetTexture(art)
			bar.CoverArt:SetTexCoord(unpack(coords))
			bar.CoverArt:SetVertexColor(unpack(cfg.artRGB or {1,1,1}))
			bar.CoverArt:SetBlendMode(cfg.blendart and 'ADD' or 'BLEND')
			bar.CoverArt:SetSize(768 * artScale, 192 * artScale)
			if cfg.showart then
				bar.CoverArt:Show()
			else
				bar.CoverArt:Hide()
			end
		end
	else
		bar.CoverArt:SetTexture(nil)
		bar.CoverArt:Hide()
	end
	bar.CoverArt.flashOnProc = flashOnProc
end