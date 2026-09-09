local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Base classes for Weapons and Projectiles
-- ================================================================================

-- ================================================================================
-- Constants
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Projectiles
-- --------------------------------------------------------------------------------
-- Projectile default size
local kProjectileDefaultSize <const> = 8
-- Projectile default image
local function createImage()
    local image = gfx.image.new(kProjectileDefaultSize, kProjectileDefaultSize)
    gfx.pushContext(image)
        gfx.fillCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end
local kProjectileDefaultImage <const> = createImage()

-- --------------------------------------------------------------------------------
-- Weapons
-- --------------------------------------------------------------------------------
-- Max ammo any weapon can carry
local kWeaponMaxAmmo <const> = 999
-- Default firing sound
local kWeaponDefaultFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/magnum_fire.wav')
kWeaponDefaultFiringSound:setVolume(0.25)
-- Dummy weapon icon
local kWeaponDefaultIcon <const> = gfx.image.new(gfx.getTextSize('?'))
gfx.pushContext(kWeaponDefaultIcon)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, kWeaponDefaultIcon.width, kWeaponDefaultIcon.height)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText('?', 0, 0, kWeaponDefaultIcon.width, kWeaponDefaultIcon.height)
gfx.popContext()

-- ================================================================================
-- Projectile Class
-- ================================================================================
class('Projectile', {
    -- Image
    image = kProjectileDefaultImage,
    -- Speed (px / sec)
    speed = 700,
    -- Damage
    damage = 1,
    -- Distance in px projectile can travel before expiring
    maxDistance = 3 * SCREEN_HEIGHT / 4,
}).extends(gfx.sprite)

function Projectile:init(originX, originY, angle, isFriendlyFire)
    self.originX = originX
    self.originY = originY
    self.angle = angle
    self.isFriendlyFire = isFriendlyFire

    -- Image
    self:setImage(self.image)

    -- Collisions
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.projectile)
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

    -- Add sprite
    self:moveTo(originX, originY)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

function Projectile:getTargetPosition()
    local rad = math.rad(self.angle)
    local newX = self.x + (self.speed * math.cos(rad) * DELTA_TIME)
    local newY = self.y + (self.speed * math.sin(rad) * DELTA_TIME)
    return newX, newY
end

function Projectile:updatePosition()
    local _, _, collisions, _ = self:moveWithCollisions(self:getTargetPosition())
    self:handleCollisions(collisions)
end

-- --------------------------------------------------------------------------------
-- Collisions
-- --------------------------------------------------------------------------------

function Projectile:handleCollisions(collisions)
    for i=1, #collisions do
        local collision = collisions[i]
        local other = collision.other
        local tag = other:getTag()
        if
            (self.isFriendlyFire and tag == TAGS.enemy)
            or (not self.isFriendlyFire and tag == TAGS.player)
        then
            -- Handle hitting a target
            self:handleCollideWithTarget(other)
        elseif tag == TAGS.wall then
            -- Remove if we hit a wall
            self:remove()
        end
    end
end

-- Logic for when a target entity is hit.
-- Assumes target is an Entity object whose isFriendly value is the opposite of self.isFriendlyFire.
-- Basic projectiles just apply damage to the target and call self:remove().
function Projectile:handleCollideWithTarget(targetEntity)
    targetEntity:applyDamage(self.damage)
    self:remove()
end

-- --------------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------------

-- Determine if maxDistance has been traveled
function Projectile:hasExceededMaxDistance()
    return pd.geometry.distanceToPoint(self.originX, self.originY, self.x, self.y) >= self.maxDistance
end

-- --------------------------------------------------------------------------------
-- Update
-- --------------------------------------------------------------------------------

function Projectile:update()
    self:updatePosition()
    if self:hasExceededMaxDistance() then
        self:remove()
    end
end


-- ================================================================================
-- Weapon States
-- ================================================================================
-- --------------------------------------------------------------------------------
-- Common Constructor
-- --------------------------------------------------------------------------------
class('WeaponState').extends('State')

function WeaponState:init(weapon)
    self.weapon = weapon
end

-- --------------------------------------------------------------------------------
-- Inactive (Not Firing)
-- --------------------------------------------------------------------------------
local kInactiveState <const> = 'inactive'
class('WeaponInactiveState', {
    key = kInactiveState,
}).extends('WeaponState')

-- --------------------------------------------------------------------------------
-- Firing
-- --------------------------------------------------------------------------------
local kFiringState <const> = 'firing'
class('WeaponFiringState', {
    key = kFiringState,
}).extends('WeaponState')

function WeaponFiringState:enter()
    self.weapon:resetShotCount()
end

function WeaponFiringState:update()
    self.weapon:attemptToFire()
end

function WeaponFiringState:exit()
    self.weapon:resetShotCount()
end

-- ================================================================================
-- Weapon Object
-- ================================================================================
class('Weapon', {
    stateClasses = {
        WeaponInactiveState,
        WeaponFiringState,
    },
    initialStateKey = WeaponInactiveState.key,

    -- Display name
    name = 'Weapon',
    -- Class of the projectile this shoots
    projectileClass = Projectile,
    -- Image for HUD/pickups
    icon = kWeaponDefaultIcon,
    -- Sound to play when firing
    fireSound = kWeaponDefaultFiringSound,
    -- Time between shots (ms)
    timeBetweenShots = 600,
    -- If true, ammo is unlimited.
    -- This always gets set to true for NPCs.
    -- Can be overridden per-instance with the 2nd optional param.
    bottomlessClip = false,
    -- Initial amount of ammo (ignored if bottomlessClip is true)
    startingAmmo = 999,
}).extends('FSMSprite')

