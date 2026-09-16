local lvgl = require("lvgl")
local dataman = require("dataman")

-- Mi Band 10 Binary Dot Clock
-- The public examples expose time values as value // 256.
local SHOW_AM_PM = true
local ON_COLOR = 0xFFFFFF
local OFF_COLOR = 0x151515
local BACKGROUND = 0x000000

local root = lvgl.Object(nil, {
    x = 0,
    y = 0,
    w = lvgl.HOR_RES(),
    h = lvgl.VER_RES(),
    bg_color = BACKGROUND,
    bg_opa = lvgl.OPA(100),
    border_width = 0,
    pad_all = 0,
})
root:clear_flag(lvgl.FLAG.SCROLLABLE)

local DOT = 12
local Y = (lvgl.VER_RES() // 2) - (DOT // 2)
local positions = {
    8,                 -- AM/PM
    32, 47, 62, 77,    -- hour, LSB -> MSB
    104, 119, 134, 149, 164, 179, -- minute, LSB -> MSB
}

local dots = {}
for i, x in ipairs(positions) do
    dots[i] = lvgl.Object(root, {
        x = x,
        y = Y,
        w = DOT,
        h = DOT,
        radius = 255,
        bg_color = OFF_COLOR,
        bg_opa = lvgl.OPA(100),
        border_width = 0,
        pad_all = 0,
    })
end

local function setDot(dot, on)
    dot:set { bg_color = on and ON_COLOR or OFF_COLOR }
end

local function setBits(value, first, width)
    for i = 0, width - 1 do
        -- Horizontal order is least-significant bit on the left.
        setDot(dots[first + i], (value & (1 << i)) ~= 0)
    end
end

local function updateHour(value)
    local hour24 = value // 256
    local hour12 = hour24 % 12
    if hour12 == 0 then hour12 = 12 end

    if SHOW_AM_PM then
        setDot(dots[1], hour24 >= 12)
    else
        dots[1]:add_flag(lvgl.FLAG.HIDDEN)
    end
    setBits(hour12, 2, 4)
end

local function updateMinute(value)
    setBits(value // 256, 6, 6)
end

dataman.subscribe("timeHour", root, updateHour)
dataman.subscribe("timeMinute", root, updateMinute)

-- Keep the page lifecycle small and explicit for the watchface runtime.
pageOnPause = function() end
pageOnResume = function() end
