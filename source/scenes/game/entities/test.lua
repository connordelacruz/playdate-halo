local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Test Entities
-- ================================================================================

-- ================================================================================
-- GunnerDummy: only has firing state, is invincible
-- ================================================================================
class('GunnerDummyFiringState', {
    key = 'firing',
}).extends('EnemyState')

function GunnerDummyFiringState:enter()
    self.enemy.isMoving = false
    self.enemy.faceAimingAngle = true
    self.enemy:toggleWeaponFire(true)
end

function GunnerDummyFiringState:update()
    self.enemy:setIdleWalkingImage()
    self.enemy:updateDirection()
end

class('GunnerDummy', {
    stateClasses = {GunnerDummyFiringState},
    initialStateKey = GunnerDummyFiringState.key,
    startingWeaponClass = PlasmaPistolWeapon,
    invincible = true,
}).extends('Enemy')