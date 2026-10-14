local _, ab = ...
local CPAPI = ConsolePort:GetData().CPAPI
local db = ab.data
local Bar = ab.bar
local WindowMixin, Generic, Layout, Button, Position, Color, Bool, Profiler, Preset = {}, {}, {}, {}, {}, {}, {}, {}, {}

-- Editor-only geometry for reversible toggles; never inserted while unchecked.
local disabledGeometry = setmetatable({}, {__mode = 'k'})

local VALID_POINTS = {
	TOP = true, 
	LEFT = true, TOPLEFT = true, BOTTOMLEFT = true,
	RIGHT = true, TOPRIGHT = true, BOTTOMRIGHT = true,
	BOTTOM = true,
	CENTER = true,
}
local VALID_DIRS = {
	up = true,
	left = true,
	down = true,
	right = true,
	[''] = true,
}

function Generic:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

function Generic:OnHide()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

function Button:OnShow()
	local entry = self.Layout.cfg[self.Binding]
	local activePreset = (ab.cfg and ab.cfg.activePreset) or (ConsolePortBarSetup and ConsolePortBarSetup.activePreset)
	-- v151: checkbox state is once again the official/v140 contract:
	-- a live layout entry exists = checked; absent = unchecked.
	-- Fallback preset geometry is editor display data only and is never inserted
	-- into the live layout until the user checks the box.
	local cached = disabledGeometry[self.Layout.cfg]
	local display = entry or (cached and cached[self.Binding]) or ab:GetPresetButtonLayout(activePreset, self.Binding)
	local point = display and display.point
	local size = display and display.size
	local dir = display and display.dir
	self:SetChecked(entry and true or false)

	if dir then self.direction:SetText(dir) else self.direction:SetText('') end
	if size then self.size:SetNumber(size) else self.size:SetText('') end
	if point then
		self.point:SetText(point[1])
		self.xOffset:SetText(point[2] or 0)
		self.yOffset:SetText(point[3] or 0)
	else
		self.point:SetText('')
		self.xOffset:SetText('')
		self.yOffset:SetText('')
	end

	if self.Wrapper then
		if dir then self.Wrapper:UpdateOrientation(dir) end
		if entry and point then
			self.Wrapper:SetPoint(unpack(point))
			self.Wrapper:Show()
		else
			self.Wrapper:Hide()
		end
	end
end

function Button:OnClick()
	local cache = disabledGeometry[self.Layout.cfg] or {}
	disabledGeometry[self.Layout.cfg] = cache
	if not self.Layout.cfg[self.Binding] then
		local activePreset = (ab.cfg and ab.cfg.activePreset) or (ConsolePortBarSetup and ConsolePortBarSetup.activePreset)
		self.Layout.cfg[self.Binding] = (cache[self.Binding] and db.table.copy(cache[self.Binding]))
			or ab:GetPresetButtonLayout(activePreset, self.Binding)
			or ab:GetDefaultButtonLayout(self.Binding)
			or { point = {'CENTER', 0, 0}, dir = 'down', size = 64}
		self.Layout.cfg[self.Binding].hidden = nil
	else
		cache[self.Binding] = db.table.copy(self.Layout.cfg[self.Binding])
		self.Layout.cfg[self.Binding] = nil
	end
	local window = self.Layout and self.Layout:GetParent()
	if window then window.layoutReloadPending = true end
	self:OnShow()
end

function Button:UpdateButton(id, setting, value)
	local entry = self.Layout.cfg[self.Binding]
	local settings = entry and entry[setting]
	local oldValue = type(settings) == 'table' and settings[id] or settings
	if oldValue == value then return end
	if type(settings) == 'table' then
		settings[id] = value
	else
		entry[setting] = value
	end
	-- v129: position/size/direction edits need a clean reload after Save.
	local window = self.Layout and self.Layout:GetParent()
	if window then window.layoutReloadPending = true end
	if self.Wrapper then
		if entry.dir then self.Wrapper:UpdateOrientation(entry.dir) end
		if entry.point then self.Wrapper:SetPoint(unpack(entry.point)) end
		if entry.size then self.Wrapper:SetSize(entry.size) end
	end
end

