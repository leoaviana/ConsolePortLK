---------------------------------------------------------------
local db = ConsolePort:GetData()
local CPAPI = db.CPAPI
---------------------------------------------------------------
local _, ab = ...
---------------------------------------------------------------
local cfg

local Bar = ConsolePortBar
local WrapperLib = ab.libs.wrapper
local state, now = ConsolePort:GetActionPageDriver()

local BAR_MIN_WIDTH = 1105
local BAR_MAX_SCALE = 1.6
local BAR_FIXED_HEIGHT = 140

-- Set up action bar
---------------------------------------------------------------
ab.bar = Bar
ab.data = db
---------------------------------------------------------------

Bar:SetAttribute('actionpage', now)
Bar:SetFrameRef('ActionBar', MainMenuBarArtFrame)
Bar:SetFrameRef('BonusActionBar', BonusActionBarFrame)  
--Bar:SetFrameRef('OverrideBar', OverrideActionBar)
Bar:SetFrameRef('Cursor', ConsolePortRaidCursor)
Bar:SetFrameRef('Mouse', ConsolePortMouseHandle)

Bar:Execute([[
	bindings = newtable()
	reticleSpellManifest = newtable()
	reticleMacroString = '/run if C_ConsoleXP then C_ConsoleXP:CastReticle() end' -- reticleMacroString = '/stopspelltarget\n/cast [@cursor] %s'
	bar = self
	cursor = self:GetFrameRef('Cursor')
	mouse = self:GetFrameRef('Mouse')
	self:SetAttribute('state', '')

	UpdateTripleScale = [=[
        local state = ...
        local myMod = self:GetAttribute("modifier") or ""
        -- Retrieve the custom base scale (default to 1.0 if not set)
        local base = self:GetAttribute("baseScale") or 1.0

        if (state == myMod or (state == 'CTRL-SHIFT-' and myMod == '')) and not self:GetAttribute("static") then 
            -- Active cluster: 105% of its base size.
            self:SetScale(base * 1.05)
        else 
            -- Inactive cluster: its natural base size
            self:SetScale(base)
        end
    ]=]
]])

function Bar:ResetAllButtons()
    -- Kill dividers from previous cfg
    local prevCfg = ab.cfg
    if prevCfg and prevCfg.dividers then
        for id in pairs(prevCfg.dividers) do
            local div = self[id]
            if div then div:Hide() self[id] = nil end
        end
    end

    local swapIDs = {'CP_T3', 'CP_T4'}
    for _, id in ipairs(swapIDs) do
        local wrapper = ab.libs.registry[id]
        if wrapper and wrapper[''] then
            wrapper[''].isMainButton = nil
        end
    end

    -- Reset all wrapper buttons
    local snippet = ab.libs.acb.childUpdateSnippet and ab.libs.acb.childUpdateSnippet()
    for id, wrapper in pairs(ab.libs.registry) do
        for mod, button in pairs(wrapper.Buttons) do
            if ab.libs.slicemask then
                ab.libs.slicemask:Remove(button)
                button._sliceMaskHooked = nil
                button._sliceMaskContainer = nil
            end

            button.isMainButton = nil
            button.tripleShims = nil
            button:SetScale(1.0)
            -- Clear fake textures
            if button.FakePushed then
                button.FakePushed:SetAlpha(0)
                button.FakePushed = nil
            end
            if button.FakeChecked then
                button.FakeChecked:SetAlpha(0)
                button.FakeChecked = nil
            end
            -- Restore stripped attribute
            if snippet and not button:GetAttribute("_childupdate-state") then
                button:SetAttribute("_childupdate-state", snippet)
            end

		    if mod ~= '' then 
			    button.hotkey:Hide() 
            end
            
            for i = 1, 2 do
                local modIcon = button['hotkey'..i]
                if modIcon then 
                    modIcon:Show()
                    modIcon:SetAlpha(1) 
                end
            end

            button:SetAlpha(0)
            button:Hide()
        end
        -- Main nomod button is always promoted by default
        local main = wrapper['']
        if main then
            main.isMainButton = true
            main:SetAlpha(1)
            main:Show()
        end
    end
