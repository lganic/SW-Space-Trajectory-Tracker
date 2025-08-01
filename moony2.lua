-- Author: lganic
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey / STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "5x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        ticks = math.max(0, ticks - 100)

        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)

        local A = 2
        local V0 = 0
        local P0 = 100

        PX0 = 2000
        PZ0 = -5000

        local VX = 7
        local VZ = 5

        -- simulator:setInputNumber(1, 0)
        -- simulator:setInputNumber(2, 0)
        -- simulator:setInputNumber(3, 0)

        local time = ticks / 60

        simulator:setInputNumber(1, PX0 + VX * time)
        simulator:setInputNumber(2, (A * time * time / 2) + V0 * time + P0)
        simulator:setInputNumber(3, PZ0 + VZ * time)

        simulator:setInputNumber(7, screenConnection.touchX)
        simulator:setInputNumber(8, screenConnection.touchY)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]


require("LifeBoatAPI.Drawing.LBColorSpace")

-- Kalman filters related matrices
A = {1,1/60,1/7200,0,1,1/60,0,0,1}
Q = {1/1679616000000,1/9331200000,1/77760000,1/9331200000,1/51840000,1/432000,1/77760000,1/432000,1/3600}
P_X = {100,0,0,0,100,0,0,0,100}
P_Y = {100,0,0,0,100,0,0,0,100}
P_Z = {100,0,0,0,100,0,0,0,100}
H = {1,0,0}
X = {0,0,0}
Y = {0,0,0}
Z = {0,0,0}

K = 100000
RK = 0.000001

Ground_Velocity = 0

Wrap_Location_X = 0
Wrap_Location_Z = -K

Render1_Min_X = -1
Render1_Max_X = 1
Render1_Min_Y = -1
Render1_Max_Y = 1

Render2_Min_X = -1
Render2_Max_X = 1
Render2_Min_Z = -1
Render2_Max_Z = 1

Margin = .2

Focus_Moon = false
Focus_Target = false
Focus_Earth = true

Touch_X = 0
Touch_Y = 0
Is_Touch = false
Action_Taken = false

RENDER_MARGINS_LERP = .1

LOGO_FRAME_TIME = 60
Logo_Frame_Count = 0

CONTROLS_HEIGHT = 15

function adjust_bounding(current, target)
    return (target - current) * RENDER_MARGINS_LERP + current
end

function accel(v, d)
    G = 10
    R = (100000 / 3) * (1 + math.sqrt(10))
    return math.min(1, d / 40000) + (v / 100) - (G * R * R) / ((R + d) ^ 2)
end

function screen_remap(location, min_range, max_range, screen_size)
    value = screen_size * ((location - min_range) / (max_range - min_range))

    return math.min(math.max(value, 0), screen_size)
end

function drawQuads(quads, minx, maxx, miny, maxy, width, height, add_x)

    for i = 1, #quads do
        local quad = quads[i]

        x1 = screen_remap(quad.ax, minx, maxx, width) + add_x
        y1 = screen_remap(quad.ay, maxy, miny, height)

        x2 = screen_remap(quad.bx, minx, maxx, width) + add_x
        y2 = screen_remap(quad.by, maxy, miny, height)

        x3 = screen_remap(quad.cx, minx, maxx, width) + add_x
        y3 = screen_remap(quad.cy, maxy, miny, height)

        x4 = screen_remap(quad.dx, minx, maxx, width) + add_x
        y4 = screen_remap(quad.dy, maxy, miny, height)

        screen.drawTriangleF(x1, y1, x2, y2, x3, y3)
        screen.drawTriangleF(x1, y1, x3, y3, x4, y4)

    end
end

function qDrawMap(x, y, width, height, min_x, max_x, min_z, max_z, screen_width, screen_height)
    drawQuads({
        {ax = x, ay = y, bx = x, by = y + height, cx = x + width, cy = y + height, dx = x + width, dy = y},        
    }, min_x, max_x, min_z, max_z, screen_width, screen_height, screen_width)
end

function simple_button(x, y, string, highlight)

    text_length = 5 * #string

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(100, 100, 100, 255)

    screen.drawRectF(x, y, text_length + 3, 9)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(200, 200, 200, 255)
    if highlight then
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 200, 0, 255)
    end

    screen.drawRectF(x + 1, y + 1, text_length + 1, 7)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 0, 0, 255)

    screen.drawText(x + 2, y + 2, string)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(150, 150, 150, 255)

    screen.drawRectF(x, y, 1, 1)
    screen.drawRectF(x+text_length+2, y, 1, 1)
    screen.drawRectF(x+text_length+2, y+8, 1, 1)
    screen.drawRectF(x, y+8, 1, 1)

    if Is_Touch then
        if Action_Taken then
            return highlight
        end

        if Is_Touch and Touch_X >= x and Touch_X < x + text_length + 3 and Touch_Y >= y and Touch_Y < y + 9 then
            Action_Taken = true
            return not highlight
        end
    else
        Action_Taken = false
    end

    return highlight

