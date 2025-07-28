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

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(10, screenConnection.width)
        simulator:setInputNumber(11, screenConnection.height)
        simulator:setInputNumber(12, screenConnection.touchX)
        simulator:setInputNumber(13, screenConnection.touchY)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]


require("LifeBoatAPI.Drawing.LBColorSpace")

A = {1,1/60,1/7200,0,1,1/60,0,0,1}
Q = {1/1679616000000,1/9331200000,1/77760000,1/9331200000,1/51840000,1/432000,1/77760000,1/432000,1/3600}
-- Q = {
--  1/51840000, 1/432000, 1/7200,
--  1/432000,   1/3600,   1/60,
--  1/7200,     1/60,     1
-- }

Q = {
 100 * (1/7200)^2,  100 * (1/7200)*(1/60),  100 * (1/7200),
 100 * (1/7200)*(1/60),  100 * (1/60)^2,     100 * (1/60),
 100 * (1/7200),     100 * (1/60),         100
}

P_X = {100,0,0,0,100,0,0,0,100}
P_Y = {100,0,0,0,100,0,0,0,100}
P_Z = {100,0,0,0,100,0,0,0,100}
H = {1,0,0}
X = {0,0,0}
Y = {0,0,0}
Z = {0,0,0}

K = 100000
R = 0.0005

Ground_Velocity = 0

Wrap_Location_X = 0
Wrap_Location_Z = -K

Render_Min_X = -1
Render_Max_X = 1
Render_Min_Y = -1
Render_Max_Y = 1

Margin = .2

Focus_Moon = false
Focus_Target = true
Focus_Earth = false

Touch_X = 0
Touch_Y = 0
Is_Touch = false
Action_Taken = false

RENDER_MARGINS_LERP = .04

LOGO_FRAME_TIME = 60
Logo_Frame_Count = 0

CONTROLS_HEIGHT = 15

function adjust_bounding(current, target)
    return (target - current) * RENDER_MARGINS_LERP + current
end

function accel(v, d)
    G = 10
    R = (100000 / 3) * (1 + math.sqrt(10))
    return 1 + (v / 100) - (G * R * R) / ((R + d) ^ 2)
end

function screen_remap(location, min_range, max_range, screen_size)
    value = screen_size * ((location - min_range) / (max_range - min_range))

    return math.min(math.max(value, 0), screen_size)
end

function drawQuads(quads, minx, maxx, miny, maxy, width, height)

    for i = 1, #quads do
        local quad = quads[i]

        x1 = screen_remap(quad.ax, minx, maxx, width)
        y1 = screen_remap(quad.ay, maxy, miny, height)

        x2 = screen_remap(quad.bx, minx, maxx, width)
        y2 = screen_remap(quad.by, maxy, miny, height)

        x3 = screen_remap(quad.cx, minx, maxx, width)
        y3 = screen_remap(quad.cy, maxy, miny, height)

        x4 = screen_remap(quad.dx, minx, maxx, width)
        y4 = screen_remap(quad.dy, maxy, miny, height)

        screen.drawTriangleF(x1, y1, x2, y2, x3, y3)
        screen.drawTriangleF(x1, y1, x3, y3, x4, y4)

    end
end

function good_textbox(x, y, string, highlight)

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
	theta = (y - 1.28 * K) / K

    if y > 442159.265359 then
        x = 2 * K - x
        y = 570159.265359 - y
    elseif y > 1.28 * K then
        x = K - ((K - x) * math.cos(y / K - 1.28))
        y = 1.28 * K + ((K - x) * math.sin(y / K - 1.28))
    end

    -- Update all axis

    -- X
    pred = transform(A, X)
    Ppred = add(multiply(multiply(A, P_X), transpose(A)), Q)
    KM = scaleVec(transform(Ppred, H),1 / (dot(H,transform(Ppred, H)) + R))
	X = addVec(pred, scaleVec(KM, (x - dot(H,pred))))
	P_X = sub(Ppred, scaleMat(Ppred, dot(KM,H)))

    -- Y
    pred = transform(A, Y)
    Ppred = add(multiply(multiply(A, P_Y), transpose(A)), Q)
    KM = scaleVec(transform(Ppred, H),1 / (dot(H,transform(Ppred, H)) + R))
	Y = addVec(pred, scaleVec(KM, (y - dot(H,pred))))
	P_Y = sub(Ppred, scaleMat(Ppred, dot(KM,H)))

    -- Z
    pred = transform(A, Z)
    Ppred = add(multiply(multiply(A, P_Z), transpose(A)), Q)
    KM = scaleVec(transform(Ppred, H),1 / (dot(H,transform(Ppred, H)) + R))
	Z = addVec(pred, scaleVec(KM, (z - dot(H,pred))))
	P_X = sub(Ppred, scaleMat(Ppred, dot(KM,H)))

    Ground_Velocity = math.sqrt((X[2] ^ 2) + (Z[2] ^ 2))
end


