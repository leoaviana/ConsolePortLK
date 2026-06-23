---------------------------------------------------------------
local db = ConsolePort:GetData()
local CPAPI = db.CPAPI
local HANDLE, WrapperMixin = {}, {}
---------------------------------------------------------------
local an, ab = ...
local acb = ab.libs.acb
---------------------------------------------------------------
ab.libs.wrapper = HANDLE
---------------------------------------------------------------
local Wrappers = {}
ab.libs.registry = Wrappers
---------------------------------------------------------------
local TEX_PATH = [[Interface\AddOns\]]..an..[[\Textures\%s]]
local NOT_BOUND_TOOLTIP = NOT_BOUND .. '\n' .. db.TUTORIAL.BIND.TOOLTIPCLICK
---------------------------------------------------------------
local size, smallSize, tSize = 64, 46, 58
local ofs, ofsB, fixA = 38, 21, 4
---------------------------------------------------------------
local mods = {
	[''] = {size = {size, size}},
	['SHIFT-'] 	= {size = {smallSize, tSize}, 
		down 	= {'TOPRIGHT', 'BOTTOMLEFT',  ofs - fixA,  ofs + fixA},
		up 		= {'BOTTOMRIGHT', 'TOPLEFT',  ofs - fixA, -ofs - fixA},
		left 	= {'BOTTOMRIGHT', 'TOPLEFT',  ofs + fixA, -ofs + fixA},
		right 	= {'BOTTOMLEFT', 'TOPRIGHT', -ofs - fixA, -ofs + fixA},
	},
	['CTRL-'] 	= {size = {smallSize, tSize}, 
		down 	= {'TOPLEFT', 'BOTTOMRIGHT', -ofs + fixA,  ofs + fixA},
		up 		= {'BOTTOMLEFT', 'TOPRIGHT', -ofs + fixA, -ofs - fixA},
		left 	= {'TOPRIGHT', 'BOTTOMLEFT',  ofs + fixA,  ofs - fixA},
		right 	= {'TOPLEFT', 'BOTTOMRIGHT', -ofs - fixA,  ofs - fixA},
	},
	['CTRL-SHIFT-'] = {size = {smallSize, tSize},
		down 	= {'TOP', 'BOTTOM', 0, ofsB},
		up 		= {'BOTTOM', 'TOP', 0, -ofsB},
		left 	= {'RIGHT', 'LEFT', ofsB, 0},
		right 	= {'LEFT', 'RIGHT', -ofsB, 0},
	},
}

local modcoords = { -- ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
	['SHIFT-'] = {
		down 	= {0, 0, 	1, 0, 	0, 1, 	1, 1},
		up 		= {1, 0,	0, 0,	1, 1,	0, 1},
		left 	= {1, 0,	1, 1,	0, 0,	0, 1},
		right 	= {0, 0, 	0, 1, 	1, 0,	1, 1},
	},
	['CTRL-'] = {
		down 	= {0, 1,	1, 1,	0, 0,	1, 0},
		up 		= {1, 1,	0, 1,	1, 0,	0, 0},
		left 	= {1, 1, 	1, 0,	0, 1,	0, 0},
		right 	= {0, 1,	0, 0,	1, 1,	1, 0},
	},
	['CTRL-SHIFT-'] = {
		down 	= {0, 1,	1, 1,	0, 0,	1, 0},
		up 		= {1, 0,	0, 0, 	1, 1,	0, 1},
		left 	= {1, 0,	1, 1,	0, 0,	0, 1},
		right 	= {0, 0,	0, 1, 	1, 0,	1, 1},
	},
}

