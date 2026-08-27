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
class('EnemyState', {
    -- Min/max time (ms) before picking a new state (if applicable)
    minDuration = 3000,
    maxDuration = 5000,
    -- Keys of states this one can randomly pick from when duration is up
    nextStateOptionKeys = {},
}).extends('State')

function EnemyState:init(enemy)
    self.enemy = enemy
    -- How long to stay in this state before picking a next one.
    -- Set on enter().
    self.duration = -1
end

-- Set duration (ms) for current state.
-- Parameter is optional, default behavior is to pick a random value between min and max.
function EnemyState:setDuration(duration)
    if duration == nil then
        duration = math.random(self.minDuration, self.maxDuration)
    end
    self.duration = duration
end

-- Returns true if duration has passed since state change.
function EnemyState:hasDurationPassed()
    return pd.getCurrentTimeMilliseconds() >= self.enemy.lastStateChangeTimestamp + self.duration
end

-- Returns key of next state, randomly selected from nextStateOptionKeys.
-- (Defaults to this state's key if next state is empty)
function EnemyState:pickNextState()
    -- Default to current state
    local nextStateKey = self.key
    if #self.nextStateOptionKeys > 0 then
        nextStateKey = self.nextStateOptionKeys[math.random(1, #self.nextStateOptionKeys)]
    end
    return nextStateKey
end

-- Checks if duration has passed, then picks a new state and transitions to it.
function EnemyState:changeStateIfPastDuration()
    if self:hasDurationPassed() then
        local nextStateKey = self:pickNextState()
        self.enemy:setState(nextStateKey)
    end
end

-- Common enter(), sets duration.
function EnemyState:enter()
    self:setDuration()
end

-- Common update(), checks if duration has passed and transitions state accordingly.
function EnemyState:update()
    self:changeStateIfPastDuration()
end

-- --------------------------------------------------------------------------------
-- State Key Constants
-- (Defined before classes so they can be used in nextStateOptionKeys)
-- --------------------------------------------------------------------------------
local kEnemyIdleState <const> = 'idle'
local kEnemyPatrolState <const> = 'patrol'
local kEnemyFiringState <const> = 'firing'

-- --------------------------------------------------------------------------------
-- Idle
-- --------------------------------------------------------------------------------
class('EnemyIdleState', {
    key = kEnemyIdleState,
    nextStateOptionKeys = {
        kEnemyPatrolState,
    },
}).extends('EnemyState')

-- --------------------------------------------------------------------------------
-- Patrol: Walk aimlessly
-- --------------------------------------------------------------------------------
class('EnemyPatrolState', {
    key = kEnemyPatrolState,
    nextStateOptionKeys = {
        kEnemyIdleState,
        kEnemyPatrolState,
    },
}).extends('EnemyState')

-- On enter: pick random angle and set is moving
function EnemyPatrolState:enter()
    EnemyPatrolState.super.enter(self)

    self.enemy.isMoving = true
    self.enemy:setRandomAngle()
end

-- Update: move sprite, update image
function EnemyPatrolState:update()
    self.enemy:handleMove()
    self.enemy:setActiveImage()

    self:changeStateIfPastDuration()
end

-- Exit: set not moving, set active image one last time.
function EnemyPatrolState:exit()
    self.enemy.isMoving = false
    self.enemy:setActiveImage()
end

-- --------------------------------------------------------------------------------
-- Firing at Player
-- --------------------------------------------------------------------------------
class('EnemyFiringState', {
    key = kEnemyFiringState,
    minDuration = 2000,
    maxDuration = 4000,
    nextStateOptionKeys = {
        -- TODO: refine behavior
        kEnemyFiringState,
    },
}).extends('EnemyState')

function EnemyFiringState:enter()
    EnemyFiringState.super.enter(self)

    self.enemy.isMoving = false
    -- TODO: random angle for testing
    self.enemy:setRandomAngle()
    self.enemy:toggleWeaponFire(true)
end

-- TODO: aiming and stuff, set active image
function EnemyFiringState:update()
    self.enemy:setActiveImage()

    self:changeStateIfPastDuration()
end

-- --------------------------------------------------------------------------------
-- TODO: common enemy states:
-- idle, searching, chasing, firing, retreating, dying
-- --------------------------------------------------------------------------------

-- ================================================================================
-- Enemy Entity Base Class
-- ================================================================================
class('Enemy', {
    stateClasses = {
        EnemyIdleState,
        EnemyPatrolState,
        EnemyFiringState,
    },
    -- initialStateKey = EnemyIdleState.key,
    -- TODO: TESTING WEAPONS
    initialStateKey = EnemyFiringState.key,
    -- Entity attributes:
    isFriendly = false,
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 50,
}).extends('Entity')

-- TODO: enemies should have reference to the player for their AI
function Enemy:init(x, y)
    -- Initialize entity instance variables, images, collide rect
    Enemy.super.init(self, x, y)
    -- Angle enemy is facing/walking
    self.angle = 0
    -- Keep track of last state change
    self.lastStateChangeTimestamp = pd.getCurrentTimeMilliseconds()

    -- Collisions
    self:setTag(TAGS.enemy)

    -- Initialize states
    self:initStatesAndSetInitial()
end

-- --------------------------------------------------------------------------------
-- States
-- --------------------------------------------------------------------------------

-- Override setState() to snap the timestamp when state was changed.
function Enemy:setState(newState)
    self.lastStateChangeTimestamp = pd.getCurrentTimeMilliseconds()
    Enemy.super.setState(self, newState)
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

-- Set facing angle. Updates direction too.
function Enemy:setAngle(angle)
    self.angle = self:constrainAngle(angle)
    self:updateDirectionFromAimingAngle()
end

-- Pick a random angle and set facing angle.
function Enemy:setRandomAngle()
    self:setAngle(math.random(360))
end

-- Based on entity speed and facing angle, return target coordinates for moving this frame.
function Enemy:getTargetPosition()
    local rad = math.rad(self.angle)
    local distance = self.speed * DELTA_TIME
    local newX = self.x + (distance * math.cos(rad))
    local newY = self.y + (distance * math.sin(rad))
    return newX, newY
end

-- Move enemy in facing direction.
-- NOTE: does not set isMoving, that should be handled by states.
function Enemy:handleMove()
    local _, _, collisions, _ = self:moveWithCollisions(self:getTargetPosition())
    -- TODO: collisions!
    -- self:handleCollisions(collisions)
end

-- --------------------------------------------------------------------------------
-- Aiming
-- --------------------------------------------------------------------------------

-- Default aiming angle to be the same as facing angle.
-- TODO: spread so aiming isn't too perfect?
function Enemy:calculateAimingAngle()
    return self.angle
end