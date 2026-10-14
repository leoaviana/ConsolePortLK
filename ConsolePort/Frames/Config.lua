---------------------------------------------------------------
-- Config.lua: Base config frame
---------------------------------------------------------------

local _, db = ...
local CPAPI = db.CPAPI
local TUTORIAL = db.TUTORIAL.CONFIG
local Mixin, FadeIn, FadeOut = db.table.mixin, db.GetFaders()
local red, green, blue = db.Atlas.GetCC()
---------------------------------------------------------------
local ConsolePort, WindowMixin = ConsolePort, {}
local Popup     = db.Atlas.CreateFrame("ConsolePortPopup")
local Config    = db.Atlas.CreateFrame("ConsolePortOldConfig")
local Container = CreateFrame("Frame", "$parentContainer", Config)
---------------------------------------------------------------
ConsolePort.configFrame = Config
Config.Container = Container

-- v105 navigation memory is intentionally Lua-session only. It resets on
-- login and /reload because this local is recreated with the UI. Setup may
-- explicitly open Bindings without consuming the first ordinary Settings open.
local CPConfigOpenedThisSession = false
local CPRestoringConfigCategory = false
local CPLastConfigCategoryThisSession = nil
---------------------------------------------------------------
Config.Obstructor = CreateFrame("Frame", nil, Config)
Config.Obstructor:SetAllPoints()
Config.Obstructor:EnableMouse(true)
---------------------------------------------------------------

-- ============================================================
-- LAYOUT CONSTANTS
-- ============================================================
local SIDEBAR_W  = 220
local HEADER_H   = 46
local FOOTER_H   = 50
local ENTRY_H    = 32
local GROUP_H    = 36
local INDENT     = 14

-- ============================================================
-- MAIN FRAME
-- ============================================================
Config.Close:Hide()
Config:SetFrameStrata("HIGH")
Config:SetSize(1200, 760)
Config:SetPoint("CENTER", 0, 0)
Config:EnableMouse(true)
Config:Hide()
Config:SetMovable(true)
Config:RegisterForDrag("LeftButton")
Config:HookScript("OnDragStart", Config.StartMoving)
Config:HookScript("OnDragStop",  Config.StopMovingOrSizing)

do
	local bg = Config:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture([[Interface\Buttons\WHITE8X8]])
	bg:SetVertexColor(0.075, 0.058, 0.042, 0.5)
end

do
	local classFile = select(2, UnitClass("player"))
	local classBG   = Config:CreateTexture(nil, "BORDER")
	classBG:SetPoint("TOPLEFT",     Config, "TOPLEFT",     0, 0)
	classBG:SetPoint("BOTTOMRIGHT", Config, "BOTTOMRIGHT", 0, 0)
	classBG:SetTexture([[Interface\AddOns\ConsolePort\Textures\Class\]] .. classFile)
	classBG:SetAlpha(1)
end

do
	local vig = Config:CreateTexture(nil, "ARTWORK")
	vig:SetAllPoints()
	vig:SetTexture([[Interface\AddOns\ConsolePort\Textures\Window\Gradient]])
	vig:SetVertexColor(0, 0, 0, 0.60)
end

do
	local strip = Config:CreateTexture(nil, "ARTWORK", nil, 10)
	strip:SetPoint("TOPLEFT")
	strip:SetPoint("TOPRIGHT")
	strip:SetHeight(3)
	strip:SetTexture([[Interface\Buttons\WHITE8X8]])
	strip:SetVertexColor(red, green, blue, 1)
end

Config:SetBackdrop({
	edgeFile = [[Interface\AddOns\ConsolePort\Textures\Window\EdgefileBig]],
	edgeSize = 24,
	insets   = { left = 12, right = 12, top = 12, bottom = 12 },
})
Config:SetBackdropBorderColor(red * 0.55 + 0.15, green * 0.45 + 0.10, blue * 0.15 + 0.02, 0.90)

-- ============================================================
-- HEADER BAR
-- ============================================================
local Header = CreateFrame("Frame", nil, Config)
Header:SetPoint("TOPLEFT",  Config, "TOPLEFT",  0, 0)
Header:SetPoint("TOPRIGHT", Config, "TOPRIGHT", 0, 0)
Header:SetHeight(HEADER_H)

do
	local hbg = Header:CreateTexture(nil, "BACKGROUND")
	hbg:SetAllPoints()
	hbg:SetTexture([[Interface\Buttons\WHITE8X8]])
	hbg:SetVertexColor(0.038, 0.030, 0.022, 0.5)

	local hgr = Header:CreateTexture(nil, "BACKGROUND", nil, 1)
	hgr:SetPoint("TOPLEFT",     Header, "TOPLEFT",     0, 0)
	hgr:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
	hgr:SetTexture([[Interface\Buttons\WHITE8X8]])
	hgr:SetGradientAlpha("HORIZONTAL",
		red * 0.18, green * 0.14, blue * 0.06, 0.5,
		0, 0, 0, 0)

	local hdiv = Header:CreateTexture(nil, "ARTWORK")
	hdiv:SetPoint("BOTTOMLEFT",  Header, "BOTTOMLEFT",  0, 0)
	hdiv:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
	hdiv:SetHeight(1)
	hdiv:SetTexture([[Interface\Buttons\WHITE8X8]])
	hdiv:SetVertexColor(red * 0.8 + 0.1, green * 0.7 + 0.08, blue * 0.3, 1)
