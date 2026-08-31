local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Magnum Weapon and Projectiles
-- ================================================================================
local kMagnumFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/magnum_fire.wav')
kMagnumFiringSound:setVolume(0.25)

-- ================================================================================
-- Projectile Class
-- ================================================================================
-- TODO: do the math, bullets shouldn't fly that far off screen
class('MagnumProjectile', {
    speed = 800,
    damage = 1,
    maxTime = 500,
}).extends('Projectile')

function MagnumProjectile:createImage()
    local image = gfx.image.new(8, 8)
    gfx.pushContext(image)
        gfx.fillCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end

-- ================================================================================
-- Weapon Class
-- ================================================================================
class('MagnumWeapon', {
    name = 'Magnum',
    projectileClass = MagnumProjectile,
    fireSound = kMagnumFiringSound,
    timeBetweenShots = 500,
    bottomlessClip = true,
}).extends('Weapon')