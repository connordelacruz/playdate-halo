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
-- Common constructor for states that keep track of duration
-- --------------------------------------------------------------------------------
class('EnemyDurationState', {
    -- Fixed duration of state
    duration = 1000,
}).extends('EnemyState')

-- Helper to determine if duration has passed
function EnemyDurationState:hasDurationPassed()
    return pd.getCurrentTimeMilliseconds() >= self.enemy.lastStateChangeTimestamp + self.duration
end

-- --------------------------------------------------------------------------------
-- Common constructor for duration states that have a randomized duration value
-- --------------------------------------------------------------------------------
class('EnemyRandomDurationState', {
    -- For these, duration gets picked on enter()
    duration = -1,
    -- Min/max possible durations
    minDuration = 2000,
    maxDuration = 4000,
}).extends('EnemyDurationState')

function EnemyRandomDurationState:enter()
    EnemyRandomDurationState.super.enter(self)
    self:setDuration()
end

-- Set duration (ms) for the current state.
-- Parameter is optional, default behavior is to pick a random duration
-- between minDuration and maxDuration.
function EnemyRandomDurationState:setDuration(duration)
    if duration == nil then
        duration = math.random(self.minDuration, self.maxDuration)
    end
    self.duration = duration
end

-- --------------------------------------------------------------------------------
-- "Unaware" States (can't see player)
-- --------------------------------------------------------------------------------
class('EnemyUnawareState', {
    -- Min/max time (ms) before picking a new state (if applicable)
    minDuration = 2000,
    maxDuration = 4000,
}).extends('EnemyRandomDurationState')

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

-- --------------------------------------------------------------------------------
-- Idle
-- --------------------------------------------------------------------------------
class('EnemyIdleState', {
    key = 'idle',
    isMoving = false,
    faceAimingAngle = false,
    minDuration = 750,
    maxDuration = 1500,
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

-- --------------------------------------------------------------------------------
-- Move in towards player
-- --------------------------------------------------------------------------------
class('EnemyChaseState', {
    key = 'chase',
    isMoving = true,
    faceAimingAngle = false,
    -- Duration to continue chase to last known player location before forcing a state switch
    duration = 1000,
}).extends('EnemyDurationState')

function EnemyChaseState:enter()
    EnemyChaseState.super.enter(self)
    -- Get current player coordinates and move towards them
    self.enemy:setAngleTowardsPlayer()
end

function EnemyChaseState:update()
    -- If we are within firing range, shoot at the player
    if self.enemy:isWithinRangeOfPlayer() then
        self.enemy:setFiringState()
    -- If duration has not passed, keep moving on current trajectory
    elseif not self:hasDurationPassed() then
        self.enemy:handleMoveAndSetImage()
    -- If duration has passed and we haven't switched to shooting state,
    -- restart chase if player is visible, otherwise switch to unaware
    else
        self.enemy:setChaseOrUnawareState()
    end
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
    self.enemy:aimAtPlayer()
    self.enemy:updateDirection()
    self.enemy:toggleWeaponFire(true)
    self.enemy:incrementBurstCounter()
end

function EnemyFiringState:update()
    self.enemy:setIdleWalkingImage()
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
}).extends('EnemyDurationState')

function EnemyPauseFiringState:init(enemy)
    EnemyPauseFiringState.super.init(self,enemy)
    -- Pull fixed duration val from enemy attributes
    self.duration = self.enemy.pauseFiringDuration
end

function EnemyPauseFiringState:update()
    -- If duration has passed, decide which state we're switching to
    if self:hasDurationPassed() then
        -- If enemy has had the max number of consecutive fire/pause cycles,
        -- reset burst counter and switch to evade state
        if self.enemy:hasBurstLimitBeenReached() then
            self.enemy:resetBurstCounter()
            self.enemy:setEvadeState()
        else
            self.enemy:setStateBasedOnPlayerDistance()
        end
    end
end

-- --------------------------------------------------------------------------------
-- Move in the opposite direction of the player
-- --------------------------------------------------------------------------------
class('EnemyEvadeState', {
    key = 'evade',
    isMoving = true,
    faceAimingAngle = false,
    -- TODO: min/max duration? or keep fixed?
    duration = 2000,
}).extends('EnemyDurationState')

function EnemyEvadeState:enter()
    EnemyEvadeState.super.enter(self)
    self.enemy:setAngleAwayFromPlayer()
end

function EnemyEvadeState:update()
    self.enemy:handleMoveAndSetImage()
    if self:hasDurationPassed() then
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
        EnemyEvadeState,
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
    shotCountBeforePause = 3,
    -- How long to pause after firing shotCountBeforePause shots (ms)
    pauseFiringDuration = 750,
    -- Max number of consecutive fire/pause cycles before evading
    maxConsecutiveFireBursts = 3,
    -- False out event types that aren't necessary for enemies
    spawnEventType = false,
    damageReceivedEventType = false,
    healthChangeEventType = false,
    shieldChangeEventType = false,
    shieldLowEventType = false,
    shieldEmptyEventType = false,
    shieldRechargingEventType = false,
    shieldFullEventType = false,
    weaponPickupEventType = false,
}).extends('Entity')