end
local LogoBtn = CreateFrame("Button", nil, Config)  -- parented to Config so it can overhang
LogoBtn:SetSize(64, 64)
LogoBtn:SetPoint("LEFT", Header, "LEFT", -10, -4)
LogoBtn:SetToplevel(true)
do
    local tex = LogoBtn:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT",     LogoBtn, "TOPLEFT",     3, -3)
    tex:SetPoint("BOTTOMRIGHT", LogoBtn, "BOTTOMRIGHT", -3, 3)
    tex:SetTexture([[Interface\AddOns\ConsolePort\Textures\Logos\CP]])  
    LogoBtn.tex = tex 

    local glow = LogoBtn:CreateTexture(nil, "OVERLAY") 
    glow:SetAllPoints() 
    glow:SetTexture([[Interface\AddOns\ConsolePort\Textures\IconMask64]]) 
    glow:SetVertexColor(1, 1, 1, 0) 
    LogoBtn._glow = glow 
 
    local timer = 0
    LogoBtn:SetScript("OnUpdate", function(self, elapsed)
        if not self.isHovered then
            timer = timer + elapsed
            local pulse = 0.8 + (math.sin(timer * 4) * 0.2)
            self.tex:SetAlpha(pulse)
        end
    end)

    -- 2. The Hover Pop & Tooltip
    LogoBtn:SetScript("OnEnter", function(self)
        self.isHovered = true 
        FadeIn(self._glow, 0.15, self._glow:GetAlpha(), 0.22)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -10)
        GameTooltip:AddLine("About ConsolePortLK", 1, 0.82, 0)
        GameTooltip:Show()
    end)

    LogoBtn:SetScript("OnLeave", function(self)
        self.isHovered = false
        FadeOut(self._glow, 0.15, self._glow:GetAlpha(), 0)
        GameTooltip:Hide() 
    end)
     
    LogoBtn:SetScript("OnMouseDown", function(self) 
        self.tex:SetPoint("TOPLEFT", self, "TOPLEFT", 5, -5)
        self.tex:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1)
    end)
    
    LogoBtn:SetScript("OnMouseUp", function(self) 
        self.tex:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
        self.tex:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
    end)
end

-- Shared tab-button factory
local function MakeHeaderTab(parent, labelText, anchorTo, anchorOff)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetHeight(HEADER_H)
	btn:SetPoint("LEFT", anchorTo, "RIGHT", anchorOff, 0)

	local strip = btn:CreateTexture(nil, "ARTWORK", nil, 5)
	strip:SetHeight(2)
	strip:SetPoint("TOPLEFT",  btn, "TOPLEFT",  0, 0)
	strip:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
	strip:SetTexture([[Interface\Buttons\WHITE8X8]])
	strip:SetVertexColor(red * 0.9 + 0.1, green * 0.75 + 0.08, blue * 0.25, 0)
	btn._strip = strip

	local hov = btn:CreateTexture(nil, "HIGHLIGHT")
	hov:SetAllPoints()
	hov:SetTexture([[Interface\Buttons\WHITE8X8]])
	hov:SetVertexColor(1, 1, 1, 0.05)

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER", btn, "CENTER", 0, 1)
	label:SetText(labelText)
	label:SetTextColor(0.72, 0.68, 0.58, 1)  -- warm grey-gold
	btn._label = label
	btn:SetWidth(label:GetStringWidth() + 28) 

	btn:SetScript("OnMouseDown", function(self)
		self._label:SetPoint("CENTER", self, "CENTER", 1, 0)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self._label:SetPoint("CENTER", self, "CENTER", 0, 1)
	end)

	btn:SetScript("OnEnter", function(self)
		if not self._active then
			self._label:SetTextColor(0.92, 0.87, 0.72, 1)
			FadeIn(self._strip, 0.12, self._strip:GetAlpha(), 0.55)
		end
	end)
	btn:SetScript("OnLeave", function(self)
		if not self._active then
			self._label:SetTextColor(0.72, 0.68, 0.58, 1)
			FadeOut(self._strip, 0.12, self._strip:GetAlpha(), 0)
		end
	end)
	return btn
end

-- Tab buttons
local BindingsBtn = MakeHeaderTab(Header, "Bindings", LogoBtn, 10)
local SettingsBtn = MakeHeaderTab(Header, "Settings", BindingsBtn, 0)

-- v82: controller shoulder proxies. Raw OnKeyDown never sees LB/RB while the
-- config window owns override bindings, so route shoulders through secure click
-- bindings just like the existing Save shortcut.
local BindingsShoulder = CreateFrame("Button", "ConsolePortConfigBindingsShoulder", Config)
local SettingsShoulder = CreateFrame("Button", "ConsolePortConfigSettingsShoulder", Config)
BindingsShoulder:SetScript("OnClick", function() BindingsBtn:Click() end)
SettingsShoulder:SetScript("OnClick", function() SettingsBtn:Click() end)

-- Vertical separator between logo area and tabs
do
	local sep = Header:CreateTexture(nil, "ARTWORK")
	sep:SetWidth(1)
	sep:SetHeight(HEADER_H * 0.55)
	sep:SetPoint("LEFT",   LogoBtn, "RIGHT",  4, 0)
	sep:SetPoint("CENTER", Header,  "CENTER", 0, 0)
	sep:SetTexture([[Interface\Buttons\WHITE8X8]])
	sep:SetVertexColor(red * 0.4 + 0.1, green * 0.3 + 0.08, blue * 0.1 + 0.02, 0.5)
end

-- Active-tab visual state helper
local headerTabs = { SettingsBtn, BindingsBtn }
local function SetActiveTab(activeBtn)
	for _, tab in ipairs(headerTabs) do
		tab._active = (tab == activeBtn)
		if tab._active then
			tab._label:SetTextColor(
				red   * 0.5 + 0.70,
				green * 0.4 + 0.62,
				blue  * 0.1 + 0.24, 1)
			FadeIn(tab._strip, 0.15, tab._strip:GetAlpha(), 1)
		else
			tab._label:SetTextColor(0.72, 0.68, 0.58, 1)
			FadeOut(tab._strip, 0.15, tab._strip:GetAlpha(), 0)
		end
	end
end