local masks = { -- SHIFT-: M1, CTRL-: M2, CTRL-SHIFT-: M3
	['SHIFT-'] = {
		down 	= TEX_PATH:format([[Masks\M1_down]]),
		up 		= TEX_PATH:format([[Masks\M1_up]]),
		left 	= TEX_PATH:format([[Masks\M1_left]]),
		right 	= TEX_PATH:format([[Masks\M1_right]]),
	},
	['CTRL-'] = {
		down 	= TEX_PATH:format([[Masks\M2_down]]),
		up 		= TEX_PATH:format([[Masks\M2_up]]),
		left 	= TEX_PATH:format([[Masks\M2_left]]),
		right 	= TEX_PATH:format([[Masks\M2_right]]),
	},
	['CTRL-SHIFT-'] = {
		down 	= TEX_PATH:format([[Masks\M3_down]]),
		up 		= TEX_PATH:format([[Masks\M3_up]]),
		left 	= TEX_PATH:format([[Masks\M3_left]]),
		right 	= TEX_PATH:format([[Masks\M3_right]]),
	},
}

local swipes = { -- SHIFT-: M1, CTRL-: M2, CTRL-SHIFT-: M3
	['SHIFT-'] = {
		down 	= TEX_PATH:format([[Swipes\M1_down]]),
		up 		= TEX_PATH:format([[Swipes\M1_up]]),
		left 	= TEX_PATH:format([[Swipes\M1_left]]),
		right 	= TEX_PATH:format([[Swipes\M1_right]]),
	},
	['CTRL-'] = {
		down 	= TEX_PATH:format([[Swipes\M2_down]]),
		up 		= TEX_PATH:format([[Swipes\M2_up]]),
		left 	= TEX_PATH:format([[Swipes\M2_left]]),
		right 	= TEX_PATH:format([[Swipes\M2_right]]),
	},
	['CTRL-SHIFT-'] = {
		down 	= TEX_PATH:format([[Swipes\M3_down]]),
		up 		= TEX_PATH:format([[Swipes\M3_up]]),
		left 	= TEX_PATH:format([[Swipes\M3_left]]),
		right 	= TEX_PATH:format([[Swipes\M3_right]]),
	},
}
---------------------------------------------------------------
local adjustTextures = {
	'Border',
	'NormalTexture',
	'HighlightTexture',
	'PushedTexture',
	'CheckedTexture',
	'NewActionTexture',
}
---------------------------------------------------------------
local hotkeyConfig = { -- {anchor point}, modifier ID
	['SHIFT-'] = {{{'CENTER', 0, 0}, {20, 20}, 'CP_M1'}},
	['CTRL-'] = {{{'CENTER', 0, 0}, {20, 20}, 'CP_M2'}},
	['CTRL-SHIFT-'] = {{{'CENTER', -4, 0}, {20, 20}, 'CP_M1'}, {{'CENTER', 4, 0}, {20, 20}, 'CP_M2'}},
}