end

function transform(M,v)
	return {(M[1] * v[1]) + (M[2] * v[2]) + (M[3] * v[3]), (M[4] * v[1]) + (M[5] * v[2]) + (M[6] * v[3]), (M[7] * v[1]) + (M[8] * v[2]) + (M[9] * v[3])}
end

function dot(v1,v2)
	return v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3]
end

function transpose(M)
	return {M[1], M[4], M[7], M[2], M[5], M[8], M[3], M[6], M[9]}
end
	
function scaleVec(v,s)
	return {v[1] *s, v[2] *s, v[3] *s}
end

function scaleMat(M,s)
	local out = {}
	for i=1,9 do out[i]=M[i] *s end
	return out
end

function multiply(a,b)
	local r={}
	for i=0,2 do
		for j=1,3 do
			r[i*3+j]=a[i*3+1]*b[j]+a[i*3+2]*b[j+3]+a[i*3+3]*b[j+6]
		end
	end
	return r
end

function add(a,b)
	local r={}
	for i=1,9 do r[i]=a[i]+b[i] end
	return r
end

function sub(a,b)
	local r={}
	for i=1,9 do r[i]=a[i]-b[i] end
	return r
end

function addVec(a,b)
	local r={}
	for i=1,3 do r[i]=a[i]+b[i] end
	return r
end

function onTick()
	moonmode = input.getBool(1)
	x = input.getNumber(1)
	y = input.getNumber(2)
	z = input.getNumber(3)

    Touch_X = input.getNumber(7)
    Touch_Y = input.getNumber(8)
    Is_Touch = input.getBool(1)

    -- Astronomy to real coordinates
	theta = (y - 1.28 * K) / K
    if y > 442159.265359 then
        x = 2 * K - x
        y = 570159.265359 - y
    elseif y > 1.28 * K then
        xn = K - ((K - x) * math.cos(y / K - 1.28))
        y = 1.28 * K + ((K - x) * math.sin(y / K - 1.28))
        x=xn
    end

    -- Apply Kalman Filters

    -- X
    pred = transform(A, X)
    Ppred = add(multiply(multiply(A, P_X), transpose(A)), Q)
    KM = scaleVec(transform(Ppred, H),1 / (dot(H, transform(Ppred, H)) + RK))
	X = addVec(pred, scaleVec(KM, (x - dot(H, pred))))
	P_X = sub(Ppred, scaleMat(Ppred, dot(KM, H)))

    -- Y
    pred = transform(A, Y)
    Ppred = add(multiply(multiply(A, P_Y), transpose(A)), Q)
    KM = scaleVec(transform(Ppred, H),1 / (dot(H, transform(Ppred, H)) + RK))
	Y = addVec(pred, scaleVec(KM, (y - dot(H, pred))))
	P_Y = sub(Ppred, scaleMat(Ppred, dot(KM, H)))

    -- Z
    pred = transform(A, Z)
    Ppred = add(multiply(multiply(A, P_Z), transpose(A)), Q)
    KM = scaleVec(transform(Ppred, H),1 / (dot(H, transform(Ppred, H)) + RK))
	Z = addVec(pred, scaleVec(KM, (z - dot(H, pred))))
	P_Z = sub(Ppred, scaleMat(Ppred, dot(KM, H)))

    Ground_Velocity = math.sqrt((X[2] ^ 2) + (Z[2] ^ 2))
end