-- Custom close button
local CloseBtn = CreateFrame("Button", nil, Header)
CloseBtn:SetSize(26, 26)
CloseBtn:SetPoint("RIGHT", Header, "RIGHT", -8, 0)
do
	local bg = CloseBtn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture([[Interface\Buttons\WHITE8X8]])
	bg:SetVertexColor(0.55, 0.08, 0.06, 1)

	local hl = CloseBtn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetTexture([[Interface\Buttons\WHITE8X8]])
	hl:SetVertexColor(1, 0.2, 0.15, 0.35)

	local x = CloseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	x:SetPoint("CENTER", 0, 1)
	x:SetText("×")
	x:SetTextColor(1, 0.85, 0.85, 1)

	CloseBtn:SetBackdrop({
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		edgeSize = 1,
	})
	CloseBtn:SetBackdropBorderColor(0.70, 0.12, 0.08, 0.9)
end
CloseBtn:SetScript("OnClick", function() Config:Hide() end)

-- ============================================================
-- FOOTER BAR
-- ============================================================
local Footer = CreateFrame("Frame", nil, Config)
Footer:SetPoint("BOTTOMLEFT",  Config, "BOTTOMLEFT",  0, 0)
Footer:SetPoint("BOTTOMRIGHT", Config, "BOTTOMRIGHT", 0, 0)
Footer:SetHeight(FOOTER_H)

do
	local fbg = Footer:CreateTexture(nil, "BACKGROUND")
	fbg:SetAllPoints()
	fbg:SetTexture([[Interface\Buttons\WHITE8X8]])
	fbg:SetVertexColor(0.042, 0.032, 0.022, 0.5)

	local fgr = Footer:CreateTexture(nil, "BACKGROUND", nil, 1)
	fgr:SetAllPoints()
	fgr:SetTexture([[Interface\Buttons\WHITE8X8]])
	fgr:SetGradientAlpha("HORIZONTAL",
		red * 0.15, green * 0.10, blue * 0.04, 0.45,
		0, 0, 0, 0)

	local fdiv = Footer:CreateTexture(nil, "ARTWORK")
	fdiv:SetPoint("TOPLEFT",  Footer, "TOPLEFT",  0, 0)
	fdiv:SetPoint("TOPRIGHT", Footer, "TOPRIGHT", 0, 0)
	fdiv:SetHeight(1)
	fdiv:SetTexture([[Interface\Buttons\WHITE8X8]])
	fdiv:SetVertexColor(red * 0.8 + 0.1, green * 0.65 + 0.08, blue * 0.2, 0.9)
end

-- ============================================================
-- CONTENT AREA
-- ============================================================
local ContentArea = CreateFrame("Frame", nil, Config)
ContentArea:SetPoint("TOPLEFT",     Header, "BOTTOMLEFT",  0,  -1)
ContentArea:SetPoint("BOTTOMRIGHT", Footer, "TOPRIGHT",    0,   1)

-- ============================================================
-- SIDEBAR
-- ============================================================
local Sidebar = CreateFrame("Frame", nil, ContentArea)
Sidebar:SetPoint("TOPLEFT",    ContentArea, "TOPLEFT",    0, 0)
Sidebar:SetPoint("BOTTOMLEFT", ContentArea, "BOTTOMLEFT", 0, 0)
Sidebar:SetWidth(SIDEBAR_W)

do
	local sbg = Sidebar:CreateTexture(nil, "BACKGROUND")
	sbg:SetAllPoints()
	sbg:SetTexture([[Interface\Buttons\WHITE8X8]])
	sbg:SetVertexColor(0.052, 0.040, 0.028, 0.5)

	local sdiv = Sidebar:CreateTexture(nil, "ARTWORK")
	sdiv:SetPoint("TOPRIGHT",    Sidebar, "TOPRIGHT",    0,  0)
	sdiv:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0,  0)
	sdiv:SetWidth(1)
	sdiv:SetTexture([[Interface\Buttons\WHITE8X8]])
	sdiv:SetVertexColor(red * 0.7 + 0.1, green * 0.55 + 0.08, blue * 0.15, 0.65)

	-- "Categories" header row
	local catBG = Sidebar:CreateTexture(nil, "BACKGROUND", nil, 1)
	catBG:SetPoint("TOPLEFT",  Sidebar, "TOPLEFT",  0,  0)
	catBG:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0,  0)
	catBG:SetHeight(30)
	catBG:SetTexture([[Interface\Buttons\WHITE8X8]])
	catBG:SetVertexColor(0.08, 0.062, 0.04, 1)

	local catDiv = Sidebar:CreateTexture(nil, "ARTWORK")
	catDiv:SetPoint("BOTTOMLEFT",  catBG, "BOTTOMLEFT",  0, 0)
	catDiv:SetPoint("BOTTOMRIGHT", catBG, "BOTTOMRIGHT", 0, 0)
	catDiv:SetHeight(1)
	catDiv:SetTexture([[Interface\Buttons\WHITE8X8]])
	catDiv:SetVertexColor(red * 0.6 + 0.08, green * 0.5 + 0.06, blue * 0.12, 0.7)

	local catLabel = Sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	catLabel:SetPoint("LEFT", Sidebar, "TOPLEFT", INDENT, -15)
	catLabel:SetText("Categories")
	catLabel:SetTextColor(0.65, 0.60, 0.48, 1)
end

local SideScroll = CreateFrame("ScrollFrame", nil, Sidebar)
SideScroll:SetPoint("TOPLEFT",     Sidebar, "TOPLEFT",     0, -36)
SideScroll:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", -6,  0)
SideScroll:EnableMouseWheel(true)
SideScroll:SetScript("OnMouseWheel", function(self, delta)
	local cur = self:GetVerticalScroll()
	local max = self:GetVerticalScrollRange()
	self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 24)))
end)

-- Visible scroll track on right edge
do
	local track = Sidebar:CreateTexture(nil, "ARTWORK")
	track:SetWidth(3)
	track:SetPoint("TOPRIGHT",    Sidebar, "TOPRIGHT",    -1, -36)
	track:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", -1,  4)
	track:SetTexture([[Interface\Buttons\WHITE8X8]])
	track:SetVertexColor(1, 1, 1, 0.06)
end

local SideChild = CreateFrame("Frame", nil, SideScroll)
SideChild:SetWidth(SIDEBAR_W)
SideChild:SetHeight(1)
SideScroll:SetScrollChild(SideChild)

