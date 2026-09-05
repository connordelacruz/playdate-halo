local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Assault Rifle Weapon and Projectiles
-- ================================================================================
-- TODO: multiple sounds, vary each shot
local kAssaultRifleFiringSound <const> = pd.sound.sampleplayer.new('sounds/weapons/assault_rifle_fire_1.wav')
kAssaultRifleFiringSound:setVolume(0.25)

local function createImage()
    local image = gfx.image.new(8, 8)
    gfx.pushContext(image)
        gfx.fillCircleInRect(0, 0, image:getSize())
    gfx.popContext()
    return image
end
local kAssaultRifleProjectileImage <const> = createImage()

-- ================================================================================
-- Projectile
-- ================================================================================
class('AssaultRifleProjectile', {
    image = kAssaultRifleProjectileImage,
    speed = 400,
    damage = 1,
    maxDistance = SCREEN_HEIGHT / 2,
}).extends('Projectile')

-- ================================================================================
-- Weapon
-- ================================================================================
class('AssaultRifleWeapon', {
    name = 'Assault Rifle',
    projectileClass = AssaultRifleProjectile,
    icon = gfx.image.new('images/weapons/assaultrifle.png'),
    fireSound = kAssaultRifleFiringSound,
    timeBetweenShots = 120,
    -- TODO: implement ammo
    bottomlessClip = true,
}).extends('Weapon')

