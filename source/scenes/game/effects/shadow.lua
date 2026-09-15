local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Shadow sprites to display under entities and items
-- ================================================================================
-- ================================================================================
-- Cache for shadow images so we don't redraw each time
-- ================================================================================
local imageCache <const> = {}
-- ================================================================================
-- Constants
-- ================================================================================
-- Height of a shadow image
local kShadowHeight <const> = 6
-- Pixles to adjust y-offset by so shadow slightly overlaps with caster
local kShadowYAdjustment <const> = kShadowHeight // 2

-- ================================================================================
-- Shadow Sprite
-- ================================================================================
class('Shadow').extends(gfx.sprite)

-- casterSprite: the sprite casting this shadow
-- widthOverride: (optional) If specified, use this as the shadow image width.
--                Defaults to width of casterSprite.
function Shadow:init(casterSprite, widthOverride)
    self.casterSprite = casterSprite
    local shadowWidth = type(widthOverride) == 'number' and widthOverride or self.casterSprite.width
    self:setImage(self:createImage(shadowWidth))
    -- Set center y to top of sprite.
    self:setCenter(0.5, 0)
    -- Pre-calculate y offset based on caster height.
    -- Assumes centered coordinates on caster.
    self.yOffset = (self.casterSprite.height / 2) - kShadowYAdjustment

    self:setZIndex(Z_INDEX.shadow)
    self:add()
end

-- Returns image to use for the shadow.
-- Will attempt to use cached image instead of drawing a new sprite.
function Shadow:createImage(width)
    -- Check cache
    if imageCache[width] ~= nil then
        return imageCache[width]
    end
    -- Draw image
    local image = gfx.image.new(width, kShadowHeight)
    gfx.pushContext(image)
        -- TODO: dither?
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer4x4)
        gfx.fillEllipseInRect(0, 0, image.width, image.height)
    gfx.popContext()
    -- Cache it
    imageCache[width] = image

    return image
end

-- TODO: it would be nice if we could keep this self-contained, but shadow position lags behind:
-- Move shadow below caster each frame.
-- function Shadow:update()
--     self:moveTo(self.casterSprite.x, self.casterSprite.y + self.yOffset)
-- end

-- Update the shadow's position to match the caster.
-- Should call in caster after running any code that would update position.
-- (I hate that this can't be self-contained, but shadow was lagging behind entity position)
function Shadow:updatePosition()
    self:moveTo(self.casterSprite.x, self.casterSprite.y + self.yOffset)
end