end

function Bar:FadeIn(alpha)
	db.UIFrameFadeIn(self, .25, alpha or 0, 1)
end

function Bar:PrimeCurrentActionPage()
	if InCombatLockdown() then return end
	-- A character can enter the world already in Prowl/form. In that case no
	-- initial stance transition occurs to seed the secure children with the
	-- existing bonus page. Explicitly run the same secure page update once after
	-- login so the first stealth exit has a fully initialized Prowl action.
	self:Execute([[
		control:RunAttribute('UpdateActionBar')
		local held = self:GetAttribute('state-modifier') or self:GetAttribute('state') or ''
		self:SetAttribute('state', held)
		control:ChildUpdate('state', held)
	]])
	self:RefreshModifierCooldowns()
end

function Bar:ReconcileFormMenuState()
    if InCombatLockdown() then return end
    -- Reuse the proven page/child refresh, but read live keys instead of a
    -- cached modifier state after an external menu cancels the player's form.
    self:Execute([[
        control:RunAttribute('UpdateActionBar')
        local held = SecureCmdOptionParse('[mod:ctrl,mod:shift] CTRL-SHIFT-; [mod:ctrl] CTRL-; [mod:shift] SHIFT-;') or ''
        self:SetAttribute('state-modifier', held)
        self:SetAttribute('state', held)
        control:ChildUpdate('state', held)
        if self:GetAttribute('isTriple') then
            local count = self:GetAttribute('childCount') or 0
            for i = 1, count do
                local child = self:GetFrameRef('child'..i)
                if child then control:RunFor(child, UpdateTripleScale, held) end
            end
            control:CallMethod('UpdateDividerFocus', held)
        end
    ]])
    self:RefreshModifierCooldowns()
end

function Bar:RefreshModifierCooldowns()
	if ab.libs.acb and ab.libs.acb.RefreshCooldowns then
		ab.libs.acb:RefreshCooldowns()
		-- WotLK can publish the new action/page identity one frame after the
		-- secure state transition. Reconcile once more after that propagation
		-- so first-use cooldowns behave like subsequent uses.
		CPAPI.TimerAfter(0.05, function()
			if ab.libs.acb and ab.libs.acb.RefreshCooldowns then
				ab.libs.acb:RefreshCooldowns()
			end
		end)
	end
end

function Bar:FadeOut(alpha)
	db.UIFrameFadeOut(self, 1, alpha or 1, 0)
end

function Bar:StopCamera()
	ConsolePortCamera:Stop()
end

function Bar:ToggleMovable(enableMouseDrag, enableMouseWheel)
	self:RegisterForDrag(enableMouseDrag and 'LeftButton')
	self:EnableMouse(enableMouseDrag)
	self:EnableMouseWheel(enableMouseWheel)
end

function Bar:UnregisterOverrides()
	self:Execute([[
		bindings = wipe(bindings)
		self:ClearBindings()
	]])
end

function Bar:UpdateOverrides()
	self:Execute([[
		for key, button in pairs(bindings) do
			self:SetBindingClick(true, key, button, 'ControllerInput')
		end
	]])
end

function Bar:RegisterOverride(key, button)
	self:Execute(format([[
		bindings['%s'] = '%s'
	]], key, button))
end

function Bar:OnNewBindings(...)
	if not InCombatLockdown() then
		self:UnregisterOverrides()
		WrapperLib:UpdateAllBindings(...)
		self:UpdateOverrides()
        self:SetupShoulderButtons()
	end
end

ConsolePort:RegisterCallback('OnNewBindings', Bar.OnNewBindings, Bar)
ConsolePort:RegisterSpellHeader(Bar, true)

function Bar:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function Bar:PLAYER_REGEN_ENABLED()
	self:FadeOut(self:GetAlpha())
end

function Bar:PLAYER_REGEN_DISABLED()
	self:FadeIn(self:GetAlpha())
end

function Bar:UPDATE_BONUS_ACTIONBAR()
	WrapperLib:UpdateAllBindings()
end