-- ============================================================
-- CONTAINER (panel host, right of sidebar)
-- ============================================================
Container:SetPoint("TOPLEFT",     ContentArea, "TOPLEFT",     SIDEBAR_W + 1, 0)
Container:SetPoint("BOTTOMRIGHT", ContentArea, "BOTTOMRIGHT", 0,             0)
Container.Frames = {}
do
	local cbg = Container:CreateTexture(nil, "BACKGROUND")
	cbg:SetAllPoints()
	cbg:SetTexture([[Interface\Buttons\WHITE8X8]])
	cbg:SetVertexColor(0.068, 0.052, 0.036, 0.7)
end

local Default

-- ============================================================
-- FULL-WIDTH PANELS
-- Panels in this set skip the sidebar entirely:
-- they fill the whole ContentArea and hide the Sidebar + Footer.
-- ============================================================
local FULLWIDTH = { Binds = "fullFooter", About = "full" }

local function SetMode(mode)
	if mode == "full" then
		CPAPI.SetShown(Sidebar, false)
		CPAPI.SetShown(Footer,  false)
		Container:ClearAllPoints()
		Container:SetPoint("TOPLEFT",     ContentArea, "TOPLEFT",     0, 0)
		Container:SetPoint("BOTTOMRIGHT", ContentArea, "BOTTOMRIGHT", 0, 0)
	elseif mode == "fullFooter" then
		CPAPI.SetShown(Sidebar, false)
		CPAPI.SetShown(Footer,  true)
		Container:ClearAllPoints()
		Container:SetPoint("TOPLEFT",     ContentArea, "TOPLEFT",     0, 0)
		Container:SetPoint("BOTTOMRIGHT", ContentArea, "BOTTOMRIGHT", 0, 0)
	else -- "normal"
		CPAPI.SetShown(Sidebar, true)
		CPAPI.SetShown(Footer,  true)
		Container:ClearAllPoints()
		Container:SetPoint("TOPLEFT",     ContentArea, "TOPLEFT",     SIDEBAR_W + 1, 0)
		Container:SetPoint("BOTTOMRIGHT", ContentArea, "BOTTOMRIGHT", 0,             0)
	end
end

-- ============================================================
-- SIDEBAR ENTRY SYSTEM
-- ============================================================
local sideEntries  = {}
local sideEntryByName = {}
local sideYOffset  = 8

local function SideUpdateHeight()
	SideChild:SetHeight(math.max(1, sideYOffset + 4))
end

local function SideSetSelected(panelName)
	for _, e in ipairs(sideEntries) do
		if not e.isGroup then
			local active = (e.name == panelName)
			if active then e.selTex:Show()  else e.selTex:Hide()  end
			if active then e.accLine:Show() else e.accLine:Hide() end
			if active then
				e.label:SetTextColor(
					red   * 0.45 + 0.72,
					green * 0.35 + 0.62,
					blue  * 0.08 + 0.20, 1)
			else
				e.label:SetTextColor(0.72, 0.68, 0.58, 1)
			end
		end
	end
end

local function AddSideGroup(groupName)
	local btn = CreateFrame("Button", nil, SideChild)
	btn:SetHeight(GROUP_H)
	btn:SetWidth(SIDEBAR_W)
	btn:SetPoint("TOPLEFT", SideChild, "TOPLEFT", 0, -sideYOffset)

	local gbg = btn:CreateTexture(nil, "BACKGROUND")
	gbg:SetAllPoints()
	gbg:SetTexture([[Interface\Buttons\WHITE8X8]])
	gbg:SetVertexColor(0.14, 0.10, 0.05, 1)

	local gleft = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
	gleft:SetWidth(3)
	gleft:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, 0)
	gleft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
	gleft:SetTexture([[Interface\Buttons\WHITE8X8]])
	gleft:SetVertexColor(red * 0.8 + 0.15, green * 0.65 + 0.10, blue * 0.15 + 0.02, 1)

	local ghl = btn:CreateTexture(nil, "HIGHLIGHT")
	ghl:SetAllPoints()
	ghl:SetTexture([[Interface\Buttons\WHITE8X8]])
	ghl:SetVertexColor(1, 1, 1, 0.06)

	local gline = btn:CreateTexture(nil, "ARTWORK")
	gline:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
	gline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
	gline:SetHeight(1)
	gline:SetTexture([[Interface\Buttons\WHITE8X8]])
	gline:SetVertexColor(red * 0.7 + 0.08, green * 0.55 + 0.06, blue * 0.12, 0.8)

	local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	arrow:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
	arrow:SetText("—")
	arrow:SetTextColor(red * 0.7 + 0.18, green * 0.55 + 0.12, blue * 0.1 + 0.02, 0.9)

	local glabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	glabel:SetPoint("LEFT", btn, "LEFT", INDENT + 4, 0)
	glabel:SetText(groupName)
	glabel:SetTextColor(red * 0.5 + 0.72, green * 0.4 + 0.60, blue * 0.08 + 0.18, 1)

	btn:SetScript("OnMouseDown", function(self)
		glabel:ClearAllPoints()
		glabel:SetPoint("LEFT", self, "LEFT", INDENT + 4 + 1, -1) 
	end)

	btn:SetScript("OnMouseUp", function(self)
		glabel:ClearAllPoints()
		glabel:SetPoint("LEFT", self, "LEFT", INDENT + 4, 0) 
	end)

	local collapsed  = false
	local groupEntry = { isGroup = true, name = groupName, btn = btn, children = {} }
	table.insert(sideEntries, groupEntry)
	sideYOffset = sideYOffset + GROUP_H
	SideUpdateHeight()

	btn:SetScript("OnClick", function()
		collapsed = not collapsed
		arrow:SetText(collapsed and "+" or "—")
		for _, child in ipairs(groupEntry.children) do
			CPAPI.SetShown(child.btn, not collapsed)
		end
	end)

	return groupEntry
end

