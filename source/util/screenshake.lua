-- ================================================================================
-- Screen Shake Helper
--
-- Inspired by SquidGodDev: https://github.com/SquidGodDev/InvadersTutorial/blob/main/screenShake.lua
-- ================================================================================
local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Screen Shake "Sprite" Class
-- ================================================================================
class('ScreenShake', {
    -- Don't remove this on scene transition
    doNotCleanup = true,
}).extends(gfx.sprite)

function ScreenShake:init()
    -- TODO: maybe we want a shake amount option separate from num frames?
    -- TODO: currently the amount it shakes and the number of frames it shakes for are both this variable:
    -- NOTE: Setting to -1, as update() shakes screen when > 0 and resets offset when == 0
    self.amount = 0
    self:add()
end

function ScreenShake:setShakeAmount(amount)
    self.amount = amount
end

function ScreenShake:update()
    if self.amount > 0 then
        local shakeAngle = math.random() * math.pi * 2
        local shakeX = math.floor(math.cos(shakeAngle)) * self.amount
        local shakeY = math.floor(math.sin(shakeAngle)) * self.amount
        -- Set display offset
        pd.display.setOffset(shakeX, shakeY)
        -- Decrement amount
        self.amount -= 1
    elseif self.amount == 0 then
        -- Once we hit 0, reset offset and set amount to a value < 0
        pd.display.setOffset(0, 0)
        self.amount = -1
    end
end