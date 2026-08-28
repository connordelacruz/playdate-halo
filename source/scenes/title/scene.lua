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
    self.bg = BackgroundVideo()
    -- TODO: music fade out
    -- TODO: rename file
    MUSIC_MANAGER:loadAndPlayTrack('music/title-mono-22k')

    -- TODO: listen for input, transition to game
end

-- Stop music on scene change
function TitleScene:exit()
    MUSIC_MANAGER:stop()
end