local pd <const> = playdate
-- ===============================================================================
-- Delta Time
-- ===============================================================================

-- Will store time in seconds since the last frame
DELTA_TIME = 0

function updateDeltaTime()
    DELTA_TIME = pd.getElapsedTime()
    pd.resetElapsedTime()
end