function Enemy:init(x, y, player)
    -- Initialize entity instance variables, images, collide rect
    Enemy.super.init(self, x, y)
    -- Keep reference to player for enemy AI logic
    self.player = player
    -- Angle enemy is facing/walking
    self.angle = 0
    -- Angle to aim weapon at. Gets set in aimAtPlayer().
    -- calculateAimingAngle() returns this value.
    self.aimingAngle = 0
    -- Number of consecutive "burst fires".
    -- If enemy has cycled thru fire/pause for maxConsecutiveFireBursts times,
    -- switch to evade state (so it's not just nonstop fire)
    self.consecutiveFireBursts = 0

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

function Enemy:setEvadeState()
    self:setState(EnemyEvadeState.key)
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

-- Set chase state if player is visible, otherwise set unaware state.
-- Chase will switch to fire on update if player is within range.
function Enemy:setChaseOrUnawareState()
    if self:canSeePlayer() then
        self:setChaseState()
    else
        self:setUnawareState()
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
    local wasStateChanged = self:attemptToSetAwareState()
    if not wasStateChanged then
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
    self:setAngle(self:getAngleTowardsPlayer())
end

-- Set facing angle away from player's current location.
function Enemy:setAngleAwayFromPlayer()
    self:setAngle(self:getAngleAwayFromPlayer())
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
    -- TODO: maybe reduce this? Getting shot from off screen all the time isn't super fun
    return self:getDistanceFromPlayer() <= self.weapon:getRange()
end

-- --------------------------------------------------------------------------------
-- Aiming
-- --------------------------------------------------------------------------------

-- Return angle towards player.
function Enemy:getAngleTowardsPlayer()
    return getAngleBetweenPoints(self.x, self.y, self.player.x, self.player.y)
end

-- Returns the angle away from player (opposite of above)
function Enemy:getAngleAwayFromPlayer()
    return getAngleBetweenPoints(self.player.x, self.player.y, self.x, self.y)
end

-- Set self.aimingAngle to point at player.
function Enemy:aimAtPlayer()
    self.aimingAngle = self:getAngleTowardsPlayer()
end

-- Returns self.aimingAngle.
-- Call aimAtPlayer() before this to update aimingAngle.
function Enemy:calculateAimingAngle()
    -- Just return aiming angle instead of running expensive atan calc each shot.
    -- Also makes it less brutal since enemy isn't firing every shot with perfect accuracy.
    return self.aimingAngle
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

-- Increment consecutive fire burst counter
function Enemy:incrementBurstCounter()
    self.consecutiveFireBursts += 1
end

-- Reset consecutive fire burst counter
function Enemy:resetBurstCounter()
    self.consecutiveFireBursts = 0
end

-- Returns true if consecutiveFireBursts has hit the max
function Enemy:hasBurstLimitBeenReached()
    return self.consecutiveFireBursts >= self.maxConsecutiveFireBursts
end