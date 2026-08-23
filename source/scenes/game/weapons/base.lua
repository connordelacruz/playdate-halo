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
-- --------------------------------------------------------------------------------
-- Weapons
-- --------------------------------------------------------------------------------
-- Default firing sound
local kWeaponDefaultFiringSound <const> = pd.sound.sampleplayer.new('scenes/game/weapons/sounds/magnum_fire.wav')
kWeaponDefaultFiringSound:setVolume(0.25)

-- ================================================================================
-- Projectile Class
-- ================================================================================
class('Projectile', {
    -- Speed (px / sec)
    speed = 700,
    -- Damage
    damage = 1,
    -- Max time projectile can travel before expiring (ms)
    maxTime = 700,
}).extends(gfx.sprite)

function Projectile:init(originX, originY, angle, isFriendlyFire)
    self.angle = angle
    self.isFriendlyFire = isFriendlyFire
    -- Keep track of the time elapsed since fired
    self.firedTimestamp = pd.getCurrentTimeMilliseconds()

    -- Image
    self:setImage(self:createImage())
    self:setCollideRect(0, 0, self:getSize())
    if isFriendlyFire then
        self:setTag(TAGS.projectileFriendly)
    else
        self:setTag(TAGS.projectileEnemy)
    end
    -- TODO: disable collisions for now
    self:setCollisionsEnabled(false)

    self:moveTo(originX, originY)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Image
-- --------------------------------------------------------------------------------

-- Returns the image for the projectile sprite.
function Projectile:createImage()
    local image = gfx.image.new(kProjectileDefaultSize, kProjectileDefaultSize)
    gfx.pushContext(image)
        gfx.fillCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

function Projectile:getTargetPosition()
    -- TODO: this was copied over from breakout ball, but I'm wondering if the negative sin is valid?
    -- TODO: prob should just store self.angle as radians to save a calculation
    local rad = math.rad(self.angle)
    local newX = self.x + (self.speed * math.cos(rad) * DELTA_TIME)
    local newY = self.y + (self.speed * math.sin(rad) * DELTA_TIME)
    return newX, newY
end

function Projectile:updatePosition()
    local _, _, collisions, _ = self:moveWithCollisions(self:getTargetPosition())
    -- TODO: collision handling, maybe return collisions so this can just be positional
end

-- --------------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------------

-- Determine if maxTime has elapsed since projectile was fired
function Projectile:isTimeUp()
    return pd.getCurrentTimeMilliseconds() - self.firedTimestamp >= self.maxTime
end

-- --------------------------------------------------------------------------------
-- Update
-- --------------------------------------------------------------------------------

function Projectile:update()
    self:updatePosition()
    -- If projectile exceeds maxTime, despawn it
    if self:isTimeUp() then
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
    initialStateKey = WeaponFiringState.key,

    -- TODO: weapon pickup image
    -- TODO: reticle image
    -- Sound to play when firing
    fireSound = kWeaponDefaultFiringSound,
    -- Class of the projectile this shoots
    projectileClass = Projectile,
    -- Time between shots (ms)
    timeBetweenShots = 600,
    -- If true, ammo is unlimited
    bottomlessClip = true,
    -- Initial amount of ammo (ignored if bottomlessClip is true)
    startingAmmo = 999,
}).extends('FSMSprite')

function Weapon:init(carrierSprite)
    self.carrierSprite = carrierSprite
    -- Whether this is a player's weapon or an enemy's
    self.isFriendlyFire = self.carrierSprite.className == 'Player'
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
        local originX, originY, angle = self.carrierSprite:getOriginAndAngle()
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
function Weapon:toggleFire()
    self:setIsFiring(self.state.key == WeaponInactiveState.key)
end