---------------------------------------------------------------
local buttonTextures = {
	[''] = {
		normal = TEX_PATH:format([[Button\BigNormal]]),
		pushed = TEX_PATH:format([[Button\BigHilite]]),
		hilite = TEX_PATH:format([[Button\BigHilite]]),
		checkd = TEX_PATH:format([[Button\BigHilite]]),
		border = TEX_PATH:format([[Button\BigHilite]]),
		new_action 	= TEX_PATH:format([[Button\BigHilite]]),
		cool_swipe 	= TEX_PATH:format([[Cooldown\Swipe]]),
		cool_edge 	= TEX_PATH:format([[Cooldown\Edge]]),
		cool_bling 	= TEX_PATH:format([[Cooldown\Bling]]),
	},
	['SHIFT-'] = {
		normal = TEX_PATH:format([[Button\M1]]),
		pushed = TEX_PATH:format([[Button\M1]]),
		border = TEX_PATH:format([[Button\M1]]),
		hilite = TEX_PATH:format([[Button\M1Hilite]]),
		checkd = TEX_PATH:format([[Button\M1Hilite]]),
		new_action 	= TEX_PATH:format([[Button\M1Hilite]]),
		cool_swipe 	= TEX_PATH:format([[Cooldown\SwipeSmall]]),
	--	cool_edge 	= TEX_PATH:format([[Cooldown\Edge]]),
		cool_charge = TEX_PATH:format([[Cooldown\SwipeSmall]]),
		cool_bling 	= TEX_PATH:format([[Cooldown\Bling]]),
	},
	['CTRL-'] = {
		normal = TEX_PATH:format([[Button\M1]]),
		pushed = TEX_PATH:format([[Button\M1]]),
		border = TEX_PATH:format([[Button\M1]]),
		hilite = TEX_PATH:format([[Button\M1Hilite]]),
		checkd = TEX_PATH:format([[Button\M1Hilite]]),
		new_action 	= TEX_PATH:format([[Button\M1Hilite]]),
		cool_swipe 	= TEX_PATH:format([[Cooldown\SwipeSmall]]),
	--	cool_edge 	= TEX_PATH:format([[Cooldown\Edge]]),
		cool_bling 	= TEX_PATH:format([[Cooldown\Bling]]),
	},
	['CTRL-SHIFT-'] = {
		normal = TEX_PATH:format([[Button\M3]]),
		pushed = TEX_PATH:format([[Button\M3]]),
		border = TEX_PATH:format([[Button\M3]]),
		hilite = TEX_PATH:format([[Button\M3Hilite]]),
		checkd = TEX_PATH:format([[Button\M3Hilite]]),
		new_action 	= TEX_PATH:format([[Button\M3Hilite]]),
		cool_swipe 	= TEX_PATH:format([[Cooldown\SwipeSmall]]),
	--	cool_edge 	= TEX_PATH:format([[Cooldown\Edge]]),
		cool_bling 	= TEX_PATH:format([[Cooldown\Bling]]),
	},
}

---------------------------------------------------------------
local config = {
	tooltip = 'enabled',
	showGrid = true,
	colors = {
		range = { 0.8, 0.1, 0.1 },
		mana = { 0.5, 0.5, 1.0 }
	},
	hideElements = {
		macro = false,
		equipped = false,
	},
	keyBoundTarget = false,
	clickOnDown = true,
	flyoutDirection = 'UP',
}
---------------------------------------------------------------
function WrapperMixin:Show()
	for _, button in pairs(self.Buttons) do
		button:Show()
	end
	self[''].shadow:Show()
end

function WrapperMixin:Hide()
	for _, button in pairs(self.Buttons) do
		button:Hide()
	end
	self[''].shadow:Hide()
end

function WrapperMixin:SetPoint(...)
	local main = self['']
	local p, x, y = ...
	main:ClearAllPoints()
	if p and x and y then
		return main:SetPoint(...)
	end
end

