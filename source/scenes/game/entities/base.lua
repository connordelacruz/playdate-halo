local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Constants
-- ================================================================================
-- Placeholder image
local kPlaceholderImage <const> = gfx.image.new(16, 20)
gfx.pushContext(kPlaceholderImage)
    gfx.setLineWidth(2)
    gfx.setStrokeLocation(gfx.kStrokeInside)
    gfx.drawRoundRect(0, 0, kPlaceholderImage.width, kPlaceholderImage.height, 4)
gfx.popContext()

-- ================================================================================
-- Base Entity Class
-- 
-- Shared behaviors between player, enemies, etc
-- ================================================================================
class('Entity', {
    -- Whether this is friendly or an enemy
    isFriendly = false,
    -- Health and shield values base values
    baseHealth = 1,
    baseShields = 0,
    -- Base movement speed (px / sec)
    baseSpeed = 140,
}).extends('FSMSprite')

-- TODO: UPDATE DOCS
-- Base constructor. Initializes instance variables and not much else.
-- Implementing classes should call <Class>.super.init(self, x, y) to initialize these,
-- then handle everything else, including adding to sprite list.
function Entity:init(x, y)
    -- Held Weapon
    self.weapon = nil
    -- Current health and shields
    self.health = self.baseHealth
    self.shields = self.baseShields
    -- Movement speed
    self.speed = self.baseSpeed
    -- Whether or not the entity is currently moving
    self.isMoving = false
    -- Facing direction
    self.direction = DIRECTION_RIGHT

    -- Initialize images and animations, as well as default image.
    self:initImages()
    -- Implementing classes should set self.defaultImage in initImages().
    -- But if they don't, set a graceful default here.
    if self.defaultImage == nil then
        self.defaultImage = kPlaceholderImage
    end
    -- Set default image.
    self:setDefaultImage()

    -- Set collide rect. Implementing classes should handle collision tags.
    self:setCollideRect(0, 0, self:getSize())

    -- Z-index
    self:setZIndex(Z_INDEX.entity)

    -- Move to initial position and add sprite
    self:moveTo(x, y)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Images
-- --------------------------------------------------------------------------------

-- Initialize images and animations.
-- Implementations should set self.defaultImage!
function Entity:initImages()
    self.defaultImage = kPlaceholderImage
end

-- Set image to default.
-- self.defaultImage MUST be set (duh).
function Entity:setDefaultImage()
    self:setImage(self.defaultImage)
end

-- Set image for "active" states (i.e. Entity is alive, walking, idling, etc).
-- Put logic in here for animating walking, walking vs idling, facing direction, etc.
function Entity:setActiveImage()
    self:setDefaultImage()
end

-- --------------------------------------------------------------------------------
-- Collisions
-- --------------------------------------------------------------------------------

-- TODO: Allow ally entities to overlap?
function Entity:collisionResponse(other)
    -- Default to freeze
    local response = gfx.sprite.kCollisionTypeFreeze
    -- Projectiles should overlap w/ entities
    if other:getTag() == TAGS.projectile then
        response = gfx.sprite.kCollisionTypeOverlap
    end
    return response
end

-- --------------------------------------------------------------------------------
-- Health, Shields, and Dying
-- --------------------------------------------------------------------------------

-- Apply damage to this entity.
function Entity:applyDamage(damage)
    -- TODO: implement shields!
    self.health -= damage
    -- If damage was fatal, call kill()
    if self.health <= 0 then
        self:kill()
    end
end

-- Kill this entity.
function Entity:kill()
    -- TODO: emit event so enemy and player deaths can be handled!
    self:remove()
end

-- --------------------------------------------------------------------------------
-- Weapons 
-- --------------------------------------------------------------------------------

-- Give the entity a new weapon.
function Entity:giveWeapon(weaponClass)
    self.weapon = weaponClass(self)
end

-- --------------------------------------------------------------------------------
-- Aiming and Direction
-- --------------------------------------------------------------------------------

-- Constrain angle to 0 - 360 degrees
function Entity:constrainAngle(angle)
    -- Modulo handles negative angles exactly how we need them! I always forget that.
    return angle % 360
end

-- Returns the angle (in degrees) entity is aiming at.
function Entity:calculateAimingAngle()
    -- TODO: log if not implemented
    -- Return dummy value
    return 0
end

-- Get coordinates of origin to spawn projectiles from as well as the angle to fire projectiles at.
-- Returns 3 values: originX, originY, and angle (degrees)
function Entity:getOriginAndAngle()
    return self.x, self.y, self:constrainAngle(self:calculateAimingAngle())
end

-- Determine whether angle is facing left or right. For sprite images.
-- TODO: does this apply when not crankin it?:
-- Angles relative to display:
--       270
--        |
-- 180 ---+--- 0
--        |
--       90
function Entity:getDirectionFromAngle(angle)
    -- Constrain to 0 - 360
    angle = self:constrainAngle(angle)
    -- Defaulting to right (when angle is between 0 (inclusive) and 90 (exclusive), or 270 (inclusive) and 360 (exclusive))
    local direction = DIRECTION_RIGHT
    -- If angle is between 90 (inclusive) and 270 (exclusive), we're facing left
    if angle >= 90 and angle < 270 then
        direction = DIRECTION_LEFT
    end
    return direction
end

-- Shorthand to get direction from self:calculateAimingAngle() and set self.direction to the return value.
-- Should be called anywhere aiming angle gets changed.
function Entity:updateDirectionFromAimingAngle()
    self.direction = self:getDirectionFromAngle(self:calculateAimingAngle())
end

-- --------------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------------

-- Remove weapon (if one is held) when removing an Entity.
function Entity:remove()
    if self.weapon ~= nil then
        self.weapon:remove()
    end
    Entity.super.remove(self)
end