local function AddSideEntry(panelName, labelText, groupEntry)
	local btn = CreateFrame("Button", nil, SideChild)
	btn:SetHeight(ENTRY_H)
	btn:SetWidth(SIDEBAR_W)
	btn:SetPoint("TOPLEFT", SideChild, "TOPLEFT", 0, -sideYOffset)

	local selTex = btn:CreateTexture(nil, "BACKGROUND")
	selTex:SetAllPoints()
	selTex:SetTexture([[Interface\Buttons\WHITE8X8]])
	selTex:SetVertexColor(red * 0.5 + 0.08, green * 0.35 + 0.04, blue * 0.08 + 0.01, 0.30)
	selTex:Hide()

	local hl = btn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetTexture([[Interface\Buttons\WHITE8X8]])
	hl:SetVertexColor(1, 1, 1, 0.06)

	local accLine = btn:CreateTexture(nil, "ARTWORK")
	accLine:SetWidth(3)
	accLine:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, 0)
	accLine:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
	accLine:SetTexture([[Interface\Buttons\WHITE8X8]])
	accLine:SetVertexColor(red * 0.6 + 0.22, green * 0.5 + 0.18, blue * 0.1 + 0.04, 1)
	accLine:Hide()

	local labelIndent = INDENT + (groupEntry and 8 or 0)
	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("LEFT",  btn, "LEFT",  labelIndent, 0)
	label:SetPoint("RIGHT", btn, "RIGHT", -8,          0)
	label:SetJustifyH("LEFT")
	label:SetText(labelText or panelName)
	label:SetTextColor(0.72, 0.68, 0.58, 1)  -- warm grey-gold default

	btn:SetScript("OnMouseDown", function(self)
		label:ClearAllPoints()
		label:SetPoint("LEFT", self, "LEFT", labelIndent + 1, -1)
		label:SetPoint("RIGHT", self, "RIGHT", -8 + 1, -1)
	end)

	btn:SetScript("OnMouseUp", function(self)
		label:ClearAllPoints()
		label:SetPoint("LEFT", self, "LEFT", labelIndent, 0)
		label:SetPoint("RIGHT", self, "RIGHT", -8, 0)
	end)

	-- Thin separator line
	local sep = btn:CreateTexture(nil, "BACKGROUND")
	sep:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  INDENT + 4, 0)
	sep:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4,         0)
	sep:SetHeight(1)
	sep:SetTexture([[Interface\Buttons\WHITE8X8]])
	sep:SetVertexColor(1, 1, 1, 0.05)

	btn:SetScript("OnClick", function()
		Container:ShowFrame(panelName)
	end)

	local entry = {
		isGroup = false,
		name    = panelName,
		btn     = btn,
		selTex  = selTex,
		accLine = accLine,
		label   = label,
	}
	table.insert(sideEntries, entry)
	sideEntryByName[panelName] = entry

	if groupEntry then
		table.insert(groupEntry.children, entry)
	end

	sideYOffset = sideYOffset + ENTRY_H
	SideUpdateHeight()

	return entry
end

-- ============================================================
-- Category replacement
-- Panels call Category:AddNew(header, bannerAtlas) through
-- WindowMixin:AddPanel. We push a sidebar entry instead and
-- keep a stub in Category.Buttons[id] so panel code that
-- indexes it numerically doesn't error.
-- ============================================================
local Category = { Buttons = {} }
Config.Category = Category
-- Dummy textures so WindowMixin:ToggleShortcuts doesn't crash
Category.NextIcon = SideChild:CreateTexture(nil, "ARTWORK")
Category.PrevIcon = SideChild:CreateTexture(nil, "ARTWORK")

function Category:AddNew(header, bannerAtlas, name)
	local id    = #self.Buttons + 1
	local target = name or header

	if not FULLWIDTH[target] then
		-- v107: the parent Settings page is the General section in the sidebar.
		AddSideEntry(target, target == 'Controls' and 'General' or header)
	end

	-- Stub so Container:HideAll / ShowFrame can call
	-- Category.Buttons[id].SelectedTexture:Show/Hide without erroring.
	-- Show() drives the sidebar highlight via SideSetSelected(target).
	self.Buttons[id] = {
		id          = id,
		IDtag       = target,
		hasPriority = false,
		SelectedTexture = {
			Show = function() SideSetSelected(target) end,
			Hide = function() end,
		},
	}

	return id
end

-- ============================================================
-- Container methods
-- ============================================================
function Container:HideAll()
	for i, frame in pairs(self.Frames) do
		if Category.Buttons[i] then
			Category.Buttons[i].hasPriority = nil
			Category.Buttons[i].SelectedTexture:Hide()
		end
		frame:Hide()
	end
end

function Container:GetFrameByName(id)
	for index, frame in pairs(self.Frames) do
		if frame.IDtag == id then
			return frame, index
		end
	end
end

function Container:GetFrameByID(id)
	local frame = self.Frames[id]
	if frame then
		return frame, id
	else
		return self:GetFrameByName(id)
	end
end

function Container:ShowFrame(id)
	local frame, index = self:GetFrameByID(id)
	if not frame then return end
	self.Current = frame
	self:HideAll()
	self.Current:Show()
	self.id = index
	-- Remember real user navigation, including Settings child pages such as
	-- Action Bars. Internal restore/open bootstrap calls set CPRestoring... first.
	if Config:IsShown() and not CPRestoringConfigCategory
	and frame.IDtag ~= 'Binds' and frame.IDtag ~= 'About' then
		ConsolePortUIConfig = ConsolePortUIConfig or {}
		CPLastConfigCategoryThisSession = frame.IDtag
	end
	if Category.Buttons[self.id] then
		Category.Buttons[self.id].hasPriority = true
		Category.Buttons[self.id].SelectedTexture:Show()
	end
	-- Switch layout mode: full-width panels hide the sidebar and footer
	SetMode(FULLWIDTH[frame.IDtag] or "normal")
	CPAPI.SetShown(Default, not self.Current.noDefault)
	return self.Current, self.id
end

