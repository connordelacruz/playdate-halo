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
-- States
-- (Common ones that can be used with implementation-specific states)
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Common constructor
-- --------------------------------------------------------------------------------
class('EntityState').extends('State')

function EntityState:init(entity)
    self.entity = entity
end

-- --------------------------------------------------------------------------------
-- Dummy Inactive State
-- (Placeholder, implemnting classes need not use this)
-- --------------------------------------------------------------------------------
class('EntityInactiveState', {
    key = 'inactive',
}).extends('EntityState')

-- --------------------------------------------------------------------------------
-- Death (play animation, remove sprite when it finishes)
-- --------------------------------------------------------------------------------
class('EntityDeathState', {
    key = 'death',
}).extends('EntityState')

-- Play death loop on enter
function EntityDeathState:enter()
    self.entity:playDeathAnimation()
end

-- Set animation frame on update. Force state exit when it completes.
function EntityDeathState:update()
    local isPlaying = self.entity:setDeathImage()
    if not isPlaying then
        self:exit()
    end
end

-- Remove entity sprite on exit.
function EntityDeathState:exit()
    self.entity:remove()
end

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
    -- Placeholder state stuff, implementing classes should override.
    stateClasses = {
        EntityInactiveState,
    },
    initialStateKey = EntityInactiveState.key,
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

-- TODO: Better abstraction:
-- TODO: All entities should have idleImages, walkingLoops, deathLoops, and defaultImage
-- TODO:    - Pretty much all of these are the same except for spritesheet filepath and start/end frames
-- TODO:    - delay should be possible to override, but default to 100 cuz that's what we use everywhere
-- TODO: If we abstract the above, then we can also abstract these:
-- TODO:    - setActiveImage()
-- TODO:    - playDeathAnimation()
-- TODO:    - setDeathImage()


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

-- TODO: play death animation, set image from that, indicate when animation finishes

-- Function to call that starts the death animation loop for facing direction.
-- Implementing classes must initialize their death animation in initImages().
-- It should be paused when initialized, and this function should unpause it.
function Entity:playDeathAnimation()
    DEBUG_MANAGER:vPrint(self.className .. ':playDeathAnimation() not implemented')
end

-- Set image from death animation. The above function should be called first to unpause it.
-- Return value should be true if the animation is still playing, false otherwise (i.e. :isValid())
function Entity:setDeathImage()
    self:setDefaultImage()
    return false
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

-- Transition to death state.
-- Emits 'death' event.
function Entity:kill()
    self:emitDeathEvent()
    self:setState(EntityDeathState.key)
end

-- --------------------------------------------------------------------------------
-- Weapons 
-- --------------------------------------------------------------------------------

-- Give the entity a new weapon.
function Entity:giveWeapon(weaponClass)
    self.weapon = weaponClass(self)
end

-- Toggle whether held weapon is firing or not.
-- flag is optional, default behavior is to toggle to the opposite of current weapon state.
-- Does nothing if no weapon held.
function Entity:toggleWeaponFire(flag)
    if self.weapon ~= nil then
        self.weapon:toggleFire(flag)
    end
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
-- States
-- --------------------------------------------------------------------------------

-- Mixin common Entity states automatically.
function Entity:initStatesAndSetInitial()
    self.stateClasses[#self.stateClasses+1] = EntityDeathState
    Entity.super.initStatesAndSetInitial(self)
end

-- --------------------------------------------------------------------------------
-- Events
-- --------------------------------------------------------------------------------

-- Broadcast Entity death event.
function Entity:emitDeathEvent()
    -- TODO: come up with some kinda way to store global constants for event names?
    EVENTS:emit('death', self)
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