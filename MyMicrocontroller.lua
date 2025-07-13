--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)
        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))     -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))      -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))     -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50) -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

Old_X = 0
Old_Y = 0
Old_Z = 0

P_X = 0
P_Y = 0
P_Z = 0
Delta_X = 0
Delta_Y = 0
Delta_Z = 0
Ground_Velocity = 0

Margin = .05

function accel(v, d)
    G = 10
    R = (100000 / 3) * (1 + math.sqrt(10))
    return 1 + (v / 100) - (G * R * R) / ((R + d) ^ 2)
end

function screen_remap(location, min_range, max_range, screen_size)
    return screen_size * ((location - min_range) / (max_range - min_range))
end

function onTick()
    local x = input.getNumber(5)
    local y = input.getNumber(6)
    P_Z = input.getNumber(7)

    local k = 100000
    local pi100k = math.pi * k


    if y < 1.28 * k then
        P_X = x
        P_Y = y
    elseif y > 1.28 + pi100k then
        P_X = 2 * k - x
        P_Y = 2.56 * k + pi100k - y
    else
        theta = (y - 1.28 * k) / k
        P_X = k - ((k - x) * math.cos(theta))
        P_Y = 1.28 * k + ((k - x) * math.sin(theta))
    end

    Delta_X = 60 * (P_X - Old_X)
    Delta_Y = 60 * (P_Y - Old_Y)
    Delta_Z = 60 * (P_Z - Old_Z)

    Old_X = P_X
    Old_Y = P_Y
    Old_Z = P_Z

    Ground_Velocity = math.sqrt((Delta_X ^ 2) + (Delta_Z ^ 2)) + 3000
end

function onDraw()
    -- Example that draws a red circle in the center of the screen with a radius of 20 pixels
    local width = screen.getWidth()
    local height = screen.getHeight()
    screen.setColor(255, 0, 0)

    -- Do forward path estimation
    local satisfied = false
    local delta_t = 1
    local x_pos = P_X
    local y_pos = P_Y + 48000
    local t = 0
    local y_vel = -100

    local path = {}
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge

    while not satisfied do
        -- RK4 Integration
        k1v = accel(Ground_Velocity, y_pos)
        k1x = y_vel

        k2v = accel(Ground_Velocity, y_pos + (delta_t / 2) * k1x)
        k2x = y_vel + (delta_t / 2) * k1v

        k3v = accel(Ground_Velocity, y_pos + (delta_t / 2) * k2x)
        k3x = y_vel + (delta_t / 2) * k2v

        k4v = accel(Ground_Velocity, y_pos + delta_t * k3x)
        k4x = y_vel + delta_t * k3v

        n_y_pos = y_pos + delta_t / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
        y_vel = y_vel + delta_t / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)

        n_x_pos = x_pos + Ground_Velocity * delta_t

        t = t + delta_t

        table.insert(path, { x = x_pos, y = y_pos })

        min_x = math.min(min_x, x_pos)
        max_x = math.max(max_x, x_pos)
        min_y = math.min(min_y, y_pos)
        max_y = math.max(max_y, y_pos)

        x_pos = n_x_pos
        y_pos = n_y_pos

        if y_pos < 0 or y_pos > 300000 or t > 1000 then
            satisfied = true
        end
    end

    -- Do min max processing here

    scale_x = max_x - min_x
    scale_y = max_y - min_y

    if scale_x > scale_y then
        center_y = (min_y + max_y) / 2
        scale = scale_x
        min_y = center_y - scale / 2
        max_y = center_y + scale / 2
    else
        center_x = (min_x + max_x) / 2
        scale = scale_y
        min_x = center_x - scale / 2
        max_x = center_x + scale / 2
    end

    addition = scale * Margin
    min_x = min_x - addition
    max_x = max_x + addition
    min_y = min_y - addition
    max_y = max_y + addition

    debug.log(min_x, max_x, min_y, max_y)

    for i = 2, #path do
        local p1 = path[i - 1]
        local p2 = path[i]

        local x1 = screen_remap(p1.x, min_x, max_x, width)
        local y1 = screen_remap(p1.y, min_y, max_y, height)
        local x2 = screen_remap(p2.x, min_x, max_x, width)
        local y2 = screen_remap(p2.y, min_y, max_y, height)

        screen.drawLine(x1, y1, x2, y2)
    end
end
