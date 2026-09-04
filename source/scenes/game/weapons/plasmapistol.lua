local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Plasma Pistol Weapon and Projectiles
-- ================================================================================
local kPlasmaPistolFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/plasma_fire.wav')
kPlasmaPistolFiringSound:setVolume(0.25)

local function createImage()
    local image = gfx.image.new(8, 8)
    gfx.pushContext(image)
        gfx.setLineWidth(2)
        gfx.drawCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end
local kPlasmaPistolProjectileImage <const> = createImage()

-- ================================================================================
-- Projectile
-- ================================================================================
class('PlasmaPistolProjectile', {
    image = kPlasmaPistolProjectileImage,
    speed = 300,
    damage = 1,
}).extends('Projectile')

-- ================================================================================
-- Weapon
-- ================================================================================
class('PlasmaPistolWeapon', {
    name = 'Plasma Pistol',
    projectileClass = PlasmaPistolProjectile,
    icon = gfx.image.new('images/weapons/plasmapistol.png'),
    fireSound = kPlasmaPistolFiringSound,
    timeBetweenShots = 400,
    bottomlessClip = true,
}).extends('Weapon')
