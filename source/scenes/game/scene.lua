import 'scenes/game/camera'
import 'scenes/game/stage'
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
    -- Create stage and boundaries
    -- TODO: figure out better stage size. This is just for testing
    self.stage = Stage(SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2)
    -- Spawn player in the center, give magnum to start
    self.player = Player(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    self.player:giveWeapon(MagnumWeapon)

    -- Create camera and attach to player's reticle
    self.camera = Camera()
    self.camera:attachTo(self.player.reticle)

    -- DEBUG: Spawn some hard-coded enemies for testing
    self.enemies = {
        Grunt(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4, self.player),
        Grunt(SCREEN_WIDTH - SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4, self.player),
        Grunt(SCREEN_WIDTH - SCREEN_WIDTH / 4, 3 * SCREEN_HEIGHT / 4, self.player),
        Grunt(SCREEN_WIDTH / 4, 3 * SCREEN_HEIGHT / 4, self.player),
    }
end

-- TODO: crank indicator