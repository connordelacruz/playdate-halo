import 'scenes/game/objects/player'

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
end

-- TODO: crank indicator