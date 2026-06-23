-- SliceMask.lua
-- Approximates MaskTexture behavior on WotLK (3.3.5a) using stacked ScrollFrames.
-- Again, inspired from  https://www.wowinterface.com/forums/showthread.php?t=45918 
-- (Huge thanks to semlar, zork and Infus for the code.)
--
-- Each sub-button icon is clipped by 16 horizontal (or vertical) ScrollFrame slices
-- derived from sampling the actual mask textures taken from Texture/Masks folder
--

local _, ab = ...
local db = ConsolePort:GetData()
local CPAPI = db.CPAPI

local SliceMask = {}
ab.libs = ab.libs or {}
ab.libs.slicemask = SliceMask
ConsolePortBar.SliceMask = SliceMask


-- Mask texture alpha-channel sampling.
-- down/up: 16 horizontal slices, top->bottom. Each = {leftFrac, rightFrac}
-- left/right: 16 vertical slices, left->right. Each = {topFrac, bottomFrac}
-- Fractions are of the full button size (0..1). 0.5/0.5 = empty/invisible slice.
local maskSlices = {
    ['SHIFT-'] = {
        down = {
            {0.4219, 0.4844},
            {0.3594, 0.4688},
            {0.2969, 0.4531},
            {0.2344, 0.4219},
            {0.1719, 0.3906},
            {0.1094, 0.3438},
            {0.0938, 0.2969},
            {0.0938, 0.2188},
            {0.125,  0.0938},
            {0.1562, 0.0938},
            {0.2031, 0.125 },
            {0.25,   0.1562},
            {0.2969, 0.2031},
            {0.3594, 0.2344},
            {0.4375, 0.2656},
            {0.5312, 0.2969},
        },
        up = {
            {0.5312, 0.2969},
            {0.4375, 0.2656},
            {0.3594, 0.2344},
            {0.2969, 0.2031},
            {0.25,   0.1562},
            {0.2031, 0.125 },
            {0.1562, 0.0938},
            {0.125,  0.0938},
            {0.0938, 0.2188},
            {0.0938, 0.2969},
            {0.1094, 0.3438},
            {0.1719, 0.3906},
            {0.2344, 0.4219},
            {0.2969, 0.4531},
            {0.3594, 0.4688},
            {0.4219, 0.4844},
        },
        left = {
            {0.5312, 0.2969},
            {0.4375, 0.2656},
            {0.3594, 0.2344},
            {0.2969, 0.2031},
            {0.25,   0.1562},
            {0.2031, 0.125 },
            {0.1562, 0.0938},
            {0.125,  0.0938},
            {0.0938, 0.2188},
            {0.0938, 0.2969},
            {0.1094, 0.3438},
            {0.1719, 0.3906},
            {0.2344, 0.4219},
            {0.2969, 0.4531},
            {0.3594, 0.4688},
            {0.4219, 0.4844},
        },
        right = {
            {0.4219, 0.4844},
            {0.3594, 0.4688},
            {0.2969, 0.4531},
            {0.2344, 0.4219},
            {0.1719, 0.3906},
            {0.1094, 0.3438},
            {0.0938, 0.2969},
            {0.0938, 0.2188},
            {0.125,  0.0938},
            {0.1562, 0.0938},
            {0.2031, 0.125 },
            {0.25,   0.1562},
            {0.2969, 0.2031},
            {0.3594, 0.2344},
            {0.4375, 0.2656},
            {0.5312, 0.2969},
        },
    },
    ['CTRL-'] = {
        down = {
            {0.4844, 0.4219},
            {0.4688, 0.3594},
            {0.4531, 0.2969},
            {0.4219, 0.2344},
            {0.3906, 0.1719},
            {0.3438, 0.1094},
            {0.2969, 0.0938},
            {0.2188, 0.0938},
            {0.0938, 0.125 },
            {0.0938, 0.1562},
            {0.125,  0.2031},
            {0.1562, 0.25  },
            {0.2031, 0.2969},
            {0.2344, 0.3594},
            {0.2656, 0.4375},
            {0.2969, 0.5312},
        },
        up = {
            {0.2969, 0.5312},
            {0.2656, 0.4375},
            {0.2344, 0.3594},
            {0.2031, 0.2969},
            {0.1562, 0.25  },
            {0.125,  0.2031},
            {0.0938, 0.1562},
            {0.0938, 0.125 },
            {0.2188, 0.0938},
            {0.2969, 0.0938},
            {0.3438, 0.1094},
            {0.3906, 0.1719},
            {0.4219, 0.2344},
            {0.4531, 0.2969},
            {0.4688, 0.3594},
            {0.4844, 0.4219},
        },
        left = {
            {0.2969, 0.5312},
            {0.2656, 0.4375},
            {0.2344, 0.3594},
            {0.2031, 0.2969},
            {0.1562, 0.25  },
            {0.125,  0.2031},
            {0.0938, 0.1562},
            {0.0938, 0.125 },
            {0.2188, 0.0938},
            {0.2969, 0.0938},
            {0.3438, 0.1094},
            {0.3906, 0.1719},
            {0.4219, 0.2344},
            {0.4531, 0.2969},
            {0.4688, 0.3594},
            {0.4844, 0.4219},
        },
        right = {
            {0.4844, 0.4219},
            {0.4688, 0.3594},
            {0.4531, 0.2969},
            {0.4219, 0.2344},
            {0.3906, 0.1719},
            {0.3438, 0.1094},
            {0.2969, 0.0938},
            {0.2188, 0.0938},
            {0.0938, 0.125 },
            {0.0938, 0.1562},
            {0.125,  0.2031},
            {0.1562, 0.25  },
            {0.2031, 0.2969},
            {0.2344, 0.3594},
            {0.2656, 0.4375},
            {0.2969, 0.5312},
        },
    },
    ['CTRL-SHIFT-'] = {
        down = {
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.2344, 0.2188},
            {0.2031, 0.1875},
            {0.1562, 0.1406},
            {0.125,  0.1094},
            {0.0938, 0.0781},
            {0.0625, 0.0312},
            {0.0156, 0.0   },
            {0.0,    0.0   },
            {0.0156, 0.0156},
            {0.1875, 0.2031},
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
        },
        up = {
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.1875, 0.2031},
            {0.0156, 0.0156},
            {0.0,    0.0   },
            {0.0156, 0.0   },
            {0.0625, 0.0312},
            {0.0938, 0.0781},
            {0.125,  0.1094},
            {0.1562, 0.1406},
            {0.2031, 0.1875},
            {0.2344, 0.2188},
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
        },
        left = {
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.2031, 0.1875},
            {0.0156, 0.0156},
            {0.0,    0.0   },
            {0.0,    0.0156},
            {0.0312, 0.0625},
            {0.0781, 0.0938},
            {0.1094, 0.125 },
            {0.1406, 0.1562},
            {0.1875, 0.2031},
            {0.2188, 0.2344},
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
        },
        right = {
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.2188, 0.2344},
            {0.1875, 0.2031},
            {0.1406, 0.1562},
            {0.1094, 0.125 },
            {0.0781, 0.0938},
            {0.0312, 0.0625},
            {0.0,    0.0156},
            {0.0,    0.0   },
            {0.0156, 0.0156},
            {0.2031, 0.1875},
            {0.5,    0.5   },
            {0.5,    0.5   },
            {0.5,    0.5   },
        },
    },
}