function onDraw()
    -- Example that draws a red circle in the center of the screen with a radius of 20 pixels
    local width = screen.getWidth()
    local height = screen.getHeight()

    if Logo_Frame_Count < LOGO_FRAME_TIME then
        Logo_Frame_Count = Logo_Frame_Count + 1
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(66, 85, 235, 255)

        -- {ax = ,ay = ,bx = ,by = , cx = , cy = , dx = , dy = },        

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
        }, 5, 68, 2, 45, width, height)

        return
    end


    -- Do forward path estimation
    local satisfied = false
    local delta_t = 1
    local x_pos = X[1]
    local y_pos = Y[1]
    local t = 0
    local y_vel = Y[2]

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

        min_x = math.min(min_x, x_pos)
        max_x = math.max(max_x, x_pos)
        min_y = math.min(min_y, y_pos)
        max_y = math.max(max_y, y_pos)

        x_pos = n_x_pos
        y_pos = n_y_pos

        y_pos = math.max(0, y_pos)

        table.insert(path, { x = x_pos, y = y_pos })

        if y_pos <= 0 or y_pos > math.max(5*K, P_Y[1] + K) or t > 1000 then
            satisfied = true
        end
    end

    -- Do min max processing here, for focus viewing

    if Focus_Earth then
        min_x = math.min(min_x, -1.28 * K)
        max_x = math.max(max_x, 1.28 * K)
        min_y = math.min(min_y, 0)
        max_y = math.max(max_y, 1.28 * K)
    end

    if Focus_Moon then
        min_x = math.min(min_x, 1.845 * K)
        max_x = math.max(max_x, 2.155 * K)
        min_y = math.min(min_y, .8 * K)
        max_y = math.max(max_y, .8 * K)
    end

    -- Adjustments to rendering, for smooth vbox transitions. 
    Render_Min_X = adjust_bounding(Render_Min_X, min_x)
    Render_Max_X = adjust_bounding(Render_Max_X, max_x)
    Render_Min_Y = adjust_bounding(Render_Min_Y, min_y)
    Render_Max_Y = adjust_bounding(Render_Max_Y, max_y)

    min_x = Render_Min_X
    max_x = Render_Max_X
    min_y = Render_Min_Y
    max_y = Render_Max_Y

    -- Rendering stuff, based on bounding.

    local scale_x = max_x - min_x
    local scale_y = max_y - min_y

    local width_d2 = width / 2
    local reduced_height = height - CONTROLS_HEIGHT

    local aspect_ratio = (width_d2 / reduced_height)

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
    }, min_x, max_x, min_y, max_y, width_d2, reduced_height)

    -- Draw Moon

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 255, 255, 255)

    drawQuads({
        {ax= 1.845 * K, ay = .8 * K, bx = 2.155 * K, by = .8 * K, cx= 2.155 * K, cy = .6 * K, dx = 1.845 * K, dy = .6 * K}
    }, min_x, max_x, min_y, max_y, width_d2, reduced_height)

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

        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 255, 0, 255)

        if p2.y > 3 * K then
            LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(200, 0, 200, 255)
        end
        
        local x1 = screen_remap(p1.x, min_x, max_x, width_d2)
        local y1 = screen_remap(p1.y, max_y, min_y, reduced_height)
        local x2 = screen_remap(p2.x, min_x, max_x, width_d2)
        local y2 = screen_remap(p2.y, max_y, min_y, reduced_height)

        screen.drawLine(x1, y1, x2, y2)
    end

    last_point = path[#path]
    if last_point.y == 0 then
        LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(255, 0, 0, 255)
        local cx = screen_remap(last_point.x, min_x, max_x, width_d2)
        local cy = screen_remap(last_point.y, max_y, min_y, reduced_height)
        screen.drawLine(cx - 3, cy - 3, cx + 3, cy + 3)
        screen.drawLine(cx + 3, cy - 3, cx - 3, cy + 3)
    end

    local ship_x = screen_remap(X[1], min_x, max_x, width_d2)
    local ship_y = screen_remap(Y[1], max_y, min_y, reduced_height)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 255, 0, 255)
    screen.drawCircleF(ship_x, ship_y, 2)

    -- Draw Controls

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(150, 150, 150, 255)
    screen.drawRectF(0, height - CONTROLS_HEIGHT, width, CONTROLS_HEIGHT)


    focus_boxpos = height - CONTROLS_HEIGHT + 1

    Focus_Moon = good_textbox(32, focus_boxpos + 2, "Moon", Focus_Moon)
    Focus_Target = good_textbox(56, focus_boxpos + 2, "Tgt", Focus_Target)
    Focus_Earth = good_textbox(75, focus_boxpos + 2, "Earth", Focus_Earth)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(120, 120, 120, 255)

    screen.drawRect(30, focus_boxpos, 74, 12)

    LifeBoatAPI.LBColorSpace.lbcolorspace_setColorGammaCorrected(0, 0, 0, 255)

    screen.drawText(2, focus_boxpos + 4, "Focus:")

    screen.setColor(255,255,255)
    screen.drawText(10,10, Ground_Velocity)

end