-- ============================================================
-- FOOTER BUTTONS
-- ============================================================
local Cancel  = db.Atlas.GetFlatButton("ConsolePortOldConfigCancel",  Footer, 140, 30)
local Save    = db.Atlas.GetFlatButton("ConsolePortOldConfigSave",    Footer, 140, 30)
Default       = db.Atlas.GetFlatButton("ConsolePortOldConfigDefault", Footer, 140, 30)

Cancel:SetPoint("RIGHT",  Footer, "RIGHT",  -16, 0)
Save:SetPoint(  "RIGHT",  Cancel, "LEFT",    -6, 0)
Default:SetPoint("LEFT",  Footer, "LEFT",    16, 0)

Cancel:SetText(TUTORIAL.CANCEL)
Save:SetText(TUTORIAL.SAVE)
Default:SetText(TUTORIAL.DEFAULT)

Save.Icon:SetSize(18, 18)
Save.Icon:SetPoint("LEFT", 8, 0)
Save.Icon:Show()


Save._bg:SetVertexColor(red * 0.28 + 0.10, green * 0.20 + 0.08, blue * 0.05 + 0.02, 1)
Save:SetBackdropBorderColor(red * 0.7 + 0.20, green * 0.55 + 0.15, blue * 0.12 + 0.03, 1)
Save.Label:SetTextColor(1, 0.95, 0.75, 1)

function Cancel:OnClick()
	if not InCombatLockdown() then
		for _, frame in ipairs(Container.Frames) do
			if frame.Cancel then frame:Cancel() end
		end
		Config:Hide()
	end
end
Cancel:SetScript("OnClick", Cancel.OnClick)

function Save:OnClick()
	local data, reload
	if not InCombatLockdown() then
		for _, frame in ipairs(Container.Frames) do
			if frame.Save and not frame.onLoad then
				local needReload, exportID, exportData = frame:Save()
				reload = needReload or reload
				if exportID and exportData then
					if not data then data = {} end
					data[exportID] = exportData
				end
			end
		end
		Config:Export(data, db('explicitProfile'))
		if reload then ReloadUI() else Config:Hide() end
	end
end
Save:SetScript("OnClick", Save.OnClick)

---------------------------------------------------------------
Default.PopupFrame          = CreateFrame("Frame",  "$parentPopup",   Default)
Default.PopupFrame.Apply    = CreateFrame("Button", "$parentApply",   Default.PopupFrame)
Default.PopupFrame.Cancel   = CreateFrame("Button", "$parentCancel",  Default.PopupFrame)
Default.PopupFrame.ResetAll  = db.Atlas.GetFutureButton("$parentResetAll",  Default.PopupFrame)
Default.PopupFrame.ResetThis = db.Atlas.GetFutureButton("$parentResetThis", Default.PopupFrame)
Default.PopupFrame.ResetAll:SetPoint("CENTER",  0,  23)
Default.PopupFrame.ResetThis:SetPoint("CENTER", 0, -23)
Default.PopupFrame.ResetAll:SetText(TUTORIAL.DEFAULTALL)
Default.PopupFrame.ResetThis:SetText(TUTORIAL.DEFAULTTHIS)
Default.PopupFrame.Apply:SetText(TUTORIAL.APPLY)
Default.PopupFrame.Cancel:SetText(TUTORIAL.CANCEL)

function Default:ResetAll()
	if not InCombatLockdown() then
		for _, frame in ipairs(Container.Frames) do
			if frame.Default then frame:Default() end
		end
	end
end

function Default:ResetThis()
	if not InCombatLockdown() then
		if Container.Current and Container.Current.Default then
			Container.Current:Default()
			Container.Current:Show()
		end
	end
end

function Default:OnClick()
	Popup:SetPopup(TUTORIAL.DEFAULTHEADER, self.PopupFrame,
		self.PopupFrame.Apply, self.PopupFrame.Cancel, 220)
end

function Default.PopupFrame:OnHide()
	self.ResetThis.SelectedTexture:Hide()
	self.ResetAll.SelectedTexture:Hide()
	self.Apply:SetScript("OnClick", nil)
end

function Default.PopupFrame.ResetAll:OnClick()
	self.SelectedTexture:Show()
	Default.PopupFrame.ResetThis.SelectedTexture:Hide()
	Default.PopupFrame.Apply:SetScript("OnClick", Default.ResetAll)
end

function Default.PopupFrame.ResetThis:OnClick()
	self.SelectedTexture:Show()
	Default.PopupFrame.ResetAll.SelectedTexture:Hide()
	Default.PopupFrame.Apply:SetScript("OnClick", Default.ResetThis)
end

Default:SetScript("OnClick", Default.OnClick)
Default.PopupFrame:SetScript("OnHide",       Default.PopupFrame.OnHide)
Default.PopupFrame.ResetAll:SetScript("OnClick",  Default.PopupFrame.ResetAll.OnClick)
Default.PopupFrame.ResetThis:SetScript("OnClick", Default.PopupFrame.ResetThis.OnClick)

-- ============================================================
-- TOOLTIP
-- ============================================================
local Tooltip = CreateFrame("GameTooltip", "$parentTooltip", Config, "GameTooltipTemplate")
Config.Tooltip = Tooltip

function Tooltip:OnShow()
	self:SetBackdrop(db.Atlas.Backdrops.TooltipBorder)
	self:SetBackdropColor(red, green, blue, 0.9)
	FadeIn(self, 0.2, 0, 1)
end

Tooltip:SetScript("OnShow", Tooltip.OnShow)
Tooltip:Show()
Tooltip:Hide()

-- ============================================================
-- POPUP
-- ============================================================
Popup.Button1   = db.Atlas.GetFutureButton("$parentButton1", Popup, nil, nil, 180, 36)
Popup.Button2   = db.Atlas.GetFutureButton("$parentButton2", Popup, nil, nil, 180, 36)
Popup.Container = db.Atlas.GetGlassWindow("$parentContainer", Popup, nil, true)
Popup.Container.BG:SetAlpha(0.1)
Popup.Container.Close:Hide()
Popup.Container.Tint:Hide()
Popup.Container:SetPoint("TOPLEFT",     Popup, "TOPLEFT",     8, -44)
Popup.Container:SetPoint("BOTTOMRIGHT", Popup, "BOTTOMRIGHT", -8,  44)