function Position:OnLoad(id, type, width, valids, filter, prev, next)
	self.Owner = self:GetParent()
	self.Layout = self.Owner.Layout
	self.Binding = self.Owner.Binding
	self.Wrapper = self.Owner.Wrapper
	self.Next = next
	self.Prev = prev
	self.type = type
	self.valids = valids
	self.filter = filter
	self:SetAutoFocus(false)
	self:SetFont(CombatLogFont:GetFont())
	self:SetBackdrop(db.Atlas.Backdrops.FullSmall)
	self:SetID(id)
	self:SetJustifyH('CENTER')
	self:SetSize(width, 42)
end

function Position:OnDeltaChanged(delta)
	if self.isNumeric and self.Owner:GetChecked() then
		local number = self:GetNumber()
		self:SetNumber(number + (  delta * 5 ) )
		self.Owner:UpdateButton(self:GetID(), self.type, self:GetNumber())
	end
end

function Position:OnEscapePressed()
	self.Owner:UpdateButton(self:GetID(), self.type, self.Backup)
	self:ClearFocus()
end

function Position:OnEnterPressed()
	self:ClearFocus()
end

function Position:OnTabPressed()
	self:OnEnterPressed()
	if IsShiftKeyDown() and self.Prev and self.Prev:IsEnabled() then
		self.Prev:SetFocus()
	elseif self.Next and self.Next:IsEnabled() then
		self.Next:SetFocus()
	end
end

function Position:OnMouseUp(button)
	if self.clickToConfirm and self:HasFocus() then
		if button == 'LeftButton' then
			self:OnEnterPressed()
		elseif button == 'RightButton' then
			self:OnEscapePressed()
		end
	else
		self.clickToConfirm = true
	end
end

function Position:OnCursorChanged()
	self.clickToConfirm = nil
end

function Position:OnEditFocusGained()
	if self.isNumeric then
		self.Backup = self:GetNumber()
		self:SetScript('OnMouseWheel', self.OnDeltaChanged)
	else
		self.Backup = self:GetText()
	end
	self.Backup = self.isNumeric and self:GetNumber() or self:GetText()
end

function Position:OnEditFocusLost()
	local entry = self.Layout.cfg[self.Binding]
	local val = entry and entry[self.type]
	if val then
		self:SetText((type(val) == 'table' and val[self:GetID()]) or val)
		self:SetTextColor(1, 1, 1)
	end
	self:SetScript('OnMouseWheel', nil)
	self.Backup = nil
	self.clickToConfirm = nil
end


function Position:OnEnter()
	if self.valids then
		local newLine, concat = '|cFFFFFFFF%s|r\n', ''
		for valid in db.table.spairs(self.valids) do
			concat = concat .. newLine:format(valid == '' and '|cFF757575<none>|r' or valid)
		end
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
		GameTooltip:SetText(db.ACTIONBAR.CFG_VALID_ENTRIES:format(concat))
	end
end

function Position:OnTextChanged(userInput)
	if userInput then
		if self.isNumeric then
			local number = self:GetNumber()
			if tonumber(self:GetText()) then
				self:SetTextColor(1, 1, 1)
			else
				self:SetTextColor(.75, .75, .75)
			end
			self.Owner:UpdateButton(self:GetID(), self.type, number)
		else
			local text = self:GetText()
			if self.valids[self.filter(text)] then
				self:SetTextColor(1, 1, 1)
				self.Owner:UpdateButton(self:GetID(), self.type, self.filter(text))
			else
				self:SetTextColor(.75, .75, .75)
			end
		end
	end
end

function Bool:OnClick()
	self:SetChecked(self:GetChecked())
	ab.cfg[self.cvar] = self:GetChecked()
	ab.bar:OnLoad(ab.cfg, true)
end

function Bool:OnShow()
	self:SetChecked(ab.cfg[self.cvar])
end

function Bool:OnEnter()
	if self.tooltipText then
		GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
		GameTooltip:SetText(self.tooltipText)
	end
end

function Color:OnClick(button)
	if button == 'LeftButton' then
		local r, g, b, a = ab:GetRGBColorFor(self.element)
		ColorPickerFrame:SetColorRGB(r, g, b, a)
		ColorPickerFrame.hasOpacity = true
		ColorPickerFrame.opacity = 1 - a
		ColorPickerFrame.previousValues = {r, g, b, a}
		ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
		self.Callback, self.Callback, self.Callback
		ColorPickerFrame:Hide()
		ColorPickerFrame:Show()
		ColorPickerFrame:GetScript('OnColorSelect')(ColorPickerFrame, r, g, b)
	else
		local r, g, b, a = ab:GetRGBColorFor(self.element, true)
		ab.cfg[self.id] = {r, g, b, a}
		Bar:OnLoad(ab.cfg, true)
		self:OnShow()
	end
