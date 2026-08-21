local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Player Attributes
-- --------------------------------------------------------------------------------
-- Base movement speed (px / sec)
local kPlayerSpeed <const> = 180

-- ================================================================================
-- Player States
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Common Constructor
-- --------------------------------------------------------------------------------
class('PlayerState').extends('State')

function PlayerState:init(player)
    self.player = player
end

-- --------------------------------------------------------------------------------
-- Active
-- --------------------------------------------------------------------------------
local kActiveState <const> = 'active'
class('PlayerActiveState', {
    key = kActiveState,
}).extends('PlayerState')

function PlayerActiveState:update()
    self.player:handleMovement()
end

-- ================================================================================
-- Player Sprite
-- ================================================================================
class('Player', {
    stateClasses = {
        PlayerActiveState,
    },
    initialStateKey = PlayerActiveState.key
}).extends('FSMSprite')

function Player:init(x, y)
    -- Attributes
    self.speed = kPlayerSpeed

    -- TODO: real sprites
    self:setImage(self:createPlaceholderImage(20, 32))
    self:setCollideRect(0, 0, self:getSize())

    -- Initialize states
    self:initStatesAndSetInitial()
    -- Move to initial position and add sprite
    self:moveTo(x, y)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

-- DEBUG: Generate placeholder image
function Player:createPlaceholderImage(w, h)
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.fillRoundRect(0, 0, w, h, 4)
    gfx.popContext()
    return image
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

-- Check for D-Pad inputs and handle player movement
function Player:handleMovement()
    local current, _, _ = pd.getButtonState()
    local dx = 0
    local dy = 0
    -- Determine direction player should move
    if (current & pd.kButtonUp) > 0 then
        dy -= 1
    end
    if (current & pd.kButtonDown) > 0 then
        dy += 1
    end
    if (current & pd.kButtonLeft) > 0 then
        dx -= 1
    end
    if (current & pd.kButtonRight) > 0 then
        dx += 1
    end

    -- Handle movement
    if dx ~= 0 or dy ~= 0 then
        local distance = self.speed * DELTA_TIME
        -- Divide distance by sqrt 2 for diagonal movement
        if dx ~= 0 and dy ~= 0 then
            distance = distance / math.sqrt(2)
        end
        -- Calculate desired position and move with collisions
        local targetX = self.x + dx * distance
        local targetY = self.y + dy * distance
        self:moveWithCollisions(targetX, targetY)
    end
end