function Bar:LoadReticleSpells()
	Bar:Execute('wipe(reticleSpellManifest)')
	local reticleSpells = ab.manifest and ab.manifest.ReticleSpells
	if type(reticleSpells) == 'table' then
		local classSpecific = reticleSpells[select(2, UnitClass('player'))]
		if type(classSpecific) == 'table' then
			for spellID, name in pairs(classSpecific) do
				Bar:Execute(format('reticleSpellManifest[%d] = "%s"', spellID, name))
			end
		end
	end
	self.LoadReticleSpells = nil
end

function Bar:ADDON_LOADED(name)
	if name == _ then
		if not ConsolePortBarSetup then
			ConsolePortBarSetup = ab:GetDefaultSettings()
		-------------------------------
		-- compat: binding ID fix for grip buttons , remove later on
		else local layout = ConsolePortBarSetup.layout
			if layout then
				layout.CP_T3 = layout.CP_T3 or layout.CP_L_GRIP1 -- translate Lgrip1 to t3
				layout.CP_T4 = layout.CP_T4 or layout.CP_R_GRIP1 -- translate Rgrip1 to t4
				layout.CP_L_GRIP1 = nil layout.CP_R_GRIP1 = nil
				layout.CP_T5 = layout.CP_T5 or layout.CP_L_GRIP2 -- translate Lgrip2 to t5
				layout.CP_T6 = layout.CP_T6 or layout.CP_R_GRIP2 -- translate Rgrip2 to t6
				layout.CP_L_GRIP2 = nil layout.CP_R_GRIP2 = nil
			end
		-------------------------------
		end
		ab:CreateManifest()
		self:LoadReticleSpells()
		self:OnLoad(ConsolePortBarSetup)
		self:UnregisterEvent('ADDON_LOADED')
		self:RegisterEvent('UPDATE_BONUS_ACTIONBAR')
		self.ADDON_LOADED = nil
	end
end

function Bar:OnMouseWheel(delta)
	if not InCombatLockdown() then
		local cfg = ab.cfg
		if IsShiftKeyDown() then
			local newWidth = self:GetWidth() + ( delta * 10 )
			cfg.width = newWidth > BAR_MIN_WIDTH and newWidth or BAR_MIN_WIDTH
			self:SetWidth(cfg.width)
		else
			local newScale = self:GetScale() + ( delta * 0.1 )
			if newScale > BAR_MAX_SCALE then cfg.scale = BAR_MAX_SCALE
			elseif newScale <= 0 then cfg.scale = 0.1
			else cfg.scale = newScale end 
			self:SetScale(cfg.scale)
		end
	end
end