Popup.Header = Popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
Popup.Header:SetPoint("TOP", 0, -32)

Popup.Button1:SetPoint("BOTTOMLEFT",  Popup, "BOTTOMLEFT",  20, 20)
Popup.Button2:SetPoint("BOTTOMRIGHT", Popup, "BOTTOMRIGHT", -20, 20)

function Popup:WrapClick(wrapper, button)
	if button then
		wrapper:Show()
		wrapper:SetText(button:GetText())
		wrapper:SetScript("OnClick", function()
			button:Click()
			if not button.dontHide then self:Hide() end
		end)
	else
		wrapper:SetText()
		wrapper:SetScript("OnClick", nil)
		wrapper:Hide()
	end
end

function Popup:SetPopup(header, frame, button1, button2, height, width)
	if self.frame and self.frame:GetParent() == self then
		self.frame:Hide()
	end
	frame:Show()
	frame:SetParent(self)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT",     self.Container, "TOPLEFT",     16, -16)
	frame:SetPoint("BOTTOMRIGHT", self.Container, "BOTTOMRIGHT", -16, 16)
	self.Header:SetText(header)
	self:WrapClick(self.Button1, button1)
	self:WrapClick(self.Button2, button2)
	self:Show()
	self:SetWidth(width  or 400)
	self:SetHeight(height or 500)
	self.frame = frame
	ConsolePort:SetCurrentNode(self.Close)
end

function Popup:SetSelection(value) self.selected = value end
function Popup:GetSelection()      return self.selected  end

function Popup:OnShow()
	Config.Obstructor:Show()
	Config.ignoreNode = true
	FadeOut(Config, 0.2, 1, 0.5)
end

function Popup:OnHide()
	Config.Obstructor:Hide()
	Config.ignoreNode = nil
	FadeIn(Config, 0.2, Config:GetAlpha(), 1)
end

function Popup:OnEvent() self:Hide() end

Popup:SetSize(400, 500)
Popup:SetPoint("CENTER", 0, 0)
Popup:EnableMouse(true)
Popup:HookScript("OnShow", Popup.OnShow)
Popup:SetScript("OnHide",  Popup.OnHide)
Popup:SetScript("OnEvent", Popup.OnEvent)
Popup:SetFrameStrata("DIALOG")
Popup:RegisterEvent("PLAYER_REGEN_DISABLED")
Popup:Hide()
Popup:SetMovable(true)
Popup:SetClampedToScreen(true)
Popup:RegisterForDrag("LeftButton")
Popup:HookScript("OnDragStart", Popup.StartMoving)
Popup:HookScript("OnDragStop",  Popup.StopMovingOrSizing)

-- ============================================================
-- Config navigation
-- ============================================================
function Config:GetCategoryID() return Container.id end
function Config:GetCategory()   return Container.Frames[Container.id] end

local function SyncHeaderTabForCategory(id)
	if id == "Binds" then SetActiveTab(BindingsBtn)
	elseif id == "About" then SetActiveTab(nil)
	else SetActiveTab(SettingsBtn) end
end

function Config:OpenCategory(id)
	ConsolePortUIConfig = ConsolePortUIConfig or {}
	local requested = id
	local wasShown = self:IsShown()

	-- The game-menu shortcut historically asks for Controls every time. After
	-- the first ordinary open in this Lua session, reinterpret that bootstrap
	-- request as "reopen where I left off". Explicit Binds requests (notably
	-- setup completion) remain explicit and win.
	if not wasShown and requested == "Controls" and CPConfigOpenedThisSession then
		id = CPLastConfigCategoryThisSession or requested
	end

	CPRestoringConfigCategory = not wasShown
	local frame, index = Container:ShowFrame(id)
	CPRestoringConfigCategory = false
	if frame then
		if not InCombatLockdown() then
			self:Show()
			SyncHeaderTabForCategory(frame.IDtag)
			-- v146: restore the proven v107 cursor method: after the frame is shown,
			-- directly select the sidebar node matching the displayed section.
			-- No ClearCurrentNode, no deferred timer, no pre-show cursor manipulation.
			if not wasShown and frame.IDtag ~= 'Binds' and frame.IDtag ~= 'About' and ConsolePort.SetCurrentNode then
				local activeEntry = sideEntryByName[frame.IDtag]
				-- v149: first visible Settings entry must not inherit the BindCatcher
				-- node left by setup/bootstrap. Clear only at this entry boundary.
				if ConsolePort.ClearCurrentNode then ConsolePort:ClearCurrentNode(true) end
				ConsolePort:SetCurrentNode((activeEntry and activeEntry.btn) or SettingsBtn)
			end
			-- Setup's forced Bindings launch is not an ordinary user opening. The
			-- next normal Controls request must still default to Settings.
			if not CPSetupOpeningBindings then
				CPConfigOpenedThisSession = true
				if frame.IDtag ~= 'Binds' and frame.IDtag ~= 'About' then
					CPLastConfigCategoryThisSession = frame.IDtag
				end
			end
			return frame
		else
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
			self.combatHide = true
			print(db.TUTORIAL.SLASH.CONFIG_COMBAT)
		end
	end
end

-- ============================================================
-- WindowMixin
-- ============================================================
function WindowMixin:AddPanel(info)
	local name, header, bannerAtlas, mixin, onCreate, onLoad =
		info.name, info.header, info.bannerAtlas,
		info.mixin, info.onCreate, info.onLoad

	local frame = CPAPI.CreateFrame("Frame", "$parent"..name, Container)
	frame:SetBackdrop(db.Atlas.Backdrops.Border)
	frame:SetBackdropColor(0, 0, 0, 0)

	local id = Category:AddNew(header, bannerAtlas, name)
	Container.Frames[id] = frame

	Mixin(frame, mixin)

	frame.IDtag     = name
	frame.noDefault = info.noDefault
	frame:SetID(id)
	frame:SetParent(self)
	frame:SetAllPoints(Container)
	frame:Hide()

	if onCreate then onCreate(frame, ConsolePort) end
	if onLoad then
		frame:SetScript("OnShow", function(self)
			self:onLoad(ConsolePort)
			self.onLoad = nil
			self:Hide()
			self:SetScript("OnShow", self.OnShow)
			self:Show()
		end)
		frame.onLoad = onLoad
	end

	db[name] = frame
	return frame