function WrapperMixin:SetSize(new)
    local preset = ab.cfg
    local layout = preset and preset.layout
    local isTriple = preset and preset.isTriple
    local bar = ConsolePortBar 
    local main = self['']

    if not self.Buttons or not main then return end

    for mod, button in pairs(self.Buttons) do
        local layoutData = layout and layout[button.id]

        if isTriple and layoutData and layoutData.point then
            -- Absolute Parenting to prevent "Scrambling"
            if button:GetParent() ~= bar then
                button:SetParent(bar)
            end
            
            button:ClearAllPoints()
            -- Force absolute coordinates from Lookup.lua
            button:SetPoint(unpack(layoutData.point))
            button:SetSize(layoutData.size or new, layoutData.size or new)

			if button.icon then
				local useSquare = preset and preset.useSquareButtons
				local ratio = useSquare and (40/45) or 1
				local iSize = (layoutData.size or new) * ratio
				button.icon:ClearAllPoints()
				button.icon:SetSize(iSize, iSize)
				button.icon:SetPoint('CENTER', 0, 0)
			end
            
            button.isMainButton = true 
            button:Show()
            button:SetAlpha(1)

            -- Re-anchor hotkeys to top
            local hotkey = button.hotkey or button.hotkey1
            if hotkey then
                hotkey:ClearAllPoints()
                hotkey:SetPoint("TOP", button, "TOP", 0, 10)
                hotkey:SetAlpha(1)
                hotkey:Show()
            end
        else
            -- MINIMAL MODE Logic
            if mod ~= '' then
                if button:GetParent() ~= main then button:SetParent(main) end
            elseif button:GetParent() ~= bar then
                button:SetParent(bar)
            end
            
            local b, t, o
			local WING_SPREAD_DIAG = 0.6   -- affects SHIFT-/CTRL- (corner wings, uses `ofs`)
			local WING_SPREAD_AXIS = 0.4 
            if mod == '' then
                b, t = new, new
                o = new * (82 / 64)
                if button.shadow then button.shadow:SetSize(o, o) end
            else 
				local scale = new / size
				b = new * (46 / 64) 
				t = new * (58 / 64) 
				if mod == 'CTRL-SHIFT-' then t = t * 0.9 end
				
				local spread = (mod == 'CTRL-SHIFT-') and WING_SPREAD_AXIS or WING_SPREAD_DIAG
				
				local pT = mods[mod] and mods[mod][button.orientation]
				if pT then
					local p, rel, x, y = unpack(pT)
					button:ClearAllPoints()
					button:SetPoint(p, main, rel, x * scale * spread, y * scale * spread)
					button:Show()
				end
			end
            
            for _, parentKey in pairs(adjustTextures) do
                local tex = button[parentKey]
                if tex then
                    tex:ClearAllPoints()
                    tex:SetPoint('CENTER', 0, 0)
                    tex:SetSize(t, t)
                end
            end
            button:SetSize(b, b)

			if button.icon then
				local useSquare = preset and preset.useSquareButtons
				local ratio = useSquare and (40/45) or 1
				local iSize = b * ratio
				button.icon:ClearAllPoints()
				button.icon:SetSize(iSize, iSize)
				button.icon:SetPoint('CENTER', 0, 0)
			end
        end
        
        -- Final texture sync
        local finalSize = button:GetWidth()
        for _, parentKey in pairs(adjustTextures) do
            local tex = button[parentKey]
            if tex then tex:SetSize(finalSize, finalSize) end
        end
    end
end

function WrapperMixin:UpdateOrientation(orientation)
    local SliceMask = ab.libs.slicemask
    local preset = ab.cfg
    local isTriple = preset and preset.isTriple

    for mod, button in pairs(self.Buttons) do
        button.orientation = orientation
        local coords = modcoords[mod] and modcoords[mod][orientation]

        -- TRIPLE MODE: promoted buttons are handled by OnLoad, skip mask
        if isTriple and preset.layout and preset.layout[button.id] then
            button.isMainButton = true
            button:SetAlpha(1)
            button:Show()
            return
        elseif not button.isMainButton then
            button:ClearAllPoints()
            button:Hide()
        end

        -- Apply textures
        if coords then
            for _, parentKey in pairs(adjustTextures) do
                local tex = button[parentKey]
                if tex then tex:SetTexCoord(unpack(coords)) end
            end
        end

        -- Apply mask/swipe for non-main modifier buttons
        if mod ~= '' and not button.isMainButton then
            local mask  = masks[mod] and masks[mod][orientation]
            local swipe = swipes[mod] and swipes[mod][orientation]

            if mask then
                button.Flash:SetTexture(mask)
                -- button.Mask:SetTexture(mask) -- no-op in WotLK, kept for reference
            end
            if swipe then
                --button.cooldown:SetSwipeTexture(swipe)
            end

            -- WotLK ScrollFrame mask approximation (non-square only)
            if SliceMask and not button.isSquareMode then
                SliceMask:Apply(button, mod, orientation)
                if not button._sliceMaskHooked then
                    button._sliceMaskHooked = true
                    local orig = button.UpdateAction
                    button.UpdateAction = function(self, ...)
                        orig(self, ...)
                        SliceMask:UpdateTexture(self)
                    end
                end
            end
        end
    end

    self:SetSize(self['']:GetSize())
