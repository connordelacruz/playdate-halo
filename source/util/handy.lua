-- ================================================================================
-- Handy utility functions
-- ================================================================================
-- TODO: i dunno how we wanna scope these, maybe as a "module"?

-- Returns angle from origin point to target point (in degrees)
function getAngleBetweenPoints(originX, originY, targetX, targetY)
    local dx = targetX - originX
    local dy = targetY - originY
    return math.deg(math.atan(dy, dx))
end