import 'scenes/title/movie'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- Title Screen Scene Class
-- ================================================================================
class('TitleScene', {
    name = 'title-scene',
}).extends('Scene')

function TitleScene:init()
    -- TODO: bg video
    self.bg = BackgroundVideo()
    -- TODO: listen for input, transition to game
end