function Bar:SetupShoulderButtons()
    local registry = ab.libs.registry
    local layout = ab.cfg and ab.cfg.layout

    -- v141: Triple shoulder strip geometry belongs to the saved layout.
    -- Do not recompute/reverse positions from binding availability on load.
    -- Xbox semantics: CP_T1=LB, CP_M1=LT, CP_M2=RT, CP_T2=RB.
    -- CP_T3/T4 are only dummy visual carriers for LT/RT when those modifier
    -- controls have no independent action binding.
    if ab.cfg and ab.cfg.isTriple and layout then
        for _, id in ipairs({'CP_T1','CP_T3','CP_T4','CP_T2'}) do
            local data = layout[id]
            local wrapper = registry[id]
            local btn = wrapper and wrapper['']
            if btn then
                if data and not data.hidden then
                    btn:Show(); btn:SetAlpha(1)
                else
                    btn:Hide(); btn:SetAlpha(0)
                end
            end
        end
    end
    local shoulderMap = {
        ['CP_T3'] = 'CP_M1',
        ['CP_T4'] = 'CP_M2',
    }

    for shoulderID, modifierID in pairs(shoulderMap) do
        if layout and layout[shoulderID] then
            local wrapper = registry[shoulderID]
            local btn = wrapper and wrapper['']
            if btn then
                local hasKey = GetBindingKey(shoulderID) ~= nil
                if not hasKey then
                    btn:SetAttribute('disableDragNDrop', true)
                    local iconPath = "Interface\\AddOns\\ConsolePort\\Controllers\\"..db('type').."\\Icons64\\"
                    local tooltipText = modifierID == 'CP_M1'
                        and 'Modifier 1: Shift\nHold to swap binding set.'
                        or  'Modifier 2: Ctrl\nHold to swap binding set.'
                    ab.libs.acb.SetDummy(btn, iconPath .. db(modifierID), tooltipText)
                    wrapper:ToggleIcon(not (ab.cfg and ab.cfg.hideIcons))
                    if btn.hotkey then btn.hotkey.texture:SetTexture(db.ICONS[modifierID]) end
                    for i = 1, 2 do
                        local modIcon = btn['hotkey'..i]
                        if modIcon then
                            modIcon:Hide()
                            modIcon:SetAlpha(0)
                        end
                    end

                    for mod, subBtn in pairs(wrapper.Buttons) do
                        if mod ~= '' then
                            subBtn:SetAlpha(0)
                            subBtn:Hide()
                        end
                    end
                else
                    ab.libs.acb.RestoreButton(btn)
                    btn:SetAttribute('disableDragNDrop', nil)
                    wrapper:ToggleIcon(not (ab.cfg and ab.cfg.hideIcons))
                    if btn.hotkey then btn.hotkey.texture:SetTexture(db.ICONS[shoulderID]) end
                    for i = 1, 2 do
                        local modIcon = btn['hotkey'..i]
                        if modIcon then
                            modIcon:Show()
                            modIcon:SetAlpha(1)
                        end
                    end

                    for mod, subBtn in pairs(wrapper.Buttons) do
                        if mod ~= '' then
                            subBtn:SetAlpha(1)
                            subBtn:Show()
                        end
                    end
                    -- Restore proper metatable
                    WrapperLib:UpdateWrapperBindings(wrapper, ConsolePort:GetCurrentBindings()[shoulderID])
                end
            end
        end
    end
end