end

function Color:OnEnter()
	local r, g, b, a = ab:GetRGBColorFor(self.element)
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
	GameTooltip:SetText(format(db.ACTIONBAR.CFG_COLOR_TOOLTIP, floor(r * 255), floor(g * 255), floor(b * 255), floor(a * 100)))
end

function Color:OnShow()
	local r, g, b, a = ab:GetRGBColorFor(self.element)
	self.Display:SetTexture(r, g, b, a)
end

function Layout:OnShow()
	self.cfg = ab.cfg.layout
	for _, button in ipairs(self.Buttons) do
		button:Show()
		if button.Binding and button.OnShow then button:OnShow() end
	end
	-- Keep legacy Popout object available to Action Bar internals but out of the
	-- integrated settings navigation.
	if self.Popout then self.Popout:Hide() end
	self:Refresh(#self.Buttons)
end

function Layout:OnHide()
	for _, button in ipairs(self.Buttons) do
		button:Hide()
	end
end

function Layout:CreateHeader(...)
	local frame = CreateFrame('Frame', nil, self.Child)
	frame:SetSize(1, 32)
	frame.Objects = {}
	for i, info in pairs({...}) do
		local object = frame['Create' .. info.type](frame, unpack(info.setup))
		local anchor = frame.Objects[i-1]
		object['Set' .. info.data](object, type(info.val) == 'table' and unpack(info.val) or info.val)
		object:SetPoint('LEFT', anchor or frame, anchor and 'RIGHT' or 'LEFT', info.x or 0, info.y or 0)
		frame.Objects[#frame.Objects + 1] = object
	end
	self:AddButton(frame, 12, 0)
	return frame
end

function Layout:CreateButton(binding, icon)
	local button = CreateFrame('CheckButton', '$parent'..binding, self.Child, 'ChatConfigCheckButtonTemplate')
	button.Layout = self
	button.Binding = binding
	button.Wrapper = ab.libs.registry[binding]
	button.Icon = button:CreateTexture('$parentIcon', 'ARTWORK')
	button.Icon:SetTexture(db.TEXTURE[binding])
	button.Icon:SetSize(28, 28)
	button.Icon:SetPoint('LEFT', button, 'RIGHT', 4, 0)
	button.point = CPAPI.CreateFrame('EditBox', '$parentPoint', button)
	button.xOffset = CPAPI.CreateFrame('EditBox', '$parentxOffset', button)
	button.yOffset = CPAPI.CreateFrame('EditBox', '$parentyOffset', button)
	button.direction = CPAPI.CreateFrame('EditBox', '$parentDirection', button)
	button.size = CPAPI.CreateFrame('EditBox', '$parentSize', button)
	button.size:SetPoint('LEFT', button.Icon, 'RIGHT', 0, 0)
	button.point:SetPoint('LEFT', button.size, 'RIGHT', -4, 0)
	button.xOffset:SetPoint('LEFT', button.point, 'RIGHT', -4, 0)
	button.yOffset:SetPoint('LEFT', button.xOffset, 'RIGHT', -4, 0)
	button.direction:SetPoint('LEFT', button.yOffset, 'RIGHT', -4, 0)

	db.table.mixin(button.size, Generic, Position)
	db.table.mixin(button.point, Generic, Position)
	db.table.mixin(button.xOffset, Generic, Position)
	db.table.mixin(button.yOffset, Generic, Position)
	db.table.mixin(button.direction, Generic, Position)

	button.size:OnLoad(1, 'size', 75, nil, nil, nil, button.point)

	button.point:OnLoad(1, 'point', 150, VALID_POINTS, strupper, button.size, button.xOffset)
	button.xOffset:OnLoad(2, 'point', 75, nil, nil, button.point, button.yOffset)
	button.yOffset:OnLoad(3, 'point', 75, nil, nil, button.xOffset, button.direction)

	button.direction:OnLoad(1, 'dir', 100, VALID_DIRS, strlower, button.yOffset)

	button.size:SetNumeric(true)
	button.size.isNumeric = true
	button.xOffset.isNumeric = true
	button.yOffset.isNumeric = true

	db.table.mixin(button, Button)
	button:OnShow()
	return button
end

function Layout:CreateBooleanSwitch(cvar, desc)
	local button = CreateFrame('CheckButton', '$parent'..cvar, self.Child, 'ChatConfigCheckButtonTemplate')
	button.text = button:CreateFontString(nil, 'OVERLAY', 'FocusFontSmall')
	button.text:SetPoint('LEFT', 30, 0)
	button.text:SetText(desc)
	button:SetChecked(ab.cfg and ab.cfg[cvar])
	button.cvar = cvar
	db.table.mixin(button, Generic, Bool)
	return button
end

function Preset:SetData(name, cfg, class)
	local viewer = self.Viewer
	self.cfg = db.table.copy(cfg)
    self.presetName = name
	color = RAID_CLASS_COLORS[select(2,UnitClass('player'))]
	escapeColor = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255) 

	self:SetText((class and escapeColor..name) or name)

	if self.cfg then
		for binding, data in pairs(self.cfg.layout) do
			viewer.Pins[binding] = viewer.Pins[binding] or viewer:CreateTexture(nil, 'ARTWORK')
			
			local pin = viewer.Pins[binding]
			pin:SetTexture(db.ICONS[binding])

			local p, xOff, yOff = unpack(data.point)
			local s = data.size or 64

			xOff = xOff * 0.25
			yOff = yOff * 0.25
			s = s * 0.25

			pin:SetPoint(p, xOff, yOff)
			pin:SetSize(s, s)

		end
		viewer:SetWidth((self.cfg.width or 1105) * 0.25)
		if self.cfg.showart then		
			local art, coords = ab:GetCover()
			if art and coords then
				viewer.Art:SetTexture(art)
				viewer.Art:SetTexCoord(unpack(coords))
				viewer.Art:Show()
			else
				viewer.Art:Hide()
			end
		end
		self:Show()
	end
end

function Preset:OnClick()
    -- v79: layout changes are supported through a UI reload. Remember that a
    -- preset was selected so Save can offer Reload Now / Close.
    if self.Layout and self.Layout:GetParent() then
        self.Layout:GetParent().layoutReloadPending = true
    end
	-- Presets define presentation/layout, but should not silently reset the
	-- user's functionality/display toggles. Preserve the current boolean
	-- preferences before loading the selected preset.
	-- v141: each named preset keeps its own edited presentation/layout state.
	-- Cache the preset we are leaving, then restore this preset's last edited copy
	-- instead of recreating factory geometry every time the user switches bars.
	ConsolePortBarSetup.presetProfiles = ConsolePortBarSetup.presetProfiles or {}
	local activePreset = ConsolePortBarSetup.activePreset
	if activePreset and ab.cfg then
		local saved = db.table.copy(ab.cfg)
		saved.presetProfiles = nil
		saved.activePreset = nil
		ConsolePortBarSetup.presetProfiles[activePreset] = saved
	end
	local cfg = ConsolePortBarSetup.presetProfiles[self.presetName]
		and db.table.copy(ConsolePortBarSetup.presetProfiles[self.presetName])
		or db.table.copy(self.cfg)
	local profiles = ConsolePortBarSetup.presetProfiles
    -- v81: cooldown preferences are user settings, not layout-preset defaults.
    -- Preserve them across every preset switch; only class art intentionally
    -- changes with the selected layout.
    cfg.enablecooldowntext = ab.cfg.enablecooldowntext
    cfg.hiddenbarcooldowns = ab.cfg.hiddenbarcooldowns
    cfg.showmodifiercooldowns = ab.cfg.showmodifiercooldowns
	for _, setting in pairs(ab:GetBooleanSettings()) do
		if setting.cvar then
            -- v74: class-art is a preset-selection default rather than a
            -- cross-preset preference. Roleplay starts checked; every other
            -- preset starts unchecked. The user can still change it afterward
            -- and Save that active layout normally.
            if setting.cvar ~= 'showart' then
                cfg[setting.cvar] = setting.toggle
            end
		end
	end
    -- Only apply the factory class-art default the first time this preset is used.
	if not profiles[self.presetName] then
		cfg.showart = (self.presetName == 'Roleplay') and true or false
	end
	cfg.presetProfiles = profiles
	cfg.activePreset = self.presetName
	Bar:OnLoad(cfg, true)


	self.Layout:Hide()
	self.Layout:Show()
end

function Preset:OnEnter()
	local settings = ab:GetBooleanSettings(self.cfg)
	local ttLine = '|T%s:24:24:0:0|t %s'
	local yes, no = 'Interface\\RAIDFRAME\\ReadyCheck-Ready', 'Interface\\RAIDFRAME\\ReadyCheck-NotReady'
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
	GameTooltip:AddLine(self.Label:GetText())
	for _, data in pairs(settings) do
		GameTooltip:AddLine(ttLine:format(data.toggle and yes or no, data.desc))
	end
	GameTooltip:Show()
end

function Profiler:CreatePreset()
	local id = self.numActive
	local preset = db.Atlas.GetFutureButton('$parentPreset'..id, self.Child, nil, nil, 300, 46, true)
	local viewer = CreateFrame('Frame', '$parentViewer', preset)

	--viewer:SetClipsChildren(true)
	viewer:SetPoint('TOP', preset, 'BOTTOM', 0, 0)
	viewer:SetSize(250, 84)
	viewer.Pins = {}


	viewer.Line = viewer:CreateTexture(nil, 'BACKGROUND', nil, 3)
	viewer.Line:SetPoint('TOP', 0, 0)
	viewer.Line:SetSize(280, 54)

	viewer.Art = viewer:CreateTexture(nil, 'BACKGROUND', nil, 3)
	viewer.Art:SetPoint('TOP', 0, 0)
	viewer.Art:SetSize(280, 54)
	viewer.Art:SetAlpha(0.5)

	viewer.Line:SetTexture('Interface\\AddOns\\ConsolePort\\Textures\\Castbar\\CastBar.blp')
	viewer.Line:SetTexCoord(0, 0.8164, 0.6660, 0.7968)
	viewer.Line:SetAlpha(0.35)

	db.table.mixin(preset, Generic, Preset)

	preset.Layout = self.Layout
	preset.Viewer = viewer
	preset:Show()
	self:AddButton(preset, 24, 0)
	self.Buttons[id] = preset
	return preset
end

function Profiler:GetPresetFromPool()
	self.numActive = self.numActive + 1
	return self.Buttons[self.numActive] or self:CreatePreset()
end

function Profiler:AddPreset(name, cfg, class)
	local profile = self:GetPresetFromPool() 
	profile:SetData(name, cfg, class)
end

function Profiler:OnShow()
	self.numActive = 0
	for _, profile in pairs(self.Buttons) do
		profile:Hide()
	end
	local default = ab:GetDefaultSettings()
	local current = ab.cfg
	local compare = db.table.compare

	
	color = RAID_CLASS_COLORS[select(2,UnitClass('player'))]
	escapeColor = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255) 

	self:AddPreset(escapeColor..'Current', current)

	for name, settings in db.table.spairs(ab:GetPresets()) do
		self:AddPreset(name, settings)
	end

	if ConsolePortCharacterSettings then
		for character, settings in db.table.spairs(ConsolePortCharacterSettings) do
			if settings.Bar then
				local setup = settings.Bar
				if not compare(setup, default) and not compare(setup, current) then 
					self:AddPreset(character, setup, settings.Class)
				end
			end
		end
	end
	self:Refresh(self.numActive)
