local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Base Enemy Class
-- 
-- Defines common behavior and attributes for enemies
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- Placeholder image size
local kEnemyWidth <const> = 16
local kEnemyHeight <const> = 20

-- ================================================================================
-- Basic Enemy States
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Common Constructor
-- --------------------------------------------------------------------------------
class('EnemyState').extends('State')

function EnemyState:init(enemy)
    self.enemy = enemy
end

-- --------------------------------------------------------------------------------
-- Inactive State
-- --------------------------------------------------------------------------------
local kEnemyInactiveState <const> = 'inactive'
class('EnemyInactiveState', {
    key = kEnemyInactiveState,
}).extends('EnemyState')

-- ================================================================================
-- Enemy Entity Base Class
-- ================================================================================
class('Enemy', {
    stateClasses = {
        EnemyInactiveState,
    },
    initialStateKey = EnemyInactiveState.key,
    -- Entity attributes:
    isFriendly = false,
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 120,
}).extends('Entity')

function Enemy:init(x, y)
    -- Initialize entity instance variables
    Enemy.super.init(self, x, y)

    -- Placeholder image
    self:setImage(self:createPlaceholderImage(kEnemyWidth, kEnemyHeight))

    -- Collisions
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.enemy)

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
function Enemy:createPlaceholderImage(w, h)
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setLineWidth(2)
        gfx.setStrokeLocation(gfx.kStrokeInside)
        gfx.drawRoundRect(0, 0, w, h, 4)
    gfx.popContext()
    return image
end