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
    -- Point value if player kills an unfriendly entity
    points = 0,
    -- Weapon class for starting weapon
    startingWeaponClass = nil,
    -- Event types to emit
    spawnEventType = EVENT_TYPES.spawn,
    healthChangeEventType = EVENT_TYPES.healthChange,
    shieldChangeEventType = EVENT_TYPES.shieldChange,
    deathEventType = EVENT_TYPES.death,
    weaponPickupEventType = EVENT_TYPES.weaponPickup,
    -- Images/spritesheets, animation delays, start/end frames:
    -- Idle + walking
    idleWalkSpritesheet = gfx.imagetable.new('images/dummy/dummy-idle-walk'),
    idleImageFrames = {
        [DIRECTION_RIGHT] = 1,
        [DIRECTION_LEFT] = 4,
    },
    walkingLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 2,
            endFrame = 3,
        },
        [DIRECTION_LEFT] = {
            startFrame = 5,
            endFrame = 6,
        },
    },
    walkingLoopDelay = 100,
    -- Death
    deathSpritesheet = gfx.imagetable.new('images/dummy/dummy-death'),
    deathLoopFrames = {
        [DIRECTION_RIGHT] = {
            startFrame = 1,
            endFrame = 5,
        },
        [DIRECTION_LEFT] = {
            startFrame = 6,
            endFrame = 10,
        },
    },
    deathLoopDelay = 100,
    -- Placeholder state stuff, implementing classes should override.
    stateClasses = {
        EntityInactiveState,
    },
    initialStateKey = EntityInactiveState.key,
}).extends('FSMSprite')

-- Base constructor. Does the following:
-- - Initializes Entity instance variables
-- - Calls :initImages() and :setDefaultImage()
-- - Sets collide rect to the size of the sprite
-- - Sets z-index to Z_INDEX.entity
-- - Moves to initial position
-- - Adds to sprite list
-- - Give starting weapon (if startingWeaponClass is defined)
-- - Emits spawn event
--
-- Implementing classes will need to do the following:
-- - Set collision tag
-- - Call :initStatesAndSetInitial()
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
    -- TODO: this should no longer be needed since we know the above sets default image:
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

    -- Give entity its starting weapon (if defined)
    if self.startingWeaponClass ~= nil then
        self:giveWeapon(self.startingWeaponClass)
    end

    -- Emit spawn event
    self:emitSpawnEvent()
end

-- --------------------------------------------------------------------------------
-- Images
-- --------------------------------------------------------------------------------

-- Initialize images and animations based on attributes.
-- The following arrays will be initialized. Their indexes are DIRECTION_RIGHT and DIRECTION_LEFT:
-- - self.idleImages
-- - self.walkingLoops 
-- - self.deathLoops
-- Will also set self.defaultImage to self.idleImages[DIRECTION_RIGHT]
function Entity:initImages()
    -- Idle
    self.idleImages = {
        [DIRECTION_RIGHT] = self.idleWalkSpritesheet[self.idleImageFrames[DIRECTION_RIGHT]],
        [DIRECTION_LEFT] = self.idleWalkSpritesheet[self.idleImageFrames[DIRECTION_LEFT]],
    }
    -- Walking
    local walkingLoopRight = gfx.animation.loop.new(self.walkingLoopDelay, self.idleWalkSpritesheet)
    walkingLoopRight.startFrame = self.walkingLoopFrames[DIRECTION_RIGHT].startFrame
    walkingLoopRight.endFrame = self.walkingLoopFrames[DIRECTION_RIGHT].endFrame
    local walkingLoopLeft = gfx.animation.loop.new(self.walkingLoopDelay, self.idleWalkSpritesheet)
    walkingLoopLeft.startFrame = self.walkingLoopFrames[DIRECTION_LEFT].startFrame
    walkingLoopLeft.endFrame = self.walkingLoopFrames[DIRECTION_LEFT].endFrame
    self.walkingLoops = {
        [DIRECTION_RIGHT] = walkingLoopRight,
        [DIRECTION_LEFT] = walkingLoopLeft,
    }
    -- Death
    local deathLoopRight = gfx.animation.loop.new(self.deathLoopDelay, self.deathSpritesheet, false)
    deathLoopRight.paused = true
    deathLoopRight.startFrame = self.deathLoopFrames[DIRECTION_RIGHT].startFrame
    deathLoopRight.endFrame = self.deathLoopFrames[DIRECTION_RIGHT].endFrame
    local deathLoopLeft = gfx.animation.loop.new(self.deathLoopDelay, self.deathSpritesheet, false)
    deathLoopLeft.paused = true
    deathLoopLeft.startFrame = self.deathLoopFrames[DIRECTION_LEFT].startFrame
    deathLoopLeft.endFrame = self.deathLoopFrames[DIRECTION_LEFT].endFrame
    self.deathLoops = {
        [DIRECTION_RIGHT] = deathLoopRight,
        [DIRECTION_LEFT] = deathLoopLeft,
    }
    -- Default fallback image
    self.defaultImage = self.idleImages[DIRECTION_RIGHT]
end

-- Set image to default.
-- self.defaultImage MUST be set (duh).
function Entity:setDefaultImage()
    self:setImage(self.defaultImage)
end

-- Set image for idle/walking based on self.isMoving and self.direction.
function Entity:setIdleWalkingImage()
    local newImage = self.defaultImage
    if self.isMoving then
        newImage = self.walkingLoops[self.direction]:image()
    else
        newImage = self.idleImages[self.direction]
    end
    self:setImage(newImage)
end

-- TODO: play death animation, set image from that, indicate when animation finishes

-- Unpause death animation for current direction.
function Entity:playDeathAnimation()
    self.deathLoops[self.direction].paused = false
end

-- Set image from death animation. The above function should be called first to unpause it.
-- Return value should be true if the animation is still playing, false otherwise (i.e. :isValid())
function Entity:setDeathImage()
    self:setImage(self.deathLoops[self.direction]:image())
    return self.deathLoops[self.direction]:isValid()
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
-- Kill if health is 0 or below.
function Entity:applyDamage(damage)
    -- TODO: implement shields and event emitter
    self:subtractHealth(damage)
    -- If damage was fatal, call kill()
    if self.health <= 0 then
        self:kill()
    end
end

-- Set Entity health.
-- Emit health change event.
function Entity:setHealth(val)
    self.health = val
    self:emitHealthChangeEvent()
end

-- Shorthand to subtract value from health.
function Entity:subtractHealth(val)
    self:setHealth(self.health - val)
end

-- Shorthand to add value to health.
function Entity:addHealth(val)
    self:setHealth(self.health + val)
end

-- Restore health to base value.
function Entity:restoreHealthToMax()
    self:setHealth(self.baseHealth)
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
-- Emits weapon pickup event.
function Entity:giveWeapon(weaponClass)
    self.weapon = weaponClass(self)
    self:emitWeaponPickupEvent()
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

function Entity:emitSpawnEvent()
    EVENTS:emit(self.spawnEventType, self)
end

function Entity:emitHealthChangeEvent()
    EVENTS:emit(self.healthChangeEventType, self)
end

-- TODO: prob want to distinguish between damage and recharge?
function Entity:emitShieldChangeEvent()
    EVENTS:emit(self.shieldChangeEventType, self)
end

function Entity:emitDeathEvent()
    EVENTS:emit(self.deathEventType, self)
end

function Entity:emitWeaponPickupEvent()
    EVENTS:emit(self.weaponPickupEventType, self.weapon)
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