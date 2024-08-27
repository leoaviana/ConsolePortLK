-- This was mostly stolen from Bartender4.
-- This code snippet hides and modifies the default action bars.

local _, ab = ...
local Bar = ab.bar
local red, green, blue = ab.data.Atlas.GetCC()

do
	-- Hidden parent frame
	local UIHider = CreateFrame('Frame')

	-------------------------------------------
	---		UI hider -> dispose of blizzbars
	-------------------------------------------

	UIHider:Hide()
	Bar.UIHider = UIHider

	for _, bar in pairs({
		MainMenuBarArtFrame,
		MainMenuBarMaxLevelBar,
		VehicleMenuBar,
		BonusActionBarFrame,
		MultiCastActionBarFrame,
		MultiBarLeft,
		MultiBarRight,
		MultiBarBottomLeft,
		MultiBarBottomRight }) do
		bar:SetParent(UIHider)
	end

	MainMenuBarArtFrame:Hide()

	-- Hide MultiBar Buttons, but keep the bars alive
	for _, n in pairs({
		'ActionButton',	
		'BonusActionButton',
		'MultiBarLeftButton',
		'MultiBarRightButton',
		'MultiBarBottomLeftButton',
		'MultiBarBottomRightButton'	}) do
		for i=1, 12 do
			local b = _G[n .. i]
			b:Hide()
			b:UnregisterAllEvents()
			b:SetAttribute('statehidden', true)
		end
	end

	UIPARENT_MANAGED_FRAME_POSITIONS['MainMenuBar'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['BonusActionBar'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['ShapeshiftBarFrame'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['StanceBarFrame'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['PossessBarFrame'] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS['PETACTIONBAR_YPOS'] = nil

	MainMenuBar:EnableMouse(false)
	if MicroButtonAndBagsBar then MicroButtonAndBagsBar:Hide() end
	if StatusTrackingBarManager then StatusTrackingBarManager:Hide() end
	if MainMenuExpBar then MainMenuExpBar:SetParent(UIHider) end
	if MainMenuBarPerformanceBar then MainMenuBarPerformanceBar:SetParent(UIHider) end
	if ReputationWatchBar then ReputationWatchBar:SetParent(UIHider) end

--	local animations = {MainMenuBar.slideOut:GetAnimations()}
--	animations[1]:SetOffset(0,0)

	-------------------------------------------
	--- 	Special action bars
	-------------------------------------------

	for _, bar in pairs({
		ShapeshiftBarFrame,
		StanceBarFrame,
		PossessBarFrame,
		PetActionBarFrame	}) do
		bar:UnregisterAllEvents()
		bar:SetParent(UIHider)
		bar:Hide()
	end

	-------------------------------------------
	--- 	Casting bar modified
	-------------------------------------------

	local castBar, overrideCastBarPos = CastingBarFrame
	local castBarAnchor = {'BOTTOM', Bar,  'BOTTOM', 0, 0}

	hooksecurefunc(castBar, 'SetPoint', function(self, point, region, relPoint, x, y)
		if overrideCastBarPos and region ~= castBarAnchor[2] then
			self:SetPoint(unpack(castBarAnchor))
		end
	end)

	
	local function CastingBarFrame_SetLook(self, look)

		local selfName = self:GetName();
		local selfSpark = _G[selfName.."Spark"];
		local selfText = _G[selfName.."Text"];
		local selfFlash = _G[selfName.."Flash"];
		local selfIcon = _G[selfName.."Icon"];
		local selfBorder = _G[selfName.."Border"];
		local selfBorderShield = _G[selfName.."BorderShield"];

		if ( look == "CLASSIC" ) then
			self:SetWidth(195);
			self:SetHeight(13);
			-- border
			selfBorder:ClearAllPoints();
			selfBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border");
			selfBorder:SetWidth(256);
			selfBorder:SetHeight(64);
			selfBorder:SetPoint("TOP", 0, 28);
			-- bordershield
			selfBorderShield:ClearAllPoints();
			selfBorderShield:SetWidth(256);
			selfBorderShield:SetHeight(64);
			selfBorderShield:SetPoint("TOP", 0, 28);
			-- text
			selfText:ClearAllPoints();
			selfText:SetWidth(185);
			selfText:SetHeight(16);
			selfText:SetPoint("TOP", 0, 5);
			selfText:SetFontObject("GameFontHighlight");
			-- icon
			selfIcon:Hide();
			-- bar spark
			selfSpark.offsetY = 2;
			-- bar flash
			selfFlash:ClearAllPoints();
			selfFlash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash");
			selfFlash:SetWidth(256);
			selfFlash:SetHeight(64);
			selfFlash:SetPoint("TOP", 0, 28);
		elseif ( look == "UNITFRAME" ) then
			self:SetWidth(150);
			self:SetHeight(10);
			-- border
			selfBorder:ClearAllPoints();
			selfBorder:SetTexture("");
			selfBorder:SetWidth(0);
			selfBorder:SetHeight(49);
			selfBorder:SetPoint("TOPLEFT", -23, 20);
			selfBorder:SetPoint("TOPRIGHT", 23, 20);
			-- bordershield
			selfBorderShield:ClearAllPoints();
			selfBorderShield:SetWidth(0);
			selfBorderShield:SetHeight(49);
			selfBorderShield:SetPoint("TOPLEFT", -28, 20);
			selfBorderShield:SetPoint("TOPRIGHT", 18, 20);
			-- text
			selfText:ClearAllPoints();
			selfText:SetWidth(0);
			selfText:SetHeight(16);
			selfText:SetPoint("TOPLEFT", 0, 4);
			selfText:SetPoint("TOPRIGHT", 0, 4);
			selfText:SetFontObject("SystemFont_Shadow_Small");
			-- icon
			selfIcon:Show();
			-- bar spark
			selfSpark.offsetY = 0;
			-- bar flash
			selfFlash:ClearAllPoints();
			selfFlash:SetTexture("Interface\\CastingBar\\UI-CastingBar-Flash-Small");
			selfFlash:SetWidth(0);
			selfFlash:SetHeight(49);
			selfFlash:SetPoint("TOPLEFT", -23, 20);
			selfFlash:SetPoint("TOPRIGHT", 23, 20);
		end
  	end

	local function ModifyCastingBarFrame(self, isOverrideBar)
		local selfName = self:GetName();
		local selfSpark = _G[selfName.."Spark"];
		local selfText = _G[selfName.."Text"];
		local selfFlash = _G[selfName.."Flash"];
		local selfIcon = _G[selfName.."Icon"];
		local selfBorder = _G[selfName.."Border"];
		local selfBorderShield = _G[selfName.."BorderShield"];

		CastingBarFrame_SetLook(self, isOverrideBar and 'CLASSIC' or 'UNITFRAME')
		CPAPI.SetShown(selfBorder, isOverrideBar)
		if isOverrideBar then
			return
		end
		-- Text anchor
		selfText:SetPoint('TOPLEFT', 0, 0)
		selfText:SetPoint('TOPRIGHT', 0, 0)
		-- Flash at the end of a cast
		selfFlash:SetTexture('Interface\\QUESTFRAME\\UI-QuestLogTitleHighlight')
		selfFlash:SetAllPoints()
		-- Border shield for uninterruptible casts
		selfBorderShield:ClearAllPoints()
		selfBorderShield:SetTexture('Interface\\CastingBar\\UI-CastingBar-Arena-Shield')
		selfBorderShield:SetPoint('CENTER', selfIcon, 'CENTER', 10, 0)
		selfBorderShield:SetSize(49, 49)

		--local r, g, b = ab:GetRGBColorFor('exp')
		--CastingBarFrame_SetStartCastColor(self, r or 1.0, g or 0.7, b or 0.0)
	end

	local function MoveCastingBarFrame()
		local cfg = ab.cfg
		if cfg and cfg.disableCastBarHook then
			overrideCastBarPos = false
		elseif OverrideActionBar and OverrideActionBar:IsShown() or (cfg and cfg.defaultCastBar) then
			ModifyCastingBarFrame(castBar, true)
			overrideCastBarPos = false
		else
			castBarAnchor[4] = ( cfg and cfg.castbarxoffset or 0 )
			castBarAnchor[5] = ( cfg and cfg.castbaryoffset or 0 )
			ModifyCastingBarFrame(castBar, false)
			castBar:ClearAllPoints()
			castBar:SetPoint(unpack(castBarAnchor))
			castBar:SetFrameStrata("HIGH")
			castBar:SetSize(
				(cfg and cfg.castbarwidth) or (Bar:GetWidth() - 280),
				(cfg and cfg.castbarheight) or 14)
			overrideCastBarPos = true
		end
	end

	Bar:HookScript('OnSizeChanged', MoveCastingBarFrame)
	Bar:HookScript('OnShow', MoveCastingBarFrame)
	Bar:HookScript('OnHide', MoveCastingBarFrame)

	if OverrideActionBar then
		OverrideActionBar:HookScript('OnShow', MoveCastingBarFrame)
		OverrideActionBar:HookScript('OnHide', MoveCastingBarFrame)
	end 

	-------------------------------------------
	--- 	Misc changes
	-------------------------------------------

	if ObjectiveTrackerFrame then
		ObjectiveTrackerFrame:SetPoint('TOPRIGHT', MinimapCluster, 'BOTTOMRIGHT', -100, -132)
	end
	AlertFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 200)

	if PlayerTalentFrame then
		PlayerTalentFrame:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	else
		hooksecurefunc('TalentFrame_LoadUI', function()
			if PlayerTalentFrame then
				PlayerTalentFrame:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
			end 
		end)
	end

	-- Replace spell push animations. 
	--[===[
	IconIntroTracker:HookScript('OnEvent', function(self, event, ...)
		local anim = ConsolePortSpellHelperFrame
		if anim and event == 'SPELL_PUSHED_TO_ACTIONBAR' then
			for _, icon in pairs(self.iconList) do
				icon:ClearAllPoints()
				icon:SetAlpha(0)
			end

			local spellID, slotIndex, slotPos = ...
			local page = math.floor((slotIndex - 1) / NUM_ACTIONBAR_BUTTONS) + 1
			local currentPage = GetActionBarPage()
			local bonusBarIndex = GetBonusBarIndex()
			if (HasBonusActionBar() and bonusBarIndex ~= 0) then
				currentPage = bonusBarIndex
			end

			if (page ~= currentPage and page ~= MULTIBOTTOMLEFTINDEX) then
				return
			end
			
			local _, _, icon = GetSpellInfo(spellID)
			local actionID = ((page - 1) * NUM_ACTIONBAR_BUTTONS) + slotPos

			anim:OnActionPlaced(actionID, icon)
		end
	end)
	--]===]
end