local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Test Entities
-- ================================================================================

-- ================================================================================
-- TODO: GunnerDummy: only has firing state, is invincible
-- ================================================================================
class('GunnerDummyFiringState', {
    key = 'firing',
}).extends('EnemyState')

function GunnerDummyFiringState:enter()
    self.enemy.isMoving = false
    self.enemy:toggleWeaponFire(true)
end

function GunnerDummyFiringState:update()
    self.enemy:setIdleWalkingImage()
    -- TODO: update aiming angle
end

class('GunnerDummy', {
    stateClasses = {GunnerDummyFiringState},
    initialStateKey = GunnerDummyFiringState.key,
    startingWeaponClass = PlasmaRifleWeapon,
    invincible = true,
}).extends('Enemy')

-- TODO: aiming angle: calculate based on self.player