function Weapon:init(carrierEntity, forceBottomless)
    self.carrierEntity = carrierEntity
    -- Whether this is a player's weapon or an enemy's
    self.isFriendlyFire = self.carrierEntity.isFriendly
    -- Current ammo count
    self.ammo = self.startingAmmo
    -- If carrier is any Entity other than Player, don't worry about ammo
    if self.carrierEntity.className ~= 'Player' or forceBottomless then
        self.bottomlessClip = true
    end
    -- Timestamp since last shot. Default to -1 so we can start firing right away
    self.lastShotTimestamp = -1
    -- Keep track of consecutive shots fired while in firing state
    self.consecutiveShotCount = 0

    self:initStatesAndSetInitial()
    self:add()
end

-- --------------------------------------------------------------------------------
-- Firing
-- --------------------------------------------------------------------------------

-- Set lastShotTimestamp to current time (ms).
function Weapon:updateLastShotTimestamp()
    self.lastShotTimestamp = pd.getCurrentTimeMilliseconds()
end

-- Checks if enough time has elapsed since last shot (i.e. we can shoot again).
-- Always returns true if self.lastShotTimestamp is negative.
function Weapon:isCooldownOver()
    return (pd.getCurrentTimeMilliseconds() - self.lastShotTimestamp >= self.timeBetweenShots) or (self.lastShotTimestamp < 0)
end

-- Checks if cooldown is over, and fires a shot if it is.
-- Takes shot origin and angle.
function Weapon:attemptToFire()
    if self:isCooldownOver() then
        if self:isOutOfAmmo() then
            -- TODO: if isOutOfAmmo(), play dry fire sound?
            DEBUG_MANAGER:vPrint('Weapon: attempted to fire, but out of ammo')
        else
            local originX, originY, angle = self.carrierEntity:getOriginAndAngle()
            self:fire(originX, originY, angle)
        end
    end
end

-- Fire projectile.
function Weapon:fire(originX, originY, angle)
    -- Create projectile
    local firedProjectile = self.projectileClass(originX, originY, angle, self.isFriendlyFire)
    -- Update lastShotTimestamp for cooldown checks
    self:updateLastShotTimestamp()
    -- Play fire sound effect
    self.fireSound:play(1)
    -- Increment shot count
    -- NOTE: This might have issues with manual fire since the single shot mode doesn't change state.
    --       But this is mostly for enemy behavior, and I don't know if we're keeping manual fire anyway.
    self:incrementShotCount()
    -- Decrease ammo
    self:updateAmmoAfterShotFired()
end

-- Set whether weapon should be firing or inactive.
function Weapon:setIsFiring(flag)
    if flag and self.state.key ~= WeaponFiringState.key then
        self:setState(WeaponFiringState.key)
    elseif not flag and self.state.key ~= WeaponInactiveState.key then
        self:setState(WeaponInactiveState.key)
    end
end

-- Returns whether we're in the firing state.
function Weapon:isFiring()
    return self.state.key == WeaponFiringState.key
end

-- Toggle firing/inactive state.
-- flag is optional, default behavior is to toggle to opposite of current state.
function Weapon:toggleFire(flag)
    if flag == nil then
        flag = self.state.key == WeaponInactiveState.key
    end
    self:setIsFiring(flag)
end

-- --------------------------------------------------------------------------------
-- Shot count
-- --------------------------------------------------------------------------------

-- Reset consecutive shot count
function Weapon:resetShotCount()
    self.consecutiveShotCount = 0
end

-- Add 1 to consecutive shot count
function Weapon:incrementShotCount()
    self.consecutiveShotCount += 1
end

-- Returns the number of consecutive shots while in the firing state
function Weapon:getShotCount()
    return self.consecutiveShotCount
end

-- --------------------------------------------------------------------------------
-- Ammo
-- --------------------------------------------------------------------------------

-- Set the weapon's ammo and tell carrier entity to emit ammo change event.
-- If ammo is now 0, will also tell carrier entity to emit ammo empty event.    
function Weapon:setAmmo(val)
    self.ammo = val
    self.carrierEntity:emitAmmoChangeEvent()
    if self.ammo == 0 then
        self.carrierEntity:emitAmmoEmptyEvent()
    end
end

-- Add ammo to weapon.
-- Will never exceed kWeaponMaxAmmo.
function Weapon:addAmmo(val)
    local newAmmo = self.ammo + val
    if newAmmo > kWeaponMaxAmmo then
        newAmmo = kWeaponMaxAmmo
    end
    self:setAmmo(newAmmo)
end

-- Remove ammo from weapon.
-- Value will never go below 0.
function Weapon:subtractAmmo(val)
    local newAmmo = self.ammo - val
    if newAmmo < 0 then
        newAmmo = 0
    end
    self:setAmmo(newAmmo)
end

-- Shorthand to subtract 1 from ammo when a shot is taken.
-- If bottomlessClip is true, just return.
function Weapon:updateAmmoAfterShotFired()
    if self.bottomlessClip then
        return
    end
    self:subtractAmmo(1)
end

-- Returns true if ammo is 0 and bottomlessClip is false.
function Weapon:isOutOfAmmo()
    return not self.bottomlessClip and self.ammo <= 0
end

-- --------------------------------------------------------------------------------
-- Projectile Helpers
-- --------------------------------------------------------------------------------

-- Returns the maxDistance of the projectile class
function Weapon:getRange()
    return self.projectileClass.maxDistance
end