import 'scenes/game/ui/__init__'
import 'scenes/game/weapons/__init__'
import 'scenes/game/entities/__init__'
import 'scenes/game/lifecycle'
import 'scenes/game/camera'
import 'scenes/game/scorekeeper'
import 'scenes/game/stage'

local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Game Scene Class
-- ================================================================================
class('GameScene', {
    name = 'game-scene',
}).extends('Scene')

function GameScene:init()
    self.gm = GameMaster()

    -- Create stage and boundaries
    -- TODO: stage size + using stage to place entities instead of PD coordinates
    self.stage = Stage(SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2)
    -- Initialize score keeper
    self.scoreKeeper = ScoreKeeper()

    -- Initialize HUD
    self.hud = HUD()
    -- Spawn player in the center
    self.player = Player(SCREEN_CENTER_X, SCREEN_CENTER_Y)

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

-- Show crank indicator if docked.
function GameScene:update()
    if pd.isCrankDocked() then
        pd.ui.crankIndicator:draw()
    end
end