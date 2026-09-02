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
-- Default firing sound
local kWeaponDefaultFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/magnum_fire.wav')
kWeaponDefaultFiringSound:setVolume(0.25)

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

function WeaponFiringState:update()
    self.weapon:attemptToFire()
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
    -- TODO: weapon pickup image
    -- Sound to play when firing
    fireSound = kWeaponDefaultFiringSound,
    -- Time between shots (ms)
    timeBetweenShots = 600,
    -- TODO: implement ammo
    -- If true, ammo is unlimited
    bottomlessClip = true,
    -- Initial amount of ammo (ignored if bottomlessClip is true)
    startingAmmo = 999,
}).extends('FSMSprite')

function Weapon:init(carrierEntity)
    self.carrierEntity = carrierEntity
    -- Whether this is a player's weapon or an enemy's
    self.isFriendlyFire = self.carrierEntity.isFriendly
    -- TODO: implement ammo
    self.ammo = self.startingAmmo
    -- Timestamp since last shot. Default to -1 so we can start firing right away
    self.lastShotTimestamp = -1

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
        local originX, originY, angle = self.carrierEntity:getOriginAndAngle()
        self:fire(originX, originY, angle)
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
end

-- Set whether weapon should be firing or inactive.
function Weapon:setIsFiring(flag)
    if flag and self.state.key ~= WeaponFiringState.key then
        self:setState(WeaponFiringState.key)
    elseif not flag and self.state.key ~= WeaponInactiveState.key then
        self:setState(WeaponInactiveState.key)
    end
end

-- Toggle firing/inactive state.
-- flag is optional, default behavior is to toggle to opposite of current state.
function Weapon:toggleFire(flag)
    if flag == nil then
        flag = self.state.key == WeaponInactiveState.key
    end
    self:setIsFiring(flag)
end