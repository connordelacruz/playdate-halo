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
    minDuration = 2000,
    maxDuration = 4000,
    -- TODO: boolean to disable duration
    -- Keys of states this one can randomly pick from when duration is up
    nextStateOptionKeys = {},
    -- Attributes to set on enemy based on what we want with this state
    isMoving = false,
    faceAimingAngle = false,
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

-- Common enter(), sets duration + state-based enemy attributes.
function EnemyState:enter()
    self:setDuration()
    self.enemy.isMoving = self.isMoving
    self.enemy.faceAimingAngle = self.faceAimingAngle
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
    minDuration = 500,
    isMoving = false,
    faceAimingAngle = false,
}).extends('EnemyState')

-- --------------------------------------------------------------------------------
-- Patrol: Walk aimlessly
-- --------------------------------------------------------------------------------
class('EnemyPatrolState', {
    key = kEnemyPatrolState,
    nextStateOptionKeys = {
        kEnemyIdleState,
        -- kEnemyPatrolState,
        kEnemyFiringState,
    },
    isMoving = true,
    faceAimingAngle = false,
}).extends('EnemyState')

-- On enter: pick random angle and set is moving
function EnemyPatrolState:enter()
    EnemyPatrolState.super.enter(self)
    self.enemy:setRandomAngle()
end

-- Update: move sprite, update image
function EnemyPatrolState:update()
    self.enemy:handleMove()
    self.enemy:setIdleWalkingImage()

    self:changeStateIfPastDuration()
end

-- Exit: set not moving, set active image one last time.
function EnemyPatrolState:exit()
    self.enemy.isMoving = false
    self.enemy:setIdleWalkingImage()
end

-- --------------------------------------------------------------------------------
-- Firing at Player
-- --------------------------------------------------------------------------------
class('EnemyFiringState', {
    key = kEnemyFiringState,
    minDuration = 1000,
    maxDuration = 2500,
    nextStateOptionKeys = {
        -- kEnemyFiringState,
        kEnemyPatrolState,
    },
    isMoving = false,
    faceAimingAngle = true,
}).extends('EnemyState')

function EnemyFiringState:enter()
    EnemyFiringState.super.enter(self)
    self.enemy:toggleWeaponFire(true)
end

function EnemyFiringState:update()
    self.enemy:setIdleWalkingImage()
    self.enemy:updateDirection()

    self:changeStateIfPastDuration()
end

function EnemyFiringState:exit()
    self.enemy:toggleWeaponFire(false)
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
    initialStateKey = EnemyPatrolState.key,
    -- Entity attributes:
    isFriendly = false,
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 50,
    points = 100,
}).extends('Entity')

function Enemy:init(x, y, player)
    -- Initialize entity instance variables, images, collide rect
    Enemy.super.init(self, x, y)
    -- Keep reference to player for enemy AI logic
    self.player = player
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
    self:updateDirection()
end

-- Pick a random angle and set facing angle.
function Enemy:setRandomAngle()
    self:setAngle(math.random(360))
end

-- Flip x direction.
function Enemy:flipX()
    self:setAngle(180 - self.angle)
end

-- Flip y direction.
function Enemy:flipY()
    self:setAngle(360 - self.angle)
end

-- Based on entity speed and facing angle, return target coordinates for moving this frame.
function Enemy:getTargetPosition()
    local rad = math.rad(self.angle)
    local distance = self.speed * DELTA_TIME
    local newX = self.x + (distance * math.cos(rad))
    local newY = self.y + (distance * math.sin(rad))
    return newX, newY
end

-- Move enemy in facing direction. Handle collisions.
-- NOTE: does not set isMoving, that should be handled by states.
function Enemy:handleMove()
    local _, _, collisions, _ = self:moveWithCollisions(self:getTargetPosition())
    self:handleCollisions(collisions)
end

-- Turn around if we hit a wall or other obstacle while moving.
function Enemy:handleCollisions(collisions)
    for i=1,#collisions do
        local collision = collisions[i]
        -- If we hit something we can't walk through, we need to turn around.
        if collision.type ~= gfx.sprite.kCollisionTypeOverlap then
            -- Determine if we hit a vertical or horizontal obstacle.
            if collision.normal.x ~= 0 then
                self:flipX()
            end
            if collision.normal.y ~= 0 then
                self:flipY()
            end
        end
    end
end

-- --------------------------------------------------------------------------------
-- Aiming
-- --------------------------------------------------------------------------------

-- Aim at player.
function Enemy:calculateAimingAngle()
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    return math.deg(math.atan(dy, dx))
end