end

function WrapperMixin:SetSwipeColor(r, g, b, a)
	--self[''].cooldown:SetSwipeColor(r, g, b, a)
end

function WrapperMixin:ToggleIcon(enabled)
	CPAPI.SetShown(self[''].hotkey, enabled)
end

function WrapperMixin:ToggleModifiers(enabled)
	for mod, button in pairs(self.Buttons) do
		local hotkey1, hotkey2 = button.hotkey1, button.hotkey2
		if hotkey1 then CPAPI.SetShown(hotkey1, enabled) end
		if hotkey2 then CPAPI.SetShown(hotkey2, enabled) end
	end
end

function WrapperMixin:SetClassicBorders(enabled)
    local useSquare = ab.cfg and ab.cfg.useSquareButtons
    local isTriple = ab.cfg and ab.cfg.isTriple
    local TEX = [[Interface\AddOns\ConsolePortBar\Textures\Button\%s]]

    for mod, button in pairs(self.Buttons) do
        button.isSquareMode = useSquare

        local nt = button:GetNormalTexture()
        local pt = button:GetPushedTexture()
        local ht = button:GetHighlightTexture()
        local ct = button:GetCheckedTexture()
		
        local bw = button:GetWidth()

        if useSquare then
            if button.Shadow then button.Shadow:SetTexture(nil) end
            if button.Mask then button.Mask:Hide() end

            button.NormalTexture:ClearAllPoints()
            button.NormalTexture:SetPoint("CENTER", button, "CENTER", 4, -2)
            button.NormalTexture:SetTexture(TEX:format("SquareNormal"))
            button.NormalTexture:SetTexCoord(0, 1, 0, 1)
            button.NormalTexture:SetSize(bw * (52/45), bw * (51/45))

            button.PushedTexture:ClearAllPoints()
            button.PushedTexture:SetPoint("CENTER", button, "CENTER", 4, -2)
            button.PushedTexture:SetTexture(isTriple and TEX:format("SquareNormal") or TEX:format("SquarePushed"))
            button.PushedTexture:SetSize(bw * (52/45), bw * (51/45))

            button.HighlightTexture:ClearAllPoints()
            button.HighlightTexture:SetSize(bw * (46/45), bw * (45/45))
            button.HighlightTexture:SetPoint("CENTER", button, "CENTER", 1, 0)
            button.HighlightTexture:SetTexture(TEX:format("SquareHilite"))
            button.HighlightTexture:SetTexCoord(0, 1, 0, 1)

            button.CheckedTexture:ClearAllPoints()
            button.CheckedTexture:SetSize(bw * (46/45), bw * (45/45))
            button.CheckedTexture:SetPoint("CENTER", button, "CENTER", 1, 0)
            button.CheckedTexture:SetTexture(not isTriple and TEX:format("SquareHilite") or nil)

            local iconSize = bw * (40/45)
            button.icon:ClearAllPoints()
            button.icon:SetSize(iconSize, iconSize)
            button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)

            button.emptyIcon = [[Interface\AddOns\ConsolePortBar\Textures\ability-empty2]]

            button.cooldown:SetAlpha(1)
            button.cooldown:Show()
            button.cooldown:ClearAllPoints()
            button.cooldown:SetAllPoints(button)
            button.cooldown:SetFrameLevel(button:GetFrameLevel() + 5)
            button.cooldown:SetFrameStrata("MEDIUM")

            if button.roundcd then
                button.roundcd:Hide()
                button.roundcd:SetAlpha(0)
                if button.roundcd.spinner then
                    button.roundcd.spinner:Hide()
                    button.roundcd.spinner:SetAlpha(0)
                end
            end

            local shadow = button.shadow or (mod == '' and self[''].shadow)
            if shadow then
                shadow:Hide()
                shadow:SetAlpha(0)
            end
        else
            local isMain = (mod == '')
            local theme = isMain and "BigNormal" or (mod == 'CTRL-SHIFT-' and "M3" or "M1")
            local hilite = isMain and "BigHilite" or (mod == 'CTRL-SHIFT-' and "M3Hilite" or "M1Hilite")

            nt:SetTexture(TEX:format(theme))
            nt:SetSize(bw, bw)
            nt:ClearAllPoints()
            nt:SetPoint("CENTER", button, "CENTER", 0, 0)
            nt:SetTexCoord(0, 1, 0, 1)

            pt:SetTexture(TEX:format(hilite))
            pt:SetSize(bw, bw)
            pt:ClearAllPoints()
            pt:SetPoint("CENTER", button, "CENTER", 0, 0)

            ht:SetTexture(TEX:format(hilite))
            ht:SetSize(bw, bw)
            ht:ClearAllPoints()
            ht:SetPoint("CENTER", button, "CENTER", 0, 0)

            ct:SetTexture(TEX:format(hilite))
            ct:SetSize(bw, bw)
            ct:ClearAllPoints()
            ct:SetPoint("CENTER", button, "CENTER", 0, 0)

            local iconSize = bw
            button.icon:ClearAllPoints()
            button.icon:SetSize(iconSize, iconSize)
            button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)

            button.emptyIcon = [[Interface\AddOns\ConsolePortBar\Textures\ability-empty]]

            if button.Shadow then
                button.Shadow:SetTexture([[Interface\AddOns\ConsolePort\Textures\Button\Shadow]])
            end

            local shadowFrame = button.shadow or (mod == '' and self[''].shadow)
            if shadowFrame then
                shadowFrame:Show()
                shadowFrame:SetAlpha(0.3)
            end

            button.cooldown:SetAlpha(0)
            button.cooldown:SetFrameStrata("LOW")

            if button.roundcd then
                button.roundcd:Show()
                button.roundcd:SetAlpha(1)
                if button.roundcd.spinner then
                    button.roundcd.spinner:Show()
                    button.roundcd.spinner:SetAlpha(0)
                end
            end

            if not isMain then
                local orientation = button.orientation or "down"
                local coords = modcoords[mod] and modcoords[mod][orientation]
                if coords then
                    nt:SetTexCoord(unpack(coords))
                    ht:SetTexCoord(unpack(coords))
                end
            end
        end

        button:UpdateAction(true)
    end
