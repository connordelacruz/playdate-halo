local pd <const> = playdate
local gfx <const> = pd.graphics

-- ================================================================================
-- "Sprite" for the background video
-- ================================================================================
class('BackgroundVideo').extends(gfx.sprite)

function BackgroundVideo:init()
    self.video = gfx.video.new('movies/halo-high-contrast-atkinson')
    -- Image video frames will render to
    self.videoContext = self.video:getContext()

    -- Number of frames in the video
    self.frameCount = self.video:getFrameCount()
    -- Current frame
    self.currentFrame = 0

    -- Initialize sprite stuff
    self:setImage(self.videoContext)
    self:setSize(self.video:getSize())
    self:setZIndex(Z_INDEX.background)
    self:moveTo(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    self:add()
end

-- Render current frame and increment
function BackgroundVideo:renderFrame()
    self.video:renderFrame(self.currentFrame)
    self.currentFrame = (self.currentFrame + 1) % self.frameCount
end

-- Render frames on update
function BackgroundVideo:update()
    self:renderFrame()
end