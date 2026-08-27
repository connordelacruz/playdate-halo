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
-- Idle
-- --------------------------------------------------------------------------------
class('EnemyIdleState', {
    key = 'idle',
}).extends('EnemyState')

-- --------------------------------------------------------------------------------
-- Patrol: Walk aimlessly
-- --------------------------------------------------------------------------------
class('EnemyPatrolState', {
    key = 'patrol',
}).extends('EnemyState')

-- On enter: pick random angle and set is moving
function EnemyPatrolState:enter()
    self.enemy.isMoving = true
    self.enemy:setRandomAngle()
end

-- Update: move sprite, update image
function EnemyPatrolState:update()
    self.enemy:handleMove()
    self.enemy:setActiveImage()
    -- TODO: check duration, switch state if time is up
end

-- Exit: set not moving, set active image one last time.
function EnemyPatrolState:exit()
    self.enemy.isMoving = false
    self.enemy:setActiveImage()
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
    },
    -- initialStateKey = EnemyIdleState.key,
    -- TODO: TESTING:
    initialStateKey = EnemyPatrolState.key,
    -- Entity attributes:
    isFriendly = false,
    baseHealth = 1,
    baseShields = 0,
    baseSpeed = 50,
}).extends('Entity')

-- TODO: enemies should have reference to the player for their AI
function Enemy:init(x, y)
    -- Initialize entity instance variables
    Enemy.super.init(self, x, y)
    -- Angle enemy is facing/walking
    self.angle = 0
    -- Keep track of last state change
    self.lastStateChangeTimestamp = pd.getCurrentTimeMilliseconds()

    -- TODO: we gotta figure out what stays here as common and what gets extracted to subclasses

    -- Placeholder image
    -- TODO: very messy, call initImages() instead of setting here
    self.defaultImage = self:createPlaceholderImage(kEnemyWidth, kEnemyHeight)
    self:setImage(self.defaultImage)

    -- Collisions
    -- TODO: collide rect should be set after implementing class sets image. tag can be set here tho
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.enemy)

    -- Initialize states
    -- TODO: REMOVE??
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

-- Set image for an active state (walking or idle).
-- Default just always returns placeholder.
function Enemy:setActiveImage()
    return self.defaultImage
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