end
function WrapperMixin:SetBorderColor(r, g, b, a)
	for mod, button in pairs(self.Buttons) do
		button.NormalTexture:SetVertexColor(r, g, b, a)
	end
end

function WrapperMixin:ConfigureSwapStates(modifier, button, stateType, stateID)
	-- modifier buttons should stay the same regardless of state
	if modifier ~= '' then
		button:SetState('', stateType, stateID)
		button:SetState('SHIFT-', stateType, stateID)
		button:SetState('CTRL-', stateType, stateID)
		button:SetState('CTRL-SHIFT-', stateType, stateID)
	end
	-- set up main button to swap to current state
	self['']:SetState(modifier, stateType, stateID)
end

function WrapperMixin:SetRebindButton()
	-- Messy code to focus this button in the rebinder
	-- TODO: Update for new config
	if not InCombatLockdown() then
		ConsolePortOldConfig:OpenCategory('Binds')
		if ConsolePortOldConfigContainerBinds.Display:GetID() ~= 2 then
			db.Settings.bindView = 2
			ConsolePortOldConfigContainerBinds.Display:SetID(2)
			ConsolePortOldConfigContainerBinds:OnShow()
		end
		local bindingBtn = _G[self.confRef]
		CPAPI.TimerAfter(0.1, function()
			if not InCombatLockdown() then
				ConsolePort:ScrollToNode(bindingBtn, ConsolePortRebindFrame)
			end
		end)
	end
