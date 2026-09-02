local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Stage object, defines level boundaries and background image.
-- ================================================================================
class('Stage').extends(gfx.sprite)

function Stage:init(stageWidth, stageHeight)
    self:setImage(self:createPlaceholderImage(stageWidth, stageHeight))
    -- Z-index
    self:setZIndex(Z_INDEX.background)
    -- Move to center and add
    self:moveTo(SCREEN_CENTER_X, SCREEN_CENTER_Y)
    self:add()
    -- Create boundary walls
    self:createBoundaries()
end

-- --------------------------------------------------------------------------------
-- Background Image
-- --------------------------------------------------------------------------------

function Stage:createPlaceholderImage(w, h)
    local image = gfx.image.new(w, h)
    gfx.pushContext(image)
        gfx.setDitherPattern(0.9, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, w, h)
    gfx.popContext()
    return image
end

-- --------------------------------------------------------------------------------
-- Boundaries
-- --------------------------------------------------------------------------------

-- Create stage boundaries with collisions.
function Stage:createBoundaries()
    -- Create images for boundary walls
    local sideWallImage = gfx.image.new(SCREEN_WIDTH, self.height)
    gfx.pushContext(sideWallImage)
        gfx.fillRect(0, 0, sideWallImage.width, sideWallImage.height)
    gfx.popContext()
    local topBottomWallImage = gfx.image.new(self.width + (2 * SCREEN_WIDTH), SCREEN_HEIGHT)
    gfx.pushContext(topBottomWallImage)
        gfx.fillRect(0, 0, topBottomWallImage.width, topBottomWallImage.height)
    gfx.popContext()
    -- Initialize wall sprites
    local topWall = gfx.sprite.new(topBottomWallImage)
    topWall:setCenter(0.5, 1.0)
    topWall:moveTo(self.x, self.y - (self.height / 2))
    local bottomWall = gfx.sprite.new(topBottomWallImage)
    bottomWall:setCenter(0.5, 0)
    bottomWall:moveTo(self.x, self.y + (self.height / 2))
    local leftWall = gfx.sprite.new(sideWallImage)
    leftWall:setCenter(1.0, 0.5)
    leftWall:moveTo(self.x - (self.width / 2), self.y)
    local rightWall = gfx.sprite.new(sideWallImage)
    rightWall:setCenter(0, 0.5)
    rightWall:moveTo(self.x + (self.width / 2), self.y)

    self.walls = {
        topWall,
        bottomWall,
        leftWall,
        rightWall,
    }
    for i=1, #self.walls do
        local wall = self.walls[i]
        wall:setCollideRect(0, 0, wall:getSize())
        wall:setTag(TAGS.wall)
        wall:add()
    end
end

-- --------------------------------------------------------------------------------
-- Lifecycle
-- --------------------------------------------------------------------------------

-- Remove walls when stage is removed
function Stage:remove()
    for i=1, #self.walls do
        self.walls[i]:remove()
    end
    Stage.super.remove(self)
end