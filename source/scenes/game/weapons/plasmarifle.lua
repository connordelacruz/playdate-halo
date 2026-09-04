local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Plasma Rifle Weapon and Projectiles
-- ================================================================================
-- TODO: vary sounds each shot? Or pull from a different game? make it distinct from pistol
local kPlasmaRifleFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/plasma_fire.wav')
kPlasmaRifleFiringSound:setVolume(0.25)

local function createImage()
    local image = gfx.image.new(8, 8)
    gfx.pushContext(image)
        gfx.setLineWidth(2)
        gfx.drawCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end
local kPlasmaRifleProjectileImage <const> = createImage()

-- ================================================================================
-- Projectile
-- ================================================================================
class('PlasmaRifleProjectile', {
    image = kPlasmaRifleProjectileImage,
    speed = 400,
    damage = 1,
    maxDistance = SCREEN_HEIGHT / 2,
}).extends('Projectile')

-- ================================================================================
-- Weapon
-- ================================================================================
class('PlasmaRifleWeapon', {
    name = 'Plasma Rifle',
    projectileClass = PlasmaRifleProjectile,
    icon = gfx.image.new('images/weapons/plasmarifle.png'),
    fireSound = kPlasmaRifleFiringSound,
    timeBetweenShots = 250,
    bottomlessClip = true,
}).extends('Weapon')

