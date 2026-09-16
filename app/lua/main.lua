local lvgl = require("lvgl")
local dataman = require("dataman")

-- Mi Band 10 Binary Dot Clock
-- The public examples expose time values as value // 256.
local SHOW_AM_PM = true
local ON_COLOR = 0xFFFFFF
local OFF_COLOR = 0x151515
local BACKGROUND = 0x000000
local TEXT_COLOR = 0xFFFFFF

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
root:add_flag(lvgl.FLAG.CLICKABLE)
root:add_flag(lvgl.FLAG.EVENT_BUBBLE)

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

-- A tap opens a full-screen date card. Keep the clock itself free of text.
local dateView = lvgl.Object(root, {
    x = 0,
    y = 0,
    w = lvgl.HOR_RES(),
    h = lvgl.VER_RES(),
    bg_color = BACKGROUND,
    bg_opa = lvgl.OPA(100),
    border_width = 0,
    pad_all = 0,
})
dateView:add_flag(lvgl.FLAG.HIDDEN)
dateView:add_flag(lvgl.FLAG.EVENT_BUBBLE)

local dateLabel = lvgl.Label(dateView, {
    x = 0,
    y = 115,
    w = lvgl.HOR_RES(),
    h = 90,
    text = "----.--.--",
    text_font = lvgl.Font("MiSans-Regular", 34),
    text_color = TEXT_COLOR,
    text_align = lvgl.ALIGN.CENTER,
    bg_opa = 0,
    border_width = 0,
})

local weekdayLabel = lvgl.Label(dateView, {
    x = 0,
    y = 225,
    w = lvgl.HOR_RES(),
    h = 120,
    text = "요일",
    text_font = lvgl.Font("MiSans-Regular", 72),
    text_color = TEXT_COLOR,
    text_align = lvgl.ALIGN.CENTER,
    bg_opa = 0,
    border_width = 0,
})

local weekdays = { "일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일" }

local function updateDate()
    local now = os.date("*t")
    dateLabel:set { text = string.format("%04d.%02d.%02d", now.year, now.month, now.day) }
    weekdayLabel:set { text = weekdays[now.wday] or "요일" }
end

local showingDate = false
local function showDate(show)
    showingDate = show
    if show then
        updateDate()
        dateView:clear_flag(lvgl.FLAG.HIDDEN)
    else
        dateView:add_flag(lvgl.FLAG.HIDDEN)
    end
end

root:onevent(lvgl.EVENT.CLICKED, function()
    showDate(not showingDate)
end)

-- dateDay changes at least once per day and also keeps the date card fresh.
dataman.subscribe("dateDay", dateView, function()
    updateDate()
end)

-- Keep the page lifecycle small and explicit for the watchface runtime.
pageOnPause = function() end
pageOnResume = function() end
