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
    -- Spawn player in the center, give magnum to start
    self.player = Player(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    self.player:giveWeapon(MagnumWeapon)

    -- DEBUG: Spawn some hard-coded enemies for testing
    self.enemies = {
        Enemy(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4),
        Enemy(SCREEN_WIDTH - SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4),
        Enemy(SCREEN_WIDTH - SCREEN_WIDTH / 4, SCREEN_HEIGHT - SCREEN_HEIGHT / 4),
        Enemy(SCREEN_WIDTH / 4, SCREEN_HEIGHT - SCREEN_HEIGHT / 4),
    }
end

-- TODO: crank indicator