end

function WindowMixin:Default()
	Bar:OnLoad(ab:GetDefaultSettings())
	if self.Layout and self.Layout:IsVisible() then
		self.Layout:Hide()
		self.Layout:Show()
	end
end

function WindowMixin:Save()
    -- v76: the selected preset has already been applied by Preset:OnClick via
    -- the benign live-preview path. Do not tear down and reconstruct the entire
    -- secure wrapper tree a second time just because Save was pressed. That
    -- duplicate destructive load was the common trigger for incomplete layouts,
    -- mixed main/satellite CPCC roles, and the v75 multi-second freeze.
    -- Re-apply presentation non-destructively so the saved UI state is current.
    Bar:OnLoad(ab.cfg, true)

	local isIdentical, allowExport = db.table.compare, true
	for _, preset in pairs(ab:GetPresets()) do
		if isIdentical(ab.cfg, preset) then
			allowExport = false
			break
		end
	end

	if ConsolePortCharacterSettings then
		for _, settings in pairs(ConsolePortCharacterSettings) do
			if isIdentical(ab.cfg, settings.Bar) then
				allowExport = false
				break
			end
		end
	end

    -- v153: compare final values with the loaded runtime, not click history.
    -- Keep this baseline until reload: dismissing a prompt does not apply secure
    -- layout changes, and navigating between sections must not reset it.
    local baseline = ab.reloadBaseline or self.Backup or ab.cfg
    local needsLayoutReload = false
    for _, key in ipairs({'layout', 'isTriple', 'dividers', 'width', 'classicBorders', 'useSquareButtons'}) do
        local before, after = baseline[key], ab.cfg[key]
        local same = type(before) == 'table' and type(after) == 'table'
            and db.table.compare(before, after) or before == after
        if not same then needsLayoutReload = true end
    end
    local needsCooldownReload = ab.cfg.enablecooldowntext and not baseline.enablecooldowntext
    self.layoutReloadPending = nil
    self.cooldownReloadPending = nil
    if needsLayoutReload or needsCooldownReload then
        StaticPopupDialogs['CONSOLEPORT_BARLAYOUT_RELOAD'] = StaticPopupDialogs['CONSOLEPORT_BARLAYOUT_RELOAD'] or {
            text = 'One or more of the changes you\nhave made require a ReloadUI.',
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function() ReloadUI() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = false,
            preferredIndex = 3,
        }
        StaticPopup_Show('CONSOLEPORT_BARLAYOUT_RELOAD')
    end

	return nil, 'Bar', ( allowExport and ab.cfg)
