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
-- TODO: min/max duration may only really apply to idle/patrol?
-- TODO: don't bother with next state stuff, simplify it and clean up code
-- TODO: setIdleWalkingImage() in this class?

class('EnemyState', {
    -- TODO: MOVE TO UNAWARE:
    -- Min/max time (ms) before picking a new state (if applicable)
    minDuration = 2000,
    maxDuration = 4000,
    -- TODO: boolean to disable duration
    -- Keys of states this one can randomly pick from when duration is up
    nextStateOptionKeys = {},
    -- TODO: END MOVE

    -- Attributes to set on enemy based on what we want with this state
    isMoving = false,
    faceAimingAngle = false,
}).extends('State')

function EnemyState:init(enemy)
    self.enemy = enemy
end

-- Common enter(), sets state-based enemy attributes.
-- Also calls setIdleWalkingImage() to update image on enter.
function EnemyState:enter()
    self.enemy.isMoving = self.isMoving
    self.enemy.faceAimingAngle = self.faceAimingAngle
    self.enemy:setIdleWalkingImage()
end

-- --------------------------------------------------------------------------------
-- "Unaware" States (can't see player)
-- --------------------------------------------------------------------------------
class('EnemyUnawareState', {
    -- Min/max time (ms) before picking a new state (if applicable)
    minDuration = 2000,
    maxDuration = 4000,
}).extends('EnemyState')

function EnemyUnawareState:init(enemy)
    EnemyUnawareState.super.init(self, enemy)
    -- How long to stay in this unaware state before picking another one.
    self.duration = -1
end

-- Call parent :enter() and then set duration
function EnemyUnawareState:enter()
    EnemyUnawareState.super.enter(self)
    self:setDuration()
end

-- Common update. Call AFTER doing implementation-specific updates.
-- Will check enemy awareness of player and switch to an appropriate aware state based on their distance.
-- If player is not close enough to switch to an aware state, and duration passes, switch to another unaware state.
function EnemyUnawareState:update()
    -- Check player distance, switch to an appropriate aware state if they're close enough
    local stateWasChanged = self.enemy:attemptToSetAwareState()
    -- If we're still in an unaware state, and duration is up, switch to another unaware state
    if not stateWasChanged and self:hasDurationPassed() then
        self.enemy:setUnawareState()
    end
end

-- Set duration (ms) for current state.
-- Parameter is optional, default behavior is to pick a random value between min and max.
function EnemyUnawareState:setDuration(duration)
    if duration == nil then
        duration = math.random(self.minDuration, self.maxDuration)
    end
    self.duration = duration
end

-- Returns true if duration has passed since state change.
function EnemyUnawareState:hasDurationPassed()
    return pd.getCurrentTimeMilliseconds() >= self.enemy.lastStateChangeTimestamp + self.duration
end

-- --------------------------------------------------------------------------------
-- Idle
-- --------------------------------------------------------------------------------
class('EnemyIdleState', {
    key = 'idle',
    isMoving = false,
    faceAimingAngle = false,
    minDuration = 500,
    maxDuration = 1000,
}).extends('EnemyUnawareState')

-- --------------------------------------------------------------------------------
-- Patrol: Walk aimlessly
-- --------------------------------------------------------------------------------
class('EnemyPatrolState', {
    key = 'patrol',
    isMoving = true,
    faceAimingAngle = false,
    minDuration = 2000,
    maxDuration = 4000,
}).extends('EnemyUnawareState')

-- On enter: pick random angle and set is moving
function EnemyPatrolState:enter()
    self.enemy:setRandomAngle()
    EnemyPatrolState.super.enter(self)
end

-- Update: move sprite, update image
function EnemyPatrolState:update()
    self.enemy:handleMoveAndSetImage()
    EnemyPatrolState.super.update(self)
end

-- Exit: set not moving, set active image one last time.
-- TODO: remove, EnemyState:enter() now sets initial image
-- function EnemyPatrolState:exit()
--     self.enemy.isMoving = false
--     self.enemy:setIdleWalkingImage()
-- end

-- --------------------------------------------------------------------------------
-- Move in towards player
-- --------------------------------------------------------------------------------
class('EnemyChaseState', {
    key = 'chase',
    isMoving = true,
    faceAimingAngle = false,
}).extends('EnemyState')

function EnemyChaseState:update()
    if self.enemy:isWithinRangeOfPlayer() then
        self.enemy:setFiringState()
    elseif self.enemy:canSeePlayer() then
        self.enemy:setAngleTowardsPlayer()
        self.enemy:handleMove()
        self.enemy:setIdleWalkingImage()
    else
        self.enemy:setUnawareState()
    end
end

-- Exit: set not moving, set active image one last time.
function EnemyChaseState:exit()
    -- TODO: can we abstract this? it's reused from patrol
    self.enemy.isMoving = false
    self.enemy:setIdleWalkingImage()
end

-- --------------------------------------------------------------------------------
-- Firing at Player
-- --------------------------------------------------------------------------------
class('EnemyFiringState', {
    key = 'firing',
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

    -- Pause firing if we've hit the shot count limit
    if self.enemy:shouldPauseFire() then
        self.enemy:setPauseFiringState()
    end
end

function EnemyFiringState:exit()
    self.enemy:toggleWeaponFire(false)
end

-- --------------------------------------------------------------------------------
-- Pause between firing bursts at player
-- --------------------------------------------------------------------------------
class('EnemyPauseFiringState', {
    key = 'pause-firing',
    isMoving = false,
    faceAimingAngle = true,
}).extends('EnemyState')

function EnemyPauseFiringState:update()
    -- If duration has passed, decide which state we're switching to
    if pd.getCurrentTimeMilliseconds() >= self.enemy.lastStateChangeTimestamp + self.enemy.pauseFiringDuration then
        self.enemy:setStateBasedOnPlayerDistance()
    end
end

-- ================================================================================
-- Enemy Entity Base Class
-- ================================================================================
class('Enemy', {
    stateClasses = {
        EnemyIdleState,
        EnemyPatrolState,
        EnemyChaseState,
        EnemyFiringState,
        EnemyPauseFiringState,
    },
    initialStateKey = EnemyPatrolState.key,
    -- Entity attributes:
    isFriendly = false,
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 50,
    points = 100,
    -- Distance that enemy becomes aware of player
    visionDistance = SCREEN_WIDTH // 2,
    -- Number of consecutive this enemy fires in the firing state before pausing
    shotCountBeforePause = 4,
    -- How long to pause after firing shotCountBeforePause shots (ms)
    pauseFiringDuration = 500,
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

function Enemy:setIdleState()
    self:setState(EnemyIdleState.key)
end

function Enemy:setPatrolState()
    self:setState(EnemyPatrolState.key)
end

function Enemy:setChaseState()
    self:setState(EnemyChaseState.key)
end

function Enemy:setFiringState()
    self:setState(EnemyFiringState.key)
end

function Enemy:setPauseFiringState()
    self:setState(EnemyPauseFiringState.key)
end

-- Randomly pick an "unaware" state
function Enemy:setUnawareState()
    local randy = math.random(0, 1)
    if randy > 0 then
        self:setPatrolState()
    else
        self:setIdleState()
    end
end

-- Set "aware" state based on player distance.
-- If player is within range, switch to firing state.
-- If player is within vision distance, switch to chase state.
-- If player is too far away, do nothing.
-- Returns true if state was switched, false otherwise.
function Enemy:attemptToSetAwareState()
    local wasStateChanged = true
    if self:isWithinRangeOfPlayer() then
        self:setFiringState()
    elseif self:canSeePlayer() then
        self:setChaseState()
    else
        wasStateChanged = false
    end
    return wasStateChanged
end

-- Set state based on player distance.
-- If player is within firing range, switch to firing state.
-- If player is within vision distance, switch to chase state.
-- If player is too far away, switch to an unaware state.
function Enemy:setStateBasedOnPlayerDistance()
    -- TODO: leverage above function?
    if self:isWithinRangeOfPlayer() then
        self:setFiringState()
    elseif self:canSeePlayer() then
        self:setChaseState()
    else
        self:setUnawareState()
    end
end

-- --------------------------------------------------------------------------------
-- Facing Angle
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

-- Set facing angle towards player's current position.
function Enemy:setAngleTowardsPlayer()
    self:setAngle(self:calculateAimingAngle())
end

-- Flip x direction.
function Enemy:flipX()
    self:setAngle(180 - self.angle)
end

-- Flip y direction.
function Enemy:flipY()
    self:setAngle(360 - self.angle)
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

-- Move enemy in facing direction. Handle collisions.
-- NOTE: does not set isMoving, that should be handled by states.
function Enemy:handleMove()
    local _, _, collisions, _ = self:moveWithCollisions(self:getTargetPosition())
    self:handleCollisions(collisions)
end

-- Shorthand to call handleMove() and then setIdleWalkingImage()
function Enemy:handleMoveAndSetImage()
    self:handleMove()
    self:setIdleWalkingImage()
end

-- Based on entity speed and facing angle, return target coordinates for moving this frame.
function Enemy:getTargetPosition()
    local rad = math.rad(self.angle)
    local distance = self.speed * DELTA_TIME
    local newX = self.x + (distance * math.cos(rad))
    local newY = self.y + (distance * math.sin(rad))
    return newX, newY
end

-- --------------------------------------------------------------------------------
-- Collisions
-- --------------------------------------------------------------------------------

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
-- Player Distance/Awareness
-- --------------------------------------------------------------------------------

-- Returns the distance between this enemy and the player
function Enemy:getDistanceFromPlayer()
    return pd.geometry.distanceToPoint(self.x, self.y, self.player.x, self.player.y)
end

-- Returns true if the distance to the player is <= the distance this enemy becomes aware of them
function Enemy:canSeePlayer()
    return self:getDistanceFromPlayer() <= self.visionDistance
end

-- Returns true if player is within firing range
function Enemy:isWithinRangeOfPlayer()
    -- No weapon = no range
    if self.weapon == nil then
        return false
    end
    return self:getDistanceFromPlayer() <= self.weapon:getRange()
end

-- --------------------------------------------------------------------------------
-- Aiming
-- --------------------------------------------------------------------------------

-- Aim at player.
-- Also used to move towards player.
function Enemy:calculateAimingAngle()
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    return math.deg(math.atan(dy, dx))
end

-- --------------------------------------------------------------------------------
-- Firing
-- --------------------------------------------------------------------------------

-- Returns true if weapon's consecutive shot count is at or above shotCountBeforePause.
-- Always returns true if enemy has no weapon (which probably should never be the case).
function Enemy:shouldPauseFire()
    if self.weapon == nil then
        return true
    end
    return self.weapon:getShotCount() >= self.shotCountBeforePause
end