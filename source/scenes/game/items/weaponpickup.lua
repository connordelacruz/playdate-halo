local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Item for weapon pickups
-- ================================================================================
-- TODO: base Item class with :pickup(player)
class('WeaponPickup').extends(gfx.sprite)

function WeaponPickup:init(x, y, weaponClass)
    self.weaponClass = weaponClass
    self:setImage(weaponClass.icon)

    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.item)
    self.collisionResponse = gfx.sprite.kCollisionTypeOverlap

    self:setZIndex(Z_INDEX.item)
    self:moveTo(x, y)
    self:add()
end

function WeaponPickup:pickup(player)
    -- TODO: check if player already has this weapon, give ammo instead
    --      (maybe have that logic in the Player class with a different give function)
    -- TODO: play sound?
    player:giveWeapon(self.weaponClass)
    self:remove()
end