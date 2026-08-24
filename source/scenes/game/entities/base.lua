local pd <const> = playdate
local gfx <const> = pd.graphics
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
end

-- --------------------------------------------------------------------------------
-- Weapons and Aiming
-- --------------------------------------------------------------------------------

-- Give the entity a new weapon.
function Entity:giveWeapon(weaponClass)
    self.weapon = weaponClass(self)
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
    return self.x, self.y, self:calculateAimingAngle()
end