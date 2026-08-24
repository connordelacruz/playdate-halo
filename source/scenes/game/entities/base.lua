local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Base Entity Class
-- 
-- Shared behaviors between player, enemies, etc
-- ================================================================================
-- TODO: Define attributes common to entities? speed maybe idk
class('Entity').extends('FSMSprite')

-- Note: Constructors should be written custom for implementations of Entity.
function Entity:init(x, y)
    self.weapon = nil

    self:moveTo(x, y)
    self:add()
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