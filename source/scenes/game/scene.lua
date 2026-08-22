import 'scenes/game/weapons/__init__'
import 'scenes/game/entities/__init__'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Game Scene Class
-- ================================================================================
class('GameScene', {
    name = 'game-scene',
}).extends('Scene')

function GameScene:init()
    self.player = Player(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    self.player:giveWeapon(MagnumWeapon)
end

-- TODO: crank indicator