end

function WindowMixin:OnHide()
	if not self.combatHide then
		self:UnregisterAllEvents()
	end
	ClearOverrideBindings(self)
end

local shortCuts = {
	CP_R_LEFT  = true, CP_R_RIGHT = true,
	CP_R_UP    = true, CP_R_DOWN  = true,
}

local function SetSaveShortCut(self)
	if not InCombatLockdown() then
		for key in pairs(shortCuts) do shortCuts[key] = true end
		for _, key in pairs(db.Mouse.Cursor) do shortCuts[key] = false end
		local freeKey
		for key, value in pairs(shortCuts) do
			if value then freeKey = key; break end
		end
		local key = freeKey and GetBindingKey(freeKey)
		if key then
			Save.Icon:SetTexture(db.ICONS[freeKey])
			SetOverrideBindingClick(self, true, key, Save:GetName())
		else
			Save.Icon:SetTexture()
		end

		local lb = GetBindingKey("CP_T1")
		local rb = GetBindingKey("CP_T2")
		if lb then SetOverrideBindingClick(self, true, lb, BindingsShoulder:GetName()) end
		if rb then SetOverrideBindingClick(self, true, rb, SettingsShoulder:GetName()) end
	else
		Save.Icon:SetTexture()
	end
end

function WindowMixin:ToggleShortcuts(enable)
	local alpha = Save.Icon:GetAlpha()
	if enable then
		FadeIn(Save.Icon, 0.2, alpha, 1)
	else
		FadeOut(Save.Icon, 0.2, alpha, 0)
	end
end

function WindowMixin:OnShow()
	if not InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		SetSaveShortCut(self)
	else
		self:Hide()
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self.combatHide = true
		print(db.TUTORIAL.SLASH.CONFIG_COMBAT)
	end
end

function WindowMixin:OnEvent(event)
	if event == "PLAYER_REGEN_DISABLED" then
		self.combatHide = true
		self:Hide()
		ClearOverrideBindings(self)
	elseif event == "PLAYER_REGEN_ENABLED" then
		FadeIn(self, 0.5, 0, 1)
		self.combatHide = nil
		self:Show()
		SetSaveShortCut(self)
	end
end

function WindowMixin:OnKeyUp(key) end

function WindowMixin:OnKeyDown(key) end

function WindowMixin:Export(characterExportData, exportAs)
	if characterExportData then
		local _, classToken = UnitClass('player')
		local specID, specName = CPAPI.GetSpecializationInfo(CPAPI.GetSpecialization())
		local sharedData = ConsolePortCharacterSettings or {}
		ConsolePortCharacterSettings = sharedData

		local uid = (exportAs ~= nil and exportAs ~= '' and exportAs) or
					('%s (%s) %s'):format(GetUnitName('player'), specName, GetRealmName())

		if not sharedData[uid] then sharedData[uid] = {} end

		local characterProfile = sharedData[uid]
		local isIdentical      = db.table.compare

		for dataID, data in pairs(characterExportData) do
			local allowExport = true
			for exportID, exportData in pairs(sharedData) do
				if isIdentical(data, exportData[dataID]) then
					allowExport = false
				end
			end
			characterProfile[dataID] = allowExport and data or nil
		end

		local exportType  = db('type')
		local exportClass = classToken
		local exportSpec  = specID

		characterProfile.Type  = nil
		characterProfile.Class = nil
		characterProfile.Spec  = nil

		if next(characterProfile) then
			characterProfile.Type  = exportType
			characterProfile.Class = exportClass
			characterProfile.Spec  = exportSpec
		else
			sharedData[uid] = nil
		end
	end
end

Mixin(Config, WindowMixin)

-- ============================================================
-- CreateConfigPanel
-- ============================================================
function ConsolePort:CreateConfigPanel()
	for _, panel in ipairs(db.PANELS) do
		Config:AddPanel(panel)
	end
	db.PANELS = nil
	self.CreateConfigPanel = nil
	self:AddFrame(Config:GetName())
	self:AddFrame(Popup:GetName())
	tinsert(UISpecialFrames, Config:GetName())
	tinsert(UISpecialFrames, Popup:GetName())

	-- Wire header tab buttons
	LogoBtn:SetScript("OnClick", function()
		Config:OpenCategory("About")
		SetActiveTab(nil)   -- About is the logo, not a tab
	end)

	SettingsBtn:SetScript("OnClick", function()
		-- v151: mirror the confirmed-good reopen behavior. Resolve the same
		-- remembered Settings subsection, show it, then focus its sidebar heading.
		local target = CPLastConfigCategoryThisSession or "Controls"
		Config:OpenCategory(target)
		SetActiveTab(SettingsBtn)
		local entry = sideEntryByName[target]
		if entry and ConsolePort.SetCurrentNode then
			ConsolePort:ClearCurrentNode(true)
			ConsolePort:SetCurrentNode(entry.btn)
		end
	end)

	BindingsBtn:SetScript("OnClick", function()
		Config:OpenCategory("Binds")
		SetActiveTab(BindingsBtn)
	end)

	-- v105: every fresh Lua/UI session bootstraps Settings. No category is
	-- restored from SavedVariables across login or /reload. Setup can still
	-- explicitly request Bindings afterward without consuming the ordinary open.
	CPRestoringConfigCategory = true
	Container:ShowFrame("Controls")
	CPRestoringConfigCategory = false
	local current = Container.Current and Container.Current.IDtag
	if current == "Binds" then SetActiveTab(BindingsBtn)
	elseif current == "About" then SetActiveTab(nil)
	else SetActiveTab(SettingsBtn) end
end