-- Build the slice container for a button.
-- For down/up: horizontal slices stacked top->bottom.
-- For left/right: vertical slices stacked left->right.
local NUM_SLICES = 16
local BUTTON_SIZE = 38

local function BuildSliceContainer(parent, slices, direction, originalSize) 
    local targetSize = (originalSize - 8) or BUTTON_SIZE 
    local isVertical = (direction == 'left' or direction == 'right') 
    local sliceSize  = targetSize / NUM_SLICES

    local container = CreateFrame('Frame', nil, parent)
    container:SetSize(targetSize, targetSize)
    container:SetPoint('CENTER', parent.icon, 'CENTER', 0, 0)
    container:SetFrameLevel(parent:GetFrameLevel() - 2)
    container._size = targetSize
    container._sliceTextures = {}
    container._isVertical = isVertical

    for i, slice in ipairs(slices) do
        local a, b = slice[1], slice[2]
        if not (a == 0.5 and b == 0.5) then
            local sf = CreateFrame('ScrollFrame', nil, container)
            local child = CreateFrame('Frame', nil, sf)
            sf:SetScrollChild(child)
            child:SetSize(targetSize, targetSize)
            child:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, 0)

            local tex = child:CreateTexture(nil, 'ARTWORK')
            tex:SetAllPoints(child)
            container._sliceTextures[i] = tex

            -- Cooldown swipe layer on top of icon
            local swipeTex = child:CreateTexture(nil, 'OVERLAY')
            swipeTex:SetAllPoints(child)
            swipeTex:SetBlendMode('BLEND')
            swipeTex:SetAlpha(0)
            swipeTex._sliceIndex = i
            container._swipeTextures = container._swipeTextures or {}
            container._swipeTextures[i] = swipeTex

            if not isVertical then
                local leftPx  = a * targetSize
                local rightPx = b * targetSize
                local sliceW  = targetSize - leftPx - rightPx
                if sliceW > 0 then
                    sf:SetHeight(sliceSize + 0.5)
                    sf:SetWidth(sliceW)
                    sf:SetPoint('TOPLEFT', container, 'TOPLEFT', leftPx, -(i-1) * sliceSize)
                    sf:SetHorizontalScroll(leftPx)
                    sf:SetVerticalScroll((i-1) * sliceSize)
                else
                    sf:Hide()
                end
            else
                local topPx    = a * targetSize
                local bottomPx = b * targetSize
                local sliceH   = targetSize - topPx - bottomPx
                if sliceH > 0 then
                    sf:SetWidth(sliceSize + 0.5)
                    sf:SetHeight(sliceH)
                    sf:SetPoint('TOPLEFT', container, 'TOPLEFT', (i-1) * sliceSize, -topPx)
                    sf:SetVerticalScroll(topPx)
                    sf:SetHorizontalScroll((i-1) * sliceSize)
                else
                    sf:Hide()
                end
            end
        end
    end
    return container
