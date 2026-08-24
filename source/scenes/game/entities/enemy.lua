local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Base Enemy Class
-- 
-- Defines common behavior and attributes for enemies
-- ================================================================================

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
    initialStateKey = kEnemyInactiveState.key,
    -- Entity attributes:
    isFriendly = false,
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 120,
}).extends('Entity')

function Enemy:init(x, y)
    -- Initialize entity instance variables
    Enemy.super.init(self, x, y)

    -- TODO: placeholder image and collisions

    -- Initialize states
    self:initStatesAndSetInitial()
    -- Move to initial position and add sprite
    self:moveTo(x, y)
    self:add()
end