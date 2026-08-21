local pd <const> = playdate
local gfx <const> = pd.graphics

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

-- TODO: update logic

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