local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Magnum Weapon and Projectiles
-- ================================================================================
local kMagnumFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/magnum_fire.wav')
kMagnumFiringSound:setVolume(0.25)

local function createImage()
    local image = gfx.image.new(8, 8)
    gfx.pushContext(image)
        gfx.fillCircleInRect(0, 0, image.width, image.height)
    gfx.popContext()
    return image
end
local kMagnumProjectileImage <const> = createImage()

-- ================================================================================
-- Projectile Class
-- ================================================================================
class('MagnumProjectile', {
    image = kMagnumProjectileImage,
    speed = 800,
    damage = 1,
}).extends('Projectile')

-- ================================================================================
-- Weapon Class
-- ================================================================================
class('MagnumWeapon', {
    name = 'Magnum',
    projectileClass = MagnumProjectile,
    icon = gfx.image.new('images/weapons/magnum.png'),
    fireSound = kMagnumFiringSound,
    timeBetweenShots = 500,
    bottomlessClip = true,
}).extends('Weapon')