end
---------------------------------------------------------------
local function CreateButton(parent, id, name, modifier, size, texSize, config)
	local button = acb:CreateButton(id, name, parent, config)

	button.NormalTexture = button:GetNormalTexture()
	button.PushedTexture = button:GetPushedTexture()
	button.HighlightTexture = button:GetHighlightTexture()
	button.CheckedTexture = button:GetCheckedTexture()
 
	button.Flash = _G[name..'Flash']
	button.Mask = _G[name..'IconMask']
	button.Border = _G[name..'Border']
	button.Shadow = _G[name..'Shadow']
	button.cooldown = _G[name..'Cooldown'];
	button.roundcd = _G[name..'RCooldown']

	local textures = buttonTextures[modifier]

	button.NewActionTexture:SetTexture(textures.new_action)
	button.NormalTexture:SetTexture(textures.normal)
	button.PushedTexture:SetTexture(textures.pushed)
	button.CheckedTexture:SetTexture(textures.checkd)
	button.HighlightTexture:SetTexture(textures.hilite)
	button.Border:SetTexture(textures.border)

--	button.cooldown:SetSwipeTexture(textures.cool_swipe)
--	button.cooldown:SetBlingTexture(textures.cool_bling)
--	button.cooldown.text = button.cooldown:GetRegions()

	-- Small buttons should not have drop shadow and smaller CD font
	if modifier ~= '' then
--		local file, height, flags = button.cooldown.text:GetFont()
--		button.cooldown.text:SetFont(file, height * 0.75, flags)
--		button:ToggleShadow(false)
	end

	if textures.cool_edge then
--		button.cooldown:SetEdgeTexture(textures.cool_edge)
--		button.cooldown:SetDrawEdge(true)
	else
--		button.cooldown:SetDrawEdge(false)
	end

	for _, parentKey in pairs(adjustTextures) do
		local texture = button[parentKey]
		texture:ClearAllPoints()
		texture:SetPoint('CENTER', 0, 0)
		texture:SetSize(texSize, texSize)
	end

	button:SetSize(size, size)
	button:SetAlpha(0)

	return button
end

local function CreateModifierHotkeyFrame(self, num)
	return CreateFrame('Frame', '$parent_HOTKEY'..( num or '' ), self, 'CPUIActionButtonTextureOverlayTemplate')
end

local function CreateMainHotkeyFrame(self, id)
	local hotkey = CreateFrame('Frame', '$parent_HOTKEY', self, 'CPUIActionButtonMainHotkeyTemplate')
	hotkey.texture:SetTexture(db.ICONS[id])
	return hotkey
end

local function CreateMainShadowFrame(self)
	-- create this as a separate frame so that drop shadow doesn't overlay modifiers
	-- note: shadow is child of bar, not of button
	local shadow = CreateFrame('Frame', self:GetName()..'_SHADOW', ab.bar, 'CPUIActionButtonMainShadowTemplate')
	shadow:SetPoint('CENTER', self, 'CENTER', 0, -6)
	return shadow
end
---------------------------------------------------------------

function HANDLE:Get(id)
	return Wrappers[id]
end