function Bar:OnLoad(cfg, benign)
	if not InCombatLockdown() then
        self:ResetAllButtons()
    end
	
    local r, g, b = db.Atlas.GetNormalizedCC()
    -- v153: migrate legacy hidden records to the v140 presence/absence contract.
    -- Preset geometry remains available separately to the editor.
    if cfg.layout then
        for binding, entry in pairs(cfg.layout) do
            if entry.hidden == true then cfg.layout[binding] = nil end
        end
    end
    if not ab.reloadBaseline then
        ab.reloadBaseline = db.table.copy(cfg)
    end
    ab.cfg = cfg
    ConsolePortBarSetup = cfg
    -- v142: retain preset identity with the saved profile. This lets the
    -- settings GUI seed never-before-enabled buttons from the correct preset.
    if not cfg.activePreset then
        -- v143: old SavedVariables predate activePreset and often contain user
        -- edits, so exact table comparison cannot identify them. Distinctive
        -- layout flags identify the square presets safely.
        if cfg.isTriple then
            cfg.activePreset = 'Crossbar: Triple'
        elseif cfg.useSquareButtons then
            cfg.activePreset = 'Crossbar: Minimal'
        else
            for presetName, presetCfg in pairs(ab:GetPresets()) do
                if db.table.compare(cfg.layout or {}, presetCfg.layout or {}) then
                    cfg.activePreset = presetName
                    break
                end
            end
        end
    end
    self:SetScale(cfg.scale or 1)

    -- Bar Visibility Driver
    self:SetAttribute('hidesafe', cfg.hidebar)
    if cfg.hidebar then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        self:RegisterEvent('PLAYER_REGEN_DISABLED')
        self:FadeOut(self:GetAlpha())
    else
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        self:UnregisterEvent('PLAYER_REGEN_DISABLED')
        self:FadeIn(self:GetAlpha())
    end

    if CPAPI.CPCC then
        if cfg.enablecooldowntext then CPAPI.CPCC:Enable() else CPAPI.CPCC:Disable() end
    end

    -- Re-evaluate every cooldown immediately when bar options are applied.
    -- This restores both satellite visibility and numerical cooldown text when
    -- the option is re-enabled while an ability is already cooling down.
    if ab.libs.acb and ab.libs.acb.RefreshCooldowns then
        ab.libs.acb:RefreshCooldowns()
    end

    local visDriver = cfg.combathide and '[nocombat] show; hide' or '[combat][nocombat] show; hide'
    RegisterStateDriver(Bar, 'visibility', visDriver)

    -- Pet Driver
    if cfg.hidepet then
        UnregisterStateDriver(Bar.Pet, 'visibility')
        Bar.Pet:Hide()
    elseif cfg.combatpethide then
        RegisterStateDriver(Bar.Pet, 'visibility', '[pet,nocombat] show; hide')
    else
        RegisterStateDriver(Bar.Pet, 'visibility', '[pet] show; hide')
    end

    -- Visual Stylings
    if cfg.showline then self.BG:Show() self.BottomLine:Show() else self.BG:Hide() self.BottomLine:Hide() end
    ab:SetArtUnderlay(cfg.showart or cfg.flashart, cfg.flashart)
    ab:SetRainbowScript(cfg.rainbow)

    if cfg.tintRGB then
        self.BG:SetGradientAlpha(ab:GetColorGradient(unpack(cfg.tintRGB)))
        self.BottomLine:SetVertexColor(unpack(cfg.tintRGB))
    else
        self.BG:SetGradientAlpha(ab:GetColorGradient(r, g, b))
        self.BottomLine:SetVertexColor(r, g, b, 1)
    end

    CPAPI.SetShown(self.Menu, cfg.quickMenu)
    self.Pet:RegisterForDrag(not cfg.lockpet and 'LeftButton' or nil)
    self:ToggleMovable(not cfg.lock, cfg.mousewheel)

    -- Core Layout Processing
    cfg.layout = cfg.layout or ab:GetDefaultButtonLayout()
    local layout = cfg.layout
    local hideIcons = cfg.hideIcons
    local hideModifiers = cfg.hideModifiers
    local classicBorders = cfg.classicBorders

    -----------------------------------------------------------
    -- TRIPLE PRESET: Deterministic Initialization
    -----------------------------------------------------------
    wipe(self.Buttons)
    self:SetAttribute('isTriple', cfg.isTriple)

	if cfg.dividers then
        for id, dividerData in pairs(cfg.dividers) do
            local div = ab.Divider:Create(self, id)
            ab.Divider:Update(div, dividerData, "M0") -- Default state
            self:SetFrameRef(id, div)
			self[id] = div -- Direct reference for quick access in focus updates
        end
    end

	local buttonIndex = 0
    for id, layoutData in pairs(layout) do
        if not layoutData.hidden then
        local baseID = id:match("^(CP_[^_]+_[^_]+)") or id
        
        -- Get or create the logic wrapper for the binding group
        local wrapper = WrapperLib:Get(baseID) or WrapperLib:Create(self, baseID, layoutData.dir or "down")

        local suffix = id:match("CP_[^_]+_[^_]+_(.+)$") or ""
        local modString = (suffix == "SHIFT" and "SHIFT-") or 
                          (suffix == "CTRL" and "CTRL-") or 
                          (suffix == "CTRL_SHIFT" and "CTRL-SHIFT-") or ""
        
        local button = wrapper.Buttons[modString]
        if button then 
			buttonIndex = buttonIndex + 1
            button.id = id -- Crucial: Set ID so WrapperMixin:SetSize finds layoutData
            button.isMainButton = true -- Bypass automatic hiding/ghosting
			button:SetAttribute("modifier", modString)
            button:SetAlpha(1)
            button:Show()
			button:SetAttribute("static", layoutData.static)

			self:SetFrameRef("child"..buttonIndex, button)
        end

        local exists = false
        for _, existing in ipairs(self.Buttons) do if existing == wrapper then exists = true end end
        if not exists then self.Buttons[#self.Buttons + 1] = wrapper end

        wrapper:SetSize(layoutData.size or 45)
        wrapper:UpdateOrientation(layoutData.dir or 'down')

        if id == baseID and layoutData.point then
            wrapper:SetPoint(unpack(layoutData.point))
        end

		if button then
			local baseScale = layoutData.scale or 1.0
    		button:SetAttribute("baseScale", baseScale)
    		button:SetScale(baseScale)
		end

        -- Visual Sync
        wrapper:ToggleIcon(not hideIcons)
        wrapper:ToggleModifiers(not hideModifiers)
        wrapper:SetClassicBorders(classicBorders)
        wrapper:SetSwipeColor(unpack(cfg.swipeRGB or {r, g, b, 1}))
        wrapper:SetBorderColor(unpack(cfg.borderRGB or {1, 1, 1, 1}))
        end
    end

	-- Strip _childupdate-state from non-promoted buttons only
	for _, wrapper in ipairs(self.Buttons) do
		for mod, button in pairs(wrapper.Buttons) do
			if not button.isMainButton then
				button:SetAttribute('_childupdate-state', nil)
            end

            if mod ~= '' then
                if(button.isMainButton) then
				    button.hotkey:Show()
                    for i = 1, 2 do
                        local modIcon = button['hotkey'..i]
                        if modIcon then
                            modIcon:Hide()
                            modIcon:SetAlpha(0) 
                        end
                    end
                end
			end  
		end
	end

	self:SetAttribute("childCount", buttonIndex)

	if cfg.isTriple then
    	self:SetupTripleClickVisuals()
	end
    -----------------------------------------------------------

    self.WatchBarContainer:Hide()
    CPAPI.SetShown(self.WatchBarContainer, not cfg.hidewatchbars)

    if not benign then
        WrapperLib:UpdateAllBindings()
        self:Hide() 
        CPAPI.SetShown(self, not cfg.hidebar)
        self:SetAttribute('disableCastOnRelease', cfg.disablecastonrelease)
        self:SetAttribute('page', 1)
        self:Execute(format([[
            disableCastOnRelease = self:GetAttribute('disableCastOnRelease')
            control:ChildUpdate('state', '')
            control:RunAttribute('_onstate-page', '%s')
        ]], now or 1))
    end

    if cfg.showbuttons then
        self.Eye:SetAttribute('showbuttons', true)
        self:Execute("control:ChildUpdate('hover', true)")
    else
        self.Eye:SetAttribute('showbuttons', false)
        self:Execute("control:ChildUpdate('hover', false)")
    end

    local width = cfg.width or (#self.Buttons > 10 and (10 * 110) + 55 or (#self.Buttons * 110) + 55)
    self:SetSize(width, BAR_FIXED_HEIGHT)

    self:SetupShoulderButtons()
end

function Bar:UpdateDividerFocus(newstate)
    local cfg = ab.cfg
    local dividers = cfg and cfg.dividers
    if not dividers then return end
    
    -- Syncing the state strings exactly
    local modMap = { 
        [""] = "M0", 
        ["SHIFT-"] = "M1", 
        ["CTRL-"] = "M2",
        ["CTRL-SHIFT-"] = "M0" -- Usually center is default for double mods in Triple
    }
    local currentMod = modMap[newstate] or "M0"

    for id, data in pairs(dividers) do	
        local div = self[id] 
        if div then
            ab.Divider:Update(div, data, currentMod)
        end
    end
end

function Bar:SetupTripleClickVisuals()
    -- Build lookup: baseButtonName -> { modString -> shimButton }
    local shimLookup = {}
	
    local TEX = [[Interface\AddOns\ConsolePortBar\Textures\Button\%s]]
    
    for _, wrapper in ipairs(self.Buttons) do
        for modString, button in pairs(wrapper.Buttons) do
            if button.isMainButton and modString ~= "" then
                -- Find the corresponding nomod button by name pattern
                -- e.g. CPB_L_LEFT_SHIFT- -> base is CPB_L_LEFT
                local baseName = button:GetName():match("^(CPB_[^_]+_[^_]+)") 
                if baseName then
                    if not shimLookup[baseName] then
                        shimLookup[baseName] = {}
                    end
                    shimLookup[baseName][modString] = button
                end
            end
        end
    end

    for _, wrapper in ipairs(self.Buttons) do
        local mainButton = wrapper['']
        if mainButton and mainButton.isMainButton then
			-- Create fake pushed on the main button too for nomod/CTRL-SHIFT- clicks
			local fakeMainPushed = mainButton:CreateTexture(nil, "OVERLAY")
			fakeMainPushed:ClearAllPoints()
			fakeMainPushed:SetPoint("CENTER", mainButton, "CENTER", mainButton:GetWidth() * (4/45), mainButton:GetHeight() * (-2/45))
			fakeMainPushed:SetTexture(TEX:format("SquarePushed"))
			fakeMainPushed:SetSize(mainButton:GetWidth() * (52/45), mainButton:GetHeight() * (51/45))
			fakeMainPushed:SetAlpha(0)
			mainButton.FakePushed = fakeMainPushed

			-- Create fake checked on the main button too for nomod/CTRL-SHIFT- clicks
			local fakeMainChecked = mainButton:CreateTexture(nil, "OVERLAY")
			fakeMainChecked:ClearAllPoints() 
			fakeMainChecked:SetSize(mainButton:GetWidth() * (46/45), mainButton:GetHeight() * (45/45)) 
			fakeMainChecked:SetPoint("CENTER", mainButton, "CENTER", mainButton:GetWidth() * (1/45), 0)
			fakeMainChecked:SetTexture(TEX:format("SquareHilite"))
			fakeMainChecked:SetBlendMode("ADD")
			fakeMainChecked:SetAlpha(0)
			
			mainButton.FakeChecked = fakeMainChecked

            local myMod = mainButton:GetAttribute("modifier") or ""
            if myMod == "" then
                local baseName = mainButton:GetName():match("^(CPB_[^_]+_[^_]+)")
                local shims = baseName and shimLookup[baseName]
				mainButton.tripleShims = shims
                if shims then

					for _, shim in pairs(shims) do
						local fake = shim:CreateTexture(nil, "OVERLAY")
						fake:ClearAllPoints()
						fake:SetPoint("CENTER", shim, "CENTER", shim:GetWidth() * (4/45), shim:GetHeight() * (-2/45))
						fake:SetTexture(TEX:format("SquarePushed"))
						fake:SetSize(shim:GetWidth() * (52/45), shim:GetHeight() * (51/45))
						fake:SetAlpha(0)
						shim.FakePushed = fake

						local fakeChecked = mainButton:CreateTexture(nil, "OVERLAY")
						fakeChecked:ClearAllPoints() 
						fakeChecked:SetSize(shim:GetWidth() * (46/45), shim:GetHeight() * (45/45)) 
						fakeChecked:SetPoint("CENTER", shim, "CENTER", shim:GetWidth() * (1/45), 0)
						fakeChecked:SetTexture(TEX:format("SquareHilite"))
						fakeChecked:SetBlendMode("ADD")
						fakeChecked:SetAlpha(0)
						
						shim.FakeChecked = fakeChecked
					end

                    mainButton:HookScript("PreClick", function(self, button, down)
                        if not self.header:GetAttribute("isTriple") then return end
                        local state = self:GetAttribute("state")
                         if state == "SHIFT-" or state == "CTRL-" then
							local shim = shims[state]
							if shim and shim.FakePushed then
								shim.FakePushed:SetAlpha(down and 1 or 0)
							end
						else
							if self.FakePushed then
								self.FakePushed:SetAlpha(down and 1 or 0)
							end
						end
                    end)
                end
            end
        end
    end
end

--------------------------
---- Secure functions ----
--------------------------
for name, script in pairs({
	['_onhide'] = [[
		self:ClearBindings()
	]],
	['_onshow'] = [[
		for key, button in pairs(bindings) do
			self:SetBindingClick(true, key, button, 'ControllerInput')
		end
		control:RunFor(mouse, mouse:GetAttribute('UpdateTarget'), mouse:GetAttribute('current'))
		if PlayerInCombat() or ( not self:GetAttribute('hidesafe') ) then
			control:CallMethod('FadeIn')
		end
	]],
	['_onstate-modifier'] = [[
		self:SetAttribute('state', newstate)
		control:ChildUpdate('state', newstate)
		-- Satellite cooldown visibility depends on which modifier layer is
		-- currently displayed. Re-evaluate immediately on press/release instead
		-- of waiting for the next spell/action cooldown event.
		control:CallMethod('RefreshModifierCooldowns')

		if(self:GetAttribute('isTriple')) then 
			-- Modifier buttons visual scale update
			local count = self:GetAttribute("childCount") or 0
			for i = 1, count do
				local child = self:GetFrameRef("child" .. i)
				if child then
					control:RunFor(child, UpdateTripleScale, newstate)
				end
			end

			control:CallMethod("UpdateDividerFocus", newstate)
		end
	]],
	['_onstate-override'] = [[ 
		control:RunAttribute('UpdateActionBar')
	]],
	['_onstate-override_hidden'] = [[  
		control:RunAttribute('UpdateActionBar') 
	]],
	['_onstate-page'] = [[
		-- A stance/stealth page change must not visually drop an actively-held
		-- LT/RT modifier layer. Update the underlying action page, then explicitly
		-- re-assert the secure modifier state for the children.
		control:RunAttribute('UpdateActionBar')
		local held = self:GetAttribute('state-modifier') or self:GetAttribute('state') or ''
		self:SetAttribute('state', held)
		control:ChildUpdate('state', held)
		control:CallMethod('RefreshModifierCooldowns')
	]],
	['UpdateActionBar'] = [[
		-- Keep ConsolePortBar's secure page in parity with ConsolePort's main
		-- pager. 3.3.5 vehicle/override/temp-shapeshift bars can otherwise leave
		-- the children on a stale page after the temporary bar disappears.
		if HasVehicleActionBar and HasVehicleActionBar() then
			newstate = GetVehicleBarIndex()
		elseif HasOverrideActionBar and HasOverrideActionBar() then
			if GetOverrideBarIndex then newstate = GetOverrideBarIndex() end
		elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
			newstate = GetTempShapeshiftBarIndex()
		elseif GetBonusBarOffset() > 0 then
			newstate = GetBonusBarOffset()+6
		else
			newstate = GetActionBarPage()
		end
		if not newstate then newstate = GetActionBarPage() end
		self:SetAttribute('actionpage', newstate)
		control:ChildUpdate('actionpage', newstate)
	]],
	['GetReticleMacro'] = [[
		if disableCastOnRelease then return end
		local actionID, buttonID, down, macro = ...  

		if down then
			if not storedSpellID then
				storedSpellID = control:RunFor(self, self:GetAttribute('GetSpellID'), actionID) 
				storedButtonID = buttonID
				if reticleSpellManifest[storedSpellID] then
					control:CallMethod('StopCamera')
				end
			end
		else
			if storedSpellID and (storedButtonID == buttonID) then
				local spellName = reticleSpellManifest[storedSpellID]
				if spellName then
					macro = reticleMacroString:format(spellName)
				end
			end
			storedSpellID, storedButtonID = nil, nil
		end

		return macro
	]]
--------------------------
}) do Bar:SetAttribute(name, script) end
--------------------------

--

Bar.CallMethodFromFrame = CPAPI.CallMethodFromFrame

---

Bar:SetScript('OnEvent', Bar.OnEvent)
Bar:SetScript('OnMouseWheel', Bar.OnMouseWheel)
for _, event in ipairs({
	'SPELLS_CHANGED',
	'PLAYER_LOGIN',
	'ADDON_LOADED',
	'PLAYER_TALENT_UPDATE',
}) do pcall(Bar.RegisterEvent, Bar, event) end

Bar.ignoreNode = true
Bar.Buttons = {}
Bar.Elements = {}
Bar.isForbidden = true 

RegisterStateDriver(Bar, 'page', state)

local ov_driver = {}
table.insert(ov_driver, "[bonusbar:5]11") 
for i=1, 4 do
	table.insert(ov_driver, string.format("[bonusbar:%s]%s",i, i))
end

RegisterStateDriver(Bar, 'override_hidden', '[bonusbar:1][bonusbar:2][bonusbar:3][bonusbar:4][bonusbar:5] show; hide')
RegisterStateDriver(Bar, 'override', table.concat(ov_driver, ';'))
RegisterStateDriver(Bar, 'modifier', '[mod:ctrl,mod:shift] CTRL-SHIFT-; [mod:ctrl] CTRL-; [mod:shift] SHIFT-; ')