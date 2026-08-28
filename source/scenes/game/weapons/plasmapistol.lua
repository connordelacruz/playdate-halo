local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Plasma Pistol Weapon and Projectiles
-- ================================================================================
local kPlasmaPistolFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/plasma_fire.wav')
kPlasmaPistolFiringSound:setVolume(0.25)

-- ================================================================================
-- Projectile
-- ================================================================================
-- TODO: do the math, bullets shouldn't fly that far off screen
class('PlasmaPistolProjectile', {
    speed = 300,
    damage = 1,
    maxTime = 700,
}).extends('Projectile')

function PlasmaPistolProjectile:createImage()
    local image = gfx.image.new(8, 8)
    gfx.pushContext(image)
        gfx.setLineWidth(2)
        gfx.drawCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end

-- ================================================================================
-- Weapon
-- ================================================================================
class('PlasmaPistolWeapon', {
    projectileClass = PlasmaPistolProjectile,
    fireSound = kPlasmaPistolFiringSound,
    timeBetweenShots = 300,
    bottomlessClip = true,
}).extends('Weapon')
