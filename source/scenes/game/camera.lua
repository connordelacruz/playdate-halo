local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Camera object. Follows sprite it's attached to.
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- Lerp smooth speed (TODO: gotta be a better way to describe this)
local kLerpSmoothSpeed <const> = 0.06

-- ================================================================================
-- Camera "sprite" class
-- ================================================================================
class('Camera').extends(gfx.sprite)

function Camera:init(target)
    -- Sprite camera is attached to
    self.target = target
    -- Lock onto target if set
    self:setInitialDrawOffset()

    self:add()
end

-- Attach camera to a sprite
function Camera:attachTo(sprite)
    self.target = sprite
end

-- Returns targetOffsetX, targetOffsetY.
-- If self.target is not set, returns 0,0
function Camera:getTargetOffset()
    local targetOffsetX, targetOffsetY = 0, 0
    if self.target ~= nil then
        targetOffsetX = -(self.target.x - SCREEN_CENTER_X)
        targetOffsetY = -(self.target.y - SCREEN_CENTER_Y)
    end
    return targetOffsetX, targetOffsetY
end

-- Set initial draw offset (no smoothing)
function Camera:setInitialDrawOffset()
    gfx.setDrawOffset(self:getTargetOffset())
end

-- Update draw offset to center on target.
-- Will reset offset if no target is set.
function Camera:updateDrawOffset()
    local targetOffsetX, targetOffsetY = self:getTargetOffset()
    gfx.setDrawOffset(self:smoothOffset(targetOffsetX, targetOffsetY))
end

-- Lerp to target coordinates for smooth movement.
function Camera:smoothOffset(targetOffsetX, targetOffsetY)
    -- Get current offset, then lerp
    local currentOffsetX, currentOffsetY = gfx.getDrawOffset()
    return pd.math.lerp(currentOffsetX, targetOffsetX, kLerpSmoothSpeed), pd.math.lerp(currentOffsetY, targetOffsetY, kLerpSmoothSpeed)
end

-- Reset offset when camera is removed.
function Camera:remove()
    gfx.setDrawOffset(0, 0)
    Camera.super.remove(self)
end

-- Update.
function Camera:update()
    self:updateDrawOffset()
end