function HANDLE:Create(parent, id, orientation)
	local wrapper = {}
	wrapper.Buttons = {}

	for mod, info in pairs(mods) do
		local name = 'CPB_' .. (id:sub(4, #id)) .. (mod == '' and mod or ('_' .. (mod:sub(1, #mod -1))))
		local bSize, tSize = unpack(info.size)
		local button = CreateButton(parent, id..mod, name, mod, bSize, tSize, mod == '' and config)
		button.plainID = id
		button.mod = mod
		-- dispatch to header
		button:SetAttribute('plainID', id)
		button:SetAttribute('modifier', mod)
		-- store button in the wrapper
		wrapper[mod] = button
		wrapper.Buttons[mod] = button
		if hotkeyConfig[mod] then
			for i, modHotkey in pairs(hotkeyConfig[mod]) do
				local hotkey = CreateModifierHotkeyFrame(button, i)
				hotkey:SetPoint(unpack(modHotkey[1]))
				hotkey:SetSize(unpack(modHotkey[2]))
				hotkey.texture:SetTexture(db.ICONS[modHotkey[3]])
				hotkey:SetAlpha(0.75)
				button['hotkey'..i] = hotkey
			end
		end
	end

	local main = wrapper['']
	main.isMainButton = true

	main:SetFrameLevel(4)
	main:SetAlpha(1)
	main.hotkey = CreateMainHotkeyFrame(main, id)

	for mod, button in pairs(wrapper.Buttons) do
		if mod ~= '' then
			-- Create a hotkey frame for the modified buttons for the triple preset, but make it hidden by default
			button.hotkey = button.hotkey or CreateMainHotkeyFrame(button, id) 
			button.hotkey:Hide()
		end
	end

	main.shadow = CreateMainShadowFrame(main)
	db.UIFrameFadeIn(main, 1, 0, 1)

	CPAPI.Mixin(wrapper, WrapperMixin)

	wrapper:UpdateOrientation(orientation)

	Wrappers[id] = wrapper

	return wrapper
end

function HANDLE:UpdateAllBindings(newBindings)
	local bindings = newBindings or db.Bindings
	--ClearOverrideBindings(ab.bar)
	if type(bindings) == 'table' then
		for binding, wrapper in pairs(Wrappers) do
			self:UpdateWrapperBindings(wrapper, bindings[binding])
		end
	end
end

function HANDLE:SetEligbleForRebind(button, id)
	button.confRef = button.plainID..id..'_CONF'
	button:SetAttribute('disableDragNDrop', true)
	button:SetState(id, 'custom', {
		tooltip = NOT_BOUND_TOOLTIP,
		texture = [[Interface\AddOns\ConsolePortBar\Textures\Icons\Unbound]],
		func = WrapperMixin.SetRebindButton,
	})
end

function HANDLE:SetArbitraryBinding(button, binding)
	button:SetAttribute('disableDragNDrop', true)
	return 'custom', {
		tooltip = ConsolePort:GetUtilityRingName(binding) or _G['BINDING_NAME_'..binding] or binding,
		texture = ab:GetBindingIcon(binding) or [[Interface\MacroFrame\MacroFrame-Icon]],
		func = function() end,
	}
end

function HANDLE:SetActionBinding(button, main, id, actionID)
	local key = GetBindingKey(button.plainID)
	if key then
		ab.bar:RegisterOverride(id..key, main:GetName())
	end
	button:SetAttribute('disableDragNDrop', (ab.cfg and ab.cfg.disablednd and true) or false)
	return 'action', actionID
end

function HANDLE:UpdateWrapperBindings(wrapper, bindings)
	if InCombatLockdown() then return end;
	
	local main = wrapper['']

	-- Skip dummy buttons entirely
    if main and main._state_type == 'dummy' then return end

	if bindings then
		for modifier, button in pairs(wrapper.Buttons) do
			local binding = bindings[modifier]
			local actionID
			--if(GetBonusBarOffset() > 0) then
			--	actionID = binding and ConsolePort:GetWBonusActionID(binding, GetBonusBarOffset())
			--else
				actionID = binding and ConsolePort:GetActionID(binding)
			--end
			local stateType, stateID
			if actionID then
				stateType, stateID = self:SetActionBinding(button, main, modifier, actionID)
			elseif binding then
				stateType, stateID = self:SetArbitraryBinding(button, binding)
			else
				self:SetEligbleForRebind(button, modifier)
			end

			wrapper:ConfigureSwapStates(modifier, button, stateType, stateID)
			-- call an update on the button to reflect new binding
			button:Execute(format([[
				control:RunAttribute('UpdateState', '%s')
				control:CallMethod('UpdateAction')
			]], modifier))
		end
	else
		for modifier, button in pairs(wrapper.Buttons) do
			self:SetEligbleForRebind(button, modifier)
		end
	end
end