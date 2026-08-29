import 'scenes/title/movie'

local pd <const> = playdate
local gfx <const> = pd.graphics
-- playout
local box <const> = playout.box.new
local txt <const> = playout.text.new
local img <const> = playout.image.new

-- ================================================================================
-- Title Screen Scene Class
-- ================================================================================
class('TitleScene', {
    name = 'title-scene',
}).extends('Scene')

function TitleScene:init()
    self.bg = BackgroundVideo()
    MUSIC_MANAGER:loadAndPlayTrack('music/title-mono-22k')

    -- TODO: make a better logo later but for now this is fiiiine
    --          (it's got alpha on some pixels tho which is making it annoying to edit)
    local logoImage = gfx.image.new('images/title/logo.png')
    self.logo = gfx.sprite.new(logoImage)
    self.logo:moveTo(SCREEN_CENTER_X, SCREEN_HEIGHT // 3)
    self.logo:add()

    self.ui = TitleUI(SCREEN_CENTER_X, 2 * SCREEN_HEIGHT // 3)
end

function TitleScene:handleInput()
    local current, pressed, released = pd.getButtonState()
    if (pressed & pd.kButtonA) > 0 then
        SCENE_MANAGER:switchScene(SCENES.game)
    end
end

function TitleScene:update()
    self:handleInput()
end

-- Stop music on scene change
function TitleScene:exit()
    -- TODO: music fade out
    MUSIC_MANAGER:stop()
end

-- ================================================================================
-- UI
-- ================================================================================
class('TitleUI').extends(gfx.sprite)

function TitleUI:init(x, y)
    self:initUI()
    self:moveTo(x, y)
    self:add()
end

function TitleUI:initUI()
    self.uiTree = self:buildUITree()
    local uiImage = self.uiTree:draw()
    self:setImage(uiImage)
end

function TitleUI:buildUITree()
    local menuTxt = txt(
        'Press (A)',
        {
            alignment = kTextAlignment.center,
            color = gfx.kColorWhite,
        }
    )
    local menuContainer = box(
        {
            padding = 4,
            backgroundColor = gfx.kColorBlack,
        },
        {
            menuTxt,
        }
    )
    return playout.tree.new(menuContainer)
end
