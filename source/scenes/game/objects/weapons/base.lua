local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Base classes for Weapons and Projectiles
-- ================================================================================

-- ================================================================================
-- Projectile Class
-- ================================================================================
class('Projectile', {
    -- TODO: image = placeholder image
    -- Speed (px / sec)
    speed = 400,
    -- Damage
    damage = 1,
    -- Max time projectile can travel before expiring (ms)
    maxTime = 3000,
}).extends(gfx.sprite)

function Projectile:init(originX, originY, angle, isFriendlyFire)
    self.angle = angle
    self.isFriendlyFire = isFriendlyFire
    -- Keep track of the time elapsed since fired
    self.firedTimestamp = pd.getCurrentTimeMilliseconds()

    -- TODO: image (rotate based on angle)
    -- TODO: collisions

    self:moveTo(originX, originY)
    self:add()
end

-- --------------------------------------------------------------------------------
-- Movement
-- --------------------------------------------------------------------------------

function Projectile:getTargetPosition()
    -- TODO: this was copied over from breakout ball, but I'm wondering if the negative sin is valid?
    -- TODO: prob should just store self.angle as radians to save a calculation
    local rad = math.rad(self.angle)
    local newX = self.x + (self.speed * math.cos(rad) * DELTA_TIME)
    local newY = self.y + (self.speed * -math.sin(rad) * DELTA_TIME)
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
-- Firing
-- --------------------------------------------------------------------------------
local kFiringState <const> = 'firing'
class('WeaponFiringState', {
    key = kFiringState,
}).extends('WeaponState')

-- TODO: design logic for firing vs not firing

-- ================================================================================
-- Weapon Object
-- ================================================================================
class('Weapon', {
    stateClasses = {
        WeaponFiringState,
    },
    initialStateKey = WeaponFiringState.key,
    -- Weapon Attributes:
    projectileClass = Projectile,
    bottomlessClip = true,
    startingAmmo = 999,
}).extends('FSMSprite')

function Weapon:init()
    
    self:initStatesAndSetInitial()
end