end

function WindowMixin:Cancel()
	if self.Backup then
		Bar:OnLoad(self.Backup)
		self.Backup = nil
	end
end

function WindowMixin:CreateLayoutModule()
	local layout = db.Atlas.GetScrollFrame('$parentLayout', self, {
		childKey = 'List',
		childWidth = 530,
		stepSize = 36,
	})
	layout:SetPoint('TOPLEFT', 32, -32)
	layout:SetSize(530, 600)
	layout.cfg = ab.cfg.layout
	db.table.mixin(layout, Layout)

	local info = ab:GetBooleanSettings()
	local subHeaders = {
		[1] = 'Functionality';
		[11] = 'Experience/watch bars';
		[13] = 'Display';
		[19] = 'Art';
	}

    local function CreateCooldownControls()
    -- v80: cooldown controls sit between Functionality and Experience/watch bars.
    layout:CreateHeader({val = 'Cooldowns', x = 0, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FriendsFont_Large'}})
    local cdRow = CreateFrame('Frame', nil, layout.Child)
    cdRow:SetSize(530, 28)
    local cdToggle = layout:CreateBooleanSwitch('enablecooldowntext', 'Show cooldowns')
    cdToggle:SetPoint('LEFT', cdRow, 'LEFT', 16, 0)
    layout:AddButton(cdRow)

    local hiddenLabel = CreateFrame('Frame', nil, layout.Child)
    hiddenLabel:SetSize(530, 24)
    hiddenLabel.text = hiddenLabel:CreateFontString(nil, 'OVERLAY', 'FocusFontSmall')
    hiddenLabel.text:SetPoint('LEFT', 16, 0)
    hiddenLabel.text:SetText('Show ability cooldowns on inactive bars:')
    layout:AddButton(hiddenLabel)

    local modeRow = CreateFrame('Frame', nil, layout.Child)
    modeRow:SetSize(530, 30)
    local modes = {
        {'60', '≤ 1h'}, {'10', '≤ 10m'}, {'5', '≤ 5m'}, {'off', 'Off'},
    }
    local radios = {}
    local function RefreshModes()
        local enabled = ab.cfg.enablecooldowntext and true or false
        local mode = ab.cfg.hiddenbarcooldowns or (ab.cfg.showmodifiercooldowns == false and 'off' or '10')
        if mode == 'all' then mode = '60' end
        ab.cfg.hiddenbarcooldowns = mode
        ab.cfg.showmodifiercooldowns = enabled and mode ~= 'off'
        hiddenLabel.text:SetTextColor(1, 1, 1)
        for _, r in ipairs(radios) do
            r:SetChecked(r.mode == mode)
            if enabled then r:Enable(); r.text:SetTextColor(1, .82, 0) else r:Disable(); r.text:SetTextColor(.5,.5,.5) end
        end
    end
    for i, data in ipairs(modes) do
        local r = CreateFrame('CheckButton', nil, modeRow, 'UIRadioButtonTemplate')
        r:SetSize(20,20)
        r:SetPoint('LEFT', 16 + (i-1)*120, 0)
        r.mode = data[1]
        r.text = r:CreateFontString(nil, 'OVERLAY', 'FocusFontSmall')
        r.text:SetPoint('LEFT', r, 'RIGHT', 2, 0)
        r.text:SetText(data[2])
        r:SetScript('OnClick', function(self)
            if not ab.cfg.enablecooldowntext then RefreshModes(); return end
            ab.cfg.hiddenbarcooldowns = self.mode
            ab.cfg.showmodifiercooldowns = self.mode ~= 'off'
            ab.bar:OnLoad(ab.cfg, true)
            RefreshModes()
        end)
        radios[#radios+1] = r
    end
    local oldCDClick = cdToggle.OnClick
    cdToggle:SetScript('OnClick', function(toggle)
        local wasEnabled = ab.cfg.enablecooldowntext and true or false
        Bool.OnClick(toggle)
        if not wasEnabled and ab.cfg.enablecooldowntext then
            -- Enabling CPCC requires one clean renderer initialization.
            self.cooldownReloadPending = true
        end
        RefreshModes()
    end)
    modeRow:SetScript('OnShow', RefreshModes)
    cdToggle:SetScript('OnShow', function(self) Bool.OnShow(self); RefreshModes() end)
    layout:AddButton(modeRow)
    end

	for i=1, #info, 2 do
        if i == 11 then CreateCooldownControls() end
		local header = subHeaders[i]
		if header then
			layout:CreateHeader({val = header, x = 0, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FriendsFont_Large'}})
		end
		local frame = CreateFrame('Frame')
		frame:SetSize(530, 16)
		local info1, info2 = info[i], info[i+1]
		if info1 then
			local b1 = layout:CreateBooleanSwitch(info1.cvar, info1.desc)
			b1:SetPoint('LEFT', frame, 'LEFT', 16, 0)
		end
		if info2 then
			local b2 = layout:CreateBooleanSwitch(info2.cvar, info2.desc)
			b2:SetPoint('CENTER', frame, 'CENTER', 16, 0)
		end
		layout:AddButton(frame)
	end 


	
	layout:CreateHeader({val = 'Bar Scale:', x = 0, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FriendsFont_Large'}})

	local scaleRow = CreateFrame('Frame', nil, layout.Child)
	scaleRow:SetSize(200, 46)

	local scaleBox = CPAPI.CreateFrame('EditBox', '$parentScaleBox', scaleRow)
	scaleBox:SetAutoFocus(false)
	scaleBox:SetFont(CombatLogFont:GetFont())
	scaleBox:SetBackdrop(db.Atlas.Backdrops.FullSmall)
	scaleBox:SetJustifyH('CENTER')
	scaleBox:SetSize(75, 24)
	scaleBox:SetPoint('CENTER', scaleRow, 'CENTER', 0, 0)

	local minusBtn = db.Atlas.GetFutureButton('$parentMinus', scaleRow, nil, nil, 36, 36, true)
	minusBtn:SetPoint('RIGHT', scaleBox, 'LEFT', -8, 0)
	minusBtn.Label:SetText('-')

	local plusBtn = db.Atlas.GetFutureButton('$parentPlus', scaleRow, nil, nil, 36, 36, true)
	plusBtn:SetPoint('LEFT', scaleBox, 'RIGHT', 8, 0)
	plusBtn.Label:SetText('+')

	local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.1, (BAR_MAX_SCALE or 1.6), 0.1

	local function RefreshScaleDisplay()
		scaleBox:SetText(string.format('%.1f', ab.cfg.scale or 1))
		scaleBox:SetTextColor(1, 1, 1)
	end

	local function ApplyScale(value)
		value = math.floor((value / SCALE_STEP) + 0.5) * SCALE_STEP
		value = math.max(SCALE_MIN, math.min(value, SCALE_MAX))
		ab.cfg.scale = value
		RefreshScaleDisplay()
		Bar:OnLoad(ab.cfg, true)
	end

	minusBtn:SetScript('OnClick', function()
		ApplyScale((ab.cfg.scale or 1) - SCALE_STEP)
	end)

	plusBtn:SetScript('OnClick', function()
		ApplyScale((ab.cfg.scale or 1) + SCALE_STEP)
	end)

	scaleBox:SetScript('OnEnterPressed', function(self)
		local number = tonumber(self:GetText())
		if number then
			ApplyScale(number)
		else
			RefreshScaleDisplay()
		end
		self:ClearFocus()
	end)
	scaleBox:SetScript('OnEscapePressed', function(self)
		RefreshScaleDisplay()
		self:ClearFocus()
	end)
	scaleBox:SetScript('OnShow', RefreshScaleDisplay)

	RefreshScaleDisplay()
	layout:AddButton(scaleRow, 12, 0)
	layout.ScaleRow = scaleRow
	layout.RefreshScaleDisplay = RefreshScaleDisplay

	-- Color header
	layout:CreateHeader({val = 'Colors:', x = 0, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FriendsFont_Large'}})

	local colors = layout:CreateHeader(
		{val = 'Border', x = 48, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Cooldown', x = 64, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Tint', x = 64, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Bars', x = 64, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Art', x = 64, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}}
	)

	for i, id in pairs({'borderRGB', 'swipeRGB', 'tintRGB', 'expRGB', 'artRGB'}) do
		local color = CreateFrame('Button', nil, colors)
		color:SetSize(24, 24)
		color:SetPoint('RIGHT', colors.Objects[i], 'LEFT', -8, 0)
		color.Display = color:CreateTexture(nil, 'ARTWORK')
		color.Display:SetAllPoints()
		color:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		color.id = id
		color.element = id:gsub('RGB', '')
		color.Callback = function(revertRGB)
			if revertRGB then
				ab.cfg[id] = revertRGB
			else
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = OpacitySliderFrame:GetValue()
				ab.cfg[id] = {r, g, b, 1 - a}
			end
			color.Display:SetTexture(unpack(ab.cfg[id]))
			Bar:OnLoad(ab.cfg, true)
		end,
		db.table.mixin(color, Generic, Color)
	end

	-- Button header
	layout:CreateHeader({val = 'Button positioning:', x = 0, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FriendsFont_Large'}})

	layout:CreateHeader(
		{val = 'Size', x = 78, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Anchor', x = 67, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'X', x = 78, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Y', x = 58, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}},
		{val = 'Facing', x = 52, data = 'Text', type = 'FontString', setup = {nil, 'ARTWORK', 'FocusFontSmall'}}
	)

	local prev
	for binding in ConsolePort:GetBindings() do
		local button = layout:CreateButton(binding)
		if prev then
			prev.direction.Next = button.size
			button.size.Prev = prev.direction
		end
		prev = button
		layout:AddButton(button, 12, 0)
	end

	local popout = CreateFrame('Button', '$parentPopout', self)
	popout:SetSize(16, 16)
	popout:SetFrameLevel(10)
	popout:SetPoint('TOPLEFT', layout, 'TOPLEFT', -4, 4)
	popout:SetNormalTexture('Interface\\AddOns\\ConsolePort\\Textures\\Window\\Popout')
	popout:SetScript('OnClick', function()
		ConsolePortPopup:SetPopup(BINDING_HEADER_ACTIONBAR, layout, nil, nil, 600, 580)
		ConsolePortOldConfig:Hide()
		popout:Hide()
	end)
	layout.Popout = popout
	layout.Panel = self
	self.Layout = layout
	self.Layout:OnShow()
	self.CreateLayoutModule = nil
	return layout
end

function WindowMixin:GetLayoutModule()
	return self.Layout or self:CreateLayoutModule()
end

function WindowMixin:CreateProfiler()
	local profiler = db.Atlas.GetScrollFrame('$parentProfiler', self, {
		childKey = 'List',
		childWidth = 330,
		stepSize = 100,
	})
	profiler:SetPoint('TOPRIGHT', -52, -32)
	profiler:SetSize(330, 600)
	profiler.numActive = 0
	-- layout will exist at this point.
	profiler.Layout = self.Layout
	db.table.mixin(profiler, Profiler)
	self.CreateProfiler = nil
	return profiler
end

function WindowMixin:OnShow()
	self.Layout:SetParent(self)
	self.Layout:ClearAllPoints()
	self.Layout:SetPoint('TOPLEFT', 32, -32)
	self.Layout:SetSize(530, 600)
	self.Layout.Backdrop:Show()
	self.Backup = db.table.copy(ab.cfg)
end

ab.configuration = ConsolePortOldConfig:AddPanel({
	name = 'ActionBarTab',
	header = ACTIONBAR_LABEL, --BINDING_HEADER_ACTIONBAR, 
	mixin = WindowMixin,
	onLoad = function(self, core)
		if not self.Layout then
			self:CreateLayoutModule()
		end
		self.Presets = self:CreateProfiler()
	end
})

function Bar:ShowLayoutPopup()
	local layout = ab.configuration:GetLayoutModule()
	layout.Popout:Click()
end