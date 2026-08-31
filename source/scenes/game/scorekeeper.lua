local pd <const> = playdate
local gfx <const> = pd.graphics
-- ================================================================================
-- Keep track of score
-- ================================================================================
class('ScoreKeeper').extends(gfx.sprite)

function ScoreKeeper:init()
    self.score = 0

    self.eventListeners = {
        [EVENT_TYPES.death] = function (entity)
            self:onEnemyDeath(entity)
        end,
    }
    EVENTS:registerListeners(self.eventListeners)

    self:add()
end

-- De-register listeners on removal
function ScoreKeeper:remove()
    EVENTS:deregisterListeners(self.eventListeners)
    ScoreKeeper.super.remove(self)
end

-- --------------------------------------------------------------------------------
-- Score Helpers
-- --------------------------------------------------------------------------------

-- Set score.
-- Emits scoreChange event.
function ScoreKeeper:setScore(score)
    self.score = score
    EVENTS:emit(EVENT_TYPES.scoreChange, self.score)
end

function ScoreKeeper:addPoints(points)
    self:setScore(self.score + points)
end

-- --------------------------------------------------------------------------------
-- Event Listeners
-- --------------------------------------------------------------------------------

function ScoreKeeper:onEnemyDeath(entity)
    if not entity.isFriendly then
        self:addPoints(entity.points)
    end
end