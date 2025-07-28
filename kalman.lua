-- Author: lganic
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
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
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

A={1,1/60,1/7200,0,1,1/60,0,0,1}
Q={1/1679616000000,1/9331200000,1/77760000,1/9331200000,1/51840000,1/432000,1/77760000,1/432000,1/3600}
P={100,0,0,0,100,0,0,0,100}
H={1,0,0}
X={0,0,0}

R = 0.0005

function onTick()

    z = input.getNumber(1)

    -- Prediction
    Xpred = transform(A,X)
    Ppred = add(multiply(multiply(A,P),transpose(A)),Q)

    -- Update
    K = scale(transform(Ppred,H),1/(dot(H,transform(Ppred,H))+R))
	X = addVec(Xpred,scale(K,(z-dot(H,Xpred))))
	P = sub(Ppred,scaleMat(Ppred,dot(K,H)))

    -- Output
    output.setNumber(1,X[1]) -- Position
	output.setNumber(2,X[2]) -- Velocity
	output.setNumber(3,X[3]) -- Acceleration
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
	
function scale(v,s)
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