function onDraw()
    local width = screen.getWidth()
    local height = screen.getHeight()

    local width_d2 = width / 2
    local reduced_height = height - CONTROLS_HEIGHT
    local aspect_ratio = (width_d2 / reduced_height)

    -- Display Logo
    if Logo_Frame_Count < LOGO_FRAME_TIME then
        Logo_Frame_Count = Logo_Frame_Count + 1
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(66, 85, 235, 255)

        drawQuads({
            {ax = 10,  ay = 10,  bx = 15,  by = 30,  cx = 20,  cy = 30,  dx = 15,  dy = 10},
            {ax = 11,  ay = 10,  bx = 16,  by = 14,  cx = 27,  cy = 14,  dx = 26,  dy = 10},

            {ax = 28,  ay = 10,  bx = 35,  by = 38,  cx = 39,  cy = 38,  dx = 32,  dy = 10},
            {ax = 15,  ay = 34,  bx = 16,  by = 38,  cx = 62,  cy = 38,  dx = 61,  dy = 34},

            {ax = 34,  ay = 10,  bx = 39,  by = 30,  cx = 42,  cy = 30,  dx = 37,  dy = 10},
            {ax = 40,  ay = 30,  bx = 48,  by = 30,  cx = 47,  cy = 26,  dx = 39,  dy = 26},
            {ax = 38,  ay = 22,  bx = 46,  by = 22,  cx = 45,  cy = 18,  dx = 37,  dy = 18},
            {ax = 37,  ay = 14,  bx = 44,  by = 14,  cx = 43,  cy = 10,  dx = 37,  dy = 10},

            {ax = 45,  ay = 10,  bx = 50,  by = 30,  cx = 53,  cy = 30,  dx = 48,  dy = 10},
            {ax = 50,  ay = 30,  bx = 60,  by = 30,  cx = 59,  cy = 26,  dx = 49,  dy = 26},
            {ax = 46,  ay = 14,  bx = 56,  by = 14,  cx = 55,  cy = 10,  dx = 45,  dy = 10}
        }, 5, 68, 2, 45, width, height, 0)

        return
    end

    -- Do forward path estimation
    local satisfied = false
    local delta_t = .1
    local x_pos = X[1]
    local y_pos = Y[1]
    local z_pos = Z[1]
    local t = 0
    local y_vel = Y[2]

    local path = {}
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge
    local min_z, max_z = math.huge, -math.huge
    
    table.insert(path, { x = x_pos, y = y_pos, z = z_pos})

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

        -- Calculate new y position, and new y velocity based on integration
        n_y_pos = y_pos + delta_t / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
        y_vel = y_vel + delta_t / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)

        -- Calculate new X and Z position based on constant velocity dead reckoning
        n_x_pos = x_pos + X[2] * delta_t
        n_z_pos = z_pos + Z[2] * delta_t

        t = t + delta_t

        if n_y_pos < 0 then

            -- Create estimate of actual impact point based on projected position, by assuming a linear trajectory between pos, and new position

            local lerp_value = y_pos / (y_pos - n_y_pos)
            n_x_pos = (n_x_pos - x_pos) * lerp_value + x_pos
            n_z_pos = (n_z_pos - z_pos) * lerp_value + z_pos

            n_y_pos = 0 -- Cap y position, cause alt can never be negative. This allows us to detect a ground impact point later
        end

        x_pos = n_x_pos
        y_pos = n_y_pos
        z_pos = n_z_pos

        min_x = math.min(min_x, x_pos)
        max_x = math.max(max_x, x_pos)
        min_y = math.min(min_y, y_pos)
        max_y = math.max(max_y, y_pos)
        min_z = math.min(min_z, z_pos)
        max_z = math.max(max_z, z_pos)

        table.insert(path, { x = x_pos, y = y_pos, z = z_pos})

        -- If altitude is less than zero, or greater than 10 minutes in path time. Or if altitude is greater than 500k (altitude probably runaway)
        -- There is a special case here, that if you are above 500k, the projected path can go above its 500k cap, up to 100k + your current alt
        -- this is to ensure that you always have a decent idea of your trajectory. 

        if y_pos <= 0 or y_pos > math.max(5*K, P_Y[1] + K) or t > 600 then
            satisfied = true
        end

        delta_t = delta_t + .1 -- Slightly increase delta t each frame, to increase performance in later stage predictions, where precision is less required.
    end

    -- min max processing, for focus viewing

    if Focus_Earth then
        min_x = math.min(min_x, -1.28 * K)
        max_x = math.max(max_x, 1.28 * K)
        min_y = math.min(min_y, 0)
        max_y = math.max(max_y, 1.28 * K)
        min_z = math.min(min_x, -1.28 * K)
        max_z = math.max(max_x, 1.28 * K)
    end

    if Focus_Moon then
        min_x = math.min(min_x, 1.845 * K)
        max_x = math.max(max_x, 2.155 * K)
        min_y = math.min(min_y, .8 * K)
        max_y = math.max(max_y, .8 * K)
        min_z = math.min(min_z, -15500)
        max_z = math.max(max_z, 15500)
    end

    -- TODO: Target view focusing

    -- Render everything, based on bounding.

    -- Render1 is for the left map, Render 2 is for the right map

    -- I am going to do render 2 first, that way I might be able to use screen.drawMap down the line.

    -- Adjustments to rendering, for smooth vbox transitions. 
    Render1_Min_X = adjust_bounding(Render1_Min_X, min_x)
    Render1_Max_X = adjust_bounding(Render1_Max_X, max_x)
    Render1_Min_Y = adjust_bounding(Render1_Min_Y, min_y)
    Render1_Max_Y = adjust_bounding(Render1_Max_Y, max_y)
    Render2_Min_X = adjust_bounding(Render2_Min_X, min_x)
    Render2_Max_X = adjust_bounding(Render2_Max_X, max_x)
    Render2_Min_Z = adjust_bounding(Render2_Min_Z, min_z)
    Render2_Max_Z = adjust_bounding(Render2_Max_Z, max_z)

    -- Do render 2

    min_x = Render2_Min_X
    max_x = Render2_Max_X
    min_z = Render2_Min_Z
    max_z = Render2_Max_Z

    -- Adjust the framing to ensure that we maintain a square aspect ratio, but still respecting the calculated min/max sizes
    local scale_x = max_x - min_x
    local scale_z = max_z - min_z

    scale_x = scale_x / aspect_ratio

    if scale_x > scale_z then
        center_z = (min_z + max_z) / 2
        scale = scale_x
        min_z = center_z - scale / 2
        max_z = center_z + scale / 2
    else
        center_x = (min_x + max_x) / 2
        scale = scale_z
        min_x = center_x - (scale * aspect_ratio) / 2
        max_x = center_x + (scale * aspect_ratio) / 2
    end

    -- Apply a margin to the current bounding, to make sure everything appears neatly on screen
    addition = scale * Margin
    min_x = min_x - addition * aspect_ratio
    max_x = max_x + addition * aspect_ratio
    min_z = min_z - addition
    max_z = max_z + addition

    -- Draw earth

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 255, 255, 255)

    qDrawMap(-1.28 * K, -1.28 * K, 2.56 * K, 2.56 * K, min_x, max_x, min_z, max_z, width_d2, reduced_height)

    -- Draw moon

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 255, 255, 255)

    qDrawMap(1.845 * K, -15500, 31000, 31000, min_x, max_x, min_z, max_z, width_d2, reduced_height)

    -- Draw Land
    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(164, 184, 117, 255)
    qDrawMap(-8000, -12000, 20000, 10000, min_x, max_x, min_z, max_z, width_d2, reduced_height)

    -- Draw Arid Island
    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(227, 208, 141, 255)
    qDrawMap(-24000, -37000, 29000, 14000, min_x, max_x, min_z, max_z, width_d2, reduced_height)

    for i = 2, #path do
        local p1 = path[i - 1]
        local p2 = path[i]

        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 200, 0, 255)

        if p2.y > 3 * K then
            LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(200, 0, 200, 255)
        end
        
        local x1 = screen_remap(p1.x, min_x, max_x, width_d2) + width_d2
        local y1 = screen_remap(p1.z, max_z, min_z, reduced_height)
        local x2 = screen_remap(p2.x, min_x, max_x, width_d2) + width_d2
        local y2 = screen_remap(p2.z, max_z, min_z, reduced_height)

        screen.drawLine(x1, y1, x2, y2)
    end

        -- If last point is an impact point, then draw an X there. 

    last_point = path[#path]
    if last_point.y == 0 then
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 0, 0, 255)
        local cx = screen_remap(last_point.x, min_x, max_x, width_d2) + width_d2
        local cy = screen_remap(last_point.z, max_z, min_z, reduced_height)
        screen.drawLine(cx - 2, cy - 2, cx + 2, cy + 2)
        screen.drawLine(cx + 2, cy - 2, cx - 2, cy + 2)
    end

    -- Draw ship
    local ship_x = screen_remap(X[1], min_x, max_x, width_d2) + width_d2
    local ship_y = screen_remap(Z[1], max_z, min_z, reduced_height)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(200, 200, 200, 255)
    screen.drawCircleF(ship_x, ship_y, 1)

    -- Prep for render 1

    -- First, draw a rect over the left side of the screen, to ensure that the we have a nice drawing space to work with. 

    screen.setColor(0,0,0)
    screen.drawRect(0, 0, width_d2, reduced_height)

    -- Draw seperation line between render 1 and render 2
    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(150, 150, 150, 255)
    screen.drawLine(width_d2, 0, width_d2, reduced_height)

    -- Do render 1

    min_x = Render1_Min_X
    max_x = Render1_Max_X
    min_y = Render1_Min_Y
    max_y = Render1_Max_Y

    -- Adjust the framing to ensure that we maintain a square aspect ratio, but still respecting the calculated min/max sizes
    local scale_x = max_x - min_x
    local scale_y = max_y - min_y

    scale_x = scale_x / aspect_ratio

    if scale_x > scale_y then
        center_y = (min_y + max_y) / 2
        scale = scale_x
        min_y = center_y - scale / 2
        max_y = center_y + scale / 2
    else
        center_x = (min_x + max_x) / 2
        scale = scale_y
        min_x = center_x - (scale * aspect_ratio) / 2
        max_x = center_x + (scale * aspect_ratio) / 2
    end

    -- Apply a margin to the current bounding, to make sure everything appears neatly on screen
    addition = scale * Margin
    min_x = min_x - addition * aspect_ratio
    max_x = max_x + addition * aspect_ratio
    min_y = min_y - addition
    max_y = max_y + addition

    -- debug.log(min_x, max_x, min_y, max_y)

    -- Draw earth

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 255, 255, 255)

    drawQuads({
        {ax = 1.28 * K, ay = .4 * K, bx = 1.28 * K, by = 0, cx = -1.28 * K, cy = 0, dx = -1.28 * K, dy = .4 * K},        
        {ax = .4 * K, ay = 1.28 * K, bx = .4 * K, by = .4 * K, cx = -.4 * K, cy = .4 * K, dx = -.4 * K, dy = 1.28 * K}        
    }, min_x, max_x, min_y, max_y, width_d2, reduced_height, 0)

    -- Draw Moon

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 255, 255, 255)

    drawQuads({
        {ax= 1.845 * K, ay = .8 * K, bx = 2.155 * K, by = .8 * K, cx= 2.155 * K, cy = .6 * K, dx = 1.845 * K, dy = .6 * K}
    }, min_x, max_x, min_y, max_y, width_d2, reduced_height, 0)

    -- Draw Geostationary orbit line.

    line_pos = screen_remap(3*K, max_y, min_y, reduced_height)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 0, 150, 255)
    screen.drawLine(0, line_pos, width_d2, line_pos)

    -- Draw Leftward position wrapping

    line_pos = screen_remap(1.28*K, max_y, min_y, reduced_height)
    line_x_pos = screen_remap(-.4*K, min_x, max_x, width_d2)

    if line_x_pos > 0 then
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 0, 0, 255)
        screen.drawLine(0, line_pos, line_x_pos, line_pos)
    end

    -- Render the path

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 0, 255, 255)
    
    for i = 2, #path do
        local p1 = path[i - 1]
        local p2 = path[i]

        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 200, 0, 255)

        if p2.y > 3 * K then
            LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(200, 0, 200, 255)
        end
        
        local x1 = screen_remap(p1.x, min_x, max_x, width_d2)
        local y1 = screen_remap(p1.y, max_y, min_y, reduced_height)
        local x2 = screen_remap(p2.x, min_x, max_x, width_d2)
        local y2 = screen_remap(p2.y, max_y, min_y, reduced_height)

        screen.drawLine(x1, y1, x2, y2)
    end

    -- If last point is an impact point, then draw an X there. 

    last_point = path[#path]
    if last_point.y == 0 then
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 0, 0, 255)
        local cx = screen_remap(last_point.x, min_x, max_x, width_d2)
        local cy = screen_remap(last_point.y, max_y, min_y, reduced_height)
        screen.drawLine(cx - 2, cy - 2, cx + 2, cy + 2)
        screen.drawLine(cx + 2, cy - 2, cx - 2, cy + 2)
    end

    -- Draw the ship position

    local ship_x = screen_remap(X[1], min_x, max_x, width_d2)
    local ship_y = screen_remap(Y[1], max_y, min_y, reduced_height)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(200, 200, 200, 255)
    screen.drawCircleF(ship_x, ship_y, 1)

    -- Draw Controls

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(150, 150, 150, 255)
    screen.drawRectF(0, height - CONTROLS_HEIGHT, width, CONTROLS_HEIGHT)


    focus_boxpos = height - CONTROLS_HEIGHT + 1

    Focus_Moon = simple_button(23, focus_boxpos + 2, "Moon", Focus_Moon)
    Focus_Target = simple_button(47, focus_boxpos + 2, "Tgt", Focus_Target)
    Focus_Earth = simple_button(66, focus_boxpos + 2, "Earth", Focus_Earth)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(120, 120, 120, 255)

    screen.drawRect(21, focus_boxpos, 74, 12)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 0, 0, 255)

    screen.drawText(2, focus_boxpos + 4, "Foc:")
end