end

function SliceMask:OnIconUpdated(button)
    if button._slicePending then
        local size = button.icon:GetWidth()
        if not size or size == 0 then size = BUTTON_SIZE end
        local pending = button._slicePending
        button._slicePending = nil
        if button._sliceMaskContainer then
            button._sliceMaskContainer:Hide()
            button._sliceMaskContainer = nil
        end
        
        local container = BuildSliceContainer(button, pending.slices, pending.direction, size)
        button._sliceMaskContainer = container
    end
    if button._sliceMaskContainer then
        self:UpdateTexture(button)
    end
end



function SliceMask:StartCooldown(button, start, duration)
    local container = button._sliceMaskContainer
    if not container then return end

    for _, tex in pairs(container._swipeTextures or {}) do
        tex:SetTexture(0,0,0,1)
        tex:SetBlendMode('BLEND')
    end

    container._cooldownStart    = start
    container._cooldownDuration = duration
    container._button           = button

    container:SetScript('OnUpdate', function(self)
        local now       = GetTime()
        local remaining = (self._cooldownStart + self._cooldownDuration) - now

        if remaining <= 0 then
            self:SetScript('OnUpdate', nil)
            for _, tex in ipairs(self._swipeTextures or {}) do
                tex:SetAlpha(0)
            end
            
            local parentname = button:GetName() .. 'RCooldown'
            local rcool = _G[parentname]
            if rcool and rcool.endanimation then
                rcool.endanimation.Start()
            end
            return
        end

        CPAPI.CPCC:OnUpdate(button:GetName(), elapsed)

        local progress  = remaining / self._cooldownDuration
        local size      = self._size
        local sliceSize = size / NUM_SLICES
        local coveredPx = progress * size

        for _, tex in pairs(self._swipeTextures or {}) do
            local si = tex._sliceIndex
            local sliceStart = (si - 1) * sliceSize
            local sliceEnd   = si       * sliceSize
            if coveredPx >= sliceEnd then
                tex:SetAlpha(0.6)
            elseif coveredPx <= sliceStart then
                tex:SetAlpha(0)
            else
                tex:SetAlpha(0.6 * ((coveredPx - sliceStart) / sliceSize))
            end
        end
    end)
end

function SliceMask:StopCooldown(button)
    local container = button._sliceMaskContainer
    if not container then return end
    container:SetScript('OnUpdate', nil)
    container._cooldownStart    = nil
    container._cooldownDuration = nil
    for _, tex in pairs(self._swipeTextures or {}) do
        tex:SetAlpha(0)
    end
end

-- Apply slice-mask to a sub-button.
-- modifier: 'SHIFT-', 'CTRL-', 'CTRL-SHIFT-'
-- direction: 'down', 'up', 'left', 'right'
function SliceMask:Apply(button, modifier, direction)
    self:Remove(button)
    local modData = maskSlices[modifier]
    if not modData then return end
    local slices = modData[direction]
    if not slices then return end
    if not button.icon then return end
 
    button.icon:SetAlpha(0)
    button.Shadow:SetAlpha(0)

    button._slicePending = { slices = slices, direction = direction }  
end

function SliceMask:Remove(button)
    if button._sliceMaskContainer then
        button._sliceMaskContainer:Hide()
        button._sliceMaskContainer = nil
    end
    if button.icon then button.icon:SetAlpha(1) end
    if button.Shadow then button.Shadow:SetAlpha(1) end
end


function SliceMask:UpdateTexture(button)
    local container = button._sliceMaskContainer
    if not container then return end
    local texture = button.icon and button.icon:GetTexture()
    if not texture then return end
    for _, tex in pairs(container._sliceTextures) do
        if tex then tex:SetTexture(texture) end
    end
end